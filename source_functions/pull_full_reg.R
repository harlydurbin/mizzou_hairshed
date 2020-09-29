library(readr)
library(dplyr)

# Setup
full_ped <- read_rds(here::here("data/derived_data/3gen/full_ped.rds"))

cleaned <- read_rds(here::here("data/derived_data/import_join_clean/cleaned.rds"))

sample_table <- 
  read_csv(here::here("data/raw_data/import_join_clean/200820_sample_sheet.csv"),
           trim_ws = TRUE,
           guess_max = 100000)

geno_prefix <- as.character(commandArgs(trailingOnly = TRUE)[1])

# Import fam file
fam <- 
  read_table2(here::here(glue::glue("{geno_prefix}.fam")),
              col_names = FALSE) %>% 
  select(international_id = 1)

# Re-join to fam to make sure rows are in the correct order
fam %>% 
  left_join(key) %>% 
  assertr::verify(length(full_reg) == length(fam$international_id)) %>% 
  assertr::verify(!is.na(full_reg)) %>% 
  select(full_reg) %>% 
  write_tsv(here::here(glue::glue("{geno_prefix}.full_reg.txt")),
            col_names = FALSE)