####################################################
# READ THE DATA
####################################################

read_listings <- function(filename){
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
  localPOI <- readRDS(paste("Data/POIs/", filename,".rds", sep=""))
  return(localPOI)
}