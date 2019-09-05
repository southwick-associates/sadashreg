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
aggregate_region <- function(df, reg, func, measure) {
    grps <- c("timeframe", "region", "group", "metric", "segment", "year", "category")
    func <- if (func == "SUM") "sum" else "mean"
    
    df <- filter(df, metric == measure)
    if (reg == "US") {
        df$region <- "US"
    } else {
        df <- filter(df, region == reg)
        if (nrow(df) == 0) return(invisible())
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

# TODO: can this be made more modular and intelligible?
# - maybe pull tests into separate funcs: few_states() [1 or none], incomplete_states()
agg_region <- function(
    df, reg = "US", grp = "all_sports", measure = "participants", func = "sum"
) {
    if (reg == "US") df$region <- "US"
    df <- filter(df, group == grp, metric == measure, region == reg)
    if (nrow(df) == 0) return(invisible())
    df <- drop_incomplete_states(df, grp, reg, measure)
    # check_few_states()
        
    df %>%
        group_by(timeframe, region, group, metric, segment, year, category) %>%
        summarise_at(vars(value), func) %>%
        ungroup() %>%
        mutate(
            aggregation = func, 
            states_included = paste(unique(df$state), collapse = ", ")
        )
}

drop_incomplete_states <- function(df, grp, reg, measure) {
    drop_states <- df %>%
        distinct(state, year) %>%
        count(state) %>%
        filter(n < max(n)) %>%
        pull(state)
    df <- filter(df, !state %in% drop_states)
    if (length(drop_states) > 0) {
        message(measure, ": States with incomplete data (", 
                paste(drop_states, collapse = ", "), 
                ") were excluded for ", grp, " ", reg)
    }
    df
}
