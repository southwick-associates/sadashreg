# functions for estimating participation rate

library(readxl)

# load reference state total population
# https://www.census.gov/data/tables/time-series/demo/popest/2010s-state-total.html
# https://www2.census.gov/programs-surveys/popest/tables/2000-2010/intercensal/state/
get_pop <- function(filename, col_names) {
    read_excel(filename, skip = 9, n_max = 51, col_names = col_names) %>%
        select(-contains("drop")) %>%
        gather(year, pop_state, -state) %>%
        mutate(state = str_replace(state, ".", ""), year = as.numeric(year))
}

# extrapolate segments for missing years
# using most recent year distributions & reference population totals
extrapolate_yr <- function(pop_seg, pop, yr, direction) {
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
age_map <- tribble(
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

# Estimate part. rate based on participant and population counts
est_rate <- function(
    part_estimate, pop_estimate, flag_rate = 50
) {
    joincols <- intersect(names(part_estimate), names(pop_estimate))
    
    out <- left_join(part_estimate, pop_estimate, by = joincols) %>%
        mutate(rate = part / pop)
    
    # warn if the rate is above the threshold in any year
    # reasonable thresholds will vary depending on priv and segment
    filter(out, rate > (flag_rate / 100)) %>%
        warn(paste0("Rate above ", flag_rate, "% in at least one year"))
    select(out, -pop, -part)
}
