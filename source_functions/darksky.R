library(darksky)
library(readr)
library(purrr)
library(stringr)
library(dplyr)
library(magrittr)

weather <- readr::read_rds(here::here("data/derived_data/weather.rds"))

# `weather` is a 3 column data frame: latitude, longitude, yyyy-mm-dd
weather %>% 
  View()

# Need to get a darksky API key and set it in the global environment
# https://darksky.net/dev/login?next=/account
Sys.setenv(DARKSKY_API_KEY = "")
darksky::darksky_api_key()

# This established a function to format dates in the timestamp format
# that darkspy requires
timestamp_chr <-
  function(var) {
    stringr::str_c(as.character(var), "T12:00:00-0400")
  }

# This establishes a function to get weather history
# given a date, lat, and lng
get_history <-
  function(lat, lng, date) {
    darksky::get_forecast_for(latitude = lat,
                              longitude = lng,
                              timestamp = timestamp_chr(date),
                              exclude = "currently")
  }


# This applies the function to each row in the data frame
# The result is a new data frame with a new list-column of
# all of the weather data
weather_done <- 
  weather %>%
  dplyr::mutate(data = purrr::pmap(list(lat, lng, value), .f = get_history))

# Save the data frame to an RDS file
readr::write_rds(weather_done, here::here("data/derived_data/weather_done.rds"))
