library(dplyr)
library(readr)

not_done <- read_rds("data/derived_data/out17.rds") %>% 
  mutate(group = as.character(group)) %>% 
  bind_rows(read_rds("data/derived_data/out16.rds")) %>% 
  bind_rows(read_rds("data/derived_data/out15.rds")) %>% 
  anti_join(weather, ., by = c("zipcode", "value"))

chunk <- 500
n <- nrow(not_done)
r  <- rep(1:ceiling(n/chunk),each=chunk)[1:n]

not_done %>%
  mutate(group = r) %>% 
  group_by(group) %>% 
  group_walk(~ write_rds(.x, here::here(str_c("data/derived_data/weather_group", .y$group, ".rds"))))
