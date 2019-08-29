#' ---
#' title: "Prepare state-processed data"
#' output: 
#'     html_document:
#'         code_folding: hide
#' ---

# TODO: Need to do some work on the state-supplied data process
# - put together checks & summaries for data validation
# - probably come up with template code for which you can use rmarkdown::render()


library(tidyverse)
library(readxl)
library(DBI)
library(salic)
source("2018-q4/code/func.R")

state <- "MA"
yrs <- 2009:2018
state_file <- "E:/SA/Projects/Data-Dashboards/MA/Dashboard_State_Prepared_Data_MA_SA_KM.xlsx"
data_dir <- "E:/SA/Data-production/Data-Dashboards"
out_dir <- "2018-q4/data"


# Get Census Data ------------------------------------------------------
# note: this isn't actually permission-specific, but it runs very quickly

con <- dbConnect(RSQLite::SQLite(), file.path(data_dir, "_Shared/census.sqlite3"))
county_fips <- tbl(con, "county_fips") %>% 
    filter(state_abbrev == state) %>%
    select(county_fips, county = county_name) %>%
    collect()
pop_county <- tbl(con, "pop_acs") %>%
    select(-state) %>% # needed for the next line (abbrev filter) to run correctly
    filter(state_abbrev == state, year %in% yrs) %>%
    collect()
dbDisconnect(con)

pop_county <- pop_county %>%
    aggregate_pop() %>% # collapse to 7 age categories
    label_categories() %>% # convert numeric categories to factor
    left_join(county_fips, by = "county_fips") %>%
    extrapolate_pop(yrs) # filling in missing population data (if needed)

# age filter
pop_county <- filter(pop_county, age != "0-17", age != "65+")

# population summary as a validation step (easily checked using google)
group_by(pop_county, year) %>% 
    summarise(sum(pop)) %>% 
    knitr::kable(caption = "State Population", format.args = list(big.mark = ","))


# Estimate Part. Rate -----------------------------------------------------

dat <- read_excel(state_file) %>%
    mutate(metric = ifelse(metric == "recruits", "participants - recruited", metric),
           quarter = 4, state = "MA") %>%
    select(-timeframe) %>%
    distinct() # drops some duplicates in import data

pop <- list(
    est_pop(pop_county, "sex") %>% rename(category = sex) %>% mutate(segment = "gender"),
    est_pop(pop_county, "age") %>% rename(category = age) %>% mutate(segment = "age"),
    est_pop(pop_county, "tot") %>% mutate(segment = "All", category = "All")
) %>% bind_rows()

rate <- dat %>%
    filter(metric == "participants") %>%
    inner_join(pop) %>%
    mutate(value = value / pop, metric = "participation rate") %>%
    select(-pop)

# also include a residency breakout for rate
rate_res <- filter(rate, segment == "All") %>% 
    mutate(segment = "Residency", category = "Resident")
rate <- bind_rows( rate, rate_res, mutate(rate_res, category = "Nonresident", value = 0) )

dat <- bind_rows(dat, rate)


# Fix churn issue ---------------------------------------------------------
# It looks like a few churn results were included on a 100 point scale

out_tbl <- dat %>% mutate(
    value = ifelse(metric == "churn" & value > 1, value / 100, value)
)

## For nat/reg dashboard, converting rates to 100 point scale
out_tbl <- out_tbl %>% mutate(
    value = ifelse(metric %in% c("churn", "participation rate"), value * 100, value)
)
glimpse(out_tbl)



# Save ----------------------------------------------------------------------

## save out_tbl results of selected permission
dir.create(out_dir, showWarnings = FALSE)
saveRDS(out_tbl, file.path(out_dir, paste0(state, ".rds")))

## check
# Row Counts
# - churn will likely be 10% smaller (except for county)
# - recruited will likely be around 50% smaller (5 yrs can't be counted)
# - month only applies to participants
count(out_tbl, group, metric, segment) %>% 
    spread(segment, n) %>%
    knitr::kable(caption = "Row counts by metric-segment")

# Summary values - particularly looking for unexpected NAs
options(scipen = 999)
group_by(out_tbl, group, metric, segment) %>%
    summarise(val = mean(value)) %>%
    spread(segment, val) %>%
    knitr::kable(caption = "Mean values by metric-segment", 
                 digits = 2, format.args = list(big.mark = ","))

sessionInfo()
