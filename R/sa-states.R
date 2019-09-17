# functions to produce dashboard summary data for Southwick dashboard states

# TODO: 
# - determine how dashboard-template code will (or won't) be used
# - might be able to use sadash instead

# TODO: global functions to deal with:
# - build_history
# - calc_metrics
# - format_metrics >> probably just use sadash

# library(DBI)
# library(tidyverse)
# library(lubridate)
# library(salic)
# source("E:/SA/Projects/R-Software/Templates/dashboard-template/code/functions.R")

# run a given permission (using functions from dashboard-template)
run_group <- function(
    cust, lic, sale, yrs = 2008:2018, timeframe = "full-year",
    group = "hunt", lic_types = c("hunt", "combo")
) {
    build_history(cust, lic, sale, yrs, timeframe, lic_types) %>%
        calc_metrics(scaleup_test = 30) %>% 
        format_metrics(timeframe, group)
}

# run 3 permissions for select state in select time period
run_state <- function(
    st, yrs, timeframe, outdir, groups = c("hunt", "fish", "all_sports"), 
    output_csv = TRUE
) {
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
    
    # make sure to use sale year
    sale <- sale %>%
        mutate(dot = lubridate::ymd(dot), year = lubridate::year(dot), 
               month = lubridate::month(dot)) %>%
        filter(year %in% yrs) %>%
        select(-dot)
    
    # some adjustments & data checking
    sale <- filter(sale, !is.na(cust_id)) # not sure why, but we have a few of these
    lic <- filter(lic, !is.na(type), type != "other")
    cust <- mutate(cust, birth_year = ifelse(birth_year < 1900, NA_integer_ , birth_year))
    data_check(cust, lic, sale) %>% print()
    
    ### 2. produce summaries for each permission
    run_group2 <- function(grp, lic_types) {
        if (!grp %in% groups) return(invisible())
        run_group(cust, lic, sale, yrs, timeframe, grp, lic_types)
    }
    out <- bind_rows(
        run_group2("hunt", c("hunt", "trap", "combo")),
        run_group2("fish", c("fish", "combo")),
        run_group2("all_sports", c("hunt", "trap", "fish", "combo"))
    ) %>%
        mutate(year = as.integer(year))
    if (output_csv) {
        dir.create(outdir, showWarnings = FALSE)
        write.csv(out, file = file.path(outdir, paste0(st, ".csv")), 
                  row.names = FALSE)
    }
    out
}
