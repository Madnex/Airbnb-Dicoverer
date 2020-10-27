

# Project for shiny

listings <- read.csv("Data/listings.csv")
listings$neighbourhood <- as.factor(listings$neighbourhood)
listings$room_type <- as.factor(listings$room_type)
nbhoods <- read.csv("Data/neighbourhoods.csv")

listings <- listings[ , !(names(listings) %in% c("neighbourhood_group"))]





names(listings)
plot(price~neighbourhood, data = listings)
plot(price~room_type, data = listings)

num_vals <- unlist(lapply(listings, is.numeric))  
corrplot::corrplot(cor(listings[,num_vals]))

library(ggplot2)
ggplot(listings) + aes(x=room_type) + geom_bar()
ggplot(listings) + aes(x=number_of_reviews) + geom_histogram(bins = 10, stat = "density")

# Leaflet map
library(leaflet)

ColorPal2 <- colorNumeric(scales::seq_gradient_pal(low = "red", high = "black", 
                                                   space = "Lab"), domain = c(0,1))
leaflet(data=listings) %>% addTiles() %>% 
  addCircleMarkers(~longitude, ~latitude,
                   popup = ~paste(paste("<b>", name, "</b>"),
                                  paste("<b>Reviews: </b> ", as.character(number_of_reviews)),
                                  paste("<b>Price: </b> ", as.character(price), "€"),
                                  paste("<b>Minimum nights: </b> ", as.character(minimum_nights)),
                                  paste("<b>Room type: </b> ", as.character(room_type)),
                                  paste("<b>Host: </b> ", as.character(host_name)),
                                  sep = "<br/>"), color = ~ColorPal2(reviews_per_month))



hist(listings$price)


