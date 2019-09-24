# produce dashboard summary data for Southwick dashboard states

library(tidyverse)
library(dashreg)

source("analysis/2019-q2/params.R")
outdir <- file.path(dir, "out")

# these will be updated once new data become available
run_state("IA", yrs, timeframe, outdir)
run_state("GA", 2010:2016, timeframe, outdir)
run_state("WI", 2009:2015, timeframe, outdir, 
          db_license = "E:/SA/Data-production/Data-Dashboards/WI/2015-q4/license.sqlite3"
)
run_state("TN", 2009:2018, timeframe, outdir, groups = "all_sports")

# these shouldn't need to change
run_state("OR", yrs, timeframe, outdir)
run_state("MO", yrs, timeframe, outdir)
run_state("SC", yrs, timeframe, outdir, scaleup_test = 35)
run_state("WI", yrs, timeframe, outdir)
run_state("VA", yrs, timeframe, outdir)


# SC data artifact in 2019 ------------------------------------------------

# big increase in recruits, particularly for hunters
f <- file.path(outdir, "SC.csv")
x <- read_csv(f)

for (i in c("hunt", "fish", "all_sports")) {
    mod <- est_lm(x, 2014:2018, "recruits", i, unique(x$category))
    x <- predict_lm(x, mod, 2019, "recruits", i, unique(x$category))
}
write_csv(x, f)
