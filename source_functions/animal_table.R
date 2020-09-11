#https://stackoverflow.com/questions/23568899/access-data-base-import-to-r-installation-of-mdb-tools-on-mac

library(magrittr)

get_animal_table <- function(path){
  
df <- 
  Hmisc::mdb.get(
    path,
    tables = "Animal",
    allow = c("_"))

#Tried to do this in a pipable fashion using the naniar package but the data frame is too large
df[df == ""] <- NA

#for now, append AMGV to animal table Gelbvieh

df <-
  df %>% 
  # Remove white space
  dplyr::mutate_if(is.character, dplyr::funs(stringr::str_squish(.))) %>% 
  dplyr::mutate(breed_assoc =
                  dplyr::case_when(
                    breed_assoc %in% c("American Angus Association ", "American Anugs Association") ~
                      "American Angus Association",
                    breed_assoc %in% c("American Shorthorn Association"," American Shorthon Association") ~
                      "American Shorthorn Association",
                    breed_assoc %in% c("American Maine Anjou Association", "Maine Anjou Association of America") ~
                      "American Maine-Anjou Association",
                    TRUE ~ 
                      as.character(breed_assoc)
                  ),
                Comment = dplyr::case_when(
                  Comment %in% c("Local Adaptation Project ", "Local Adptation Project", "Local Adaptaion Project", "Local Adapatation Project") ~
                    "Local Adaptation Project", 
                  TRUE ~ 
                    as.character(Comment)
                ),
                Reg = dplyr::case_when(
                  BC == "GEL" & breed_assoc == "American Gelbvieh Association" & breed_assoc_country == "USA" & !stringr::str_detect(Reg, "GV") ~
                    stringr::str_c("AMGV", Reg), 
                  TRUE ~
                    as.character(Reg)
                ),
                DOB = stringr::str_remove(DOB, " 00:00:00"),
                DOB = lubridate::mdy(DOB))
return(df)
}