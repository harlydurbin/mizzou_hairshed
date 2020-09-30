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
  mutate(SNP_ID = row_number()) %>% 
  select(SNP_ID, CHR = X1, POS = X4) %>% 
  write_delim(here::here(glue::glue("{geno_prefix}.chr_info.txt")),
              delim = " ",
              col_names = TRUE)

bim %>% 
  mutate(chrpos = glue::glue("{X1}:{X4}")) %>% 
  select(chrpos) %>% 
  write_delim(here::here(glue::glue("{geno_prefix}.chrpos.txt")),
              col_names = FALSE)

