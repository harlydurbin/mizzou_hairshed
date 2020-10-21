## ----setup, include=FALSE-----------------------------------------------------
knitr::opts_chunk$set(echo = TRUE)
library(readr)
library(tidyr)
library(stringr)
library(dplyr)
library(glue)
library(magrittr)
library(lubridate)
library(tidylog)

source(here::here("source_functions/cg_tallies.R"))



## ---- warning=FALSE, message=FALSE--------------------------------------------
cleaned <- read_rds(here::here("data/derived_data/import_join_clean/cleaned.rds"))


## ---- warning=FALSE, message=FALSE--------------------------------------------
full_ped <- read_rds(here::here("data/derived_data/3gen/full_ped.rds"))


## ---- warning=FALSE, message=FALSE--------------------------------------------
coord_key <- read_csv(here::here("data/derived_data/environmental_data/coord_key.csv"))


## -----------------------------------------------------------------------------
dat <-
  cleaned %>%
  # Females only
  filter(sex == "F") 


## -----------------------------------------------------------------------------
dat %<>% 
  left_join(coord_key %>% 
              select(farm_id, lat)) %>% 
  assertr::verify(!is.na(lat))


## -----------------------------------------------------------------------------
dat %<>%
  filter(!is.na(date_score_recorded)) %>% 
  mutate(from_may1 = as.numeric(date_score_recorded - ymd(glue("{year}/05/01")))) %>% 
  assertr::verify(!is.na(from_may1))


## -----------------------------------------------------------------------------
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
                                    TRUE ~ calving_season)) %>% 
  filter(!is.na(calving_season)) %>% 
  assertr::verify(!is.na(calving_season))
  
  


## -----------------------------------------------------------------------------

dat %<>% 
  mutate(toxic_fescue = if_else(farm_id %in% c("BAT", "CRC"), 
                                "YES",
                                toxic_fescue)) %>% 
  filter(!is.na(toxic_fescue)) %>% 
  assertr::verify(!is.na(toxic_fescue))



## -----------------------------------------------------------------------------

dat %<>% 
  filter(!is.na(age)) %>% 
  assertr::verify(!is.na(age))



## -----------------------------------------------------------------------------
dat %<>% 
  group_by(age) %>% 
  filter(n() >= 5)


## -----------------------------------------------------------------------------
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
  


## -----------------------------------------------------------------------------
matched %>% 
  distinct(Lab_ID,farm_id, animal_id, temp_id, registration_number, full_reg) %>% 
  write_csv(here::here("data/derived_data/base_varcomp/fixed1/sanity_key.csv"),
            na = "")


## -----------------------------------------------------------------------------
matched %>% 
  select(full_reg, farm_id, year, calving_season, toxic_fescue, age, from_may1, lat, hair_score) %>% 
  write_delim(here::here("data/derived_data/base_varcomp/fixed1/data.txt"),
              col_names = FALSE)

