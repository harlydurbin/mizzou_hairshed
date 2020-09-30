library(readr)
library(tidyr)
library(glue)
library(dplyr)
library(tidylog)

geno_prefix <- as.character(commandArgs(trailingOnly = TRUE)[1])

bim <- 
  read_table2(here::here(glue::glue("{geno_prefix}.bim")), 
              col_names = FALSE)

bim %>% 
  select(X1, X4) %>% 
  mutate(snp_name = row_number()) %>% 
  select(snp_name, X1, X4) %>% 
  write_delim(here::here(glue::glue("{geno_prefix}.chr_info.txt")),
              col_names = FALSE)

bim %>% 
  mutate(chrpos = glue::glue("{X1}:{X4}")) %>% 
  select(chrpos) %>% 
  write_delim(here::here(glue::glue("{geno_prefix}.chrpos.txt")),
              col_names = FALSE)

