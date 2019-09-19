# for summary data provided to us by states
# hopefully the oddities will decrease with the available dashboard-template

# Notes:
# - Using est_residents() to fill in the oversite that we didn't get resident-specific breakouts

# TODO:
# - look into additional standardization that might be useful here
# - think about any adjustments needed
#   + IA hunting


library(tidyverse)
library(readxl)
library(dashreg)

source("analysis/2018-q4/params.R")
outdir <- file.path(dir, "out")


# TX ----------------------------------------------------------------------


# NE ----------------------------------------------------------------------

st <- "NE"
f <- "analysis/2018-q4/data/NE/Nebraskafull-year2010to2018.csv"
x <- read_csv(f)
x <- est_residents(x) # needed for sep 2019

count(x, group)
count(x, segment)
count(x, category)
count(x, year)
count(x, metric)

write_csv(x, file.path(outdir, paste0(st, ".csv")))

# FL ----------------------------------------------------------------------

# FL requires quite a bit of tweaking
# - some recoding for naming conventions
# - drop 2019 (there shouldn't be any of these...they probably used fiscal year)
# - churn recoding:
#   + convert to 0 to 1 scale (from 0 to 100)
#   + move forward by 1 year
#   + convert from renewal rate
# - scale up segments to peg to total
# - smooth out 2015 hunting artifact

st <- "FL"
f <- "analysis/2018-q4/data/FL/FL_dashboard_2018FullYear_Summary.csv.xlsx"
x <- read_excel(f)
names(x) <- tolower(names(x))

# naming
x <- x %>% mutate(
    metric = ifelse(metric == "Pariticipants", "Participants", metric),
    metric = tolower(metric), segment = tolower(segment)
)
count(x, metric)

# years
x <- filter(x, year != 2019)
count(x, year)

# churn
x <- arrange(x, group, metric)
x <- x %>%
    mutate(
        value = ifelse(metric == "churn", value / 100, value),
        value = ifelse(metric == "churn", 1 - value, value)
    )
drop <- filter(x, metric == "churn", year == 2018)
x <- anti_join(x, drop)
x <- x %>% mutate(
    year = ifelse(metric == "churn", year + 1, year)
)
filter(x, metric == "churn", segment == "all", year > 2015) 

# scale segments
check_scale <- function(x) {
    group_by(x, group, metric, year, segment) %>% 
        filter(metric != "churn") %>% summarise(sum(value))
}
check_scale(x)
x <- scale_segs(x)
check_scale(x)

# hunt artifact smoothing
source("analysis/adjust-fl.R")

# add residency
x <- est_residents(x)

count(x, group)
count(x, segment)
count(x, category)
count(x, year)
count(x, metric)

write_csv(x, file.path(outdir, paste0(st, ".csv")))

# MA ----------------------------------------------------------------------
# not included in the Sep 2019 dashboard presentation

# no all_sports group created for MA...will need to follow-up with Jody S.

# st <- "MA"
# x <- read_excel("analysis/2018-q4/data/MA/2019-02-26/Dashboard_State_Prepared_Data_MA_SA_KM.xlsx")
# 
# # churn isn't coded consistently
# x <- mutate(x, value = case_when(
#     metric == "churn" & value > 1 ~ value / 100,
#     TRUE ~ value
# ))
# group_by(x, metric) %>%
#     summarise(min(value), mean(value), max(value))
# 
# count(x, group)
# count(x, segment)
# count(x, category)
# count(x, year)
# count(x, metric)
# 
# write_csv(x, file.path(outdir, paste0(st, ".csv")))
