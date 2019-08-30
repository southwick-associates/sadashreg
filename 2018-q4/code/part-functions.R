

## convenience function: aggregate population data to 7 age categories
# (i.e., collapse the larger number of census age categories)
aggregate_pop <- function(pop_county) {
    pop_county %>%
        group_by(county_fips, year, sex, age) %>% # collapse to 7 age categories
        summarise(pop = sum(pop)) %>%
        ungroup()
}

## Extrapolate population forward for years in which estimates are not yet available
# imports dplyr
extrapolate_pop <- function(pop_acs, yrs) {
    
    yrs_to_extrapolate <- yrs[yrs > max(pop_acs$year)]
    
    if (length(yrs_to_extrapolate) == 0) {
        return(pop_acs) # no extrapolation needed
    } 
    if (length(yrs_to_extrapolate) > 1) {
        warning(paste(
            "Extrapolating population estimates more than one year forward.", 
            "Newer census estimates may be available (see '_Shared' code)."
        ))
    }
    # estimate statewide % change per year
    # it's a simplistic method, but probably fine our purposes
    growth_rate <- group_by(pop_acs, year) %>%
        summarise(pop = sum(pop)) %>%
        mutate(change = pop / lag(pop)) %>% 
        summarise(mean(change, na.rm = TRUE)) %>%
        pull()
    
    # extrapolate forward
    extrapolate_yr <- function(yr) {
        yrs_forward <- yr - max(pop_acs$year)
        filter(pop_acs, year == max(year)) %>% 
            mutate(year = yr, pop = pop * growth_rate^yrs_forward)
    }
    lapply(yrs_to_extrapolate, extrapolate_yr) %>% 
        bind_rows(pop_acs)
}

## Estimate part. rate based on participant and population counts
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

## Estimate monthly sales
est_month <- function(x, dashboard_yrs, grp = "tot") {
    
    # one leading year needed for monthly comparisons
    month_yrs <- c(dashboard_yrs[1]-1, dashboard_yrs)
    
    x <- x %>%
        filter(year %in% month_yrs) %>%
        count(year, month) %>%
        rename(value = n, category = month) %>%
        mutate(segment = "month", category = as.character(category))
    
    if (grp == "tot") {
        x <- mutate(x, metric = "participants")
    } else {
        x <- mutate(x, metric = "participants - recruited")
    }
    x
}

