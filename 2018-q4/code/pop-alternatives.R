# seeing if tidycensus provides an alternative

library(tidycensus)

options(tigris_use_cache = TRUE) # optional - to cache the Census shapefile

get_acs(
    geography = "county",  
    variables = "B01001_001", year = 2015, state = "OR"
)
