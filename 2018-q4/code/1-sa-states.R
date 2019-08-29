# produce dashboard summary data for Southwick dashboard states

library(DBI)
library(dplyr)
library(lubridate)
library(salic)
source("E:/SA/Projects/R-Software/Templates/dashboard-template/code/functions.R")

# parameters
timeframe <- "full-year" # full-year or mid-year
base_yrs <- 2008:2018

# run for each state
run_group <- function(
    cust, lic, sale, yrs = 2008:2018, timeframe = "full-year",
    group = "hunt", lic_types = c("hunt", "combo")
) {
    build_history(cust, lic, sale, yrs, timeframe, lic_types) %>%
        calc_metrics(scaleup_test = 30) %>% 
        format_metrics(timeframe, group)
}

run_state <- function(st, yrs) {
    
    ### 1. Preparation
    # pull data from sqlite
    f <- file.path("E:/SA/Data-production/Data-Dashboards", st, "license.sqlite3")
    con <- dbConnect(RSQLite::SQLite(), f)
    lic <- tbl(con, "lic") %>% 
        select(lic_id, type, duration) %>%
        collect() %>%
        distinct() # at least one state (OR) doesn't have unique lic_ids
    cust <- tbl(con, "cust") %>%
        select(cust_id, sex, birth_year) %>%
        collect()
    sale <- tbl(con, "sale") %>%
        select(cust_id, lic_id, dot, res) %>%
        collect()
    dbDisconnect(con)
    
    sale <- sale %>%
        mutate(dot = ymd(dot), year = year(dot), month = month(dot)) %>%
        filter(year %in% yrs) %>%
        select(-dot)
    
    # some adjustments
    sale <- filter(sale, !is.na(cust_id)) # not sure why, but we have a few of these
    lic <- filter(lic, !is.na(type), type != "other")
    if (st == "MO") lic$duration <- 1 # temporary for checking
    
    # final filtering & checking
    cust <- semi_join(cust, sale, by = "cust_id")
    cust <- mutate(cust, birth_year = ifelse(birth_year < 1900, NA_integer_ , birth_year))
    lic <- semi_join(lic, sale, by = "lic_id") 
    data_check(cust, lic, sale)
    
    ### 2. produce summaries for each permission
    all_sports <- run_group(
        cust, lic, sale, yrs, timeframe, "all_sports", c("hunt", "trap", "fish", "combo")
    )
    if (st == "TN") {
        readr::write_csv(all_sports, paste0("out/", st, ".csv"))
        return(invisible())
    }
    hunt <- run_group(
        cust, lic, sale, yrs, timeframe, "hunt", c("hunt", "trap", "combo")
    )
    fish <- run_group(
        cust, lic, sale, yrs, timeframe, "fish", c("fish", "combo")
    )
    bind_rows(hunt, fish, all_sports) %>%
        readr::write_csv(paste0("out/", st, ".csv"))
}

# these will be updated (if possible) prior to Sep 16th
run_state("IA", 2009:2018) # run with existing data, we just know it's wrong for hunting
run_state("GA", 2010:2016) # old data
run_state("WI", 2008:2015) # old data

# these shouldn't need to change
run_state("OR", base_yrs)
run_state("MO", base_yrs)
run_state("SC", 2009:2018)
run_state("TN", 2009:2018) # only all_sports
run_state("VA", base_yrs)
