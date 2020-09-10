library(dplyr)
library(magrittr)
library(readr)
library(tidyr)
library(tibble)
library(sommer)

source(here::here("source_functions/sommer_tidiers.R"))


# nm <- stringr::str_c(rundate, ".", mod)

nm <- as.character(commandArgs(trailingOnly = TRUE)[1])

which <- as.character(commandArgs(trailingOnly = TRUE)[2])

obj <-
  readr::read_rds(
    here::here(stringr::str_c("data/derived_data/sommer/sommer_mod/", nm, ".rds"))
  )

# Write out BLUPs
tidy_blup(obj) %>%
  readr::write_csv(
    here::here(stringr::str_c("data/derived_data/sommer/", which, "/",
		 nm,
		  ".blup.csv")),
    col_names = TRUE
  )

# Write out variance components
sommer::summary.mmer(obj)$varcomp %>%
  janitor::clean_names() %>%
  tibble::rownames_to_column(var = "effect") %>%
  readr::write_csv(
    here::here(stringr::str_c("data/derived_data/sommer/", which, "/",
		 nm,
		  ".varcomp.csv")),
    col_names = TRUE
  )

# Betas
sommer::summary.mmer(obj)$beta %>%
  janitor::clean_names() %>%
  dplyr::mutate_if(is.factor, as.character) %>%
  readr::write_csv(
    here::here(stringr::str_c("data/derived_data/sommer/", which, "/",
		 nm,
		  ".beta.csv")),
    col_names = TRUE
  )

# AIC/BIC
tibble::tibble(bic = obj$BIC,
       aic = obj$AIC) %>%
  readr::write_csv(
    here::here(stringr::str_c("data/derived_data/sommer/", which, "/",
                              nm,
                              ".aic_bic.csv")),
    col_names = TRUE
  )

# residuals
obj$data %>%
  dplyr::select(international_id, hair_score) %>%
  bind_cols(tibble::tibble(resid = obj$residuals)) %>%
  mutate(international_id = as.character(international_id)) %>%
  readr::write_csv(
    here::here(stringr::str_c("data/derived_data/sommer/", which, "/",
                              nm,
                              ".resid.csv")),
    col_names = TRUE
  )
