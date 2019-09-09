# get dashboard metrics using data from 2017 lic analysis
# for years 2009 thru 2016

library(tidyverse)
library(lubridate)
library(DBI)
library(salic)
source("../dashboard-template/code/functions.R")

# pull data
f <- "D:/SA/Data2/FL_License_Analysis_2017/lic.sqlite3"
db <- src_sqlite(f)
lic <- tbl(db, "lic") %>%
    filter(level == "stand-alone") %>%
    select(lic_id, type, duration) %>%
    collect() %>%
    mutate(
        type = ifelse(type == "trap", "hunt", type),
        duration = ifelse(is.na(duration), 1, duration)
    ) 
sale <- tbl(db, "sale") %>% select(cust_id, lic_id, res, dot) %>% collect()
cust <- tbl(db, "cust") %>% select(cust_id, sex, birth_year, exempt) %>% collect()

sale <- mutate(sale, dot = ymd(dot), year = year(dot), month = month(dot))
sale <- filter(sale, year >= 2009)
sale <- semi_join(sale, lic, by = "lic_id")
sale <- mutate(sale, res = ifelse(res > 1, NA, res))
lic <- semi_join(lic, sale, by = "lic_id")
cust <- mutate(cust, birth_year = ifelse(birth_year < 1901, NA, birth_year))
cust <- mutate(cust, birth_year = ifelse(birth_year > 2017, NA, birth_year))
data_check(cust, lic, sale)

## exclude 3 license types
disabled <- c(546, 547, 548)
tbl(db, "lic") %>% filter(lic_id %in% disabled) %>% count(description)
lic <- filter(lic, !lic_id %in% disabled)
sale <- semi_join(sale, lic, by = "lic_id")

# build metrics & save to csv
# - full-year
yrs <- 2009:2016
hunt <- run_group(cust, lic, sale, yrs)
fish <- run_group(cust, lic, sale, yrs, group = "fish", lic_types = c("fish", "combo"))
sport <- run_group(cust, lic, sale, yrs, group = "all_sports", lic_types = c("fish", "combo", "hunt"))

outdir <- "analysis/2018-q4/checks/FL-SA"
dir.create(outdir, showWarnings = FALSE)
bind_rows(hunt, fish, sport) %>%
    write_csv(file.path(outdir, "full-year.csv"))

# - mid-year
yrs <- 2009:2017
hunt <- run_group(cust, lic, sale, yrs, "mid-year")
fish <- run_group(cust, lic, sale, yrs, "mid-year", "fish", lic_types = c("fish", "combo"))
sport <- run_group(cust, lic, sale, yrs, "mid-year", "all_sports", lic_types = c("fish", "combo", "hunt"))
bind_rows(hunt, fish, sport) %>%
    write_csv(file.path(outdir, "mid-year.csv"))

# explore
source("../dashboard-template/visualize/app-functions.R")
run_visual(outdir)


# FL-supplied results -----------------------------------------------------
# making some changes for comparison

full <- read_csv("analysis/2018-q4/out/FL.csv")
mid <- read_csv("analysis/2019-q2/out/FL.csv")

# use correct churn rate (not renewal rate)
full <- mutate(full, value = ifelse(metric == "churn", 1 - value, value))

# exclude recent year results
full <- filter(full, year <= 2016)
mid <- filter(mid, year <= 2017)

# write
write_csv(full, "analysis/2018-q4/checks/FL/full-year.csv")
write_csv(mid, "analysis/2018-q4/checks/FL/mid-year.csv")
