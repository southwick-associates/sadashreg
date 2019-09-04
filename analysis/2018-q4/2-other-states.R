# for summary data provided to us by states
# hopefully the oddities will decrease with the available dashboard-template

library(tidyverse)
library(readxl)
outdir <- file.path(dir, "out")

# TX ----------------------------------------------------------------------


# NE ----------------------------------------------------------------------

# churn appears to be set 1 year behind
# participants is missing for all_sports
# could be incomplete in other ways....the data look strange...will need to take a closer look
st <- "NE"
f <- "analysis/2018-q4/data/NE/southwick.csv"
x1 <- read_csv(f, n_max = 576)

cols <- c("timeframe", "group", "category", "segment", "year", "metric", "value")
x2 <- read_csv(f, cols, skip = 577)
x <- bind_rows(x1, x2)
count(x, group, metric)

x <- x %>% mutate(
    group = ifelse(group == "all", "all_sports", group),
    segment = ifelse(segment == "ageGroup", "age", segment),
    segment = ifelse(segment == "resident", "residency", segment)
)
x <- filter(x, metric != "participation rate")

# change churn to 0 to 1 instead of 0 to 100
x <- mutate(x, value = ifelse(metric == "churn", value / 100, value))
group_by(x, metric) %>% summarise(min(value), mean(value), max(value))

# drop segment == gender, category == gender
drop <- filter(x, category == "gender") # no idea what these represent
drop
x <- anti_join(x, drop)

# move churn forward by 1 year
x <- mutate(x, year = ifelse(metric == "churn", year + 1, year))
filter(x, metric == "churn") %>% count(year)

count(x, group)
count(x, segment)
count(x, category)
count(x, year)
count(x, metric)

write_csv(x, file.path(outdir, paste0(st, ".csv")))

# FL ----------------------------------------------------------------------

# can do some corrections
# - scale up segments to peg to total (probably can use salic funcs)
# - maybe smooth out the 2015 artifact in hunting (at least temporarily)

st <- "FL"
f <- "analysis/2018-q4/data/FL/FL_dashboard_2018FullYear_Summary.csv.xlsx"
x <- read_excel(f)
names(x) <- tolower(names(x))

x <- mutate(x, metric = ifelse(metric == "Pariticipants", "Participants", metric))
count(x, metric)

x <- filter(x, year != 2019)
count(x, year)

x <- arrange(x, group, metric)
x <- mutate(x, value = ifelse(metric == "churn", value / 100, value))

# move churn forward by 1 year
drop <- filter(x, metric == "churn", year == 2018)
x <- anti_join(x, drop)
x <- x %>% mutate(
    year = ifelse(metric == "churn", year + 1, year)
)

# scale segments to total
tot <- filter(x, segment == "All", metric != "churn") %>%
    select(-category, -segment) %>%
    rename(value_tot = value)

x1 <- filter(x, segment != "All", metric != "churn") %>%
    group_by(group, segment, year, metric) %>%
    mutate(value_sum = sum(value)) %>%
    ungroup() %>%
    left_join(tot) %>%
    mutate(value = value * value_tot / value_sum)
x <- filter(x, segment == "All" | metric == "churn") %>%
    bind_rows(x1)

count(x, group)
count(x, segment)
count(x, category)
count(x, year)
count(x, metric)

write_csv(x, file.path(outdir, paste0(st, ".csv")))

# MA ----------------------------------------------------------------------
# no all_sports group created for MA...will need to follow-up with Jody S.

st <- "MA"
x <- read_excel("analysis/2018-q4/data/MA/2019-02-26/Dashboard_State_Prepared_Data_MA_SA_KM.xlsx")

# churn isn't coded consistently
x <- mutate(x, value = case_when(
    metric == "churn" & value > 1 ~ value / 100,
    TRUE ~ value
))
group_by(x, metric) %>%
    summarise(min(value), mean(value), max(value))

count(x, group)
count(x, segment)
count(x, category)
count(x, year)
count(x, metric)

write_csv(x, file.path(outdir, paste0(st, ".csv")))
