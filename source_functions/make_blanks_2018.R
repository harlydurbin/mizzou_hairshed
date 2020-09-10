##Make 2018 blank data recording files
##Written 4/10/18

master <- readRDS("master.RDS")
library(tidyverse)
library(readxl)
library(stringr)

farms <- master %>% 
  select(Farm_ID) %>% 
  distinct() 

farms <- as.vector(farms$Farm_ID)

for (i in seq_along(farms)) {
  master %>% 
    mutate(Age2017 = if_else(is.na(Age2017) & !is.na(Age2016), 
                             Age2016 + 1, 
                             as.double(Age2017))) %>%
    mutate(Age2016 = if_else(is.na(Age2016) & !is.na(Age2017), 
                             Age2017 - 1, 
                             as.double(Age2016))) %>% 
    filter(Farm_ID == farms[i] ) %>% 
    filter(is.na(Sold2017)) %>% 
    select(Farm_ID, Breed, Reg, Sire_reg, Sex, GE_EPD, Color, Animal_ID, Age2017, CalvingSeason2017, ToxicFescue2017, Barcode) %>% 
    mutate(Age = Age2017 + 1) %>% 
    mutate(DateScoreRecorded = "") %>% 
    mutate(HairScore = "") %>% 
    mutate(Comment = "") %>% 
    mutate(Sold2018 = "") %>% 
    mutate(Reg = if_else(Reg == Barcode, " ", Reg)) %>% 
    rename(CalvingSeason = CalvingSeason2017, ToxicFescue = ToxicFescue2017, Farm = Farm_ID, Breed_code = Breed, RegistrationNumber = Reg, SireRegistration = Sire_reg) %>% 
    select(Farm, Breed_code, RegistrationNumber, SireRegistration, Sex, Color, GE_EPD, Animal_ID, DateScoreRecorded, HairScore, Age, CalvingSeason, ToxicFescue, Comment, Barcode, Sold2018) %>% 
    openxlsx::write.xlsx(file = str_c("/Users/harlyjanedurbin/Box Sync/HairShedding/ReportedData/2018/DataRecording_", farms[i], "_2018.xlsx" ))
  
}