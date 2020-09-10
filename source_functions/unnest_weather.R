library(readr)
library(dplyr)
library(purrr)
library(tidyr)
library(magrittr)
library(here)

weather_done <- 
  readr::read_rds(here::here("data/derived_data/weather_done.rds")) %>% 
  # Pull hourly data from the `data` column and save it to its own column 
  dplyr::mutate(hourly = purrr::map(data, "hourly", .default = NA),
         # Pull daily average data from the `data` column and save 
         # it to its own column 
         daily = purrr::map(data, "daily", .default = NA)) %>% 
  # Remove the data column
  dplyr::select(-data) 

weather_done %>% 
  tidyr::unnest(daily)