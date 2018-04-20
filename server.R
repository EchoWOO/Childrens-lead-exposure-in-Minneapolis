
library(shiny)
library(maps)
library(dplyr)
library(leaflet)

shinyServer(function(input, output, session) {
  
  tracts = st_read_db(con, query = "SELECT * FROM tract16withld", geom_column = 'wkb_geometry')
  
  # points = st_read_db(con, query = "SELECT * FROM tract16ct", geom_column = 'wkb_geometry')
  
  #bigtracts <- filter(world.cities, pop > 1000000)
  
  # tracts$pct_ebll_county <- gsub("%","", tracts$pct_ebll_county)
  # 
  # tracts$pct_ebll_county <- as.numeric(tracts$pct_ebll_county)
  
  # points$pct_ebll_county <- gsub("%","", points$pct_ebll_county)
  # 
  # points$pct_ebll_county <- as.numeric(points$pct_ebll_county)
  
  
  output$selectEBLL <- renderUI({
    EBLLlist <- arrange(tracts, per_eblls_label)
    EBLLlist <- unique(EBLLlist$per_eblls_label)
    EBLLlist <- c("All",EBLLlist)
    selectInput("EBLL", "Select a EBLL level", as.list(EBLLlist))
  })
  
  
  selecttracts <- eventReactive(input$recalc, {
    
    if(is.null(input$EBLL) || input$EBLL == "All") {
      return(tracts)
    } else {
      return(filter(tracts,per_eblls_label == as.numeric(input$EBLL)))  
    }
    
  }, ignoreNULL = FALSE)
  
  
  
  output$table <- renderDataTable({
    
    selecttracts()
    
    
  })
  
  
  
  output$mymap <- renderLeaflet({
    
    leaflet() %>%
      addProviderTiles(providers$CartoDB.PositronNoLabels) %>%
      addPolygons( data = selecttracts(),
                   # important () to use the interactive data,
                   fillColor = "blue",
                   weight = 0.8,
                   opacity = 0.6,
                   smoothFactor = 0.1,
                   color = "white",
                   fillOpacity = 0.8)
  })
  
  
})