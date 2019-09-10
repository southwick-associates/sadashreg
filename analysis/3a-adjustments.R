# Workflow to smooth out FL hunting data artifact beginning in 2015
# hopefully won't be needed in 2019-q4 (will want repull of 2019-q2 as well)

library(tidyverse)
source("analysis/R/adjustments.R")

# params
if (!exists("timeframe")) {
    dir <- "analysis/2019-q2"
    timeframe <- "mid-year"
    yrs <- 2009:2019
}

# this file will be overwritten
infile <- file.path(dir, "out", "FL.csv")

# Notes -------------------------------------------------------------------

### Hunting
# applies to most categories (all, 45+, resident, female, male)
# applies to mid-year & full-year

# churn in 2015: avg of 2014/2016 
# part in 2015+: extrapolate based on linear trend from 2009 to 2014
# recruit in 2015+: extrapolate based on participants trend (used above)

### Fishing & overall? (for 2019)
# alternative 1: apply smoothing for 2009, similar to what is done for hunt below
# alternative 2: exclude 2009 for all national/regional trends (and FL)
# alternative 3: leave it be (probably don't want this)

# Perform Adjustment -----------------------------------------------------------

df <- read_csv(infile)
ignore_cats <- c("Nonresident", "18-24", "25-34")
cats <- setdiff(unique(df$category), ignore_cats)

# use correct churn rate (not renewal rate)
df <- mutate(df, value = ifelse(metric == "churn", 1 - value, value))

# adjust full-year churn
if (timeframe == "full-year") {
    new16 <- df %>%
        filter(metric == "churn", !category %in% ignore_cats, year %in% c(2015, 2017)) %>%
        group_by(timeframe, group, segment, category, metric) %>%
        summarise(value = mean(value)) %>% 
        ungroup() %>%
        mutate(year = 2016)
    df <- df %>%
        anti_join(new16, by = c("timeframe", "group", "segment", "category", "metric", "year")) %>%
        bind_rows(new16)
}

# adjust participants
yrs_ref <- 2009:2014
yrs_adjust <- setdiff(yrs, yrs_ref)

mod_lm <- est_lm(df, yrs_ref, "Participants", "hunt", cats)
df <- predict_lm(df, mod_lm, yrs_adjust, "Participants", "hunt", cats)

# adjust recruits
df <- predict_lm(df, mod_lm, yrs_adjust, "Recruits", "hunt", cats)

# - additional adjustment needed since we are using a participant-based model
adjust <- filter(df, year == 2014, metric %in% c("Recruits", "Participants"), 
                 !category %in% ignore_cats, group == "hunt") %>%
    spread(metric, value) %>%
    mutate(adjust = Recruits / Participants) %>%
    select(-Recruits, -Participants, -year) %>%
    mutate(metric = "Recruits")
df <- left_join(df, adjust) %>%
    mutate(value = ifelse(is.na(adjust) | year == 2014, value, value * adjust)) %>%
    select(-adjust)

# write to csv
write_csv(df, infile)

source("../dashboard-template/visualize/app-functions.R")
run_visual(dirname(infile))
