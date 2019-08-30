# run validations on summary data
# - do segments sum to total?
# - others?

# Tally
# - FL has a data artifact issue with hunting in 2015 (for those above about 50 yrs old)
#   + also present to a lesser extent in fishing/all_sports
# - FL churn looks wrong in 2018 (might just need to shift everything 1 year forward)
# - MA issue with hunt churn in 2017/2018
# - NE age breakout issues
# - NE no participants for all_sports

library(tidyverse)

# Visualize ---------------------------------------------------------------

source("E:/SA/Projects/R-Software/Templates/dashboard-template/visualize/app-functions.R")
run_visual()


# Test Segment Sum --------------------------------------------------------

# this can probably be wrapped into a function
# & then probably put it at the end of 3-combine
# (probably also calculate part. rate first so it can be easily checked as well)

dat <- read_csv("../out/full-year2018.csv")

x <- filter(dat, metric != "churn")
tot <- filter(x, segment == "all") %>%
    select(group, year:state)

# this reveals errors pretty much immediately
seg <- filter(x, segment != "all") %>%
    group_by(state, group, metric, year, segment) %>%
    summarise(value.seg = sum(value))

# around 
issues <- full_join(tot, seg) %>%
    mutate(pct_diff = (value.seg - value) / value * 100) %>%
    filter(abs(pct_diff) > 0.01)
count(issues, state)

# every state has issues with this
# should I just peg to match total?
# - that seems fine with FL
filter(issues, state == "FL") %>% View()

# MA seems to have some more serious problems for several years
filter(issues, state == "MA") %>% View()

# NE has some serious issues as well
filter(issues, state == "NE") %>% View()
