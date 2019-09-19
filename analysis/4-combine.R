# stack states & compute regional aggregations
# outputs as a single table (for tableau) & individual by state (for checking)

library(tidyverse)
library(salic)
library(dashreg)

# needs to be adjusted for time periods
source("analysis/2019-q2/params.R")

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

# drop 2009
x <- filter(x, year >= 2010)
x <- filter(x, !is.na(value)) # drops some missing rate estimates (this is okay)
x <- mutate(x, timeframe = tolower(timeframe))

# check dimensions
count(x, state)
count(x, group)
count(x, segment)
count(x, category)
count(x, metric)
count(x, year)

# add regions
dashboard <- left_join(x, region_relate, by = "state")
count(dashboard, region, state)

# check coverage
group_by(dashboard, metric) %>% summarise(min(value), mean(value), max(value))
count(dashboard, group, region, state, year) %>% 
    spread(year, n, fill = 0) %>%
    data.frame()

# Get Regional Aggregations -------------------------------------------------

regs <- c(unique(dashboard$region), "US")

# for regional: fill-in NE recruits in 2014 based on trend
# - should probably modularize this
if (timeframe == "full-year") {
    df_ne <- filter(dashboard, state == "NE")
    df_ne <- df_ne %>% bind_rows(
        filter(df_ne, metric == "recruits", year == 2015) %>% mutate(year = 2014),
        filter(df_ne, metric == "churn", year == 2011) %>% mutate(year = 2010)
    )
    for (i in c("hunt", "fish", "all_sports")) {
        mod <- est_lm(df_ne, 2015:2018, "recruits", i, unique(df_ne$category))
        df_ne <- predict_lm(df_ne, mod, 2014, "recruits", i, unique(df_ne$category))
        
        mod <- est_lm(df_ne, 2011:2018, "churn", i, unique(df_ne$category))
        df_ne <- predict_lm(df_ne, mod, 2010, "churn", i, unique(df_ne$category))
    }
    dashboard2 <- filter(dashboard, state != "NE") %>% bind_rows(df_ne)
} else {
    dashboard2 <- dashboard
}

# get regional estimates
dashboard_reg <- bind_rows(
    agg_region_all(dashboard2, regs, "participants", "sum"),
    agg_region_all(dashboard2, regs, "recruits", "sum"),
    if (timeframe == "full-year") agg_region_all(dashboard2, regs, "churn", "mean"),
    agg_region_all(dashboard2, regs, "rate", "mean")
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
