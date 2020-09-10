library(dplyr)
library(stringr)
library(magrittr)
library(readr)
library(tidyr)
library(tibble)
library(sommer)


nm <- as.character(commandArgs(trailingOnly = TRUE)[1])

cv <- as.integer(commandArgs(trailingOnly = TRUE)[2])

full <- readr::read_rds(here::here("data/derived_data/pheno_cv.rds"))

grm <- readr::read_rds(here::here("data/derived_data/grm_raw.rds"))

reduced <-
full %>%
  mutate(hair_score =
           case_when(
             cv_group == cv ~ NA_integer_,
             TRUE ~ hair_score
           ),
         age = forcats::as_factor(age))

mod <-
  mmer(hair_score~1
		+ sex
		+ calving_season
		+ date_deviation
		+ lat
		+ age
		+ toxic_fescue
		+ temp_group
		+ PC1
		+ PC2,
     # NEED to specify international ID twice: first one is relating the
     # GRM to individuals --> Additive genetic
     # Second one is relating identity matrix to individual --> Permanent environment
     random = ~vs(international_id, Gu = grm) + international_id,
     # Covariance of residuals
     rcov = ~ units,
     method = "AI",
     # Don't drop individuals that are missing phenotypes
     na.method.X = "include",
     data = reduced)

readr::write_rds(mod,
                 here::here(str_c("data/derived_data/sommer_mod/cv/",
                                  nm,
                                  ".rds")))
