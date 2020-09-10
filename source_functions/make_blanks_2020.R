## ----setup, include=FALSE-----------------------------------------------------------------------------------------------------------------------------
knitr::opts_chunk$set(echo = TRUE)
library(readxl)
library(dplyr)
library(purrr)
library(stringr)


## -----------------------------------------------------------------------------------------------------------------------------------------------------
cleaned <- readr::read_rds(here::here("data/derived_data/cleaned.rds"))


## -----------------------------------------------------------------------------------------------------------------------------------------------------
make_blank <-
  function(farm) {
    instructions <-
      read_excel(here::here("data/raw_data/DataRecording_template_2020.xlsx"),
                 sheet = "Instructions")
    breed_codes <-
      read_excel(here::here("data/raw_data/DataRecording_template_2020.xlsx"),
                 sheet = "BreedCodes")
    coat_codes <-
      read_excel(here::here("data/raw_data/DataRecording_template_2020.xlsx"),
                 sheet = "CoatCodes")
    
    data_sheet <-
      cleaned %>%
      filter(farm_id == farm) %>%
      filter(sold == FALSE) %>%
      distinct(
        farm_id,
        breed_code,
        registration_number,
        animal_id,
        sex,
        color,
        temp_id,
        barcode,
        Lab_ID
      ) %>%
      left_join(
        cleaned %>%
          filter(farm_id == farm) %>%
          filter(sold == FALSE & year == 2019) %>%
          distinct(animal_id, temp_id, age, dob, calving_season)
      ) %>%
      mutate(age = case_when(
        !is.na(age) ~ as.integer(age + 1),
        !is.na(dob) ~ as.integer(lubridate::ymd("2020-05-01") - dob)
      )) %>%
      mutate(
        date_score_recorded = NA_character_,
        hair_score = NA_character_,
        toxic_fescue = NA_character_,
        comment = NA_character_,
        sold = NA_character_
      ) %>%
      select(
        farm_id,
        breed_code,
        registration_number,
        sex,
        color,
        animal_id,
        date_score_recorded,
        hair_score,
        age,
        calving_season,
        toxic_fescue,
        comment,
        barcode,
        sold
      ) %>%
      set_names(
        c(
          "Farm",
          "Breed_code",
          "RegistrationNumber",
          "Sex",
          "Color",
          "Animal_ID",
          "DateScoreRecorded",
          "HairScore",
          "Age",
          "CalvingSeason",
          "ToxicFescue",
          "Comment",
          "Barcode",
          "Sold2020"
        )
      )
    
    writexl::write_xlsx(
      list(
        "DataEntry" = data_sheet,
        "Instructions" = instructions,
        "BreedCodes" = breed_codes,
        "CoatCodes" = coat_codes
      ),
      glue::glue(
        "/Users/harlyjanedurbin/Box Sync/HairShedding/ReportedData/Blank2020/DataRecording_{farm}_2020.xlsx"
      )
    )
  }


## -----------------------------------------------------------------------------------------------------------------------------------------------------
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


## -----------------------------------------------------------------------------------------------------------------------------------------------------
farm_list %>% 
  purrr::map(~ make_blank(farm = .x))

