
library(shiny)
library(DT)
library(leaflet)
library(rsconnect)

rsconnect::setAccountInfo(name='echoxiaowu',
                          token='1585CEB73E03B759606B594D20BD30C8',
                          secret='CtRTt06ImILgniEC03Ugr3oOEwbubf3xmzTHasqU')

fluidPage(
  
  titlePanel("2016 Childhood Lead Exposure in Minneapolis"),
  
  tabsetPanel(type = "tabs",
              tabPanel("Map", leafletOutput("mymap")),
              tabPanel("Table", dataTableOutput('table')),
              tabPanel("About", 
                       h4("Elevated blood lead levels (EBLLs) in young children are linked with health effects, including learning impairment, behavioral problems, and even death if lead levels are very high. There is no safe level of exposure to lead. Children up to 6 years old and living in older homes are at the highest risk for lead exposure. Swallowing dust contaminated with lead-based paint is a common cause of elevated blood lead levels."),
                       fluidRow(
                         column(4,offset=4, 
                                img(src='noun_578567_cc.svg')
                         )
                       ),
                       br(),
                       p("For more information about blood lead testing, elevated blood lead levels, and risk factors for lead exposure, see [MN Public Health Data Access: Childhood Lead Exposure](https://data.web.health.state.mn.us/lead)")
              )
  ),
  hr(),
  fluidRow(
    column(6,offset=1, 
           
           uiOutput("selectEBLL")
    ),
    column(5,
           actionButton("recalc", "Generate new points")
           
    )
  )
)

