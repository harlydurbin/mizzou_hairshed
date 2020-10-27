## ----setup, include=FALSE-------------------------------------------------------------------------------------------------------
knitr::opts_chunk$set(echo = TRUE)
library(readr)
library(dplyr)
library(glue)
library(purrr)
library(DRP)
library(magrittr)
library(stringr)
library(tidylog)

source(here::here("source_functions/calculate_acc.R"))



## -------------------------------------------------------------------------------------------------------------------------------
dir <- as.character(commandArgs(trailingOnly = TRUE)[1])

animal_effect <- as.numeric(commandArgs(trailingOnly = TRUE)[2])

gen_var <- as.numeric(commandArgs(trailingOnly = TRUE)[3])

h2 <- as.numeric(commandArgs(trailingOnly = TRUE)[4])

model <- str_extract(dir, "(?<=/)[[:alnum:]]+$")


## -------------------------------------------------------------------------------------------------------------------------------
full_ped <- read_rds(here::here("data/derived_data/3gen/full_ped.rds"))


## -------------------------------------------------------------------------------------------------------------------------------
ped_inb <- read_csv(here::here("data/derived_data/grm_inbreeding/ped_inb.csv"))


## -------------------------------------------------------------------------------------------------------------------------------
trait <-
  read_table2(here::here(glue("{dir}/solutions")),
              col_names = c("trait", "effect", "id_new", "solution", "se"),
              skip = 1) %>%
  # limit to animal effect
  filter(effect == animal_effect) %>%
  select(id_new, solution, se) %>% 
  # Re-attach original IDs
  left_join(read_table2(here::here(glue("{dir}/renadd0{animal_effect}.ped")),
                        col_names = FALSE) %>%
              select(id_new = X1, full_reg = X10)) %>%
  left_join(ped_inb) %>%
  mutate(f = tidyr::replace_na(f, 0),
         acc = purrr::map2_dbl(.x = se,
                               .y = f,
                              ~ calculate_acc(u = gen_var,
                                              se = .x,
                                              f = .y,
                                              option = "reliability")),
         acc = if_else(0 > acc, 0, acc))


## -------------------------------------------------------------------------------------------------------------------------------
trait %<>% 
  left_join(read_csv(here::here("data/derived_data/grm_inbreeding/mizzou_hairshed.diagonal.full_reg.csv"))) %>% 
  filter(!is.na(diagonal)) %>% 
  left_join(full_ped %>% 
              select(full_reg, sire_reg, dam_reg)) %>% 
  left_join(trait %>% 
              select(sire_reg = full_reg, sire_acc = acc, sire_sol = solution)) %>% 
  left_join(trait %>% 
              select(dam_reg = full_reg, dam_acc = acc, dam_sol = solution)) %>% 
  select(contains("reg"), contains("sol"), contains("acc")) %>% 
  mutate_at(vars(contains("reg")), 
            ~ if_else(. == "0", NA_character_, .))


## -------------------------------------------------------------------------------------------------------------------------------
wideDRP(Data = trait,
        animalId = "full_reg",
        sireId = "sire_reg",
        damId = "dam_reg",
        animalEBV = "solution",
        sireEBV = "sire_sol",
        damEBV = "dam_sol",
        animalr2 = "acc",
        sirer2 = "sire_acc",
        damr2 = "dam_acc",
        c = 0.1,
        h2 = h2) %>% 
  mutate(Group = 1,
         Rel = sqrt(Anim_DRP_Trait_r2),
         Rel = (1/Rel)-1) %>%
  select(ID = full_reg, Group, Obs = Anim_DRP_Trait, Rel, acc) %>% 
  assertr::verify(between(Rel, 0, 1)) %>% 
  write_tsv(here::here(glue("data/derived_data/snp1101/{model}/trait.txt")))

