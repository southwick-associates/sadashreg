# checking that the mid-year breakout produces expected result (OR)
# will also want to test with MO once it is completed

# some changes from the nat/reg code are needed
# - use year, month from data
# - don't filter based on age


library(DBI)
library(dplyr)
library(lubridate)
library(salic)
source("../dashboard-template/code/functions.R")

# parameters
timeframe <- "mid-year" # full-year or mid-year
yrs <- 2005:2019

calc_metrics <- function(
    history,
    tests = c(tot = 20, res = 35, sex = 35, agecat = 35),
    scaleup_test = 10
) {
    # prepare category variables
    history <- history %>%
        label_categories() %>%
        recode_agecat()
    
    # calculate metrics across 4 segments
    segs <- c("tot", "res", "sex", "agecat")
    sapply2 <- function(x, ...) sapply(x, simplify = FALSE, ...) # for convenience
    
    part <- sapply2(segs, function(x) est_part(history, x, tests[x]))
    participants <- lapply(part, function(x) scaleup_part(x, part$tot, scaleup_test))
    
    if ("lapse" %in% names(history)) {
        churn <- sapply2(segs, function(x) est_churn(history, x, tests[x]))
    }
    if ("R3" %in% names(history)) {
        history <- filter(history, R3 == "Recruit")
        part <- sapply2(segs, function(x) est_recruit(history, x, tests[x]))
        recruits <- lapply(part, function(x) scaleup_recruit(x, part$tot, scaleup_test))
    }
    sapply2(c("participants", "recruits", "churn"), function(x) if (exists(x)) get(x))
}

# run for each state
run_group <- function(
    cust, lic, sale, yrs = 2008:2018, timeframe = "full-year",
    group = "hunt", lic_types = c("hunt", "combo")
) {
    build_history(cust, lic, sale, yrs, timeframe, lic_types) %>%
        calc_metrics(scaleup_test = 30) %>% 
        format_metrics(timeframe, group)
}

st <- "OR"
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
    select(cust_id, lic_id, year, month, res) %>%
    collect()
dbDisconnect(con)

# some adjustments
sale <- filter(sale, year %in% yrs)
sale <- filter(sale, !is.na(cust_id)) # not sure why, but we have a few of these
lic <- filter(lic, !is.na(type), type != "other")

# final filtering & checking
cust <- semi_join(cust, sale, by = "cust_id")
cust <- mutate(cust, birth_year = ifelse(birth_year < 1900, NA_integer_ , birth_year))
lic <- semi_join(lic, sale, by = "lic_id") 
data_check(cust, lic, sale)

### 2. produce summaries for each permission
hunt <- run_group(
    cust, lic, sale, yrs, timeframe, "hunt", c("hunt", "trap", "combo")
)
fish <- run_group(
    cust, lic, sale, yrs, timeframe, "fish", c("fish", "combo")
)
all_sports <- run_group(
    cust, lic, sale, yrs, timeframe, "all_sports", c("hunt", "trap", "fish", "combo")
)