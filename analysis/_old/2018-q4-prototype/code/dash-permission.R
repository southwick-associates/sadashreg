#' ---
#' title: "Run by-permission Tableau Production for annual views"
#' output: 
#'     html_document:
#'         code_folding: hide
#' ---

library(tidyverse)
library(DBI)
library(salic)
source("2018-q4/code/func.R")


# Testing ------------------------------------------------------------------

# This will be suppressed in production runs: via run_dash()
# (i.e., params_passed variable should only exist if script is sourced from a function call)
if (!exists("params_passed")) {
    
    state <- "SC"
    qtr <- 2 # quarter to be estimated
    yrs <- 2009:2018
    data_dir <- "E:/SA/Data-production/Data-Dashboards"
    out_dir <- "2018-q4/data"
    priv_nm <- "hunt" # (fish, hunt, all_sports) or (deer, trout, etc.)
    
    # pull customer data
    con <- dbConnect(RSQLite::SQLite(), file.path(data_dir, state, "license.sqlite3"))
    cust <- tbl(con, "cust") %>% select(cust_id, sex, birth_year, county_fips) %>% collect()
    dbDisconnect(con)
}


# Get Census Data ------------------------------------------------------
# note: this isn't actually permission-specific, but it runs very quickly

con <- dbConnect(RSQLite::SQLite(), file.path(data_dir, "_Shared/census.sqlite3"))

# don't actually need county-level for nat/reg, but carrying over code from state dashboards
pop_county <- tbl(con, "pop_acs") %>%
    select(-state) %>% # needed for the next line (abbrev filter) to run correctly
    filter(state_abbrev == state, year %in% yrs) %>%
    collect()
dbDisconnect(con)

pop_county <- pop_county %>%
    aggregate_pop() %>% # collapse to 7 age categories
    label_categories() %>% # convert numeric categories to factor
    extrapolate_pop(yrs) # filling in missing population data (if needed)

# population summary as a validation step (easily checked using google)
group_by(pop_county, year) %>% 
    summarise(sum(pop)) %>% 
    knitr::kable(caption = "State Population", format.args = list(big.mark = ","))


# Get Production Data ----------------------------------------------------
# Note: If subtypes are present, will need additional code (see VA 2018 Q4)

## 1. Permission license history Data
con <- dbConnect(RSQLite::SQLite(), file.path(data_dir, state, "history.sqlite3"))
priv <- tbl(con, priv_nm) %>%
    select(cust_id, year, res, lapse, R3) %>%
    filter(year %in% yrs) %>%
    collect()
priv <- priv %>%
    left_join(cust, by = "cust_id") %>%
    label_categories() %>%
    recode_agecat() %>%
    select(cust_id, year, res, lapse, R3, sex, age = agecat)
dbDisconnect(con)

## 2. Sales: for identifying quarters
con <- dbConnect(RSQLite::SQLite(), file.path(data_dir, state, "license.sqlite3"))
lic_slct <- tbl(con, "permission") %>% filter(permission == priv_nm) %>% collect()

sale <- tbl(con, "sale") %>%
    filter(year %in% yrs, lic_id %in% lic_slct$lic_id) %>%
    select(cust_id, year, month) %>% 
    collect()

sale <- mutate(sale, quarter = case_when(
    month <= 3 ~ 1,
    month %in% 4:6 ~ 2,
    month %in% 7:9 ~ 3,
    month >= 10 ~ 4
))
dbDisconnect(con)

## 3. Apply Age Filter (for nat/reg we need to exclude youths and seniors)
# TODO: In the future, might need a function if we need special treatment for edge effects
priv <- filter(priv, age != "0-17", age != "65+")
pop_county <- filter(pop_county, age != "0-17", age != "65+")


# Estimate ----------------------------------------------------------------

### A. Preparation

if (qtr != 4) {
    # Filter by cumulative quarter (e.g., quarter 4 includes 1-4)
    sale <- filter(sale, quarter <= qtr)
    priv <- select(priv, -lapse) %>%
        semi_join(sale, by = c("cust_id", "year"))
}

### B. Estimation
segs <- c("tot", "res", "sex", "age")

## 1. Participants
part <- sapply(segs[1:4], function(i) est_part(priv, i), simplify = F)
part <- lapply(part, function(x) scaleup_part(x, part$tot))

# Participants by residency (for rates)
priv_res <- filter(priv, res == "Resident")
tot_res <- filter(part[["res"]], res == "Resident") # for scaling
part_res <- sapply(segs[-2], function(i) est_part(priv_res, i), simplify = F)
part_res <- lapply(part_res, function(x) scaleup_part(x, tot_res))

## 2. Participation rate
pop <- sapply(segs[-2], function(i) est_pop(pop_county, i), simplify = F)
rate <- mapply(est_rate, part_res, pop, SIMPLIFY = F)
    
# residency-specific rates are also included for Tableau (so all nonres show zeroes)
rate[["res"]] <- select(part[["res"]], res, year) %>%
    left_join(select(rate[["tot"]], year, rate), by = "year") %>%
    mutate(rate = ifelse(res == "Nonresident", 0, rate))

## 3. New recruits
priv_new <- filter(priv, !is.na(R3), R3 == "Recruit")
has_recruit <- nrow(priv_new) > 0 # no R3 will be available if < 5 yrs of data

if (has_recruit) {
    part_new <- sapply(segs[1:4], function(i) est_part(priv_new, i), simplify = F)
    part_new <- lapply(part_new, function(x) scaleup_part(x, part_new$tot))
}

## 4. churn rate
# only needed for full year results in nat/reg
if (qtr == 4) {
    churn <- sapply(segs, function(i) est_churn(priv, i), simplify = F)
}

## Format for Tableau
tableau <- function(df, metric) format_tableau(df, metric, yrs, county_fips)
out_tbl <- bind_rows(
    lapply(part, tableau, metric = "participants"),
    lapply(rate, tableau, metric = "participation rate"),
    if (qtr == 4) lapply(churn, tableau, metric = "churn"),
    if (has_recruit) lapply(part_new, tableau, metric = "participants - recruited")
) %>%
    mutate(quarter = qtr, group = priv_nm, state = state,
           timeframe = ifelse(qtr == 4, "full-year", "mid-year")) %>%
    select(state, timeframe, group, segment, year, category, metric, value) %>%
    filter(category != "0-17", category != "65+")

## For nat/reg dashboard, converting rates to 100 point scale
out_tbl <- out_tbl %>% mutate(
    value = ifelse(metric %in% c("churn", "participation rate"), value * 100, value)
)
glimpse(out_tbl)


# Save ----------------------------------------------------------------------

## save out_tbl results of selected permission
dir.create(out_dir, showWarnings = FALSE)
saveRDS(out_tbl, file.path(out_dir, paste0(priv_nm, state, qtr, ".rds")))

## check
# Row Counts
# - churn will likely be 10% smaller (except for county)
# - recruited will likely be around 50% smaller (5 yrs can't be counted)
# - month only applies to participants
count(out_tbl, metric, segment) %>% 
    spread(segment, n) %>%
    knitr::kable(caption = "Row counts by metric-segment")

# Summary values - particularly looking for unexpected NAs
options(scipen = 999)
group_by(out_tbl, metric, segment) %>%
    summarise(val = mean(value)) %>%
    spread(segment, val) %>%
    knitr::kable(caption = "Mean values by metric-segment", 
                 digits = 2, format.args = list(big.mark = ","))

sessionInfo()
