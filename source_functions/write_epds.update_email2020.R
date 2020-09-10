## ----setup, include=FALSE-----------------------------------------------------------------------------------------------------------------------
knitr::opts_chunk$set(echo = TRUE)
library(stringr)
library(dplyr)
library(readr)
library(dplyr)

source(here::here("source_functions/calculate_acc.R"))


## -----------------------------------------------------------------------------------------------------------------------------------------------
farm_list <-
  combine(
    list.files(path = "~/Box Sync/HairShedding/ReportedData/2016", full.names = TRUE),
    list.files(path = "~/Box Sync/HairShedding/ReportedData/2017", full.names = TRUE),
    list.files(path = "~/Box Sync/HairShedding/ReportedData/2018", full.names = TRUE),
    list.files(path = "~/Box Sync/HairShedding/ReportedData/2019", full.names = TRUE)
  ) %>% 
  str_extract(., "(?<=_)[[:alnum:]]+(?=_)") %>% 
  # Arkansas is processed separately
  str_subset(., "UofA", negate = TRUE) %>% 
  unique(.)


## -----------------------------------------------------------------------------------------------------------------------------------------------
update_sol <-
  # blupf90 solutions
  read_table2(
    here::here("data/derived_data/update_email2020/no_breed/solutions"),
    col_names = c("trait", "effect", "id_new", "solution", "se"),
    skip = 1
  ) %>%
  # limit to animal effect
  filter(effect == 2) %>%
  select(id_new, solution, se) %>%
  # Re-attach original IDs
  left_join(read_table2(
    here::here("data/derived_data/update_email2020/no_breed/renadd02.ped"),
    col_names = FALSE
  ) %>%
    select(id_new = X1, full_reg = X10)) %>%
  select(full_reg, everything(), -id_new) %>%
  # re-attach ID metadata
  left_join(
    read_rds(here::here("data/derived_data/update_dat.rds")) %>%
      distinct(
        full_reg,
        farm_id,
        animal_id,
        temp_id,
        Lab_ID,
        breed_code,
        sex,
        genotyped
      )
  ) %>%
  # standardize breed codes
  mutate(
    breed_code = if_else(
      is.na(breed_code),
      str_extract(
        full_reg,
        "^SIM|^HER|^RAN|^BSH|^CIA|^RDP|^CHA|^BGR|^AAA|^AMGV|^GVH|^HFD|^BIR|^AAN|^AMAR|^AMXX"
      ),
      breed_code
    ),
    breed_code =
      case_when(
        breed_code %in% c("AAA", "AAN", "AN", "BIR") ~ "AN",
        breed_code %in% c("ANR", "AMAR", "RAN") ~ "ANR",
        breed_code %in% c("HER", "HFD") ~ "HFD",
        breed_code %in% c("AMXX", "AMGV", "GVH", "GEL") ~ "GEL",
        breed_code %in% c("BGR", "BG") ~ "BG",
        breed_code %in% c("MAAN", "RDP") ~ "MAAN",
        breed_code %in% c("SH", "BSH") ~ "SH",
        breed_code %in% c("CHIA", "CIA") ~ "CHIA",
        is.na(breed_code) ~ "CROS",
        TRUE ~ breed_code
      ),
    # calculate accuracy
    acc = purrr::map_dbl(.x = se, ~ calculate_acc(
      e = 0.50472, u = 0.32498, se = .x, option = "bif"
    )),
    # divide breeding values by 2 to get epd
    epd = solution / 2
  ) %>%
  # add full breed name
  left_join(
    read_csv("~/googledrive/research_extension/breeds.csv") %>%
      select(breed_code = assoc_code,
             breed_name = Breed)
  ) %>%
  select(
    full_reg,
    farm_id,
    animal_id,
    temp_id,
    Lab_ID,
    breed_code,
    breed_name,
    sex,
    epd,
    acc,
    se,
    genotyped
  ) 



## -----------------------------------------------------------------------------------------------------------------------------------------------
email_sol <-
  read_table2(
  here::here("data/derived_data/update_email2020/no_breed/data.txt"),
  col_names = c("full_reg", "cg", "hair_score")
) %>%
  group_by(full_reg) %>%
  tally(name = "n_scores", sort = TRUE) %>%
  ungroup() %>%
  right_join(update_sol) %>% 
  mutate(genotyped = if_else(is.na(genotyped), FALSE, genotyped)) %>% 
  filter(!is.na(farm_id) & !farm_id %in% c("SAV", "BAT")) %>% 
  left_join(read_rds(here::here("data/derived_data/cleaned.rds")) %>%
              select(farm_id, registration_number, animal_id, sex, temp_id, sold) %>% 
              distinct()) %>% 
  select(farm_id, animal_id, registration_number, breed_code, sex, epd, epd_accuracy = acc, n_scores, genotype_used = genotyped, sold) %>% 
  mutate_at(vars(contains("epd")), ~ round(., digits = 2))
  


## -----------------------------------------------------------------------------------------------------------------------------------------------

purrr::map(.x = farm_list,
           ~ email_sol %>%
             filter(farm_id == .x) %>%
             writexl::write_xlsx(
               glue::glue(
                 "~/Box Sync/HairShedding/ReportedData/EPDs2020/{.x}_April2020EPDs.xlsx"
               )
             ))

  

