# for summary data provided to us by states

library(tidyverse)
library(readxl)

# TX ----------------------------------------------------------------------


# NE ----------------------------------------------------------------------

# churn appears to be set 1 year behind
# participants is missing for all_sports
# could be incomplete in other ways....the data look strange...will need to take a closer look
st <- "NE"
f <- "data/NE/southwick.csv"
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

write_csv(x, paste0("2018-q4/out/", st, ".csv"))

# FL ----------------------------------------------------------------------
# looks kosher, assuming no problems here

st <- "FL"
f <- "data/FL/FL_dashboard_2018FullYear_Summary.csv.xlsx"
x <- read_excel(f)
names(x) <- tolower(names(x))

x <- mutate(x, metric = ifelse(metric == "Pariticipants", "Participants", metric))
count(x, metric)

x <- filter(x, year != 2019)
count(x, year)

x <- arrange(x, group, metric)
x <- mutate(x, value = ifelse(metric == "churn", value / 100, value))

count(x, group)
count(x, segment)
count(x, category)
count(x, year)
count(x, metric)

write_csv(x, paste0("2018-q4/out/", st, ".csv"))

# MA ----------------------------------------------------------------------
# no all_sports group created for MA...will need to follow-up with Jody S.

st <- "MA"
x <- read_excel("data/MA/2019-02-26/Dashboard_State_Prepared_Data_MA_SA_KM.xlsx")

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

write_csv(x, paste0("2018-q4/out/", st, ".csv"))
