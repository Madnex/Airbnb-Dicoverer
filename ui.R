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
            ####################################################
            # INFO PAGE
            ####################################################
             tabPanel("Info",
                      fluidPage(
                        column(6, offset = 3,
                          includeMarkdown("infoPage.md")
                        )
                      )
             ),
            ####################################################
            # DATA PAGE
            ####################################################
             tabPanel("Data", 
                      navlistPanel(
                        widths = c(2,10),
                        tabPanel(
                          "Summary",
                          verbatimTextOutput("summaryData")
                        ),
                        tabPanel(
                          "Details",
                          wellPanel(
                            radioButtons("detailsSelection", "Select the data set",
                                         choices = c("Calendar", "Listings", "POIs"),
                                         selected = "Listings",
                                         inline = TRUE)
                          ),
                          dataTableOutput("allInfo")
                        ),
                        tabPanel(
                          "Descriptive Stats",
                          sidebarLayout(
                            sidebarPanel(
                              selectInput("barplot_var", "Select Variable", 
                                          choices = c("Room Type", "Neighbourhood"),
                                          selected = "room_type")
                            ),
                            mainPanel(
                              plotOutput("barplot"),
                            )
                          ),
                          sidebarLayout(
                            sidebarPanel(
                              sliderInput("quantileHist", "Select quantile to cutoff", 
                                          min=0.1, max=1, step=0.01, value=0.99),
                              sliderInput("barsHist", "Select number of bins", 
                                          min=1, max=300, step=1, value=100),
                              selectInput("varHist", "Select variable", 
                                          choices = choicesHistogram)
                            ),
                            mainPanel(
                              amChartsOutput("histograms")
                            )
                          ),
                          sidebarLayout(
                            sidebarPanel(
                              sliderInput("quantileScatterX", "Select quantile to cutoff x",
                                          min=0.1, max=1, step=0.01, value=0.99),
                              sliderInput("quantileScatterY", "Select quantile to cutoff y",
                                          min=0.1, max=1, step=0.01, value=0.99),
                              selectInput("xVarScatter", "Select variable for x",
                                          choices = choicesScatter, selected = choicesScatter[1]),
                              selectInput("yVarScatter", "Select variable for y",
                                          choices = choicesScatter, selected = choicesScatter[4])
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
                          tags$head(tags$style(type="text/css", "
                             #loadmessage {
                                width: 100px;
                                height: 35px;
                                position: absolute;
                                top:0;
                                bottom: 0;
                                left: 0;
                                right: 0;
                                margin: auto;
                                padding: 5px;
                                text-align: center;
                                font-weight: bold;
                                color: #000000;
                                border-radius: 25px;
                                background-color: #808080;
                                z-index: 9999;
                             }
                          ")
                          ),
                          conditionalPanel(condition="$('html').hasClass('shiny-busy')",
                                           tags$div("Loading...",id="loadmessage")),
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
            ####################################################
            # EXPLORE PAGE
            ####################################################
            tabPanel("Explore",
                     sidebarLayout(
                       sidebarPanel(
                         radioButtons("nhoodValue", "Neighbourhood color by:", 
                                      choices = c("Number of Listings"="count",
                                                  "Average Price"="avgPrice",
                                                  "Number of Reviews"="nReviews"),
                                      selected = "count"),
                         uiOutput("selectHostForMap"),
                         uiOutput("maxPriceSlider"),
                         uiOutput("minNightsSlider"),
                         uiOutput("roomTypesCheckbox"),
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
            ),
            ####################################################
            # LINEAR MODEL PAGE
            ####################################################
            tabPanel("Linear Model",
                     fluidPage(
                       htmlOutput("headingLM")
                     ),
                     sidebarLayout(
                       sidebarPanel(
                         uiOutput("lmSelectionCheckbox")
                       ),
                       # Show a plot of the generated distribution
                       mainPanel(
                         verbatimTextOutput("lmSummary")
                       )
                     )
            )
  )
)
