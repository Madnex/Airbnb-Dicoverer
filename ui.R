#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(colourpicker)
library(shinythemes)

shinyUI(
  navbarPage("Airbnb discovery",
                   theme = shinytheme("yeti"),
                   header = fluidPage(
                     fluidRow(
                       column(12,
                              wellPanel(
                                radioButtons(inputId = "dataset", 
                                             label = "Selected city", 
                                             choices = supportedCities, 
                                             selected = supportedCities[1],
                                             inline = TRUE
                                            )
                              )
                      )
                    )
                   ),
             tabPanel("Info",
                      fluidPage(
                        column(6, offset = 3,
                          includeMarkdown("infoPage.md")
                        )
                      )
             ),
             tabPanel("Data", 
                      navlistPanel(
                        widths = c(2,10),
                        tabPanel(
                          "Summary",
                          verbatimTextOutput("summaryData")
                        ),
                        tabPanel(
                          "Details",
                          dataTableOutput("allInfo")
                        ),
                        tabPanel(
                          "Descriptive Stats",
                          sidebarLayout(
                            sidebarPanel(
                              selectInput("barplot_var", "Select Variable", choices = c("Room Type", "Neighbourhood"), selected = "room_type")
                            ),
                            mainPanel(
                              plotOutput("barplot"),
                            )
                          ),
                          sidebarLayout(
                            sidebarPanel(
                              sliderInput("quantileHist", "Select quantile to cutoff", min=0.1, max=1, step=0.01, value=0.99),
                              sliderInput("barsHist", "Select number of bins", min=1, max=300, step=1, value=100),
                              selectInput("varHist", "Select variable", choices = choicesHistogram)
                            ),
                            mainPanel(
                              amChartsOutput("histograms")
                            )
                          ),
                          sidebarLayout(
                            sidebarPanel(
                              sliderInput("quantileScatterX", "Select quantile to cutoff x", min=0.1, max=1, step=0.01, value=0.99),
                              selectInput("xVarScatter", "Select variable for x", choices = choicesScatter, selected = choicesScatter[1]),
                              selectInput("yVarScatter", "Select variable for y", choices = choicesScatter, selected = choicesScatter[2])
                            ),
                            mainPanel(
                              plotOutput("scatterPlot")
                            )
                          )
                        ),
                        tabPanel(
                          "Calendar",
                          sidebarLayout(
                            sidebarPanel(
                              uiOutput("selectHostForGant")
                            ),
                            mainPanel(
                              plotOutput("gantchartIDs")
                            )
                          )
                        ),
                        tabPanel(
                          "Neighbourhoods",
                          amChartsOutput("pieChart"),
                          amChartsOutput("barChartPrice")
                        ),
                        tabPanel(
                          "Hosts",
                          amChartsOutput("barChartListHost"),
                          sidebarLayout(
                            sidebarPanel(
                              uiOutput("selectHostForPrices")
                            ),
                            mainPanel(
                              amChartsOutput("boxplotHost")
                            )
                          )
                        )
                      )
             ),
            tabPanel("Explore",
                     sidebarLayout(
                       sidebarPanel(
                         uiOutput("maxPriceSlider"),
                         uiOutput("minNightsSlider"),
                         uiOutput("roomTypesCheckbox"),
                         radioButtons("nhoodValue", "Neighbourhood color by:", 
                                      choices = c("Number of Listings"="count", "Average Price"="avgPrice",
                                                  "Number of Reviews"="nReviews"), selected = "count"),
                         checkboxInput("showPOIs", "Show Points of Interest"),
                         uiOutput("poiCategoryRadio"),
                         uiOutput("poiSubCategoryCheckbox"),
                       ),
                       
                       # Show a plot of the generated distribution
                       mainPanel(
                         leafletOutput("map", height = "70vh"),
                         verbatimTextOutput("clickValMap"),
                         uiOutput("availableText"),
                         plotOutput("gantChartForMap")
                       )
                     )
            )
  )
)
