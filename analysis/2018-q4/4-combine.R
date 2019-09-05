# stack states & compute regional aggregations & % changes
# outputs a single table to csv

library(tidyverse)

# for development convenience
if (!exists("timeframe")) {
    dir <- "analysis/2018-q4"
    timeframe <- "full-year"
    yrs <- 2008:2018
}

source("analysis/reg-aggregate.R")
indir <- file.path(dir, "out-rate")
outfile <- file.path(dir, "dashboard.csv")
outdir <- file.path(dir, "out-dashboard") # for checking individual states

# Pull Data  -------------------------------------------------------

# pull states into a single table
get_state <- function(f) {
    st <- str_sub(f, end = 2)
    read_csv(file.path(indir, f))
}
infiles <- list.files(indir)
x <- sapply(infiles, get_state, simplify = FALSE) %>% bind_rows()

# check dimensions
count(x, group)
count(x, segment)
count(x, category)
count(x, metric)
count(x, year)

# add regions
dashboard <- left_join(x, region_relate, by = "state")
count(dashboard, region, state)

# Get Regional Aggregations -------------------------------------------------

regs <- c(unique(dashboard$region), "US")

dashboard_reg <- bind_rows(
    agg_region_all(dashboard, regs, "participants", "sum"),
    agg_region_all(dashboard, regs, "recruits", "sum"),
    agg_region_all(dashboard, regs, "churn", "mean"),
    agg_region_all(dashboard, regs, "rate", "mean")
)

# check
count(dashboard_reg, region)
group_by(dashboard_reg, metric) %>% summarise(min(value), mean(value), max(value))
group_by(dashboard, metric) %>% summarise(min(value), mean(value), max(value))

# stack with state results
dashboard <- bind_rows(
    mutate(dashboard, aggregation = "NONE"), 
    dashboard_reg
)

# Final Formatting -----------------------------------------------------------

dashboard <- dashboard %>% mutate(metric = case_when(
    metric == "recruits" ~ "participants - recruited",
    metric == "rate" ~ "participation rate",
    TRUE ~ metric
))

# check that rows are uniquely identified by dimensions
nrow(dashboard) == nrow(
    distinct(dashboard,region, state, timeframe, group, metric, segment, year,  
             category, aggregation)
)

## add res/nonres rows for participation rate
dashboard <- bind_rows(
    dashboard,
    filter(dashboard, segment == "all", metric == "participation rate") %>%
        mutate(segment = "residency", category = "resident"),
    filter(dashboard, segment == "all", metric == "participation rate") %>%
        mutate(segment = "residency", category = "nonresident", value = 0)
)

# Run some Summaries ------------------------------------------------------

glimpse(dashboard)
count(dashboard, region)
count(dashboard, state)
count(dashboard, metric)
count(dashboard, segment)
count(dashboard, category)
count(dashboard, year)
filter(dashboard, state == region) %>% count(region, states_included)

# Write to Individual Files for Visuals -----------------------------------

# individual  files(for checking)
dir.create(outdir, showWarnings = FALSE)
x <- split(dashboard, dashboard$state)

for (i in names(x)) {
    write_csv(x[[i]], file.path(outdir, paste0(i, ".csv")))
}
# source("../dashboard-template/visualize/app-functions.R")
# run_visual(outdir, pct_range = 0.2)

# Write to CSV for Tableau ------------------------------------------------

# TODO - drop this once an updated 9/5 file is sent to Ben
# temporary - add mid-year dummy data
mid <- filter(dashboard, metric != "churn") %>%
    mutate( value = value / 2, timeframe = "mid-year" )
dashboard <- bind_rows(dashboard, mid)
count(dashboard, timeframe)

# stacked
dashboard %>%
    select(region, state, timeframe, group, metric, segment, year, category,
           value, aggregation, states_included) %>%
    write.csv(outfile)
