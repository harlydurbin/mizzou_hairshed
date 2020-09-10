##Pull samples that need to be transferred from GeneSeek to breed associations

library(tidyverse)
library(readxl)
library(magrittr)
library(lubridate)

########

# #Read in mbd file of the Animal table
# animal_table <-
#   Hmisc::mdb.get(
#     "/Users/harlyjanedurbin/googledrive/Samples_181002.mdb",
#     tables = "Animal",
#     allow = c("_")
#   )
# 
# db_keep <-
#   c(
#     "Lab_ID",
#     "BC",
#     "Reg",
#     "Name",
#     "Sex",
#     "DOB",
#     "Sire_Reg",
#     "Dam_Reg",
#     "Ref_ID",
#     "Ref_ID_source",
#     "Comment",
#     "Ref_ID2",
#     "Ref_ID_source2",
#     "Ref_ID3",
#     "Ref_ID_source3",
#     "breed_assoc",
#     "international_id",
#     "lab_id_sire",
#     "sire_international_id",
#     "lab_id_dam",
#     "dam_international_id"
#   )
# 
# animal_table <- doctoR::clear_labels(animal_table) %>%
#   #Select a subset of columns
#   #select(one_of(db_keep)) %>%
#   #Hmisc doesn't have a "stringsAsFactors" flag during import, so change all factor columns to characters
#   mutate_if(is.factor, as.character)
# 
# #Tried to do this in a pipable fashion using the naniar package but the data frame is too large
# animal_table[animal_table == ""] <- NA
# 
# #########
# 
# #Read in mbd file of the Tissue table
# tissue <-
#   Hmisc::mdb.get(
#     "/Users/harlyjanedurbin/googledrive/Samples_181002.mdb",
#     tables = "Tissue",
#     allow = c("_")
#   )
# 
# tissue <- doctoR::clear_labels(tissue) %>%
#   #Select a subset of columns
#   #select(one_of(db_keep)) %>%
#   #Hmisc doesn't have a "stringsAsFactors" flag during import, so change all factor columns to characters
#   mutate_if(is.factor, as.character)
# 
# #Tried to do this in a pipable fashion using the naniar package but the data frame is too large
# tissue[tissue == ""] <- NA

###########



###########

sample_transfer <- function(earliest, latest) {
  
  #Breed association/primary breed key
  breed_assoc <-
    read_csv("~/googledrive/research_extension/breed_assoc_key.csv")
  
  now <- gsub("-",
              "",
              as.character(today()))
  
  #Create a list of filepaths
  filepaths <-
    list.files(
      "~/Box Sync/HairShedding/ReportedData/To_GeneSeek/",
      pattern = "To_GeneSeek_[[:digit:]]+\\.xlsx",
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
