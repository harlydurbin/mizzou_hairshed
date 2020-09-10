library(tidyverse)
library(readxl)
library(lubridate)

nested_join <-
  read_rds(here::here("data/derived_data/nested_join"))
source(here::here("source_functions/function.pull_all.R"))
source(here::here("source_functions/function.pull_true.R"))


joined_18 <-
  nested_join %>%
  filter(sold == "NO") %>%
  pull_all_int(age) %>%
  #keep only those that had a hair score in 2018
  filter(!map_lgl(data_2018, is.null)) %>%
  unnest(data_2018) %>%
  select(-ends_with("1"), -age) %>%
  mutate(
    pull_age_2018 = case_when(
      is.na(pull_age_2018) &
        !is.na(pull_age_2017) ~ as.integer(pull_age_2017 + 1),
      is.na(pull_age_2018) &
        !is.na(pull_age_2016) ~ as.integer(pull_age_2016 + 2),
      TRUE ~ as.integer(pull_age_2018)
    )
  ) %>%
  left_join(animal_table %>%
              select(Lab_ID, DOB),
            by = c("Lab_ID")) %>%
  mutate(
    pull_age_2018 = case_when(
      !is.na(DOB) &
        !is.na(date_score_recorded) ~ as.integer(time_length(date_score_recorded - DOB, unit = "years")),
      !is.na(DOB) &
        is.na(date_score_recorded) ~ as.integer(time_length(mdy("5/1/18") - DOB, unit = "years")),
      TRUE ~ pull_age_2018
    )
  ) %>%
  select(
    farm_id,
    breed_code,
    registration_number,
    sire_registration,
    sex,
    color,
    ge_epd,
    animal_id,
    date_score_recorded,
    hair_score,
    pull_age_2018,
    calving_season,
    toxic_fescue,
    comment,
    barcode,
    sold
  )

instructions <-
  read_excel(here::here("data/raw_data/DataRecording_template_2019.xlsx"),
             sheet = 2)
breed_codes <-
  read_excel(here::here("data/raw_data/DataRecording_template_2019.xlsx"),
             sheet = 3)
coat_codes <-
  read_excel(here::here("data/raw_data/DataRecording_template_2019.xlsx"),
             sheet = "CoatCodes")

joined_18 %>%
  mutate(
    date_score_recorded = NA_character_,
    hair_score = NA_character_,
    toxic_fescue = NA_character_,
    comment = NA_character_,
    sold = NA_character_
  ) %>%
  set_names(
    c(
      "Farm",
      "Breed_code",
      "RegistrationNumber",
      "SireRegistration",
      "Sex",
      "Color",
      "GE_EPD",
      "Animal_ID",
      "DateScoreRecorded",
      "HairScore",
      "Age",
      "CalvingSeason",
      "ToxicFescue",
      "Comment",
      "Barcode",
      "Sold2019"
    )
  ) %>%
  mutate(Age = case_when(!is.na(Age) ~ as.integer(Age + 1),
                         TRUE ~ Age)) %>%
  group_split(Farm) %>%
  map( ~ writexl::write_xlsx(
    list(
      "DataEntry" = .x,
      "Instructions" = instructions,
      "BreedCodes" = breed_codes,
      "CoatCodes" = coat_codes
    ),
    str_c(
      "/Users/harlyjanedurbin/Box Sync/HairShedding/ReportedData/Blank2019/DataRecording_",
      .x$Farm,
      "_2019.xlsx"
    )
  ))