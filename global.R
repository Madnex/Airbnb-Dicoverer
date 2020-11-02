# Global variables 

library(ggplot2)
library(leaflet)
library(rgdal)

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

supportedCities <- list("Paris", "Lyon", "Bordeaux")
cityListings <- list(Paris=read_data("paris"), Lyon=read_data("lyon"), Bordeaux=read_data("bordeaux"))
cityNhoods <- list(Paris=read_nhoods("paris"), Lyon=read_nhoods("lyon"), Bordeaux=read_nhoods("bordeaux"))

####################################################
# Choices for displaying value and key:
####################################################

choicesHistogram <- c("Price" = "price", "Minimum Nights" = "minimum_nights",
                      "Number of Listings of Host" = "calculated_host_listings_count",
                      "Number of Reviews" = "number_of_reviews")
choicesScatter <- c("Price" = "price", "Minimum Nights" = "minimum_nights",
                      "Number of Listings of Host" = "calculated_host_listings_count",
                      "Number of Reviews" = "number_of_reviews")