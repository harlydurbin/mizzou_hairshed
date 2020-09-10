library(dplyr)

get_tissue <- function(date_string){

  # tissue <- Hmisc::mdb.get(str_c("/Volumes/UMAG_samplesDB/Samples_", date, ".accdb"), tables = "Tissue", allow = c("_"))
  #tissue <- Hmisc::mdb.get(glue::glue("~/Box Sync/HairShedding/ReportedData/Samples_{date_string}.accdb"), tables = "Tissue", allow = c("_"))
   tissue <- Hmisc::mdb.get(glue::glue("~/Desktop/Samples_{date_string}.accdb"), tables = "Tissue", allow = c("_"))
doctoR::clear_labels(tissue) %>% 
  #Hmisc doesn't have a "stringsAsFactors" flag during import, so change all factor columns to characters
  mutate_if(is.factor, as.character)
}
