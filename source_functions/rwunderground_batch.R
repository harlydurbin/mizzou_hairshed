library(readr)
library(rwunderground)
library(purrr)
library(dplyr)
library(tidyr)
library(here)
library(stringr)
library(ratelimitr)

# This function just correctly/consistently formats
# dates as characters
ymd_chr <-
  function(var) {
    gsub("-", "", as.character(var))
  }

# This establishes a function to get weather history
# given a date, zipcode
# get_history <-
#   function(zipcode, value) {
#     rwunderground::history(location = zipcode,
#                            date = ymd_chr(value),
#                            key = "")
#   }

# Limit the rate of the get_history function to 10 
# times maximum every minute
# limit <-
#   ratelimitr::limit_rate(get_history,
#              rate(n = 10, period = 60))

longhaul <-
  function(group) {
    
    # Read in date_data data frame
    # 3 column data frame: latitude, longitude, yyyy-mm-dd
    date_data <-
      read_rds(str_c("/data/tnr343/hjd_climate/weather_group", group, ".rds")) %>%
      # Create an ID column based on group number
      mutate(group = group)
    
    date_done <-
      date_data %>%
      # For each row in date data, pull down weather history and save it in 
      # a new column called "data"
      mutate(data = purrr::map2(
        zipcode,
        value,
        ~ rwunderground::history(
          location = .x,
          date = ymd_chr(.y),
          # Need a rwunderground key 
          key = ""
        )
      ))
    
    date_done %>%
      readr::write_rds(str_c("/data/tnr343/hjd_climate/out", group, ".rds"))
    
  }

# limit function to run only once every 86,300 seconds (once every 24 hours)
long_limit <-
  limit_rate(longhaul,
             rate(n = 1, period = 86300))

# run `long_limit` function for all 14 weather files
purr::walk(list(1:14), long_limit)