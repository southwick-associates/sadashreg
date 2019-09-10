# Workflow to smooth out FL hunting data artifact beginning in 2015

library(tidyverse)
library(broom)

# Notes -------------------------------------------------------------------

### Notes on changes needed (hunt)
# applies to most categories (all, 45+, resident, female, male)
# applies to mid-year & full-year

# churn in 2015: avg of 2014/2016 
# part in 2015+: extrapolate based on linear trend from 2009 to 2014
# recruit in 2015+: extrapolate based on participants trend (used above)

### Changes in fishing & overall? (for 2019)

# alternative 1: apply smoothing for 2009, similar to what is done for hunt below
# alternative 2: exclude 2009 for all national/regional trends (and FL)
# alternative 3: leave it be (probably don't want this)

# Functions ---------------------------------------------------------------

# estimate smoothing factor per year
# - df: summary results in data frame
# - yrs: years that will be used for linear trend estimation
est_lm <- function(
    df_all, yrs = 2009:2014, met = "Participants", grp = "hunt", 
    cats = c("45-54", "55-64", "All", "Female", "Male", "Resident")
) {
    df <- filter(df_all, metric == met, group == grp, year %in% yrs, category %in% cats)
    split(df, df$category) %>%
        lapply(function(x) lm(value ~ year, x))
} 

# apply smooothing based on factor
predict_lm <- function(
    df_all, mod, yrs = 2015:2018, met = "Participants", grp = "hunt", 
    cats = c("45-54", "55-64", "All", "Female", "Male", "Resident")
) {
    est_cat <- function(mod, df) {
        x <- filter(df, metric == met, group == grp, year %in% yrs, category %in% cats)
        if (nrow(x) == 0) return(df)
        x$value <- predict(mod, x)
        df %>%
            anti_join(x, by = c("timeframe", "group", "segment", "category", "metric", "year")) %>%
            bind_rows(x)
    }
    out <- split(df_all, df_all$category)
    sapply(names(out), function(cat) est_cat(mod[[cat]], out[[cat]]), simplify = FALSE) %>%
        bind_rows()
} 

# Code --------------------------------------------------------------------

full <- read_csv("analysis/2018-q4/out/FL.csv")
mid <- read_csv("analysis/2019-q2/out/FL.csv")
ignore_cats <- c("Nonresident", "18-24", "25-34", "35-44")

# use correct churn rate (not renewal rate)
full <- mutate(full, value = ifelse(metric == "churn", 1 - value, value))

# adjust full-year churn
new16 <- full %>%
    filter(metric == "churn", !category %in% ignore_cats, year %in% c(2015, 2017)) %>%
    group_by(timeframe, group, segment, category, metric) %>%
    summarise(value = mean(value)) %>% 
    ungroup() %>%
    mutate(year = 2016)
full <- full %>%
    anti_join(new16, by = c("timeframe", "group", "segment", "category", "metric", "year")) %>%
    bind_rows(new16)

# adjust participants
mod_lm <- est_lm(full)
full <- predict_lm(full, mod_lm)

# adjust recruits
# TODO - START HERE - use mod_lm for recruits

# save & check
outdir <- "analysis/2018-q4/checks/FL-corrected"
dir.create(outdir, showWarnings = FALSE)
write_csv(full, file.path(outdir, "full-year.csv"))

source("../dashboard-template/visualize/app-functions.R")
run_visual(outdir)
