# produce dashboard summary data for Southwick dashboard states

source("analysis/sa-states.R")
outdir <- file.path(dir, "out")

# these will be updated (if possible) prior to Sep 16th
run_state("IA", 2009:2018, timeframe, outdir) # we know this is wrong for hunting
run_state("GA", 2010:2016, timeframe, outdir) # old data
run_state("WI", 2008:2015, timeframe, outdir) # old data

# these shouldn't need to change
run_state("OR", yrs, timeframe, outdir)
run_state("MO", yrs, timeframe, outdir)
run_state("SC", 2009:2018, timeframe, outdir)
run_state("TN", 2009:2018, timeframe, outdir, groups = "all_sports")
run_state("VA", yrs, timeframe, outdir)
