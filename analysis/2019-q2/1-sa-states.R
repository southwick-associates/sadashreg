# produce dashboard summary data for Southwick dashboard states

library(dashreg)
source("analysis/2019-q2/params.R")
outdir <- file.path(dir, "out")

# these will be updated once new data become available
run_state("IA", yrs, timeframe, outdir) # we know this is wrong for hunting
run_state("GA", 2010:2016, timeframe, outdir)
run_state("WI", 2009:2015, timeframe, outdir, 
          db_license = "E:/SA/Data-production/Data-Dashboards/WI/2015-q4/license.sqlite3"
)
run_state("TN", 2009:2018, timeframe, outdir, groups = "all_sports")

# these shouldn't need to change
run_state("OR", yrs, timeframe, outdir)
run_state("MO", yrs, timeframe, outdir)
run_state("SC", yrs, timeframe, outdir, scaleup_test = 35)
run_state("VA", yrs, timeframe, outdir)
