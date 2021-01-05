library(readr)
library(tidyr)
library(stringr)
library(dplyr)
library(glue)
library(magrittr)

model <- as.character(commandArgs(trailingOnly = TRUE)[1])

data_path <- glue("data/derived_data/aireml_varcomp/{model}/data.txt")

dat <-
  read_table2(here::here(data_path),
              col_names = c("full_reg", "cg_num", "hair_score"))


choose_validation_set <-
  function(df, frac) {
    
    # Registration numbers whose phenotypes will be dropped
    drop <-
      df %>%
      distinct(full_reg) %>%
      sample_frac(frac) %>%
      pull(full_reg)
    
    val_set <-
      df %>%
      filter(full_reg %in% drop) %>%
      mutate(hair_score = 999)
    
    train_set <-
      df %>%
      filter(!full_reg %in% drop)
    
    bind_rows(train_set, val_set)
    
  }


choose_validation_set(dat, 0.25) %>% 
  filter(hair_score == 999)
