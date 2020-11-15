# Global variables 

library(shiny)
library(ggplot2)
library(leaflet)
library(rgdal)
library(rAmCharts)
library(shinyWidgets)

source('read_data.R')

####################################################
# SUPPORTED CITIES
####################################################
# Paris is not supported on shinyapps.io since it takes too much ram, however, if you
# run this app locally you can simply add "Paris" here to see it as well. 
# For adding more cities see README.md
#
supportedCities <- list("Brussels", "Edinburgh", "Lyon", "Bordeaux", "Munich", "Athens", "Paris")
#
#
####################################################
# END SUPPORTED CITIES
####################################################

# Loading the data variables cityListings, cityNhoods, cityCalendar and cityPOI
cityListings <- lapply(supportedCities, function(u){
  read_listings(tolower(u))
})
names(cityListings) <- supportedCities

cityNhoods <- lapply(supportedCities, function(u){
  read_nhoods(tolower(u))
})
names(cityNhoods) <- supportedCities

cityCalendar <- lapply(supportedCities, function(u){
  read_calendar(tolower(u))
})
names(cityCalendar) <- supportedCities

cityPOI <- lapply(supportedCities, function(u){
  read_pois(tolower(u))
})
names(cityPOI) <- supportedCities


####################################################
# CHOICES FOR DISPLAYING VALUE AND KEY:
####################################################

choicesHistogram <- c("Price" = "price", "Minimum Nights" = "minimum_nights",
                      "Number of Listings of Host" = "calculated_host_listings_count",
                      "Number of Reviews" = "number_of_reviews")
choicesScatter <- c("Price" = "price", "Minimum Nights" = "minimum_nights",
                      "Number of Listings of Host" = "calculated_host_listings_count",
                      "Number of Reviews" = "number_of_reviews")