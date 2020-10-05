#' ---
#' title: "Basic variance components and parameters"
#' author: "Harly Durbin"
#' output: html_document
#' ---
#' 
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


#' 
#' # Notes & questions
#' 
#' # Setup 
#' 
## ---- warning=FALSE, message=FALSE--------------------------------------------
cleaned <- read_rds(here::here("data/derived_data/import_join_clean/cleaned.rds"))

#' 
## ---- warning=FALSE, message=FALSE--------------------------------------------
full_ped <- read_rds(here::here("data/derived_data/3gen/full_ped.rds"))

#' 
## ---- warning=FALSE, message=FALSE--------------------------------------------
coord_key <- read_csv(here::here("data/derived_data/environmental_data/coord_key.csv"))

#' 
## -----------------------------------------------------------------------------
mean_apparent_high <- 
  read_rds(here::here("data/derived_data/environmental_data/weather.rds")) %>%  
  # Pull daily data from the `data` column and save it to its own column 
  mutate(daily = purrr::map(data, "daily", .default = NA),
         # Extract daily apparent high from daily column
         apparent_high = purrr::map_dbl(daily,
                              ~ .x %>% 
                                dplyr::pull(apparentTemperatureHigh))) %>% 
  # Remove the data column
  select(-data) %>% 
  group_by(date_score_recorded, lat, long) %>% 
  # Take rows for max 30 days
  slice_max(order_by = value, n = 30) %>% 
  summarise(mean_apparent_high = mean(apparent_high)) %>% 
  ungroup()

#' 
#' # First, remove males
#' 
## -----------------------------------------------------------------------------
dat <-
  cleaned %>%
  # Females only
  filter(sex == "F") 

#' 
#' # Add latitude
#' 
## -----------------------------------------------------------------------------
dat %<>% 
  left_join(coord_key %>% 
              select(farm_id, lat, long)) %>% 
  assertr::verify(!is.na(lat))

#' 
#' # Mean apparent high temperature
#' 
## -----------------------------------------------------------------------------
dat %<>%
  filter(!is.na(date_score_recorded)) %>% 
  left_join(mean_apparent_high) %>% 
  assertr::verify(!is.na(mean_apparent_high))

#' 
#' # Calving season
#' 
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
  
  

#' 
#' # Toxic fescue
#' 
## -----------------------------------------------------------------------------

dat %<>% 
  mutate(toxic_fescue = if_else(farm_id %in% c("BAT", "CRC"), 
                                "YES",
                                toxic_fescue)) %>% 
  filter(!is.na(toxic_fescue)) %>% 
  assertr::verify(!is.na(toxic_fescue))


#' 
#' 
#' # Age group
#' 
## -----------------------------------------------------------------------------

dat %<>% 
  mutate(age_group = case_when(age == 1 ~ "yearling",
                               age == 2 ~ "fch",
                               age == 3 ~ "three",
                               age >= 4 ~ "mature")) %>% 
  filter(!is.na(age_group)) %>% 
  assertr::verify(!is.na(age_group))


#' 
#' # Remove categorical fixed effects with fewer than 5 observations
#' 
## -----------------------------------------------------------------------------
dat %<>% 
  group_by(age_group) %>% 
  filter(n() >= 5) %>% 
  ungroup()

#' 
#' # Export
#' 
#' ## Data
#' 
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

#' 
## -----------------------------------------------------------------------------
print("Duplicate animals, different full_reg")
matched %>% 
  distinct(farm_id, temp_id, full_reg) %>% 
  group_by(farm_id, temp_id) %>% 
  filter(n() > 1)

#' 
## -----------------------------------------------------------------------------
matched %>% 
  distinct(Lab_ID,farm_id, animal_id, temp_id, registration_number, full_reg) %>% 
  write_csv(here::here("data/derived_data/base_varcomp/fixed2/sanity_key.csv"),
            na = "")

#' 
## -----------------------------------------------------------------------------
matched %>% 
  select(full_reg, year, calving_season, toxic_fescue, age_group, mean_apparent_high, lat, hair_score) %>% 
  write_delim(here::here("data/derived_data/base_varcomp/fixed2/data.txt"),
              col_names = FALSE)

