# run all results for time period

dir <- "analysis/2018-q4"
timeframe <- "full-year"
yrs <- 2008:2018

source("analysis/2018-q4/1-sa-states.R")
source("analysis/2018-q4/2-other-states.R")
source("analysis/2018-q4/3-part-rates.R")
source("analysis/2018-q4/4-combine.R")
