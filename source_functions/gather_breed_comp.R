library(dplyr)
library(readr)


## American Simmental Association
sim_breed <-
  read_csv(here::here("data/raw_data/201005.SIM.breeds.csv")) %>% 
  select(registration_number = asa_nbr, breed_code, pct) %>% 
  mutate(breed_code = if_else(pct == 1, breed_code, "cross")) %>% 
  distinct(registration_number, breed_code) %>% 
  left_join(read_csv(here::here("data/raw_data/201005.SIM.breeds.csv")) %>% 
              distinct(breed_code, breed_name)) %>% 
  rename(cross = breed_code) %>% 
  bind_rows(read_csv(here::here("data/raw_data/201005.SIM.AnimalList.csv")) %>% 
              select(registration_number = ASA, cross = Brds) %>% 
              mutate(cross = case_when(cross == "PB SM" ~ "SIM",
                                       cross == "PB AN" ~ "AN", 
                                       cross == "PB AR" ~ "AR",
                                       TRUE ~ "cross")))

## Red Angus Association of America

ran_breed <-
  read_csv(here::here("data/raw_data/201005.raaa.animal.20180501.csv"), 
           na = ".") %>% 
  mutate(cross = if_else(frac1 == 1000, "RAN", "cross")) %>% 
  select(registration_number = regisno, animal_id, cross) %>% 
  bind_rows(read_csv(here::here("data/raw_data/201005.RAN.AnimalList.csv")) %>% 
              select(registration_number = 1, cross = 6) %>% 
              mutate(cross = if_else(cross == "100% AR", "RAN", "cross")))

## RHF data

rhf_breed <- read_rds("data/raw_data/201005.rhf_breed.rds")
