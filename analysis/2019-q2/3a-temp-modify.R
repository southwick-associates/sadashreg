# temporary modification code to smooth out results
# should not be dropped by Sep 16, 2019

library(tidyverse)
indir <- "2018-q4/out"
outfile <- "full-year2018.csv"

# pull all results
get_state <- function(f) {
    st <- str_sub(f, end = 2)
    read_csv(file.path(indir, f)) %>%
        mutate(state = st)
}
infiles <- list.files(indir)
dat <- sapply(infiles, get_state, simplify = FALSE)


# Temp State-specific corrections -----------------------------------------

# these overwrite CSVs from the previous two steps (not super wise, but temporary)
# - filling in gaps for averages (2009 to 2018)
# - this is very hacky, will come up with a better approach later

# FL
# set post-2015 to 2015 due to the data artifact
x <- dat[["FL.csv"]]

x <- filter(x, year <= 2014) %>%
    bind_rows(
        filter(x, year == 2014) %>% mutate(year = 2015),
        filter(x, year == 2014) %>% mutate(year = 2016),
        filter(x, year == 2014) %>% mutate(year = 2017),
        filter(x, year == 2014) %>% mutate(year = 2018)
    )
write_csv(x, file.path(indir, "FL.csv"))

# GA (fill backwards and forwards)
x <- dat[["GA.csv"]]

x <- bind_rows(
    x,
    filter(x, year == 2011, metric == "churn") %>% mutate(year = 2010),
    filter(x, year == 2010) %>% mutate(year = 2009),
    filter(x, year == 2016) %>% mutate(year = 2017),
    filter(x, year == 2016) %>% mutate(year = 2018),
    filter(x, year == 2015, metric == "recruits") %>% mutate(year = 2014)
)
write_csv(x, file.path(indir, "GA.csv"))

# MA (just going to exclude them for now)

# MO (drop first year for each metric)
x <- dat[["MO.csv"]]

x <- anti_join(x, filter(x, year == 2008))
x <- anti_join(x, filter(x, year == 2009, metric == "churn"))
x <- anti_join(x, filter(x, year == 2013, metric == "recruits"))
write_csv(x, file.path(indir, "MO.csv"))

# NE (cast back 1 year & set all_sports participants to hunting + 25%)
x <- dat[["NE.csv"]]

x <- bind_rows(
    x,
    filter(x, year == 2011, metric == "churn") %>% mutate(year = 2010),
    filter(x, year == 2010) %>% mutate(year = 2009),
    filter(x, year == 2015, metric == "recruits") %>% mutate(year = 2014),
    filter(x, metric == "participants", group == "hunt") %>%
        mutate(group = "all_sports", value = value + (value * 0.25))
)
write_csv(x, file.path(indir, "NE.csv"))

# OR (drop first year for each metric)
x <- dat[["OR.csv"]]

x <- anti_join(x, filter(x, year == 2008))
x <- anti_join(x, filter(x, year == 2009, metric == "churn"))
x <- anti_join(x, filter(x, year == 2013, metric == "recruits"))
write_csv(x, file.path(indir, "OR.csv"))

# VA (drop first year for each metric)
x <- dat[["VA.csv"]]

x <- anti_join(x, filter(x, year == 2008))
x <- anti_join(x, filter(x, year == 2009, metric == "churn"))
x <- anti_join(x, filter(x, year == 2013, metric == "recruits"))
write_csv(x, file.path(indir, "VA.csv"))

# WI - cast forward & drop first year
x <- dat[["WI.csv"]]

x <- anti_join(x, filter(x, year == 2008))
x <- anti_join(x, filter(x, year == 2009, metric == "churn"))
x <- anti_join(x, filter(x, year == 2013, metric == "recruits"))

x <- bind_rows(
    x,
    filter(x, year == 2015) %>% mutate(year = 2016),
    filter(x, year == 2015) %>% mutate(year = 2017),
    filter(x, year == 2015) %>% mutate(year = 2018)
)
write_csv(x, file.path(indir, "WI.csv"))
