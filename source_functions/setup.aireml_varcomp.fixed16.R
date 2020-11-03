#' ---
#' title: "Basic variance components and parameters"
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

source(here::here("source_functions/cg_tallies.R"))

#'
#' # Notes & questions
#'
#' # Setup
#'
## ---- warning=FALSE, message=FALSE--------------------------------------------------------------------------------------------------
cleaned <- read_rds(here::here("data/derived_data/import_join_clean/cleaned.rds"))

#'
## ---- warning=FALSE, message=FALSE--------------------------------------------------------------------------------------------------
full_ped <- read_rds(here::here("data/derived_data/3gen/full_ped.rds"))

#'
#' # Score group

#'
## -----------------------------------------------------------------------------------------------------------------------------------
dat <-
  cleaned %>%
  left_join(bind_rows(read_excel(here::here("data/derived_data/ua_score_groups.xlsx")),
                      read_excel(here::here("data/derived_data/score_groups.xlsx"))) %>%
              select(farm_id, date_score_recorded, score_group) %>%
              mutate(date_score_recorded = lubridate::ymd(date_score_recorded))) %>%
  mutate(score_group = tidyr::replace_na(score_group, 1))

#'
## -----------------------------------------------------------------------------------------------------------------------------------
dat %>%
  distinct(score_group)

dat %>% 
  group_by(age) %>% 
  tally() %>% 
  View()

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
  mutate(cat_age = case_when(age >= 14 ~ "old",
                             TRUE ~ as.character(age))) %>%
  filter(!is.na(cat_age)) %>%
  assertr::verify(!is.na(cat_age))


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
  mutate(cg = glue("{farm_id}{year}{calving_season}{score_group}{toxic_fescue}"),
         cg_num = as.integer(factor(cg)))


#'
## -----------------------------------------------------------------------------------------------------------------------------------
dat %>%
  cg_tallies()

#'
## -----------------------------------------------------------------------------------------------------------------------------------
dat %<>%
  group_by(cg) %>%
  filter(n() >= 5) %>%
  ungroup()

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
  mutate(breed_code = case_when(breed_code == "AN" ~ "AAN",
                                breed_code == "ANR" ~ "RAN",
                                breed_code == "BG" ~ "BGR",
                                breed_code == "BRN" ~ "BSW",
                                breed_code == "MAAN" ~ "RDP"),
         full_reg = case_when(is.na(full_reg) &
                                !is.na(registration_number) ~ glue("{breed_code}{registration_number}"),
                              is.na(full_reg) &
                                is.na(registration_number) ~ glue("{farm_id}{animal_id}{temp_id}"),
                              TRUE ~ full_reg)) %>%
  assertr::verify(!is.na(full_reg)) %>%
  assertr::verify(!is.na(hair_score))

#'
## -----------------------------------------------------------------------------------------------------------------------------------
print("Duplicate animals, different full_reg")
matched %>%
  distinct(farm_id, temp_id, full_reg) %>%
  group_by(farm_id, temp_id) %>%
  filter(n() > 1)

#'
## -----------------------------------------------------------------------------------------------------------------------------------
matched %>%
  distinct(Lab_ID,farm_id, animal_id, temp_id, registration_number, full_reg) %>%
  write_csv(here::here("data/derived_data/aireml_varcomp/fixed16/sanity_key.csv"),
            na = "")

#'
## -----------------------------------------------------------------------------------------------------------------------------------
matched %>%
  group_by(full_reg, cg_num) %>%
  filter(n() == 1) %>%
  ungroup() %>%
  select(full_reg, cg_num, cat_age, hair_score) %>%
  write_delim(here::here("data/derived_data/aireml_varcomp/fixed16/data.txt"),
              col_names = FALSE)
