
library(shiny)
library(maps)
library(dplyr)
library(leaflet)

tracts = st_read_db(con, query = "SELECT * FROM tract16withld", geom_column = 'wkb_geometry')

points = st_read_db(con, query = "SELECT * FROM tract16ct", geom_column = 'wkb_geometry')

#bigtracts <- filter(world.cities, pop > 1000000)

tracts$pct_ebll_county <- gsub("%","", tracts$pct_ebll_county)

tracts$pct_ebll_county <- as.numeric(tracts$pct_ebll_county)

points$pct_ebll_county <- gsub("%","", points$pct_ebll_county)

points$pct_ebll_county <- as.numeric(points$pct_ebll_county)

shinyServer(function(input, output, session) {
  
  
  output$selectEBLL <- renderUI({
    EBLLlist <- arrange(points, pct_ebll_county)
    EBLLlist <- unique(EBLLlist$pct_ebll_county)
    EBLLlist <- c("All",EBLLlist)
    selectInput("EBLL", "Select a EBLL level", as.list(EBLLlist))
  })
  

  points <- eventReactive(input$recalc, {
  
      if(is.null(input$EBLL) || input$EBLL == "All") {
        return(points)
      } else {
        return(filter(points,pct_ebll_county == as.numeric(input$EBLL)))  
      }
      
  }, ignoreNULL = FALSE)
  
  
  
  output$table <- renderDataTable({
   
    points()
    
  })
    

  
  output$mymap <- renderLeaflet({
    
    leaflet() %>%
      addProviderTiles(providers$CartoDB.PositronNoLabels) %>%
      addCircleMarkers(
        data = points(),
        lng = ~long,
        lat = ~lat,
        radius = ~sqrt(pct_ebll_county)/1,
        color = "blue",
        stroke = FALSE,
        fillOpacity = 0.3,
        label = ~id
      )
  })
  
  
})
