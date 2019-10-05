# functions for estimating participation rate

#' Aggregate population by segment
#' 
#' This is a convenience function to prepare the population data to match
#' the dimension and naming convention needed for joining with participant
#' summaries produced by \code{\link[salic]{est_part}}.
#' 
#' @param pop_seg input population data frame 
#' @param seg name of segment to be stored in output data frame
#' @param var name of input variable to summarize
#' @family functions for estimating participation rate
#' @export
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

#' Add participation rate to summary table for each state
#' 
#' This takes the ratio of the "residents" metric and the population value and
#' combines the result with the input dashboard data frame.
#' 
#' @param dashboard tableau formatted dashboard data
#' @param pop population data prepared with aggregate_pop()
#' @family functions for estimating participation rate
#' @export
est_rate <- function(dashboard, pop) {
    rate <- dashboard %>%
        filter(metric == "residents") %>%
        left_join(pop, by = c("state", "segment", "category", "year")) %>%
        mutate(metric = "rate", value = value / pop) %>%
        arrange(group, segment, category, year) %>%
        select(-pop)
    bind_rows(dashboard, rate)
}
