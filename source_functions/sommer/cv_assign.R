
library(tidyverse)

cv_assign <- 
  
  function(df) {
  
  one <-
    df %>%
    distinct(international_id, .keep_all = TRUE) %>%
    select(Lab_ID, international_id, breed_code) %>%
    group_by(breed_code) %>%
    sample_frac(1 / 3) %>%
    ungroup() %>%
    mutate(cv_group = 1)
  # summarise(n = n()) %>%
  # View()
  
  two <-
    df %>%
    filter(!international_id %in% one$international_id) %>%
    distinct(international_id, .keep_all = TRUE) %>%
    select(Lab_ID, international_id, breed_code) %>%
    group_by(breed_code) %>%
    sample_frac(1 / 2) %>%
    ungroup() %>%
    mutate(cv_group = 2)
  
  
  three <-
    df %>%
    filter(!international_id %in% one$international_id) %>%
    filter(!international_id %in% two$international_id) %>%
    distinct(international_id, .keep_all = TRUE) %>%
    select(Lab_ID, international_id, breed_code) %>%
    mutate(cv_group = 3)
  
  bind_rows(one, two, three)
  
}
