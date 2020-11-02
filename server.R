#
# This is the server logic of a Shiny web application. You can run the
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(ggplot2)
library(plyr)

shinyServer(function(input, output, session) {
  listings <- reactive({
    cityListings[[input$dataset]]
  })
  output$summaryData <- renderPrint({
    summary(listings())
  })
  output$maxPriceSlider <- renderUI({
    sliderInput("maxPrice", "Maximal Price", 
                min=min(listings()$price), max=quantile(listings()$price, 0.9), 
                value = median(listings()$price))
  })
  output$minNightsSlider <- renderUI({
    sliderInput("minNights", "Minumum Nights", 
                min=1, max=quantile(listings()$minimum_nights, 0.9), 
                value = median(listings()$minimum_nights))
  })
  output$roomTypesCheckbox <- renderUI({
    checkboxGroupInput("roomTypes", "Room Type", 
                       choices = levels(listings()$room_type), 
                       selected = levels(listings()$room_type))
  })
  output$barplot <- renderPlot({
    xdata <- if(input$barplot_var == "Neighbourhood") "neighbourhood" else "room_type"
    ggplot(listings()) + aes_string(x=xdata) + geom_bar() + labs(y="Number of Listings", x=input$barplot_var)
  })
  output$histograms <- renderAmCharts({
    custom_listings <- custom_listings <- listings()[listings()[,input$varHist] < quantile(listings()[,input$varHist], input$quantileHist),]
    amHist(custom_listings[,input$varHist], control_hist = list(breaks = input$barsHist),
           freq=FALSE, xlab=names(choicesHistogram)[choicesHistogram == input$varHist])
  })
  output$scatterPlot <- renderPlot({
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
    amPie(sorted[1:20,], inner_radius = 50, depth = 10, main="Proportion of number of Listings by neighbourhood (only top 20)")
  })
  output$barChartPrice <- renderAmCharts({
    stats_by_neighb <- ddply(listings(),~neighbourhood,summarise,price=round(mean(price), digits = 2))
    names(stats_by_neighb) <- c("label", "value")
    sorted <- stats_by_neighb[order(stats_by_neighb$value, decreasing = TRUE),]
    amBarplot("label", "value", data = sorted, depth = 10, labelRotation=20, main="Average Price per neighbourhood")
  })
  output$map <- renderLeaflet({
    ColorPal2 <- colorNumeric(scales::seq_gradient_pal(low = "red", high = "black", 
                                                       space = "Lab"), domain = c(0,1))
    customdata <- listings()[1:300,] # Taking only a small subset for now to test stuff..
    customdata <- customdata[customdata$price <= input$maxPrice,]
    customdata <- customdata[customdata$minimum_nights <= input$minNights,]
    customdata <- customdata[customdata$room_type %in% input$roomTypes,]
    leaflet(data=customdata) %>% addTiles() %>% 
      addCircleMarkers(~longitude, ~latitude,
                       popup = ~paste(paste("<b>", name, "</b>"),
                                      paste("<b>Reviews: </b> ", as.character(number_of_reviews)),
                                      paste("<b>Price: </b> ", as.character(price), "€"),
                                      paste("<b>Minimum nights: </b> ", as.character(minimum_nights)),
                                      paste("<b>Room type: </b> ", as.character(room_type)),
                                      paste("<b>Host: </b> ", as.character(host_name)),
                                      sep = "<br/>"), color = ~ColorPal2(reviews_per_month))
  })
  output$allInfo <- renderDataTable(listings())
})
