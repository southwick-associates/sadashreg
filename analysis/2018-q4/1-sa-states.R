# produce dashboard summary data for Southwick dashboard states

library(tidyverse)
library(dashreg)

source("analysis/2018-q4/params.R")
outdir <- file.path(dir, "out")

# these will be updated once new data become available
run_state("IA", yrs, timeframe, outdir) # we know this is wrong for hunting
run_state("GA", 2010:2016, timeframe, outdir)
run_state("WI", 2009:2015, timeframe, outdir, 
          db_license = "E:/SA/Data-production/Data-Dashboards/WI/2015-q4/license.sqlite3"
)

# these shouldn't need to change
run_state("OR", yrs, timeframe, outdir)
run_state("MO", yrs, timeframe, outdir)
run_state("SC", yrs, timeframe, outdir)
run_state("TN", yrs, timeframe, outdir, groups = "all_sports")
run_state("VA", yrs, timeframe, outdir)


# Temp IA Scaling ---------------------------------------------------------

# IA hunting numbers are too low in first iteration (based on previous dashboards)
# - simply applying an adjustment factor to hunting totals
f <- file.path(outdir, "IA.csv")
x <- read_csv(f)
part_hunt <- filter(x, metric != "churn", group == "hunt")
other <- anti_join(x, part_hunt)

ratio <- 241569 / 180988 # hunting in 2010: old vs current results
part_hunt$value <- part_hunt$value * ratio

bind_rows(part_hunt, other) %>% write_csv(f)
