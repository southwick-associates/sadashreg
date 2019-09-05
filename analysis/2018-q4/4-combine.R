# stack states & compute regional aggregations & % changes
# outputs a single table to csv

library(tidyverse)

source("analysis/reg-aggregate.R")
indir <- file.path(dir, "out-rate")
outfile <- file.path(dir, "dashboard.csv")

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

# Add % Change Metric -----------------------------------------------------

pct_change <- dashboard %>%
    arrange(group, region, state, metric, segment, category, year) %>%
    group_by(group, region, state, metric, segment, category) %>%
    mutate(
        pct_change_yr = (value - lag(value)) / lag(value),
        pct_change_yr = ifelse(lag(value) == 0, 0, pct_change_yr),
        pct_change_yr = ifelse(is.na(pct_change_yr), 0, pct_change_yr),
        pct_change_all = cumsum(pct_change_yr)
    ) %>% 
    ungroup() %>%
    select(-value)

# check
summary(pct_change$pct_change_yr)
summary(pct_change$pct_change_all)

# stack with point values
dashboard <- bind_rows(
    mutate(dashboard, value_type = "total"),
    gather(pct_change, value_type, value, pct_change_yr, pct_change_all)
)

# Final Formatting -----------------------------------------------------------

dashboard <- dashboard %>% 
    mutate(metric = case_when(
        metric == "recruits" ~ "participants - recruited",
        metric == "rate" ~ "participation rate",
        TRUE ~ metric
    )) %>%
    select(
        region, state, timeframe, group, metric, segment, year, category, 
        value, aggregation, value_type, states_included
    )

# check that rows are uniquely identified by dimensions
nrow(dashboard) == nrow(
    distinct(dashboard,region, state, timeframe, group, metric, segment, year,  
             category, aggregation, value_type)
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
group_by(dashboard, metric, value_type) %>% 
    summarise(min(value), mean(value), max(value))

# Write to Individual Files for Visuals -----------------------------------

# individual  files(for checking)
outdir <- str_remove(outfile, ".csv")
dir.create(outdir, showWarnings = FALSE)
x <- split(dashboard, dashboard$state)

for (i in names(x)) {
    y <- split(x[[i]], x[[i]]$value_type)
    for (j in names(y)) write_csv(y[[j]], file.path(outdir, paste0(i, "-", j, ".csv")))
}
# source("../dashboard-template/visualize/app-functions.R")
# run_visual(outdir, pct_range = 0.2)

# Write to CSV for Tableau ------------------------------------------------

# stacked
dashboard %>%
    select(region, state, timeframe, group, metric, segment, year, category,
           value, aggregation, value_type) %>%
    write.csv(outfile)
