# Global variables 

library(shiny)
library(ggplot2)
library(leaflet)
library(rgdal)
library(rAmCharts)
library(shinyWidgets)

####################################################
# DATA
####################################################

read_data <- function(filename){
  listings <- read.csv(paste("Data/Listings/", filename, ".csv", sep = ""))
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
read_pois <- function(filename){
  pois <- read.csv(paste("Data/POIs/", filename,"-pois.osm.csv.gz", sep=""), header = TRUE, sep = "|")
  # Filter for area square
  camelCase <- paste(toupper(substring(filename, 1,1)),substring(filename, 2), sep = "")
  listings <- cityListings[[camelCase]]
  c_lat <- mean(listings$latitude)
  c_lon <- mean(listings$longitude)
  # Select only a circle around the center of the city
  r <- 0.05
  lon <- pois$LON - c_lon
  lat <- pois$LAT - c_lat
  area_sel <- lon**2 + lat**2 < r**2 
  # Filter for category
  boring <- pois$CATEGORY %in% c("BUSINESS", "RELIGIOUS", "EDUCATION", "LANDUSE",
                                    "AUTOMOTIVE", "SETTLEMENTS", "HEALTH", "ACCOMMODATION", 
                                    "PUBLICSERVICE", "TRANSPORT")
  localPOI <- pois[area_sel & !boring,]
  localPOI$CATEGORY <- as.factor(localPOI$CATEGORY)
  localPOI$SUBCATEGORY <- as.factor(localPOI$SUBCATEGORY)

  return(localPOI)
}

####################################################
# SUPPORTED CITIES

# Paris is not supported on shinyapps.io since it takes too much ram, however, if you
# run this app locally you can simply add "Paris" here to see it as well.

supportedCities <- list("Brussels", "Edinburgh", "Lyon", "Bordeaux", "Munich", "Athens")

####################################################

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