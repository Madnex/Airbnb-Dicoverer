# Global variables 

library(ggplot2)
library(leaflet)

read_data <- function(filename){
  listings <- read.csv(paste("Data/", filename, ".csv", sep = ""))
  listings$neighbourhood <- as.factor(listings$neighbourhood)
  listings$room_type <- as.factor(listings$room_type)
  #nbhoods <- read.csv("Data/neighbourhoods.csv")
  listings <- listings[ , !(names(listings) %in% c("neighbourhood_group"))]
  return(listings)
}

supportedCities <- list("Paris", "Lyon", "Bordeaux")
cityListings <- list(Paris=read_data("paris"), Lyon=read_data("lyon"), Bordeaux=read_data("bordeaux"))
