library(readr)
library(dplyr)
library(glue)
library(purrr)
library(tidyr)
library(lubridate)
library(magrittr)
library(stringr)

source(here::here("source_functions/calculate_acc.R"))

dir <- as.character(commandArgs(trailingOnly = TRUE)[1])

animal_effect <- as.numeric(commandArgs(trailingOnly = TRUE)[2])

gen_var <- as.numeric(commandArgs(trailingOnly = TRUE)[3])

model <- str_extract(dir, "(?<=/)[[:alnum:]]+$")

# blupf90 solutions
trait <-
  read_table2(here::here(glue("{dir}/solutions")),
              col_names = c("trait", "effect", "id_new", "solution", "se"),
              skip = 1) %>%
  # limit to animal effect
  filter(effect == animal_effect) %>%
  select(id_new, solution, se)

trait %<>%
  # Re-attach original IDs
  left_join(read_table2(here::here(glue("{dir}/renadd0{animal_effect}.ped")),
                        col_names = FALSE) %>%
              select(id_new = X1, full_reg = X10)) %>%
  left_join(read_csv(here::here("data/derived_data/grm_inbreeding/mizzou_hairshed.diagonal.full_reg.csv"))) %>%
  filter(!is.na(diagonal)) %>%
  mutate(acc = purrr::map2_dbl(.x = se,
                               .y = diagonal,
                              ~ calculate_acc(u = gen_var,
                                              se = .x,
                                              diagonal = .y,
                                              option = "reliability"))) %>% 
  assertr::verify(between(acc, 0, 1))

trait %>%
  summarise(min(acc), max(acc))

trait %<>%
  mutate(Group = 1,
         acc = round(acc*100, digits = 0),
         solution = round(solution, digits = 3)) %>%
  select(ID = full_reg, Group, Obs = solution, Rel = acc) %>%
  filter(!is.na(Obs))

write_tsv(trait, here::here(glue("data/derived_data/snp1101/{model}/trait.txt")))
