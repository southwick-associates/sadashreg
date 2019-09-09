# stack states & compute regional aggregations
# outputs as a single table (for tableau) & individual by state (for checking)

library(tidyverse)

# for development convenience
if (!exists("timeframe")) {
    dir <- "analysis/2019-q2"
    timeframe <- "mid-year"
    yrs <- 2009:2019
}

source("analysis/R/reg-aggregate.R")
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
x <- sapply(infiles, get_state, simplify = FALSE) %>% 
    bind_rows() %>%
    filter(year %in% yrs)

# check dimensions
count(x, group)
count(x, segment)
count(x, category)
count(x, metric)
count(x, year)

# add regions
dashboard <- left_join(x, region_relate, by = "state")
count(dashboard, region, state)

# check coverage
count(dashboard, group, region, state, year) %>% 
    spread(year, n, fill = 0) %>%
    data.frame()

# Get Regional Aggregations -------------------------------------------------

regs <- c(unique(dashboard$region), "US")

dashboard_reg <- bind_rows(
    agg_region_all(dashboard, regs, "participants", "sum"),
    agg_region_all(dashboard, regs, "recruits", "sum"),
    if (timeframe == "full-year") agg_region_all(dashboard, regs, "churn", "mean"),
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

# check that rows are uniquely identified by dimensions - should be TRUE
nrow(dashboard) == nrow(
    distinct(dashboard,region, state, timeframe, group, metric, segment, year,  
             category, aggregation)
)

# add res/nonres rows for participation rate
dashboard <- bind_rows(
    dashboard,
    filter(dashboard, segment == "all", metric == "participation rate") %>%
        mutate(segment = "residency", category = "resident"),
    filter(dashboard, segment == "all", metric == "participation rate") %>%
        mutate(segment = "residency", category = "nonresident", value = 0)
)

# run some summaries
glimpse(dashboard)
count(dashboard, region)
count(dashboard, state)
count(dashboard, metric)
count(dashboard, segment)
count(dashboard, category)
count(dashboard, year)
filter(dashboard, state == region) %>% count(region, states_included)

# Write to CSV -------------------------------------------------------

# individual files (for checking)
dir.create(outdir, showWarnings = FALSE)
x <- split(dashboard, dashboard$state)

for (i in names(x)) {
    write_csv(x[[i]], file.path(outdir, paste0(i, ".csv")))
}

# one file (for tableau input)
dashboard %>%
    select(region, state, timeframe, group, metric, segment, year, category,
           value, aggregation, states_included) %>%
    write.csv(outfile)
