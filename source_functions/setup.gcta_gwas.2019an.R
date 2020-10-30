#' ---
#' title: "GCTA GWAS"
#' author: "Harly Durbin"
#' output: html_document
#' ---
#'
## ----setup, include=FALSE-----------------------------------------------------------------------------------------------------------
knitr::opts_chunk$set(echo = TRUE)
library(readr)
library(tidyr)
library(stringr)
library(dplyr)
library(glue)
library(magrittr)
library(lubridate)
library(tidylog)
library(readxl)

#'
#' # Notes & questions
#'
#' # Setup
#'
## ---- warning=FALSE, message=FALSE--------------------------------------------------------------------------------------------------
cleaned <- read_rds(here::here("data/derived_data/import_join_clean/cleaned.rds"))

#'
## ---- warning=FALSE, message=FALSE--------------------------------------------------------------------------------------------------

breed_key <- read_rds(here::here("data/derived_data/breed_key/breed_key.rds"))

genotyped <- read_csv(here::here("data/derived_data/grm_inbreeding/mizzou_hairshed.diagonal.full_reg.csv"))

full_ped <- read_rds(here::here("data/derived_data/3gen/full_ped.rds"))

## Angus data only

dat <-
  breed_key %>% 
  mutate(keep = case_when(cross == "AN" ~ TRUE,
                          source == "American Angus Association" ~ TRUE,
                          brd_source == "American Angus Association" ~ TRUE,
                          an == 1 ~ TRUE,
                          TRUE ~ FALSE)) %>% 
  filter(keep == TRUE) %>% 
  select(Lab_ID:full_reg) %>% 
  left_join(cleaned)

#'
#' # Score group

#'
## -----------------------------------------------------------------------------------------------------------------------------------
dat %<>%
  left_join(bind_rows(read_excel(here::here("data/derived_data/ua_score_groups.xlsx")),
                      read_excel(here::here("data/derived_data/score_groups.xlsx"))) %>%
              select(farm_id, date_score_recorded, score_group) %>%
              mutate(date_score_recorded = lubridate::ymd(date_score_recorded))) %>%
  mutate(score_group = tidyr::replace_na(score_group, 1))

#'
## -----------------------------------------------------------------------------------------------------------------------------------
dat %>%
  distinct(score_group)

#'
#' # Remove males
#'
## -----------------------------------------------------------------------------------------------------------------------------------
dat %<>%
  filter(sex == "F")

#'
#' # Calving season
#'
## -----------------------------------------------------------------------------------------------------------------------------------
dat %<>%
  # If calving season missing, impute using most recent calving season
  group_by(farm_id, temp_id) %>%
  arrange(date_score_recorded) %>%
  fill(calving_season, .direction = "downup") %>%
  ungroup() %>%
  # If calving season still missing, impute using DOB
  mutate(calving_season = case_when(farm_id == "UMCT" ~ "SPRING",
                                    farm_id == "UMF" ~ "FALL",
                                    is.na(calving_season) &
                                      between(lubridate::month(dob),
                                              left = 1,
                                              right = 6) ~ "SPRING",
                                    is.na(calving_season) &
                                      between(lubridate::month(dob),
                                              left = 7,
                                              right = 12) ~ "FALL",
                                    TRUE ~ calving_season))

#'
#' # Age group
#'
## -----------------------------------------------------------------------------------------------------------------------------------

dat %<>%
  mutate(age_group = case_when(age == 1 ~ "yearling",
                               age %in% c(2, 3) ~ "growing",
                               between(age, 4, 9) ~ "mature",
                               age >= 10 ~ "old"))


#'
#' # Toxic fescue
#'
## -----------------------------------------------------------------------------------------------------------------------------------

dat %<>%
  mutate(toxic_fescue = if_else(farm_id %in% c("BAT", "CRC"),
                                "YES",
                                toxic_fescue))


#'
#' # Contemporary group
#'
## -----------------------------------------------------------------------------------------------------------------------------------
dat %<>%
  mutate(cg = glue("{farm_id}{year}{calving_season}{age_group}{score_group}{toxic_fescue}"),
         cg_num = as.integer(factor(cg)))

# Specified year only

dat %<>% 
  filter(year == 2019)
#'
#' # Export
#'
#' ## Data
#'
## -----------------------------------------------------------------------------------------------------------------------------------
matched <-
  dat %>%
  left_join(full_ped %>%
              distinct(farm_id, temp_id, full_reg)) %>%
  mutate(breed_code = case_when(breed_code == "AN" ~ "AAA",
                                breed_code == "ANR" ~ "RAN",
                                breed_code == "BG" ~ "BGR",
                                breed_code == "BRN" ~ "BSW",
                                breed_code == "MAAN" ~ "RDP",
                                breed_code == "HFD" ~ "HER",
                                TRUE ~ breed_code),
         full_reg = case_when(is.na(full_reg) &
                                !is.na(registration_number) ~ glue("{breed_code}{registration_number}"),
                              is.na(full_reg) &
                                is.na(registration_number) ~ glue("{farm_id}{animal_id}{temp_id}"),
                              TRUE ~ full_reg)) %>%
  assertr::verify(!is.na(full_reg)) %>%
  assertr::verify(!is.na(hair_score)) 


matched %<>% 
  group_by(full_reg) %>% 
  slice(1) %>% 
  ungroup()

matched %<>% 
  left_join(read_table2(here::here("data/derived_data/grm_inbreeding/mizzou_hairshed.grm.id"),
                        col_names = c("full_reg", "iid"))) %>% 
  filter(!is.na(iid))

#'
## -----------------------------------------------------------------------------------------------------------------------------------
matched %>%
  select(full_reg, iid, hair_score) %>%
  write_delim(here::here("data/derived_data/gcta_gwas/2019an/pheno.txt"),
              col_names = FALSE)

matched %>%
  select(full_reg, iid, cg_num) %>%
  write_delim(here::here("data/derived_data/gcta_gwas/2019an/covar.txt"),
              col_names = FALSE)

