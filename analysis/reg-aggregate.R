# functions for nat/reg aggregated metrics

region_relate <- tibble::tribble(
    ~state, ~region,
    "FL", "Southeast",
    "GA", "Southeast",
    "IA", "Midwest",
    "MO", "Midwest",
    "NE", "Midwest",
    "OR", "Northwest",
    "SC", "Southeast",
    "TN", "Southeast",
    "VA", "Southeast",
    "WI", "Midwest"
)

# build regional averages
# - df: input data
# - func: function to use for aggregation (SUM or AVG)
# - metrics: metrics to be aggregated
# - nat: if TRUE, aggregate all states
agg_region <- function(
    dashboard, func = "SUM", metrics = c("participants", "participants - recruited"), 
    nat = FALSE
) {
    grp <- c("region", "timeframe", "group", "metric", "segment", "year", "category")
    if (nat) grp <- setdiff(grp, "region")
    func <- if (func == "SUM") "sum" else "mean"
    
    x <- dashboard %>%
        filter(metric %in% metrics) %>%
        group_by_at(grp) %>%
        summarise_at("value", func) %>%
        ungroup() %>%
        mutate(aggregation = func)
    if (nat) x$region <- "US"
    x$state <- x$region # so that "state" can be used for any geographic dimension
    x
}

aggregate_region <- function(df, reg, func, measure) {
    grps <- c("timeframe", "region", "group", "metric", "segment", "year", "category")
    func <- if (func == "SUM") "sum" else "mean"
    
    df <- filter(df, metric == measure)
    if (reg == "US") {
        df$region <- "US"
    } else {
        df <- filter(df, region == reg)
    }
    # function for 1 group ("hunt", "fish", "all_sports") & metric
    aggregate_group <- function(df, grp) {
        y <- filter(df, group == grp)
        if (nrow(y) == 0) {
            message(measure, ": No states included for ", grp, " ", reg)
            return(invisible())
        }
        # exclude incomplete states (i.e., missing 1 or more years)
        drop_states <- distinct(y, state, year) %>%
            count(state) %>%
            filter(n < max(n)) %>%
            pull(state)
        y <- filter(y, !state %in% drop_states)
        if (length(drop_states) > 0) {
            message(measure, ": States with incomplete data (", 
                    paste(drop_states, collapse = ", "), 
                    ") were excluded for ", grp, " ", reg)
        }
        # no aggregation if only 1 state
        states <- unique(y$state)
        if (length(states) < 2) {
            message(measure, ": Only ", length(states), " state(s) included for ", 
                    grp, " in ", reg, ", so no aggregation was performed.")
            return(invisible())
        }
        # run aggregation
        group_by_at(y, grps) %>%
            summarise_at("value", func) %>%
            ungroup() %>%
            mutate(aggregation = func, states_included = paste(states, collapse = ", "))
    }
    x <- lapply(unique(df$group), function(grp) aggregate_group(df, grp)) %>% bind_rows()
    if (nrow(x) > 1) {
        mutate(x, state = region)
    }
}

# aggregate_region(dashboard, "US", "SUM", "recruits")
# 
# filter(dashboard, metric == "recruits", group == "all_sports") %>%
#     group_by_at(grps) %>%
#     summarise(value = sum(value)) %>%
#     ungroup()


# TODO: can this be made more modular and intelligible?
# - maybe pull tests into separate funcs: few_states() [1 or none], incomplete_states()
agg_reg <- function(df, reg = "US", grp = "all_sports", measure, func = "sum") {
    
}
    