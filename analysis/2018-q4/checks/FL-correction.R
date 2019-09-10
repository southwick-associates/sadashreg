# Workflow to smooth out FL hunting data artifact beginning in 2015

### Notes on changes needed (hunt)
# applies to most categories (all, 45+, resident, female, male)
# applies to mid-year & full-year

# churn in 2015: avg of 2014/2016 
# part in 2015+: extrapolate based on linear trend from 2009 to 2014
# recruit in 2015+: extrapolate based on participants trend (used above)

### Changes in fishing & overall? (for 2019)

# alternative 1: could do something similar for 2009
# alternative 2: exclude 2009 for all national/regional trends (and FL)
# alternative 3: leave it be (probably don't want this)


# Code --------------------------------------------------------------------

library(tidyverse)

full <- read_csv("analysis/2018-q4/out/FL.csv")
mid <- read_csv("analysis/2019-q2/out/FL.csv")

# use correct churn rate (not renewal rate)
full <- mutate(full, value = ifelse(metric == "churn", 1 - value, value))

# adjust full-year churn

# adjust participants

# adjust recruits

# save & check