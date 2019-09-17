# functions for estimating participation rate

# TODO: complete documentation for part-rate & reg-aggregate

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
