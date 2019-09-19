# for summary data provided to us by states
# these may involve some amount of special treatment

library(tidyverse)
library(readxl)
library(dashreg)

source("analysis/2019-Q2/params.R")
outdir <- file.path(dir, "out")

# FL ----------------------------------------------------------------------

st <- "FL"
f <- "analysis/2019-q2/data/FL/FL_dashboard_2019MidYear_Summary.csv.xlsx"
x <- read_excel(f)
names(x) <- tolower(names(x))

# naming
x <- x %>% mutate(
    metric = ifelse(metric == "Pariticipants", "Participants", metric),
    metric = tolower(metric)
)
count(x, metric)

# add a segment variable
x <- x %>% mutate(segment = case_when(
    category %in% c("18-24", "25-34", "35-44", "45-54", "55-64") ~ "Age",
    category %in% c("Male", "Female") ~ "Gender",
    category %in% c("Resident", "Nonresident") ~ "Residency",
    TRUE ~ "All") %>% tolower()
)
count(x, segment, category)


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
