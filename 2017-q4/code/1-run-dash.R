# Run dashboard results for each Permission

source("2017-q4/code/func.R") # temporary

library(tidyverse)
library(salic)
library(DBI)

firstyr <- 2008
lastyr <- 2017
quarter <- 4
dir <- "2017-q4"
dir_data <- "E:/SA/Data-production/Data-Dashboards"
states <- c("OR", "MO")


# Pull Census Data --------------------------------------------------------

con <- dbConnect(RSQLite::SQLite(), file.path(dir_data, "_Shared/census.sqlite3"))

pop_acs <- tbl(con, "pop_acs") %>%
    filter(state_abbrev %in% states) %>%
    collect() %>%
    # collapse to 7 age categories
    group_by(state_abbrev, year, sex, age) %>%
    summarise(pop = sum(pop)) %>%
    ungroup() %>%
    label_categories() %>%
    rename(agecat = age)

dbDisconnect(con)


# Build Tableau Data -------------------------------------------------------

# for running parameterized by-permission.R
run_dash <- function(state, priv_nm, yrs = firstyr:lastyr) {
    
    # setting local=TRUE seems to do the trick
    # doesn't dump data into global env, and does show warnings
    # probably all I care about is warnings, so I can just sink them to a log.txt file
    source(file.path(dir, "code", "by-permission.R"), local = TRUE)
    
    # rmarkdown::render(
    #     input = file.path(dir, "code", "by-permission.R"),
    #     # output_file = file.path("log", paste0(priv_nm, ".html")),
    #     knit_root_dir = getwd(), quiet = FALSE
    # )
}

state <- "OR"
con <- dbConnect(RSQLite::SQLite(), file.path(dir_data, state, "license.sqlite3"))
cust <- dbGetQuery(con, "SELECT cust_id, sex, birth_year FROM cust")
dbDisconnect(con)
run_dash(state, "hunt")



for (state in states) {
    con <- dbConnect(RSQLite::SQLite(), file.path(dir_data, state, "license.sqlite3"))
    cust <- dbGetQuery(con, "SELECT cust_id, sex, birth_year FROM cust")
    dbDisconnect(con)
    
    run_dash(state, "hunt")
    run_dash(state, "fish")
}


### Whoa, lots of warnings ###

# Everything but MO hunt is catching quite a few warnings
# [VA also seems to have some issues regarding the census population data]

## Need a game plan for what to do with this info ##
# It does seem to be more warnings than is really useful
# since looking at the visuals provides a better indication of problems

## Maybe the visual part is the answer ##
# Producing the trends that would show obvious problems in the final data
# could be a worthwhile reason to save the rds versions
# which "might" make it easier to code up some ggplots


# Stack & Summarize -------------------------------------------------------


