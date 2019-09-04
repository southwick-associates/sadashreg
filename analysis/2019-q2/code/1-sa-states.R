# produce dashboard summary data for Southwick dashboard states

source("R/sa-states.R")

# parameters
timeframe <- "mid-year" # full-year or mid-year
base_yrs <- 2008:2019
outdir <- "2019-q2/out"

# these will be updated (if possible) prior to Sep 16th
run_state("IA", 2008:2018, timeframe, outdir) # run with existing data, we just know it's wrong for hunting
run_state("GA", 2010:2016, timeframe, outdir) # old data
run_state("WI", 2008:2015, timeframe, outdir) # old data

# these shouldn't need to change
run_state("OR", base_yrs, timeframe, outdir)
run_state("MO", base_yrs, timeframe, outdir)
run_state("SC", 2009:2018, timeframe, outdir)
run_state("TN", 2009:2018, timeframe, outdir, groups = "all_sports")
run_state("VA", base_yrs, timeframe, outdir)
