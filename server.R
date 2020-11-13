#
# This is the server logic of a Shiny web application. You can run the
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(plyr)
library(tidyverse)


shinyServer(function(input, output, session) {
  #####################################
  # Dynamic data:
  #####################################
  listings <- reactive({
    cityListings[[input$dataset]]
  })
  
  nhoods <- reactive({
    cityNhoods[[input$dataset]]
  })
  
  calendar <- reactive({
    cityCalendar[[input$dataset]]
  })
  
  clickVal <- eventReactive(input$map_marker_click,{
    click<-input$map_marker_click
    if(is.null(click))
      return()
    click$id
  })
  
  gantDataForMap <- reactive({
    id <- clickVal()
    if(is.null(id))
      return()
    myCalendar <- calendar()
    myID <- myCalendar[myCalendar$listing_id==id,]
    if (dim(myID)[1] == 0)
      return()
    tmp <- data.frame(day=myID$date, value=as.numeric(myID$available)-1)
    tmp$group <- cumsum(c(1, diff(tmp$value) != 0))
    booking <- tmp %>% group_by(group) %>% summarise(start_day=min(day), end_day=max(day))
    booking$value <- sapply(booking$group, function(u) {
      day <- booking$start_day[booking$group==u]
      return (tmp$value[tmp$day==day])
    })
    booking <- booking[booking$value==1,]
    if (dim(booking)[1] == 0)
      return()
    g.gantt <- gather(booking, "state", "date", 2:3)
    g.gantt$value <- as.factor(g.gantt$value)
    g.gantt$Listing_ID <- id
    g.gantt$group <- paste(g.gantt$Listing_ID, g.gantt$group, sep = "_")
    g.gantt$Listing_ID <- as.factor(g.gantt$Listing_ID)
    
    if(dim(g.gantt)[1]!=0){
      start_m <- min(g.gantt$date)
      end_m <- max(g.gantt$date)
    } else{
      start_m <- min(myCalendar$date)
      end_m <- max(myCalendar$date)
    }
    seqs <- seq.Date(start_m, end_m, "month")
    
    return(list(data=g.gantt, seqs=seqs))
  })
  
  #####################################
  # output variable
  #####################################
  output$summaryData <- renderPrint({
    summary(listings())
  })
  
  output$clickValMap <- renderText({
    as.character(clickVal())
  })
  
  output$maxPriceSlider <- renderUI({
    # Creating a nice slider to allow for a good range and also the possibility to 
    # select even the extreme outliers
    price <- listings()$price
    slideRanges <- c(round(seq(min(price), quantile(price, 0.9), length.out = 49)), max(price))
    sliderTextInput("maxPrice", "Maximal Price", 
                choices = slideRanges,
                selected = slideRanges[10])
  })
  
  output$minNightsSlider <- renderUI({
    # Creating a nice slider to allow for a good range and also the possibility to 
    # select even the extreme outliers
    min_nights <- listings()$minimum_nights
    slideRanges <- c(round(seq(min(min_nights), quantile(min_nights, 0.9), length.out = 49)), max(min_nights))
    sliderTextInput("minNights", "Minumum Nights", 
                    choices = slideRanges,
                    selected = slideRanges[25])
  })
  
  output$roomTypesCheckbox <- renderUI({
    checkboxGroupInput("roomTypes", "Room Type", 
                       choices = levels(listings()$room_type), 
                       selected = levels(listings()$room_type))
  })
  
  output$selectHostForGant <- renderUI({
    byHost <- listings() %>% group_by(host_id) %>% summarise(listings=length(host_id))
    choicesHosts <- c(byHost[byHost$listings >= 3 & byHost$listings <= 10,1])
    selectInput("HostForGant", "Host", 
                       choices = choicesHosts, 
                       selected = choicesHosts[1])
  })
  
  output$selectHostForPrices <- renderUI({
    byHost <- listings() %>% group_by(host_id) %>% summarise(listings=length(host_id))
    choicesHosts <- c(byHost[byHost$listings >= 3 & byHost$listings <= 180,1])
    selectInput("HostForPrices", "Host", 
                choices = choicesHosts, 
                selected = choicesHosts[1])
  })
  
  output$barplot <- renderPlot({
    xdata <- if(input$barplot_var == "Neighbourhood") "neighbourhood" else "room_type"
    ggplot(listings()) + aes_string(x=xdata) + geom_bar() + labs(y="Number of Listings", x=input$barplot_var) + coord_flip()
  })
  
  output$histograms <- renderAmCharts({
    # Create a custom data frame with a cutoff, to allow for detailed selectable plots
    custom_listings <- custom_listings <- listings()[listings()[,input$varHist] < quantile(listings()[,input$varHist], input$quantileHist),]
    amHist(custom_listings[,input$varHist], control_hist = list(breaks = input$barsHist),
           freq=FALSE, xlab=names(choicesHistogram)[choicesHistogram == input$varHist])
  })
  
  output$scatterPlot <- renderPlot({
    # Create a custom data frame with a cutoff, to allow for detailed selectable plots
    custom_listings <- custom_listings <- listings()[listings()[,input$xVarScatter] < quantile(listings()[,input$xVarScatter], input$quantileScatterX),]
    p <- ggplot(custom_listings) + aes_string(x=input$xVarScatter, y=input$yVarScatter, colour="room_type") + geom_point(alpha=0.5)
    p <- p + xlab(names(choicesScatter)[choicesScatter == input$xVarScatter]) + ylab(names(choicesScatter)[choicesScatter == input$yVarScatter])
    p <- p + guides(colour=guide_legend(title="Room Type"))
    p
  })
  
  output$pieChart <- renderAmCharts({
    stats_by_neighb <- ddply(listings(),~neighbourhood,summarise,count=length(price))
    names(stats_by_neighb) <- c("label", "value")
    sorted <- stats_by_neighb[order(stats_by_neighb$value, decreasing = TRUE),]
    # Limit the output to the top 20 since too many neighbourhoods are not suitable for a piechart
    amPie(sorted[1:20,], inner_radius = 50, depth = 10, main="Proportion of number of Listings by neighbourhood (only top 20)")
  })
  
  output$barChartPrice <- renderAmCharts({
    stats_by_neighb <- ddply(listings(),~neighbourhood,summarise,price=round(mean(price), digits = 2))
    names(stats_by_neighb) <- c("label", "value")
    sorted <- stats_by_neighb[order(stats_by_neighb$value, decreasing = TRUE),]
    amBarplot("label", "value", data = sorted, depth = 10, labelRotation=20, main="Average Price per neighbourhood")
  })
  

  output$boxplotHost <- renderAmCharts({
    # plotting the prices of all listings of a given host 
    # The host has to have at least 3 listings to allow for a nice plot, therefore only those
    # hosts are selectable (see output$selectHostForPrice)
    
    myListings <- listings()
    
    ids <- unique(myListings$host_id[myListings$host_id==input$HostForPrices])
    allGant <- data.frame(matrix(ncol=2, nrow=0))
    colnames(allGant) <- c("price", "ID")
    
    for(i in 1:length(ids)){
      id <- ids[i]
      myID <- myListings[myListings$host_id==id,]
      if(dim(myID)[1]!=0){
        tmp <- data.frame(price=myID$price, ID=id)
        allGant <- rbind(allGant, tmp)
      }
    }
    allGant$ID <- as.factor(allGant$ID)
    
    amBoxplot(price ~ ID, data = allGant, main = "Prices distribution")
  })

  output$barChartListHost <- renderAmCharts({
    stats_by_host <- ddply(listings(),~as.character(host_id),summarise,count=length(price))
    names(stats_by_host) <- c("label", "value")
    sorted <- stats_by_host[order(stats_by_host$value, decreasing = TRUE),]
    amBarplot("label", "value", data = sorted[1:30,], depth = 10, labelRotation=20, main="Number of Listings per Host (only top 30)")
  })
  output$allInfo <- renderDataTable(listings())
  
  output$gantchartIDs <- renderPlot({
    # Gantt Chart, plotting the availability of all listings of a given host 
    # The host has to have 3-10 listings to allow for a nice plot, therefore only those
    # hosts are selectable (see output$selectHostForGant)
    myCalendar <- calendar()
    myListings <- listings()
    ids <- unique(myListings$id[myListings$host_id==input$HostForGant])
    if(length(ids) == 0 && !any(myCalendar$listing_id %in% ids)){
      ids <- unique(myCalendar$listing_id)[1:5]
    }
    allGant <- data.frame(matrix(ncol=5, nrow=0))
    colnames(allGant) <- c("group", "value", "state", "date", "ID")

    for(i in 1:length(ids)){
      id <- ids[i]
      myID <- myCalendar[myCalendar$listing_id==id,]
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
        g.gantt$Listing_ID <- id
        g.gantt$group <- paste(g.gantt$Listing_ID, g.gantt$group, sep = "_")
        allGant <- rbind(allGant, g.gantt)
      }
    }
    allGant$Listing_ID <- as.factor(allGant$Listing_ID)
    
    # If there is no listing at all available for this host we show an empty plot
    if(dim(allGant)[1]!=0){
      start_m <- min(allGant$date)
      end_m <- max(allGant$date)
    } else {
      start_m <- min(myCalendar$date)
      end_m <- max(myCalendar$date)
    }
    seqs <- seq.Date(start_m, end_m, "month")
    
    ggplot(allGant, aes(date, Listing_ID, color = Listing_ID, group=group)) + 
      geom_line(size = 10) +
      labs(x="Availability", y=NULL, title="Available timelines by listing") +
      scale_x_date(breaks=seqs, labels=strftime(seqs, "%b %y")) +
      theme_gray(base_size=14)
  })
  
  output$messageNoAvailability <- renderText({
    if(is.null(gantDataForMap()))
      return("This listing is not available at all :(")
    return("This listing is available on the following dates:")
  })
  output$gantChartForMap <- renderPlot({
    data <- gantDataForMap()
    if(is.null(data))
      return()
    g.gantt <- data$data
    seqs <- data$seqs
    ggplot(g.gantt, aes(date, Listing_ID, color = Listing_ID, group=group)) + 
      geom_line(size = 20) +
      labs(x="Availability", y=NULL, title=paste("Available timelines for listing", clickVal())) +
      scale_x_date(breaks=seqs, labels=strftime(seqs, "%b %y")) +
      theme_gray(base_size=14) + theme(legend.position = "none")
  })
  
  output$map <- renderLeaflet({
    # Predefined stuff:
    pal <- colorNumeric("Reds", NULL)
    palNhoods <- colorNumeric("viridis", NULL)
    myListings <- listings()#[1:300,] # Taking only a small subset for now to test stuff..
    myNhoods <- nhoods()
    
    customdata <- myListings[myListings$price <= input$maxPrice,]
    customdata <- customdata[customdata$minimum_nights <= input$minNights,]
    customdata <- customdata[customdata$room_type %in% input$roomTypes,]
    
    # Neighbourhoods
    selValue <- input$nhoodValue
    stats_by_neighb <- ddply(myListings,~neighbourhood,summarise, count=length(price), avgPrice=mean(price), nReviews=sum(number_of_reviews))
    
    stats_by_neighb$neighbourhood <- sapply(stats_by_neighb$neighbourhood, as.character)
    joinedN <-join(data.frame(neighbourhood=myNhoods$neighbourhood), stats_by_neighb, by="neighbourhood")
    if (selValue=="count"){myNhoods$value <- joinedN$count; labelNhood <- " Listings"}
    else if (selValue=="avgPrice"){myNhoods$value <- joinedN$avgPrice; labelNhood <- " $"}
    else {myNhoods$value <- joinedN$nReviews; labelNhood <- " Reviews"}
    
    
    leaflet(data=myNhoods) %>% addTiles() %>% addPolygons(fillColor = ~palNhoods(value)) %>% 
      addCircleMarkers(~longitude, ~latitude, layerId=~id,
                       popup = ~paste(paste("<b>", name, "</b>"),
                                      paste("<b>Reviews: </b> ", as.character(number_of_reviews)),
                                      paste("<b>Price: </b> ", as.character(price), "€"),
                                      paste("<b>Minimum nights: </b> ", as.character(minimum_nights)),
                                      paste("<b>Room type: </b> ", as.character(room_type)),
                                      paste("<b>Host: </b> ", as.character(host_name)),
                                      paste("<b>Link: <a href='https://www.airbnb.com/rooms/", as.character(id), "' target='_blank'>Airbnb</a>", sep = ""),
                                      sep = "<br/>"),
                       color = ~pal(price), data = customdata, radius = 2, opacity = 0.7) %>% 
                      addLegend("bottomright", pal = palNhoods, values = ~value,
                           title = "Neighbourhood",
                           labFormat = labelFormat(suffix = labelNhood),
                           opacity = 0.7
                       ) %>%
                      addLegend("bottomleft", pal = pal, values = ~price,
                                title = "Listings",
                                labFormat = labelFormat(prefix = "$"),
                                opacity = 0.7, data = customdata
                      )
  })
})
