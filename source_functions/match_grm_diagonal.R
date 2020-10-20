library(readr)
library(dplyr)

read_table2(here::here("data/derived_data/grm_inbreeding/mizzou_hairshed.diagonal.txt"),
            col_names = FALSE) %>% 
  select(diagonal = X4) %>% 
  bind_cols(read_table2(here::here("data/derived_data/grm_inbreeding/mizzou_hairshed.grm.id"),
                        col_names = FALSE) %>% 
              select(full_reg = X1)) %>% 
  assertr::verify(!is.na(diagonal)) %>% 
  write_csv(here::here("data/derived_data/grm_inbreeding/mizzou_hairshed.diagonal.full_reg.csv"))