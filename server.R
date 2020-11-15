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
library(digest)


shinyServer(function(input, output, session) {
  ##############################################################################
  # DYNAMIC DATA
  ##############################################################################
  listings <- reactive({
    cityListings[[input$dataset]]
  })
  
  nhoods <- reactive({
    cityNhoods[[input$dataset]]
  })
  
  calendar <- reactive({
    cityCalendar[[input$dataset]]
  })
  pois <- reactive({
    cityPOI[[input$dataset]]
  })
  
  linearModel <- reactive({
    selection <- input$lmSelection
    myListings <-  select(listings(), selection, price)
    lm(price~., data = myListings)
  })
  
  # Indicator variable for the text to display under the map
  wasClicked <- reactiveVal(FALSE)
  
  # Handling clicks on the map returns the id of the selected point
  clickVal <- eventReactive(input$map_marker_click,{
    wasClicked(TRUE)
    click<-input$map_marker_click
    if(is.null(click)){
      wasClicked(FALSE)
      return()
    }
    wasClicked(typeof(click$id) != "character")
    click$id
  })
  
  # Processing the gantt data depending on the selected listing
  gantDataForMap <- reactive({
    id <- clickVal()
    if(is.null(id) || typeof(id) == "character")
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
  
  ##############################################################################
  # OUTPUT VARIABLE
  ##############################################################################
  
  ################################
  # UI INPUTS
  ################################
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
    slideRanges <- rev(slideRanges)
    sliderTextInput("minNights", "Minumum Nights", 
                    choices = slideRanges,
                    selected = slideRanges[25])
  })
  
  output$roomTypesCheckbox <- renderUI({
    checkboxGroupInput("roomTypes", "Room Type", 
                       choices = levels(listings()$room_type), 
                       selected = levels(listings()$room_type))
  })
  
  output$lmSelectionCheckbox <- renderUI({
    # Selection checkbox for the linear model
    vars <- c("neighbourhood", "latitude", "longitude", "room_type", 
              "number_of_reviews", "availability_365")
    checkboxGroupInput("lmSelection", "Variables", 
                       choices = vars, 
                       selected = vars)
  })
  
  output$poiCategoryRadio <- renderUI({
    # If the POIs are not shown, do not show this input
    if(!input$showPOIs)
      return()
    cats <- levels(pois()$CATEGORY)
    # By default we want to select the tourism category
    selection <- if("TOURISM" %in% cats) "TOURISM" else cats[1]
    radioButtons("poiCategory", "Category of POI", 
                 choices = cats, 
                 selected = selection)
  })
  
  output$poiSubCategoryCheckbox <- renderUI({
    # If the POIs are not shown, do not show this input
    if(!input$showPOIs)
      return()
    cat <- input$poiCategory
    myPois <- pois()
    myPois <- myPois[myPois$CATEGORY==cat,]
    # Finding all the subcategories that belong to the selected category
    selections <- unique(myPois$SUBCATEGORY)
    selectInput("poiSubCategory", "Subcategory of POI", 
                choices = selections, 
                selected = NULL, 
                multiple = TRUE)
  })
  
  output$selectHostForGant <- renderUI({
    # Group by hosts and count their listings
    byHost <- listings() %>% group_by(host_id) %>% summarise(listings=length(host_id))
    # To allow for a nice plot only offer hosts with 3-10 listings
    choicesHosts <- c(byHost[byHost$listings >= 3 & byHost$listings <= 10,1])
    selectInput("HostForGant", "Host (with 3-10 listings)", 
                choices = choicesHosts, 
                selected = choicesHosts[1])
  })
  
  output$selectHostForPrices <- renderUI({
    # Group by hosts and count their listings
    byHost <- listings() %>% group_by(host_id) %>% summarise(listings=length(host_id))
    # To allow for only interesting hosts with at least 3 listings
    choicesHosts <- c(byHost[byHost$listings >= 3,1])
    selectInput("HostForPrices", "Host (with more than 2 listings)", 
                choices = choicesHosts, 
                selected = choicesHosts[1])
  })
  
  output$selectHostForMap <- renderUI({
    # Group by hosts and names and count their listings
    byHost <- listings() %>% group_by(host_id,host_name) %>% summarise(listings=length(host_id))
    # To allow for only interesting hosts with at least 3 listings
    byHost <- byHost[byHost$listings > 3,]
    choicesHosts <- c("No host selected",paste(byHost$host_name, byHost$host_id, sep = "_"))
    selectInput("HostForMap", "Host (with more than 3 listings)", 
                choices = choicesHosts,
                selected = choicesHosts[1])
  })
  
  ################################
  # TEXT
  ################################
  output$clickValMap <- renderText({
    if(typeof(clickVal()) == "character"){
      return(paste("You selected the POI with id:", clickVal()))
    }
    paste("You selected the listing with id:", as.character(clickVal()))
  })
  
  output$headingLM <- renderText({
    "<h2>A customizable linear model for the target variable price</h2>"
  })
  
  output$availableText <- renderUI({
    if(!wasClicked())
      return(HTML("<h3>Click on a listing to find out about it's availability :)</h3>"))
    if(is.null(gantDataForMap()))
      return(HTML("<h3>This listing is not available at all :(</h3>"))
    return(HTML("<h3>This listing is available on the following dates:</h3>"))
  })
  
  ################################
  # PLOTS AND THE REST
  ################################
  
  output$summaryData <- renderPrint({
    summary(listings())
  })
  
  output$barplot <- renderPlot({
    xdata <- if(input$barplot_var == "Neighbourhood") "neighbourhood" else "room_type"
    ggplot(listings()) + aes_string(x=xdata) + geom_bar() + labs(y="Number of Listings",
                                                                 x=input$barplot_var) + coord_flip()
  })
  
  output$histograms <- renderAmCharts({
    # Create a custom data frame with a cutoff, to allow for detailed selectable plots
    custom_listings <- listings()[listings()[,input$varHist] < quantile(listings()[,input$varHist], input$quantileHist),]
    amHist(custom_listings[,input$varHist], control_hist = list(breaks = input$barsHist),
           freq=FALSE, xlab=names(choicesHistogram)[choicesHistogram == input$varHist])
  })
  
  output$scatterPlot <- renderPlot({
    # Create a custom data frame with a cutoff, to allow for detailed selectable plots
    custom_listings <- listings()[listings()[,input$xVarScatter] < quantile(listings()[,input$xVarScatter], input$quantileScatterX),]
    custom_listings <- custom_listings[custom_listings[,input$yVarScatter] < quantile(custom_listings[,input$yVarScatter], input$quantileScatterY),]
    
    p <- ggplot(custom_listings)
    p <- p + aes_string(x=input$xVarScatter, y=input$yVarScatter, colour="room_type")
    p <- p + geom_point(alpha=0.5)
    p <- p + xlab(names(choicesScatter)[choicesScatter == input$xVarScatter])
    p <- p + ylab(names(choicesScatter)[choicesScatter == input$yVarScatter])
    p <- p + guides(colour=guide_legend(title="Room Type"))
    p
  })
  
  output$pieChart <- renderAmCharts({
    stats_by_neighb <- ddply(listings(),~neighbourhood,summarise,count=length(price))
    names(stats_by_neighb) <- c("label", "value")
    sorted <- stats_by_neighb[order(stats_by_neighb$value, decreasing = TRUE),]
    # Making sure that the colors are the same as the colors in the bar chart
    sorted$color <- sapply(sorted$label, function(u) paste('#',substring(digest(u), 1,6), sep=""))
    # Limit the output to the top 15 since too many neighbourhoods are not suitable for a piechart
    amPie(sorted[1:15,], inner_radius = 50, depth = 10, 
          main="Proportion of number of listings by neighbourhood (only top 15)")
  })
  
  output$barChartPrice <- renderAmCharts({
    stats_by_neighb <- ddply(listings(),~neighbourhood,summarise,price=round(mean(price), digits = 2))
    names(stats_by_neighb) <- c("label", "value")
    sorted <- stats_by_neighb[order(stats_by_neighb$value, decreasing = TRUE),]
    sorted$description <- paste(sorted$label, sorted$value)
    # Making sure that the colors are the same as the colors in the pie chart
    sorted$color <- sapply(sorted$label, function(u) paste('#',substring(digest(u), 1,6), sep=""))
    amBarplot("label", "value", data = sorted, depth = 10, labelRotation=20, 
              main="Average price per neighbourhood")
  })
  
  output$boxplotHost <- renderAmCharts({
    # plotting the prices of all listings of a given host 
    # hosts are selectable (see output$selectHostForPrice)
    myListings <- listings()
    myIDs <- myListings[myListings$host_id==input$HostForPrices,]
    amBoxplot(myIDs$price, main = "Prices distribution")
  })

  output$barChartListHost <- renderAmCharts({
    stats_by_host <- ddply(listings(),~as.character(host_id),summarise,count=length(price))
    names(stats_by_host) <- c("label", "value")
    sorted <- stats_by_host[order(stats_by_host$value, decreasing = TRUE),]
    sorted$description <- paste(sorted$label, ":", sorted$value)
    amBarplot("label", "value", data = sorted[1:30,], depth = 10, labelRotation=20,
              main="Number of listings per Host (only top 30)")
  })
  
  output$allInfo <- renderDataTable({
    sel <- input$detailsSelection
    if(sel == "Calendar")
      return(calendar())
    if(sel == "Listings")
      return(listings())
    if(sel == "POIs")
      return(pois())
    })
  
  output$gantchartIDs <- renderPlot({
    # Gantt Chart, plotting the availability of all listings of a given host 
    # The host has to have 3-10 listings to allow for a nice plot, therefore only those
    # hosts are selectable (see output$selectHostForGant)
    myCalendar <- calendar()
    myListings <- listings()
    ids <- unique(myListings$id[myListings$host_id==input$HostForGant])
    # In case we have not yet selected anything we show this default based on the first 5 ids
    if(length(ids) == 0 && !any(myCalendar$listing_id %in% ids)){
      ids <- unique(myCalendar$listing_id)[1:5]
    }
    allGant <- data.frame(matrix(ncol=5, nrow=0))
    colnames(allGant) <- c("group", "value", "state", "date", "ID")
    
    # Looping over the listings of the given host and adding them to the summary df: allGant
    for(i in 1:length(ids)){
      id <- ids[i]
      myID <- myCalendar[myCalendar$listing_id==id,]
      if(dim(myID)[1]!=0){
        tmp <- data.frame(day=myID$date, value=as.numeric(myID$available)-1)
        # Using cumsum to identify the cuts of the availability, i.e. when does it switch
        # from available to not available and vice versa. These are the groups then that
        # are grouped in the next step
        tmp$group <- cumsum(c(1, diff(tmp$value) != 0))
        booking <- tmp %>% group_by(group) %>% summarise(start_day=min(day), end_day=max(day))
        booking$value <- sapply(booking$group, function(u) {
          day <- booking$start_day[booking$group==u]
          return (tmp$value[tmp$day==day])
        })
        # Filter out only the periods where the listing is available
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
  
  output$gantChartForMap <- renderPlot({
    data <- gantDataForMap()
    # If no listing is selected do not display anything
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
    myListings <- listings()
    myNhoods <- nhoods()
    
    # Filtering the data
    customdata <- myListings[myListings$price <= input$maxPrice,]
    customdata <- customdata[customdata$minimum_nights >= input$minNights,]
    customdata <- customdata[customdata$room_type %in% input$roomTypes,]
    if(!is.null(input$HostForMap)){
      if (input$HostForMap != "No host selected"){
        customdata <- customdata[customdata$host_id == strsplit(input$HostForMap, "_")[[1]][2],]
      }
    }
   
    # Neighbourhoods
    selValue <- input$nhoodValue
    stats_by_neighb <- ddply(myListings,~neighbourhood,summarise, count=length(price), 
                             avgPrice=mean(price), nReviews=sum(number_of_reviews))
    stats_by_neighb$neighbourhood <- sapply(stats_by_neighb$neighbourhood, as.character)
    
    # We need to join the data from the listings (stats_by_neighb) with the 
    # geojson data (myNhoods) as we can not be sure that both data sources are in the same order
    joinedN <-join(data.frame(neighbourhood=myNhoods$neighbourhood),
                   stats_by_neighb, by="neighbourhood")
    
    # Setting some values for the markers and legends
    if (selValue=="count"){
      myNhoods$value <- joinedN$count; labelNhood <- " Listings"; labelNhoodPopUp <- "Listings:"
    }
    else if (selValue=="avgPrice"){
      myNhoods$value <- joinedN$avgPrice; labelNhood <- " $"; labelNhoodPopUp <- "Avg. Price ($):"
    }
    else {
      myNhoods$value <- joinedN$nReviews; labelNhood <- " Reviews"; labelNhoodPopUp <- "Reviews:"
    }
    
    # Creating the leaflet map
    myMap <- leaflet(data=myNhoods) %>% addTiles() 
    
    # Adding the neighbourhoods
    myMap <- myMap %>% addPolygons(fillColor = ~palNhoods(value), 
                                   popup = ~paste(paste("<b>", neighbourhood, "</b>"),
                                                  paste("<b>", labelNhoodPopUp, "</b>", round(value)),
                                                  sep = "<br/>")
                                   )
    
    # Adding the listings
    myMap <- myMap %>% addCircleMarkers(~longitude, ~latitude, layerId=~id,
                       popup = ~paste(paste("<b>", name, "</b>"),
                                      paste("<b>Reviews: </b> ", as.character(number_of_reviews)),
                                      paste("<b>Price: </b> ", as.character(price), "€"),
                                      paste("<b>Minimum nights: </b> ", as.character(minimum_nights)),
                                      paste("<b>Room type: </b> ", as.character(room_type)),
                                      paste("<b>Host: </b> ", as.character(host_name)),
                                      paste("<b>Link: <a href='https://www.airbnb.com/rooms/", as.character(id), "' target='_blank'>Airbnb</a>", sep = ""),
                                      sep = "<br/>"),
                       color = ~pal(price), data = customdata, radius = 4, opacity = 0.7)
    
    # Adding the legends
    myMap <- myMap %>% addLegend("bottomright", pal = palNhoods, values = ~value,
                           title = "Neighbourhood",
                           labFormat = labelFormat(suffix = labelNhood),
                           opacity = 0.7
                       )
    myMap <- myMap %>% addLegend("bottomleft", pal = pal, values = ~price,
                                title = "Listings",
                                labFormat = labelFormat(prefix = "$"),
                                opacity = 0.7, data = customdata
                      )
    
    # Adding the POIs if selected
    if(input$showPOIs && length(input$poiCategory) == 1){
      myPois <- pois()
      myPois <- myPois[myPois$CATEGORY==input$poiCategory,]
      # Clustering is based on whether a subcategory is selected or not
      clustering <- TRUE
      if(length(input$poiSubCategory) > 0){
        myPois <- myPois[as.character(myPois$SUBCATEGORY) %in% input$poiSubCategory,]
        clustering <- NULL
      }
      
      myMap <- myMap %>% addMarkers(~LON, ~LAT, layerId = ~ID, 
                                    popup = ~paste(paste("<b>", NAME, "</b>"),
                                                   paste("<b>Category: </b> ", as.character(CATEGORY)),
                                                   paste("<b>Subcategory: </b> ", as.character(SUBCATEGORY)),
                                                   paste("<b>Link: <a href='https://www.openstreetmap.org/", as.character(ID), "' target='_blank'>OSM</a>", sep = ""),
                                                   sep = "<br/>"),
                                    label = ~as.character(NAME),
                                    clusterOptions = clustering,
                                    data = myPois
                                    )
    }
    
    # Returning the map
    myMap
  })
  
  output$lmSummary <- renderPrint({
    myLM <- linearModel()
    summary(myLM)
  })
    
})
