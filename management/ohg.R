nested %>% 
  filter(farm_id == "OHG") %>% 
  pull_true(sold) %>% 
  filter(is.na(sold)) %>% 
  pull_true(sex) %>% 
  pull_true(ge_epd) %>% 
  pull_true(calving_season) %>% 
  pull_true(sire_registration) %>% 
  pull_true(breed_code) %>% 
  pull_all(age) %>% 
  mutate(pull_age_2016 = as.numeric(pull_age_2016),
         pull_age_2018 = pull_age_2016 + 2) %>% 
  select(farm_id, breed_code, registration_number, sire_registration, sex, color, ge_epd, animal_id, pull_age_2018, calving_season, barcode) %>% 
  writexl::write_xlsx("~/Desktop/DataRecording_OHG.xlsx")