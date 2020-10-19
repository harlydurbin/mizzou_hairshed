library(readr)
library(dplyr)
library(glue)
library(purrr)
library(tidyr)
library(lubridate)
library(magrittr)
library(stringr)

source(here::here("source_functions/calculate_acc.R"))

solutions <- as.character(commandArgs(trailingOnly = TRUE)[1])

ped <- as.character(commandArgs(trailingOnly = TRUE)[2])

# blupf90 solutions
trait <-
  read_table2(here::here(solutions),
              col_names = c("trait", "effect", "id_new", "solution", "se"),
              skip = 1) %>%
  # limit to animal effect
  filter(effect == 5) %>%
  select(id_new, solution, se)


trait %<>%
  # Re-attach original IDs
  left_join(read_table2(here::here(ped),
                        col_names = FALSE) %>%
    select(id_new = X1, full_reg = X10)) %>%
  mutate(acc = purrr::map_dbl(.x = se,
                              ~ calculate_acc(u = 0.29067,
                                              se = .x,
                                              option = "reliability")),
  Group = 1,
  acc = round(acc*100, digits = 0),
  solution = round(solution, digits = 3)) %>%
  select(ID = full_reg, Group, Obs = solution, Rel = acc) %>%
  filter(!is.na(Obs))


write_tsv(trait, here::here("data/derived_data/snp1101/length1/trait.txt"))
