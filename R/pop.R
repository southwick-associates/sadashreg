# functions/data for acs population estimates

#' Relation table for acs to dashboard age categories
#' 
#' @format A data frame with 23 rows and 2 variables:
#' \describe{
#'   \item{lic_age}{numeric code for dashboard age category}
#'   \item{acs_age}{category from census}
#' }
#' @family sadashreg data
"age_map"

#' Load reference state total population
#' 
#' https://www.census.gov/data/tables/time-series/demo/popest/2010s-state-total.html
#' https://www2.census.gov/programs-surveys/popest/tables/2000-2010/intercensal/state/
#' 
#' @param filename path to excel data file
#' @param col_names names to use for columns (passed to \code{\link[readxl]{read_excel}})
#' @family functions for acs population estimates
#' @export
get_pop <- function(filename, col_names) {
    filename %>%
        readxl::read_excel(skip = 9, n_max = 51, col_names = col_names) %>%
        select(-contains("drop")) %>%
        tidyr::gather(year, pop_state, -state) %>%
        mutate(state = stringr::str_replace(state, ".", ""), year = as.numeric(year))
}

#' Extrapolate (forward) overall state population for 1 missing year
#' 
#' This function naively assumes percent change is the same as the previous year.
#' 
#' @param pop population data frame
#' @param yr year to be estimated
#' @family functions for acs population estimates
#' @export
extrapolate_yr <- function(pop, yr) {
    pct_change <- pop %>%
        filter(year %in% c(yr-1, yr-2)) %>%
        arrange(year) %>%
        group_by(state) %>%
        mutate(pct_change = (pop_state - lag(pop_state)) / pop_state) %>%
        filter(year == yr-1) %>%
        select(-pop_state, -year)
    newyr <- pop %>%
        filter(year == yr-1) %>%
        left_join(pct_change, by = "state") %>%
        mutate(
            pop_state = pop_state + (pop_state * pct_change),
            year = yr
        ) %>%
        select(-pct_change)
    bind_rows(pop, newyr)
}

#' Extrapolate by-segment state population for missing years
#' 
#' Uses most recent year distributions and pegs to reference state totals
#' for the year estimated.
#' 
#' @param pop_seg census sex-by-age data frame (by state)
#' @param  pop census by state population data frame
#' @param yr year to be extrapolated
#' @param direction either "forward" (future) or "backward"
#' @family functions for acs population estimates
#' @export
extrapolate_yr_seg <- function(pop_seg, pop, yr, direction) {
    if (direction == "forward") {
        yr_compare = yr - 1
        compare <- function(x) lag(x)
    } else {
        yr_compare = yr + 1
        compare <- function(x) lead(x)
    }
    ref <- pop %>%
        filter(year %in% c(yr, yr_compare)) %>%
        arrange(state, year) %>%
        group_by(state) %>%
        mutate(ratio = pop_state / compare(pop_state)) %>%
        ungroup() %>%
        select(state, year, ratio)
    pop_seg %>%
        filter(year == yr_compare) %>%
        mutate(year = yr) %>%
        left_join(ref, by = c("state", "year")) %>%
        mutate(pop = pop * ratio) %>%
        select(-ratio)
}
