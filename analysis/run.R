# produce tableau input for national/regional dashboard

# define timeframe-specific parameters
dir <- "analysis/2019-q2"
timeframe <- "mid-year"
yrs <- 2009:2019

# produce summary results for timeframe
# - code that is timeframe-specific
source(file.path(dir, "1-sa-states.R")) # this step requires the most time
source(file.path(dir, "2-other-states.R"))

# - code that is shared across timeframes
source("analysis/3a-adjustments.R") # should only be needed in Sep 2019
source("analysis/3-part-rates.R")
source("analysis/4-combine.R")

# check new results
source("../dashboard-template/visualize/app-functions.R")
run_visual(file.path(dir, "out-dashboard"), pct_range = 0.2)

# stack current and previous timeframe for tableau input
lastdir <- "analysis/2018-q4"
bind_rows(
    read_csv(file.path(dir, "dashboard.csv")),
    read_csv(file.path(lastdir, "dashboard.csv"))
) %>%
    write_csv(paste0(dir, "-dashboard.csv"))
