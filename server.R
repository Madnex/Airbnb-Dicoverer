#
# This is the server logic of a Shiny web application. You can run the
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)

shinyServer(function(input, output, session) {
  listings <- reactive({
    cityListings[[input$dataset]]
  })
  output$summaryData <- renderPrint({
    summary(listings())
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
