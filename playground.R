

# Project for shiny
library(rAmCharts)
listings <- read.csv("Data/listings.csv")
listings$neighbourhood <- as.factor(listings$neighbourhood)
listings$room_type <- as.factor(listings$room_type)
nbhoods <- read.csv("Data/neighbourhoods.csv")

calendar <- read.csv("Data/Calendar/lyon.csv.gz", colClasses = c("integer", "Date", "factor", "character", "character", "integer", "integer"))
calendar$price <- sapply(calendar$price, function(u) as.numeric(substr(u, 2, nchar(u))))
calendar <- calendar[,-5]
saveRDS(calendar, file = "Data/Calendar/lyon.rds")

filename="paris"
calendar <- readRDS(paste("Data/Calendar/", filename,".rds", sep=""))

calendar[calendar$listing_id==695607,]



listings <- cityListings[["Paris"]]

listings[listings$host_id==6792,]

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

########################################
# Calendar
########################################
library(dplyr)
library(tidyverse)
calendar <- cityCalendar[["Paris"]]

unique(listings$host_id)
byHost <- listings %>% group_by(host_id) %>% summarise(listings=length(host_id))
choicesHosts <- unique(c(byHost[byHost$listings >= 2 & byHost$listings <= 10,1])$host_id)

host_id <- 397551
# Prepare Gant data
ids <- unique(listings$id[listings$host_id==host_id])
ids <- unique(calendar$listing_id %in% ids)

ids <- c(16186775, 16187211, 18685122)

myListings <- listings
names(myListings)[1] <- "listing_id"
myListings <- myListings[myListings$host_id %in% choicesHosts,]
joined_data <- join(calendar, myListings, by="listing_id", type="inner") %>% select(listing_id, host_id)
byHost <- joined_data %>% group_by(host_id, listing_id) %>% summarise(listings=length(host_id)) %>% summarise(listings=length(host_id))
choicesHosts1 <- unique(c(byHost[byHost$listings >= 2 & byHost$listings <= 10,1])$host_id)
  
  
allGant <- data.frame(matrix(ncol=5, nrow=0))
colnames(allGant) <- c("group", "value", "state", "date", "ID")
for(i in 1:length(ids)){
  id <- ids[i]
  myID <- calendar[calendar$listing_id==id,]
  if(dim(myID)[1]!=0){
    tmp <- data.frame(day=myID$date, value=as.numeric(myID$available)-1)
    tmp$group <- cumsum(c(1, diff(tmp$value) != 0))
    booking <- tmp %>% group_by(group) %>% summarise(start_day=min(day), end_day=max(day))
    booking$value <- sapply(booking$group, function(u) {
      day <- booking$start_day[booking$group==u]
      return (tmp$value[tmp$day==day])
    })
    booking <- booking[booking$value==1,]
    g.gantt <- gather(booking, "state", "date", 2:3)
    g.gantt$value <- as.factor(g.gantt$value)
    g.gantt$ID <- id
    g.gantt$group <- paste(g.gantt$ID, g.gantt$group, sep = "_")
    allGant <- rbind(allGant, g.gantt)
  }
}
allGant$ID <- as.factor(allGant$ID)

  if(dim(allGant)[1]!=0){
    start_m <- min(allGant$date)
    end_m <- max(allGant$date)
  } else {
    start_m <- min(calendar$date)
    end_m <- max(calendar$date)
  }

seqs <- seq.Date(start_m, end_m, "month")

ggplot(allGant, aes(date, ID, color = ID, group=group)) + 
  geom_line(size = 10) +
  labs(x="Availability", y=NULL, title="Available timelines by listing") +
  scale_x_date(breaks=seqs, labels=strftime(seqs, "%b %y")) +
  theme_gray(base_size=14)


  


# Leaflet map
library(leaflet)
library(rgdal)




nhoods <- cityNhoods[["Lyon"]]


selValue <- "count"
stats_by_neighb <- ddply(listings,~neighbourhood,summarise, count=length(price), avgPrice=mean(price), nReviews=sum(number_of_reviews))
stats_by_neighb$neighbourhood <- sapply(stats_by_neighb$neighbourhood, as.character)
joinedN <-join(data.frame(neighbourhood=nhoods$neighbourhood), stats_by_neighb, by="neighbourhood")
nhoods$count <- joinedN$count
nhoods$avgPrice <- joinedN$avgPrice
nhoods$nReview <- joinedN$nReviews

ColorPal2 <- colorNumeric(scales::seq_gradient_pal(low = "red", high = "black", 
                                                   space = "Lab"), domain = c(0,1))
pal <- colorNumeric("viridis", NULL)

leaflet(nhoods) %>% addTiles() %>%  addPolygons(fillColor = ~pal(selValue)) %>% 
  addCircleMarkers(~longitude, ~latitude,
                   popup = ~paste(paste("<b>", name, "</b>"),
                                  paste("<b>Reviews: </b> ", as.character(number_of_reviews)),
                                  paste("<b>Price: </b> ", as.character(price), "€"),
                                  paste("<b>Minimum nights: </b> ", as.character(minimum_nights)),
                                  paste("<b>Room type: </b> ", as.character(room_type)),
                                  paste("<b>Host: </b> ", as.character(host_name)),
                                  sep = "<br/>"), color = ~pal(reviews_per_month), data = listings[1:100,])




hist(listings$price)




