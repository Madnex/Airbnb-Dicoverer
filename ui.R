#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(colourpicker)
library(shinythemes)

shinyUI(
  navbarPage("Airbnb discovery",
                   theme = shinytheme("yeti"),
                   
                   tabPanel("Data", 
                            navlistPanel(
                              widths = c(2,10),
                              tabPanel(
                                "Data",
                                # Sidebar with a slider input for number of bins
                                sidebarLayout(
                                  sidebarPanel(
                                    radioButtons(inputId = "dataset", label = "City", choices = supportedCities, selected = supportedCities[1])
                                  ),
                                  
                                  # Show a plot of the generated distribution
                                  mainPanel(
                                    verbatimTextOutput("summaryData")
                                  )
                                )
                              ),
                              tabPanel(
                                "Summary",
                                dataTableOutput("allInfo")
                              )
                            )
                   ),
                  tabPanel("Explore",
                           sidebarLayout(
                             sidebarPanel(
                               uiOutput("maxPriceSlider"),
                               uiOutput("minNightsSlider"),
                               uiOutput("roomTypesCheckbox")
                             ),
                             
                             # Show a plot of the generated distribution
                             mainPanel(
                               leafletOutput("map")
                             )
                           )
                  )
  )
)
