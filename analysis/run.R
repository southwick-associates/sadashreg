# produce tableau input for national/regional dashboard

# define timeframe-specific parameters
dir <- "analysis/2019-q2"
timeframe <- "mid-year"
yrs <- 2008:2019

# produce summary results for timeframe
# - code that varies by timeframe
source(file.path(dir, "1-sa-states.R")) # this step requires the most time
source(file.path(dir, "2-other-states.R"))
# - code that remains the same across timeframes
source("analysis/3-part-rates.R")
source("analysis/4-combine.R")

# check new results
source("../dashboard-template/visualize/app-functions.R")
run_visual(file.path(dir, "out-dashboard"), pct_range = 0.2)

# stack full-year & mid-year for tableau input
