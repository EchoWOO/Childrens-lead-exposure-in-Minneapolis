
library(RPostgreSQL)
library(sf)
library(postGIStools)
library(tidyverse)
library(viridis)
library(classInt)
library(RColorBrewer)
library(leaflet)
library(rgdal)
library(htmlwidgets)
library(ggmap)
library(tidycensus)


myTheme <- function() {
  theme_void() + 
    theme(
      text = element_text(size = 7),
      plot.title = element_text(size = 14, color = "#eeeeee", hjust = 0, vjust = 0, face = "bold"), 
      plot.subtitle = element_text(size = 12, color = "#cccccc", hjust = 0, vjust = 0),
      axis.ticks = element_blank(),
      panel.grid.major = element_line(colour = "#000000"),
      panel.background = element_rect(fill = "#000000"),
      plot.background = element_rect(fill = "#000000"),
      legend.direction = "vertical", 
      legend.position = "right",
      plot.margin = margin(1, 1, 1, 1, 'cm'),
      legend.key.height = unit(1, "cm"), legend.key.width = unit(0.4, "cm"),
      legend.title = element_text(size = 12, color = "#eeeeee", hjust = 0, vjust = 0, face = "bold"),
      legend.text = element_text(size = 8, color = "#cccccc", hjust = 0, vjust = 0),
      legend.key.size = unit(5,"line")
    ) 
}

drv <- dbDriver("PostgreSQL")
con <- dbConnect(drv, dbname = "Assign2",
                 host = "127.0.0.1", port = 5432,
                 user = "postgres", password = 'xx6161')

############Important note: How to get rid of warnings in postgres
###Sys.setlocale("LC_ALL", "English")

Minchildlead <- readOGR("childhoodLeadTract.json") %>%
  st_as_sf()

Sys.getenv("CENSUS_API_KEY")

# get 2016 tract level data
Tract16 <- 
  get_acs(geography = "tract", variables = c("B01001_001E","B01001_003E","B01001_004E","B01001_027E",
                                                   "B01001_028E","B09018_002E","B19013_001E"), 
          endyear = 2016, state=27, county=053, geometry=F) %>%
  dplyr::select(variable,estimate,GEOID) %>%
  as.data.frame() %>%
  spread(variable,estimate) %>%
  rename(TotalPopulation=B01001_001,
         TotalMaleUnder5=B01001_003,
         TotalMale5to9=B01001_004,
         TotalFemaleUnder5=B01001_027,
         TotalFemale5to9=B01001_028,
         TotalOwnchild=B09018_002,
         MEDINC12=B19013_001)

# Read the GeoID for all the tracts
TractID <- st_read("C:/Users/dell/Box Sync/MUSA_Practicum/Shapefiles/CensusTracts_2016_clip_proj.shp") %>%
  dplyr::select("STATEFP", "COUNTYFP", "GEOID") %>%
  as.data.frame() %>%
  dplyr::select(-geometry)

# Select the tracts of Minneapolis
Tract16MN <- left_join(TractID, Tract16, by=c("GEOID" = "GEOID")) %>%
  dplyr::select(-STATEFP,-COUNTYFP)%>% 
  mutate(Totalchild = (TotalMaleUnder5 + TotalMale5to9 + TotalFemaleUnder5 + TotalFemale5to9))

# Join the census tracts data with the lead data
minchildlead$tract_id <- as.character(Minchildlead$tract_id)
tract16withLD <- right_join(Minchildlead, Tract16MN, by=c("tract_id" = "GEOID")) %>%
  dplyr::select(-TotalMaleUnder5,-TotalMale5to9,-TotalFemaleUnder5,-TotalFemale5to9,-pct_ebll_cat,-primary_county,-Num_EBLLs_tract) %>%
  dplyr::rename(id = tract_id) %>%
  st_as_sf()

# name to lower case
names(tract16withld) <- tolower(names(tract16withld))

# transform to simple feature
tract16withld <- st_as_sf(tract16withld)

# Create centroids for each 
tract16ct <- st_centroid(tract16withld)%>%
  st_as_sf()

#write the minneapolis children's lead polygon data to database
st_write_db(con, tract16withld, "tract16withld",drop = TRUE)
dbGetQuery(con, "CREATE INDEX tract16withld_gix ON tract16withld USING GIST (wkb_geometry)")

#write the minneapolis children's lead center data to database
st_write_db(con, tract16ct, "tract16ct",drop = TRUE)
dbGetQuery(con, "CREATE INDEX tract16ct_gix ON tract16ct USING GIST (wkb_geometry)")

# See all the tables in one database
dbGetQuery(con, "SELECT * FROM geometry_columns")

# export table into SF object
tracts = st_read_db(con, query = "SELECT * FROM tract16withld", geom_column = 'wkb_geometry')

points = st_read_db(con, query = "SELECT * FROM tract16ct", geom_column = 'wkb_geometry')
