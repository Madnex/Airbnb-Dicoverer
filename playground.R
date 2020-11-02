

# Project for shiny
library(rAmCharts)
listings <- read.csv("Data/listings.csv")
listings$neighbourhood <- as.factor(listings$neighbourhood)
listings$room_type <- as.factor(listings$room_type)
nbhoods <- read.csv("Data/neighbourhoods.csv")

listings <- listings[ , !(names(listings) %in% c("neighbourhood_group"))]


listings <- cityListings[["Bordeaux"]]

custom_listings <- listings[listings$price < quantile(listings$price, 0.99),]

names(listings)
boxplot(price~neighbourhood, data = custom_listings, range=3)
plot(price~room_type, data = custom_listings, range=3)

lm.1 <- lm(price~ host_id+neighbourhood+latitude+longitude+room_type+minimum_nights+number_of_reviews+availability_365, data=custom_listings )
summary(lm.1)
plot(lm.1)

num_vals <- unlist(lapply(listings, is.numeric))  
corrplot::corrplot(cor(listings[,num_vals]))

library(ggplot2)
ggplot(listings) + aes(x=room_type) + geom_bar()
ggplot(custom_listings) + aes(x=price) + geom_histogram(bins = 10, stat = "density")
amHist(custom_listings$price, control_hist = list(breaks = 100), freq=FALSE)
p <- ggplot(custom_listings) + aes(x=price, y=number_of_reviews, colour=room_type) + geom_point(alpha=0.5)
p <- p + xlab("NEW RATING TITLE") + ylab("NEW DENSITY TITLE")
p <- p + guides(colour=guide_legend(title="New Legend Title"))
p

custom_listings_n <- custom_listings[custom_listings$neighbourhood == levels(custom_listings$neighbourhood)[1],]
counts <- custom






