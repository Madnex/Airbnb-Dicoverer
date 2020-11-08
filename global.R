# Global variables 

library(shiny)
library(ggplot2)
library(leaflet)
library(rgdal)
library(rAmCharts)
library(shinyWidgets)

####################################################
# Data
####################################################

read_data <- function(filename){
  listings <- read.csv(paste("Data/", filename, ".csv", sep = ""))
  listings$neighbourhood <- as.factor(listings$neighbourhood)
  listings$room_type <- as.factor(listings$room_type)
  listings <- listings[ , !(names(listings) %in% c("neighbourhood_group"))]
  return(listings)
}
read_nhoods <- function(filename){
  nhoods <- rgdal::readOGR(paste("Data/Neighbourhoods/", filename, ".geojson", sep = ""))
  return(nhoods)
}
read_calendar <- function(filename){
  calendar <- readRDS(paste("Data/Calendar/", filename,".rds", sep=""))
  return(calendar)
}

supportedCities <- list("Lyon", "Bordeaux", "Munich", "Athens")

# Loading the data variables cityListings, cityNhoods and cityCalendar
cityListings <- lapply(supportedCities, function(u){
  read_data(tolower(u))
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


####################################################
# Choices for displaying value and key:
####################################################

choicesHistogram <- c("Price" = "price", "Minimum Nights" = "minimum_nights",
                      "Number of Listings of Host" = "calculated_host_listings_count",
                      "Number of Reviews" = "number_of_reviews")
choicesScatter <- c("Price" = "price", "Minimum Nights" = "minimum_nights",
                      "Number of Listings of Host" = "calculated_host_listings_count",
                      "Number of Reviews" = "number_of_reviews")