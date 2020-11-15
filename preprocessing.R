# Generating Preprocessed files for the calendar as the processing takes a while..

source('read_data.R')

####################################################
# CALENDAR PREPROCESSING
####################################################
preprocess_calendar <- function(filename){
  calendar <- read.csv(paste("Data/Calendar/raw/", filename, ".csv.gz", sep = ""), 
                       colClasses = c("integer", "Date", "factor", "character", 
                                      "character", "integer", "integer"))
  calendar$price <- sapply(calendar$price, function(u) as.numeric(substr(u, 2, nchar(u))))
  calendar <- calendar[,-5]
  saveRDS(calendar, file = paste("Data/Calendar/", filename,".rds", sep = ""))
}

# Add your city here and execute the code after you copied the raw file into Data/Calendar/raw/
preprocess_calendar("lyon")
preprocess_calendar("bordeaux")
preprocess_calendar("paris")
preprocess_calendar("munich")
preprocess_calendar("athens")
preprocess_calendar("edinburgh")
preprocess_calendar("brussels")

####################################################
# POI PREPROCESSING
####################################################
preprocess_pois <- function(filename){
  pois <- read.csv(paste("Data/POIs/raw/", filename,"-pois.osm.csv.gz", sep=""), 
                   header = TRUE, sep = "|")
  # Filter for area square
  camelCase <- paste(toupper(substring(filename, 1,1)),substring(filename, 2), sep = "")
  listings <- read_listings(filename)
  c_lat <- mean(listings$latitude)
  c_lon <- mean(listings$longitude)
  # Select only a circle around the center of the city with radius 0.05
  # 0.05 corresponds to approx. 5 KM. In detail this simple calculation
  # will not select a perfect circle but an ellipsis as the earth is not flat :P
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
  saveRDS(localPOI, file = paste("Data/POIs/", filename,".rds", sep = ""))
}

# Add your city here and execute the code after you copied the raw file into Data/Calendar/raw/
# The raw file has to be a gz file with the name nameofthecity-pois.osm.csv.gz and must only
# contain the csv file.
preprocess_pois("lyon")
preprocess_pois("bordeaux")
preprocess_pois("paris")
preprocess_pois("munich")
preprocess_pois("athens")
preprocess_pois("edinburgh")
preprocess_pois("brussels")
