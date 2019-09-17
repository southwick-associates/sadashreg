# functions for estimating participation rate

# load reference state total population
# https://www.census.gov/data/tables/time-series/demo/popest/2010s-state-total.html
# https://www2.census.gov/programs-surveys/popest/tables/2000-2010/intercensal/state/
get_pop <- function(filename, col_names) {
    readxl::read_excel(filename, skip = 9, n_max = 51, col_names = col_names) %>%
        select(-contains("drop")) %>%
        tidyr::gather(year, pop_state, -state) %>%
        mutate(state = stringr::str_replace(state, ".", ""), year = as.numeric(year))
}

# extrapolate (forward) overall population for 1 missing year
# naively assumes % change is the same as the previous year
extrapolate_yr <- function(pop, yr) {
    pct_change <- filter(pop, year %in% c(yr-1, yr-2)) %>%
        arrange(year) %>%
        group_by(state) %>%
        mutate(pct_change = (pop_state - lag(pop_state)) / pop_state) %>%
        filter(year == yr-1) %>%
        select(-pop_state, -year)
    newyr <- filter(pop, year == yr-1) %>%
        left_join(pct_change, by = "state") %>%
        mutate(
            pop_state = pop_state + (pop_state * pct_change),
            year = yr
        ) %>%
        select(-pct_change)
    bind_rows(pop, newyr)
}

# extrapolate segments for missing years
# using most recent year distributions & reference population totals
# - pop_seg: census sex-by-age table (by state)
# - pop: census by state population
# - yr: year to be extrapolated to
# - direction: either "forward" (future) or "backward"
extrapolate_yr_seg <- function(pop_seg, pop, yr, direction) {
    if (direction == "forward") {
        yr_compare = yr - 1
        compare <- function(x) lag(x)
    } else {
        yr_compare = yr + 1
        compare <- function(x) lead(x)
    }
    ref <- filter(pop, year %in% c(yr, yr_compare)) %>%
        arrange(state, year) %>%
        group_by(state) %>%
        mutate(ratio = pop_state / compare(pop_state)) %>%
        ungroup() %>%
        select(state, year, ratio)
    filter(pop_seg, year == yr_compare) %>%
        mutate(year = yr) %>%
        left_join(ref, by = c("state", "year")) %>%
        mutate(pop = pop * ratio) %>%
        select(-ratio)
}

# relation table for acs to dashboard age categories
# - lic_age: numeric code for dashboard age cat
# - acs_age: category from census
age_map <- tibble::tribble(
    ~lic_age, ~acs_age,
    1,"Under 5 years",
    1,"5 to 9 years",
    1,"10 to 14 years",
    1,"15 to 17 years",
    2,"18 and 19 years",
    2,"20 years",
    2,"21 years",
    2,"22 to 24 years",
    3,"25 to 29 years",
    3,"30 to 34 years",
    4,"35 to 39 years",
    4,"40 to 44 years",
    5,"45 to 49 years",
    5,"50 to 54 years",
    6,"55 to 59 years",
    6,"60 and 61 years",
    6,"62 to 64 years",
    7,"65 and 66 years",
    7,"67 to 69 years",
    7,"70 to 74 years",
    7,"75 to 79 years",
    7,"80 to 84 years",
    7,"85 years and over"
)

# aggregate population by segment (for joining with participant summary)
# - pop_seg: input population data frame 
# - seg: name of segment to be stored in output data frame
# - var: name of input variable to summarize
aggregate_pop <- function(pop_seg, seg = "gender", var = "sex") {
    # identify category value (consistent with tableau input)
    if (seg == "all") {
        pop_seg$category <- "all"
    } else {
        pop_seg$category <- pop_seg[[var]]
    }
    # aggregate
    group_by(pop_seg, state, year, category) %>% 
        summarise(pop = sum(pop)) %>%
        mutate(segment = seg) %>%
        ungroup()
}

# add participation rate to summary table for each state
# - dashboard: tableau formatted dashboard data
# - pop: poulation data prepared with aggregate_pop()
est_rate <- function(dashboard, pop) {
    rate <- filter(dashboard, metric == "participants", segment != "residency") %>%
        left_join(pop, by = c("state", "segment", "category", "year")) %>%
        mutate(metric = "rate", value = value / pop) %>%
        arrange(group, segment, category, year) %>%
        select(-pop)
    bind_rows(dashboard, rate)
}
