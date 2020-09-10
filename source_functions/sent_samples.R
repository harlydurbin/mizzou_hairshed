sent <-
  list.files(
    "~/Box Sync/HairShedding/ReportedData/To_GeneSeek",
    pattern = "_[[:digit:]]+.xlsx",
    full.names = TRUE
  ) %>%
  # Name the elements of the list based on a stripped down version of the filepath
  set_names(nm = (basename(.) %>%
                    tools::file_path_sans_ext())) %>%
  # Create a list of data frames using readxl
  map(read_excel, col_types = "text", sheet = 1, trim_ws = TRUE) %>%
  # Based on the name of the file, create a column for when they were sent to Geneseek
  imap(~ mutate(.x,
                sent_date = str_extract(.y,
                                        "(?<=_)[[0-9]]+"))) %>%
  # Reduce the list of dataframes to one dataframe
  reduce(full_join) %>%
  # Format date column as a date
  mutate(sent_date = lubridate::mdy(sent_date)) %>%
  # Select the columns I want
  select(Lab_ID, barcode = Barcode, sent_date) %>%
  mutate(Lab_ID = as.integer(Lab_ID))

write_rds(sent, here::here("data/derived_data/sent.rds"))