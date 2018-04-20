
library(shiny)
library(maps)
library(dplyr)
library(leaflet)

shinyServer(function(input, output, session) {
  
  drv <- dbDriver("PostgreSQL")
  
  con <- dbConnect(drv, dbname = "Assign2",
                   host = "127.0.0.1", port = 5432,
                   user = "postgres", password = 'xx6161')
  
  tracts = st_read_db(con, query = "SELECT * FROM tract16withld", geom_column = 'wkb_geometry')
  
  pal_blue11 = c("#d8f2ed",
                 "#bfded8", "#a9ccc6", "#93bab4", "#7ea8a2",
                 "#6b9993", "#588782", "#477872", "#376b66", 
                 "#265c56", "#154f4a")
  
  
  paletteContinuousC <- colorNumeric(palette = pal_blue11, domain = tracts$per_eblls_label)

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
                   fillColor = ~paletteContinuousC(per_eblls_label),
                   weight = 0.8,
                   opacity = 0.6,
                   smoothFactor = 0.1,
                   color = "white",
                   fillOpacity = 0.8,
                   highlight = highlightOptions(
                     fillColor = "yellow",
                     fillOpacity = 0.8,
                     weight = 2,
                     bringToFront = TRUE),
                    popup = paste0("<strong>TractID: </strong>",
                                   selecttracts()$id,
                                   "<br/><strong>Percent of children with EBLL: </strong>",
                                   selecttracts()$per_eblls_label,
                                   "<br/><strong>Children tested: </strong>",
                                   selecttracts()$tested,
                                   "<br/><strong>Percent of children with EBLL in county: </strong>",
                                   selecttracts()$pct_ebll_county,
                                   "<br/><strong>Percent EBLLs compared to Minnesota: </strong>",
                                   selecttracts()$pct_ebll_cat_label,
                                   "<br/><strong>Total Population in Tract: </strong>",
                                   selecttracts()$TotalPopulation,
                                   "<br/><strong>Total Number of Households with Children: </strong>",
                                   selecttracts()$Totalchild,
                                   "<br/><strong>Median House Income: </strong>",
                                   selecttracts()$MEDINC12)
                   )
  })
  
  
})