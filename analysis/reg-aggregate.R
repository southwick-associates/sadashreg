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

# build regional aggregations for selected metric
# this function is a wrapper for agg_region()
# - df: input summary data in tableau input format
# - regs: region to aggregate ("US", "Southeast", etc.)
# - measure: metric to aggregate ("participants", etc.)
# - func: function to use for aggregation ("sum" or "mean")
# - grps: permission groups to aggregate over
agg_region_all <- function(
    df, regs, measure, func, grps = c("all_sports", "hunt", "fish")
) {
    missing_regs <- setdiff(regs, c(unique(df$region), "US"))
    if (length(missing_regs) > 0) {
        message("No records for region(s): ", paste(missing_regs, collapse = ", "))
    }
    sapply2 <- function(...) sapply(..., simplify = FALSE) # for convenience
    agg_region_grp <- function(grps, reg) {
        sapply2( grps, function(grp) agg_region(df, reg, grp, measure, func)) %>% 
            bind_rows() 
    }
    sapply2(regs, function(reg) agg_region_grp(grps, reg)) %>% bind_rows()
}

# build regional averages for selected region, group, and metric
agg_region <- function(df, reg, grp, measure, func) {
    if (reg == "US") df$region <- "US"
    df <- filter(df, group == grp, metric == measure, region == reg)
    if (nrow(df) == 0) return(invisible())
    df <- drop_incomplete_states(df, grp, reg, measure)
    if (too_few_states(df, grp, reg, measure)) return(invisible())
        
    df %>%
        group_by(timeframe, region, group, metric, segment, year, category) %>%
        summarise_at(vars(value), func) %>%
        ungroup() %>%
        mutate(
            aggregation = func, 
            states_included = paste(unique(df$state), collapse = ","),
            state = region
        )
}

# exclude states with missing years from aggregation
# only to be called from agg_region()
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

# determine whether there are insufficient states to perform aggregation
# only to be called from agg_region()
too_few_states <- function(df, grp, reg, measure) {
    states <- unique(df$state)
    if (length(states) < 2) {
        message(measure, ": Only ", length(states), " state(s) included for ", 
                grp, " in ", reg, ", so no aggregation was performed.")
        TRUE
    } else {
        FALSE
    }
}
