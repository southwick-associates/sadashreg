# for summary data provided to us by states
# these may involve some amount of special treatment

library(tidyverse)
library(readxl)
outdir <- file.path(dir, "out")

# FL ----------------------------------------------------------------------

st <- "FL"
f <- "analysis/2019-q2/data/FL/FL_dashboard_2019MidYear_Summary.csv.xlsx"
x <- read_excel(f)
names(x) <- tolower(names(x))

x <- mutate(x, metric = ifelse(metric == "Pariticipants", "Participants", metric))
count(x, metric)

# add a segment variable
x <- x %>% mutate(segment = case_when(
    category %in% c("18-24", "25-34", "35-44", "45-54", "55-64") ~ "Age",
    category %in% c("Male", "Female") ~ "Gender",
    category %in% c("Resident", "Nonresident") ~ "Residency",
    TRUE ~ "All"
))
count(x, segment, category)

# scale segments to total
tot <- filter(x, segment == "All", metric != "churn") %>%
    select(-category, -segment) %>%
    rename(value_tot = value)

# demonstrate need for scaling
filter(x, segment != "All", metric != "churn") %>%
    group_by(group, segment, year, metric) %>%
    summarise(value_sum = sum(value)) %>%
    ungroup() %>% 
    left_join(tot) %>%
    mutate(pctdiff = (value_sum - value_tot) / value_tot * 100) %>%
    filter(abs(pctdiff) > 0) %>%
    arrange(desc(pctdiff))

# apply scaling
x1 <- filter(x, segment != "All", metric != "churn") %>%
    group_by(group, segment, year, metric) %>%
    mutate(value_sum = sum(value)) %>%
    ungroup() %>%
    left_join(tot) %>%
    mutate(value = value * value_tot / value_sum)
x <- filter(x, segment == "All" | metric == "churn") %>%
    bind_rows(x1) %>%
    select(-value_sum, -value_tot)

# check scaling > should return no rows
group_by(x, group, year, metric, segment) %>%
    summarise(value = sum(value)) %>%
    filter(max(value) != value)

count(x, group)
count(x, segment)
count(x, category)
count(x, year)
count(x, metric)

write_csv(x, file.path(outdir, paste0(st, ".csv")))
