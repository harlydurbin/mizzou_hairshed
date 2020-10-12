library(readr)
library(dplyr)
library(glue)
library(purrr)
library(tidyr)
library(lubridate)
library(magrittr)
library(stringr)

source(here::here("source_functions/calculate_acc.R"))

# blupf90 solutions
trait <-
  read_table2(here::here("data/derived_data/random_regression/length1/solutions"),
              col_names = c("trait", "effect", "id_new", "solution", "se"),
              skip = 1) %>%
  # limit to animal effect
  filter(effect == 7) %>%
  select(id_new, solution, se)


trait %<>%
  # Re-attach original IDs
  left_join(read_table2(here::here("data/derived_data/random_regression/length1/renadd07.ped"),
                        col_names = FALSE) %>%
    select(id_new = X1, full_reg = X10)) %>%
  mutate(acc = purrr::map_dbl(.x = se,
                              ~ calculate_acc(e = 0.53274,
                                              u = 0.37679,
                                              se = .x,
                                              option = "reliability")),
  Group = 1,
  acc = round(acc*100, digits = 0),
  solution = round(solution, digits = 3)) %>%
  select(ID = full_reg, Group, Obs = solution, Rel = acc) %>%
  filter(!is.na(Obs))


write_tsv(trait, here::here("data/derived_data/snp1101/length1/trait.txt"))

read_table2(here::here("data/derived_data/3gen/blupf90_ped.txt"),
            col_names = c("full_reg", "sire_reg", "dam_reg")) %>% 
  write_tsv(here::here("data/derived_data/snp1101/length1/ped.txt"))
