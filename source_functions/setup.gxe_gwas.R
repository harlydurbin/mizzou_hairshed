#' ---
#' title: "GEMMA GxE GWAS"
#' author: "Harly Durbin"
#' output:
#'   html_document:
#'     toc: true
#'     toc_depth: 2
#'     df_print: paged
#'     code_folding: hide
#' ---
#' 
## ----setup, include=FALSE-------------------------------------------------------------------------
knitr::opts_chunk$set(echo = TRUE)
library(readr)
library(tidyr)
library(stringr)
library(dplyr)
library(glue)
library(magrittr)
library(lubridate)

#' 
#' # Notes & questions
#' 
#' * Fit fixed effects directly in GEMMA, dummy coded
#'     + Column of 1s for mean
#'     + Calving season, age group, fescue
#' * Need to have phenotype file and genotype file in same order
#'     + Phenotype in fam file - make fam manually then use `--keep` to subset genotypes?
#' 
#' # Setup
#' 
## -------------------------------------------------------------------------------------------------
geno_prefix <- as.character(commandArgs(trailingOnly = TRUE)[1])

#' 
## -------------------------------------------------------------------------------------------------
score_year <- as.numeric(commandArgs(trailingOnly = TRUE)[2])

#' 
## -------------------------------------------------------------------------------------------------
var <- as.character(commandArgs(trailingOnly = TRUE)[3])

#' 
## ---- warning=FALSE, message=FALSE----------------------------------------------------------------
cleaned <- read_rds(here::here("data/derived_data/import_join_clean/cleaned.rds"))

#' 
## -------------------------------------------------------------------------------------------------
full_ped <- read_rds(here::here("data/derived_data/3gen/full_ped.rds"))

#' 
## -------------------------------------------------------------------------------------------------
full_fam <- 
  read_table2(here::here(glue("{geno_prefix}.fam")),
              col_names = FALSE)

#' 
## ---- message=FALSE, warning=FALSE----------------------------------------------------------------
weather <-
  read_rds(here::here("data/derived_data/environmental_data/weather.rds")) %>%
  mutate(daily = purrr::map(data, "daily", .default = NA),
         apparent_high = purrr::map_dbl(daily,
                                        ~ .x %>%
                                          dplyr::pull(apparentTemperatureHigh)),
         # 10/9/20 forgot to convert from F to C
         apparent_high = measurements::conv_unit(apparent_high, from = "F", to = "C"),
         sunrise = purrr::map_chr(daily,
                                  ~.x %>%
                                    dplyr::pull(sunriseTime) %>%
                                    as.character(.)),
         sunset = purrr::map_chr(daily,
                                 ~.x %>%
                                   dplyr::pull(sunsetTime) %>%
                                   as.character(.)),
         sunrise = lubridate::as_datetime(sunrise),
         sunset = lubridate::as_datetime(sunset),
         day_length = as.numeric(sunset - sunrise)) %>%
  # Remove the data column
  select(-data)  %>%
  group_by(date_score_recorded, lat, long) %>%
  # Take rows for max 30 days
  slice_max(order_by = value, n = 30) %>%
  summarise(mean_apparent_high = mean(apparent_high),
            mean_day_length = mean(day_length)) %>%
  ungroup()



#' 
## ---- message=FALSE, warning=FALSE----------------------------------------------------------------
coord_key <- read_csv(here::here("data/derived_data/environmental_data/coord_key.csv"))

#' 
#' # Filtering & joining
#' 
#' ## Remove males
#' 
## -------------------------------------------------------------------------------------------------
dat <-
  cleaned %>% 
  filter(sex == "F")

#' 
#' ## Add coordinates
#' 
## -------------------------------------------------------------------------------------------------

dat %<>%
  left_join(coord_key %>%
              select(farm_id, lat, long)) %>%
  assertr::verify(!is.na(lat)) %>%
  assertr::verify(!is.na(long))


#' 
#' ## Mean apparent high temperature, mean day length
#' 
## -------------------------------------------------------------------------------------------------
dat %<>%
  filter(!is.na(date_score_recorded)) %>%
  left_join(weather) %>%
  assertr::verify(!is.na(mean_apparent_high)) %>%
  assertr::verify(!is.na(mean_day_length))

#' 
#' ## Calving season
#' 
## -------------------------------------------------------------------------------------------------
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
#' ## Toxic fescue
#' 
## -------------------------------------------------------------------------------------------------
dat %<>%
  mutate(toxic_fescue = if_else(farm_id %in% c("BAT", "CRC"),
                                "YES",
                                toxic_fescue)) %>%
  filter(!is.na(toxic_fescue)) %>%
  assertr::verify(!is.na(toxic_fescue))

#' 
#' ## Age group
#' 
## -------------------------------------------------------------------------------------------------
dat %<>%
  mutate(age_group = case_when(age == 1 ~ "yearling",
                               age %in% c(2, 3) ~ "twothree",
                               between(age, 4, 7) ~ "mature",
                               age >= 8 ~ "old",
                               is.na(age) ~ "mature")) %>%
  assertr::verify(!is.na(age_group))

#' 
#' ## Specified year only, take random record for animals with multiple records within a year
#' 
## -------------------------------------------------------------------------------------------------
dat %<>%
  filter(year == score_year) %>%
  group_by(farm_id, temp_id) %>%
  sample_n(1) %>% 
  ungroup() 

#' 
#' ## ID matching
#' 
## -------------------------------------------------------------------------------------------------
dat %<>%
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
#' # Export 
#' 
#' ## Phenotypes in new `.fam` file
#' 
## -------------------------------------------------------------------------------------------------
matched <-
  full_fam %>% 
  left_join(dat %>% 
              select(X1 = full_reg, hair_score)) %>% 
  filter(!is.na(hair_score)) %>% 
  select(X1:X5, hair_score)

#' 
## -------------------------------------------------------------------------------------------------
matched %>% 
  write_tsv(here::here(glue("data/derived_data/gxe_gwas/{var}/{score_year}/manual_fam.fam")),
            col_names = FALSE)

#' 
#' ## PLINK `--keep`/`--indiv-sort` file
#' 
## -------------------------------------------------------------------------------------------------
matched %>% 
  select(X1, X2) %>% 
  write_tsv(here::here(glue("data/derived_data/gxe_gwas/{var}/{score_year}/keep_sort.txt")),
            col_names = FALSE)

#' 
#' ## Design matrix for fixed effects
#' 
## -------------------------------------------------------------------------------------------------
# Left join to `matched` to get correct sample order
matched %>% 
  select(full_reg = X1) %>% 
  left_join(dat %>% 
              select(full_reg, calving_season, age_group, toxic_fescue)) %>% 
  fastDummies::dummy_cols(select_columns = c("calving_season", "age_group", "toxic_fescue")) %>% 
  mutate(mean = 1) %>% 
  select(mean, calving_season_FALL, age_group_twothree, age_group_mature, age_group_old, toxic_fescue_YES) %>% 
  write_tsv(here::here(glue("data/derived_data/gxe_gwas/{var}/{score_year}/design_matrix.txt")),
            col_names = FALSE)


#' 
#' ## GxE file
#' 
## -------------------------------------------------------------------------------------------------

if(var == "day_length") {
  matched %>% 
    select(full_reg = X1) %>% 
    left_join(dat %>% 
              select(full_reg, mean_day_length)) %>% 
    select(mean_day_length) %>% 
    write_tsv(here::here(glue("data/derived_data/gxe_gwas/{var}/{score_year}/gxe.txt")),
              col_names = FALSE)
  } else if(var == "temp") {
    matched %>% 
      select(full_reg = X1) %>% 
      left_join(dat %>% 
              select(full_reg, mean_apparent_high)) %>% 
      select(mean_apparent_high) %>% 
      write_tsv(here::here(glue("data/derived_data/gxe_gwas/{var}/{score_year}/gxe.txt")),
                col_names = FALSE)
    }

#' 
#' # Range summary
#' 
## -------------------------------------------------------------------------------------------------
dat %>% 
  summarise_at(vars(c("mean_apparent_high", "mean_day_length")), ~ range(.))

#' 
