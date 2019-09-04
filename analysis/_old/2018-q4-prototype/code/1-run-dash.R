# Run dashboard results for each Permission

library(tidyverse)
library(salic)
library(DBI)
source("2018-q4/code/func.R")

yrs <- 2009:2018
qtr <- 2
data_dir <- "E:/SA/Data-production/Data-Dashboards"
out_dir <- "2018-q4/data"
script_dir <- "2018-q4/code"
states <- c("OR", "MO", "SC", "VA")
regions <- c("Northwest", "Midwest", "Southeast", "Southeast")


# Build Tableau Data -------------------------------------------------------

# for running parameterized by-permission.R
run_dash <- function(state, priv_nm) {
    params_passed <- TRUE # to disable default script parameters
    dir.create(file.path(script_dir, "log"), showWarnings = FALSE)
    rmarkdown::render(
        input = file.path(script_dir, "dash-permission.R"),
        output_file = file.path("log", paste0(priv_nm, state, ".html")),
        knit_root_dir = getwd(), quiet = FALSE
    )
}

state <- "OR"
con <- dbConnect(RSQLite::SQLite(), file.path(data_dir, state, "license.sqlite3"))
cust <- tbl(con, "cust") %>% select(cust_id, sex, birth_year, county_fips) %>% collect()
dbDisconnect(con)

run_dash(state, "hunt")
run_dash(state, "fish")
run_dash(state, "sports")

qtr <- 4
run_dash(state, "hunt")
run_dash(state, "fish")
run_dash(state, "sports")


for (state in states) {
    con <- dbConnect(RSQLite::SQLite(), file.path(data_dir, state, "license.sqlite3"))
    cust <- tbl(con, "cust") %>% select(cust_id, sex, birth_year, county_fips) %>% collect()
    dbDisconnect(con)
    
    run_dash(state, "hunt")
    run_dash(state, "fish")
    if (state == "OR") run_dash(state, "sports") else run_dash(state, "all_sports")
}


# Stack & Nat/Reg Processing ------------------------------------------------

states <- c(states, "MA")
regions <- c(regions, "Northeast")
reg_relate <- data.frame(state = states, region = regions, stringsAsFactors = FALSE)

dashout <- out_dir %>%
    list.files(full.names = T) %>%
    lapply(readRDS) %>%
    bind_rows() %>%
    mutate(group = ifelse(group == "sports", "all_sports", group)) %>%
    left_join(reg_relate, by = "state")

# not including MA at this point
dashout <- filter(dashout, state != "MA")

## Checking MA (temp)

# it looks like MA data is incomplete....
# I guess I'll take a closer look
# there are goddam dups in here....but not quite exact dups...
# count(dashout, state, year) %>% spread(state, n)
# 
# filter(dashout, state == "MA", year %in% 2016:2017) %>%
#     filter(segment == "All") %>%
#     View()
# 
# filter(dashout, state == "MA", year == 2017, group == "fish") %>% View()
# filter(dashout, state == "MA", year == 2017) %>% spread(group, value) %>% View()

# convert churn/rate to point values
# dashout <- dashout %>%
#     mutate(value = ifelse(metric %in% c("churn", "participation rate"), value * 100, value))

## Build regional averages
agg_region <- function(x, ag = "SUM", metrics = c("participants", "participants - recruited"),
                       nat = FALSE) {
    grp <- c("region", "quarter", "group", "metric", "segment", "year", "category")
    if (nat) grp <- setdiff(grp, "region")
    func <- if (ag == "SUM") "sum" else "mean"
    
    x <- x %>%
        filter(metric %in% metrics) %>%
        group_by_at(grp) %>%
        summarise_at("value", func) %>%
        ungroup() %>%
        mutate(aggregation = ag)
    if (nat) x$region <- "US"
    x$state <- x$region
    x
}
reg <- bind_rows(
    agg_region(dashout, "SUM", c("participants", "participants - recruited")),
    agg_region(dashout, "SUM", c("participants", "participants - recruited"), TRUE),
    agg_region(dashout, "AVG", c("churn", "participation rate")),
    agg_region(dashout, "AVG", c("churn", "participation rate"), TRUE)
)
# note that the aggregations won't make sense when years are missing in some states
# not sure how we intend to deal with that (maybe only inlclude states with full sets in aggregations)
count(reg, region)
dashout <- bind_rows(
    mutate(dashout, aggregation = "NONE"), 
    reg
)

## Add %change metric
pct_change <- dashout %>%
    arrange(region, state, metric, segment, category, year) %>%
    group_by(region, state, metric, segment, category) %>%
    mutate(
        pct_change_yr = (value - lag(value)) / value,
        pct_change_yr = ifelse(is.na(pct_change_yr), 0, pct_change_yr),
        pct_change_all = cumsum(pct_change_yr)
    ) %>% ungroup()
pct_change <- pct_change %>%
    select(-value) %>%
    gather(value_type, value, pct_change_yr, pct_change_all)
dashout <- dashout %>%
    mutate(value_type = "total") %>%
    bind_rows(pct_change) 
glimpse(dashout)


# Save & Summarize ----------------------------------------------------------

dashout %>%
    select(region, state:value, aggregation, value_type) %>%
    write.csv("2018-q4/out/dash-out-reg_2019-05-21.csv")
