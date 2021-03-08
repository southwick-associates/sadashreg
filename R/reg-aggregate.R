# functions for preparing regional & national metrics

#' Relation table for states by region
#' 
#' @format A data frame with 10 rows and 2 variables:
#' \describe{
#'   \item{state}{2-character state abbreviation}
#'   \item{region}{region to be used in dashboard}
#' }
#' @family sadashreg data
"region_relate"


#' Build regional aggregations for selected metric
#' 
#' Basically a wrapper for \code{\link{agg_region}} that applies to multiple 
#' regions and groups.
#' 
#' @param df input summary data in tableau input format
#' @param regs regions over which to aggregate
#' @param measure metric to aggregate ("participants", etc.)
#' @param func function to use for aggregation ("sum" or "mean")
#' @param grps permission groups to aggregate over
#' @export
#' @family functions for preparing regional & national metrics
agg_region_all <- function(
    df, regs, measure, func, grps = c("all_sports", "hunt", "fish", "bow")
) {
    missing_regs <- setdiff(regs, c(unique(df$region), "US"))
    if (length(missing_regs) > 0) {
        message("No records for region(s): ", paste(missing_regs, collapse = ", "))
    }
    sapply2 <- function(...) sapply(..., simplify = FALSE) # for convenience
    agg_region_grp <- function(grps, reg) {
        sapply2(grps, function(grp) agg_region(df, reg, grp, measure, func)) %>% 
            bind_rows() 
    }
    sapply2(regs, function(reg) agg_region_grp(grps, reg)) %>% bind_rows()
}

#' Build regional averages for selected region, group, and metric.
#' 
#' To be called from \code{\link{agg_region_all}}
#' 
#' @inheritParams agg_region_all
#' @param reg region over which to aggregate
#' @param grp group over which to aggregate
#' @export
#' @family functions for preparing regional & national metrics
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

#' Exclude states with missing years from aggregation
#' 
#' To be called from \code{\link{agg_region}}
#' 
#' @inheritParams agg_region
#' @export
#' @family functions for preparing regional & national metrics
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

#' Determine whether there are insufficient states to perform aggregation
#' 
#' To be called from \code{\link{agg_region}}
#' 
#' @inheritParams agg_region
#' @export
#' @family functions for preparing regional & national metrics
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
