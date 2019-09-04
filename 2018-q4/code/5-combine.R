# stack together all states

# visualize interactively
# source("../dashboard-template/visualize/app-functions.R")
# run_visual("2018-q4/out-rate", pct_range = 0.3)

library(tidyverse)
source("R/")
indir <- "2018-q4/out-rate"
outfile <- "out/full-year2018.csv"

# Pull Data & Check -------------------------------------------------------

# pull all results
get_state <- function(f) {
    st <- str_sub(f, end = 2)
    read_csv(file.path(indir, f)) %>%
        mutate(state = st)
}
infiles <- list.files(indir)
x <- sapply(infiles, get_state, simplify = FALSE) %>% bind_rows()

x <- x %>% mutate(
    metric = case_when( 
        metric == "recruits" ~ "participants - recruited", 
        metric == "rate" ~ "participation rate", 
        TRUE ~ metric
    ),
    quarter = ifelse(timeframe == "full-year", 4, 2)
) %>%
    select(-timeframe)

# check naming
count(x, group)
count(x, segment)
count(x, category)
count(x, metric)
count(x, year)

# add regions
regions <- tibble::tribble(
    ~state, ~region,
    "FL", "Southeast",
    "GA", "Southeast",
    "IA", "Midwest",
    "MO", "Midwest",
    "NE", "Midwest",
    "OR", "Northwest",
    "SC", "Southeast",
    "TN", "Southeast",
    "VA", "Southeast",
    "WI", "Midwest"
)
dashout <- left_join(x, regions)
count(dashout, state, region)
glimpse(dashout)

# tmp check previous data
# read_csv("2018-q4-prototype/out/dash-out-reg_2019-05-21.csv")

# Get Averages ------------------------------------------------------------

# TODO: make sure these are well-tested
# - probably will want 2 functions: get_region(), get_pct_change()
# - maybe place in R/tableau_format.R

## build regional averages
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
count(reg, region)
dashout <- bind_rows(
    mutate(dashout, aggregation = "NONE"), 
    reg
)

## Add %change metric
pct_change <- dashout %>%
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

# stack with existing results
dashout <- bind_rows(
    mutate(dashout, value_type = "total"),
    gather(pct_change, value_type, value, pct_change_yr, pct_change_all)
)

# order the columns
dashout <- dashout %>% select(
    region, state, quarter, group, metric, segment, year, category, 
    value, aggregation, value_type
)

# check that rows are uniquely identified by dimensions
nrow(dashout) == nrow(
    distinct(dashout,region, state, quarter, group, metric, segment, year,  
             category, aggregation, value_type)
)

## add res/nonres rows for participation rate
dashout <- bind_rows(
    dashout,
    filter(dashout, segment == "all", metric == "participation rate") %>%
        mutate(segment = "residency", category = "resident"),
    filter(dashout, segment == "all", metric == "participation rate") %>%
        mutate(segment = "residency", category = "nonresident", value = 0)
)

glimpse(dashout)
count(dashout, region)
count(dashout, state)
count(dashout, metric)
count(dashout, segment)
count(dashout, category)
count(dashout, year)

# Write to CSV -------------------------------------------------------------

# individual  files(for checking)
outdir <- str_remove(outfile, ".csv")
dir.create(outdir, showWarnings = FALSE)
x <- split(dashout, dashout$state)

for (i in names(x)) {
    y <- split(x[[i]], x[[i]]$value_type)
    for (j in names(y)) write_csv(y[[j]], file.path(outdir, paste0(i, "-", j, ".csv")))
}
# source("../dashboard-template/visualize/app-functions.R")
# run_visual(outdir, pct_range = 0.2)

## temporary - include mock mid-year data
dashout <- rename(dashout, timeframe = quarter) %>% mutate(timeframe = "full-year")
mid <- filter(dashout, metric != "churn") %>%
    mutate(value = ifelse(value_type == "total", value / 2, value))
dashout <- bind_rows(dashout, mid)

dashout %>% 
    group_by(metric, value_type, timeframe) %>%
    summarise(min(value), mean(value), max(value))

# stacked
dashout %>%
    select(region, state, timeframe, group, metric, segment, year, category,
           value, aggregation, value_type) %>%
    write.csv(outfile)
