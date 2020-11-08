# Generating Preprocessed files for the calendar as the processing takes a while..

preprocess_calendar <- function(filename){
  calendar <- read.csv(paste("Data/Calendar/raw/", filename, ".csv.gz", sep = ""), 
                       colClasses = c("integer", "Date", "factor", "character", "character", "integer", "integer"))
  calendar$price <- sapply(calendar$price, function(u) as.numeric(substr(u, 2, nchar(u))))
  calendar <- calendar[,-5]
  saveRDS(calendar, file = paste("Data/Calendar/", filename,".rds", sep = ""))
}

preprocess_calendar("lyon")
preprocess_calendar("bordeaux")
preprocess_calendar("paris")
preprocess_calendar("munich")
preprocess_calendar("athens")
