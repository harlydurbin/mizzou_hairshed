##Pull samples that need to be transferred from GeneSeek to breed associations

library(tidyverse)
library(readxl)
library(magrittr)
library(lubridate)

########

#Read in mbd file of the Animal table

source(here::here("source_functions/function.animal_table.R"))

animal_table <- get_animal_table("181221")

#########
source(here::here("source_functions/function.tissue_table.R"))

#Read in mbd file of the Tissue table
tissue <- get_tissue("181221")
###########

#Breed association/primary breed key
breed_assoc <-
  read_csv("~/googledrive/research_extension/breed_assoc_key.csv")

###########

#Dates in "yyyy-mm-dd" format
sample_transfer <- function(earliest, latest) {
  now <- gsub("-",
              "",
              as.character(today()))
  
  #Create a list of filepaths
  filepaths <-
    list.files(
      "~/Box Sync/HairShedding/ReportedData/To_GeneSeek/",
      pattern = ".xlsx",
      full.names = TRUE
    ) %>%
    #Name the elements of the list based on a stripped down version of the filepath
    set_names(nm = (basename(.) %>%
                      tools::file_path_sans_ext()))
  
  filepaths %>%
    #Create a list of data frames using readxl
    map(read_excel, col_types = "text", sheet = 1) %>%
    #Based on the name of the file, create a column for when they were sent to Geneseek
    imap( ~ mutate(.x,
                   sent_date = str_extract(.y,
                                           "(?<=_)[[0-9]]+"))) %>%
    #Reduce the list of dataframes to one dataframe
    reduce(full_join) %>%
    #Format date column as a date
    mutate(sent_date = lubridate::mdy(sent_date)) %>%
    #Pull out samples from the specified range
    filter(sent_date > as.Date(earliest) &
             sent_date < as.Date(latest)) %>%
    #Select the columns I want
    select(Lab_ID, Reg, Barcode) %>%
    #Select a few columns from the animal table
    #change Lab_ID column in the animal table to character
    #Left join dataframe generated above to my trimmed down Animal table by Lab_ID
    left_join(
      animal_table %>%
        select(
          Lab_ID,
          Ref_ID,
          Ref_ID_source,
          BC,
          Sex,
          DOB,
          Sire_Reg,
          Dam_Reg,
          registered,
          breed_assoc
        ) %>%
        mutate(Lab_ID = as.character(Lab_ID)),
      by = c("Lab_ID")
    ) %>%
    #Keep only registered animals
    filter(registered == 1) %>%
    left_join(
      tissue %>%
        select(Lab_ID, Source_code) %>%
        mutate(Lab_ID = as.character(Lab_ID)),
      by = c("Lab_ID")
    ) %>%
    left_join(breed_assoc %>%
                select(assoc_code, breed_assoc),
              by = c("breed_assoc")) %>%
    distinct() %>%
    #Split into list of dataframes by breed association
    split(.$breed_assoc) %>%
    #Apply a function (write_csv) to the list of dataframes (.x)
    #Name each file by creating a string that has the breed code associated with each breed association in the middle
    purrr::walk( ~ .x %>%
                   writexl::write_xlsx(
                     path = str_c(
                       "~/Box Sync/HairShedding/ReportedData/SendToBreedAssociations/",
                       now,
                       ".",
                       unique(.x$assoc_code),
                       ".xlsx"
                     ),
                     col_names = TRUE
                   ))
}
