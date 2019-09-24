# produce tableau input for national/regional dashboard

# Results for a single Timeframe ------------------------------------------

dir_timeframe <- "2018-q4" 

# code that is timeframe-specific
source(file.path("analysis", dir_timeframe, "1-sa-states.R"))
source(file.path("analysis", dir_timeframe, "2-other-states.R"))

# code shared across timeframes
source(file.path("analysis", dir_timeframe, "params.R"))
source("analysis/3-part-rates.R")
source("analysis/4-combine.R")

# visualize
dashtemplate::run_visual(file.path("analysis", dir_timeframe, "out-dashboard"))

# Stack Timeframes for Tableau ----------------------------------------------

library(tidyverse)

# stack current and previous timeframe for tableau input
x <- bind_rows(
    read_csv(file.path("analysis/2018-q4", "dashboard.csv")),
    read_csv(file.path("analysis/2019-q2", "dashboard.csv"))
)
write_csv(x, "analysis/dashboard.csv")
