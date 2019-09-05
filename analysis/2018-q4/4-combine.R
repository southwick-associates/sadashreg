# stack together all states

library(tidyverse)

source("analysis/reg-aggregate.R")
indir <- file.path(dir, "out-rate")
outfile <- file.path(dir, "dashboard.csv")
# regs <- c("Southeast", "Midwest", "US")

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

# temp, check differences
# old
dashboard_reg <- bind_rows(
    sapply(regs, function(reg) aggregate_region(dashboard, reg, "SUM", "participants")), 
    sapply(regs, function(reg) aggregate_region(dashboard, reg, "SUM", "recruits")),
    sapply(regs, function(reg) aggregate_region(dashboard, reg, "AVG", "churn")),
    sapply(regs, function(reg) aggregate_region(dashboard, reg, "AVG", "rate"))
)
# new
reg <- agg_reg(dashboard)

# compare
format_result <- function(x) {
    filter(x, region == "US", group == "all_sports", metric == "recruits") %>%
        select(metric, region, group, segment, year, category, value) %>%
        arrange(metric, region, group, segment, year, category, value)
}
dashboard_reg <- format_result(dashboard_reg)
reg <- format_result(reg)
all.equal(dashboard_reg, reg)

# inclusion of NE causes differences...not entirely certain why
compare_row <- function(row) {
    print(dashboard_reg[row,])
    print(reg[row,])
}
compare_row(1509)

count(dashboard_reg, region)
dashboard <- bind_rows(
    mutate(dashboard, aggregation = "NONE"), 
    dashboard_reg
)

# Add % Change Metric -----------------------------------------------------

# TODO: we are running into problems here with dashboard_reg
# - clearly something changed with the new function
# - probably just run both functions and compare results

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


# Formatting --------------------------------------------------------------

# stack with existing results
dashboard <- bind_rows(
    mutate(dashboard, value_type = "total"),
    gather(pct_change, value_type, value, pct_change_yr, pct_change_all)
)

# order the columns
dashboard <- dashboard %>% select(
    region, state, quarter, group, metric, segment, year, category, 
    value, aggregation, value_type
)

# check that rows are uniquely identified by dimensions
nrow(dashboard) == nrow(
    distinct(dashboard,region, state, quarter, group, metric, segment, year,  
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

# do some final standardization for tableau
x <- mutate(x, metric = case_when(
    metric == "recruits" ~ "participants - recruited", 
    metric == "rate" ~ "participation rate", 
    TRUE ~ metric
))
x$timeframe <- timeframe

glimpse(dashboard)
count(dashboard, region)
count(dashboard, state)
count(dashboard, metric)
count(dashboard, segment)
count(dashboard, category)
count(dashboard, year)
group_by(dashboard, metric, value_type) %>% summarise(min(value), mean(value), max(value))

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
