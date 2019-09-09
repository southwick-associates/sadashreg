# produce dashboard summary data for Southwick dashboard states

source("analysis/R/sa-states.R")
outdir <- file.path(dir, "out")

# these will be updated (if possible) prior to Sep 16th
run_state("IA", 2008:2019, timeframe, outdir) # run with existing data, we just know it's wrong for hunting
run_state("GA", 2010:2016, timeframe, outdir) # old data
run_state("WI", 2008:2015, timeframe, outdir) # old data

# these shouldn't need to change
run_state("OR", yrs, timeframe, outdir)
run_state("MO", yrs, timeframe, outdir)
run_state("SC", 2009:2019, timeframe, outdir)
run_state("TN", 2009:2019, timeframe, outdir, groups = "all_sports")
run_state("VA", yrs, timeframe, outdir)
