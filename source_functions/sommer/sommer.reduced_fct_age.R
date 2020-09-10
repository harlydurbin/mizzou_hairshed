library(sommer)
library(dplyr)
library(readr)
library(forcats)
library(magrittr)
library(stringr)
library(here)

rundate <- as.character(commandArgs(trailingOnly = TRUE)[1])

grm <- readr::read_rds(here::here("data/derived_data/grm_raw.rds"))

pheno <- readr::read_rds(here::here("data/derived_data/pheno.rds"))

# grm <- readr::read_rds(here::here("data/derived_data/grm_test.rds"))
#
# pheno <- readr::read_rds(here::here("data/derived_data/pheno_test.rds"))

pheno <-
  pheno %>%
  mutate(age = forcats::as_factor(age))

mod <-
  sommer::mmer(hair_score~1 +
                 sex +
                 calving_season +
                 date_deviation +
                 lat +
                 age +
                 toxic_fescue +
                 temp_group, #+ PC1 + PC2,
       # NEED to specify international ID twice: first one is relating the
       # GRM to individuals
       # Second one is relating identity matrix to individual
       random = ~vs(international_id, Gu = grm) + international_id,
       # I don't know what this does
       # I think treating repeated records individually?
       # Covariance of residuals
       rcov = ~ units,
       method = "AI",
       # Don't drop individuals that are missing phenotypes
       na.method.X = "include",
       data = pheno)

readr::write_rds(mod,
                 here::here(stringr::str_c("data/derived_data/sommer_mod/",
                                           rundate,
                                           ".reduced_fct_age.rds")))
