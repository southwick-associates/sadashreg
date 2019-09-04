# Pulling state-specific data prior to permission-specific Tableau Production

# Keeping this on hand for state-level template work to be done later

library(tidyverse)
library(salic)
library(DBI)

source("2017-q4/code/func.R") # temporary


# Parameters --------------------------------------------------------------
# Intended to be commented out for production runs

firstyr <- 2008
lastyr <- 2017
quarter <- 4
dir <- "2017-q4"
datadir <- "E:/SA/Data-production/Data-Dashboards"

state <- "MO"
yrs <- firstyr:lastyr


# Pull Data ---------------------------------------------------------------

# 1. Census Population Data
con <- dbConnect(RSQLite::SQLite(), file.path(datadir, "_Shared/census.sqlite3"))
counties <- dbGetQuery(con, paste0("SELECT * FROM county_fips WHERE state_abbrev ='", state, "'")) %>%
    rename(county = county_name)

pop_county <- dbGetQuery(con, paste0("SELECT * FROM pop_acs WHERE state_abbrev ='", state, "'")) %>%
    aggregate_pop() %>%       # collapse to 7 age categories
    extrapolate_pop(yrs) %>%  # extrapolate where census lags behind current year (simple avg % change)
    label_categories() %>%    # convert numeric categories to factors
    rename(agecat = age) %>%
    left_join(counties, by = "county_fips")
dbDisconnect(con)

# 2. Customer Data
con <- dbConnect(RSQLite::SQLite(), file.path(datadir, state, "license.sqlite3"))
cust <- dbGetQuery(con, "SELECT cust_id, sex, birth_year, county_fips FROM cust") %>%
    left_join(counties, by = "county_fips")
dbDisconnect(con)
