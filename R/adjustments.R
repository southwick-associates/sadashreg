# functions to make adjustments to deal with data artifacts, etc.

# TODO: call scale_generic() from est_residents()

# Segment Adjustments & Estimates -----------------------------------------

#' Peg segment breakouts to total
#' 
#' This is necessary when state-supplied segment breakouts weren't scaled to
#' match totals.
#' 
#' @inheritParams est_residents
#' @family functions to adjust state results
#' @export
scale_segs <- function(df) {
    # churn doesn't need to be scaled
    part <- filter(df, metric != "churn")
    df_churn <- filter(df, metric == "churn") # for stacking at the end
    
    # reference: total participants/recruits
    tot <- filter(part, segment == "all") 
    ref <- tot %>%
        select(-category, -segment) %>%
        rename(value_ref = value)
    
    seg <- filter(part, segment != "all") %>%
        scale_generic(ref)
    bind_rows(df_churn, tot, seg) %>%
        arrange(group, metric, segment, category, year)
}

# helper function for scaling
# - seg: segments to scale
# - ref: refernce totals
scale_generic <- function(
    seg, ref, byvars = c("timeframe", "group", "year", "metric")
) {
    seg <- seg %>%
        group_by(group, segment, metric, year) %>%
        mutate(value_sum = sum(value)) %>%
        ungroup()
    
    seg <- seg %>%
        left_join(ref, byvars) %>%
        mutate(value = value * value_ref / value_sum) %>%
        select(-value_sum, -value_ref) 
    
    # check
    not_summed <- group_by(seg, group, year, segment, metric) %>%
        summarise(value = sum(value)) %>%
        left_join(ref, by = c("group", "year", "metric")) %>%
        filter(round(value,0) != round(value_ref,0))
    if (nrow(not_summed) > 1) {
        warning("Output result doesn't sum to total residents.",
                " Check your work!")
    }
    seg
}

#' Estimate resident breakouts
#' 
#' This was needed in Sep 2019 since state's didn't provided resident breakouts
#' (oversite on Dan's part). It makes a naive assumption that the demographic
#' distributions for overall match residents. This probably isn't too egregious
#' since residents usually dominate the total numbers.
#' 
#' @param df data frame that holds table of summary results
#' @return Returns a data frame with input df stacked with resident summaries
#' @family functions to adjust state results
#' @export
est_residents <- function(df) {
    # breakouts to be scaled down to residents
    part <- filter(df, metric == "participants", category != "Nonresident")
    
    # reference: total residents
    ref <- filter(df, metric == "participants", category == "Resident") %>%
        rename(value_ref = value) %>%
        select(-category, -segment)
    
    res <- part %>%
        group_by(group, segment, year) %>%
        mutate(value_sum = sum(value)) %>%
        ungroup()
    res <- res %>%
        left_join(ref, by = c("timeframe", "group", "year", "metric")) %>%
        mutate(
            value = value * value_ref / value_sum,
            metric = "residents"
        ) %>%
        select(-value_sum, -value_ref) 
    
    # check
    not_summed <- group_by(res, group, year, segment) %>%
        summarise(value = sum(value)) %>%
        left_join(ref, by = c("group", "year")) %>%
        filter(round(value,0) != round(value_ref,0))
    if (nrow(not_summed) > 1) {
        warning("Output result doesn't sum to total residents.",
                " Check your work!")
    }
    bind_rows(df, res)
}

# Artifact Smoothing ------------------------------------------------------

#' Estimate smoothing factor (using linear regression)
#' 
#' Developed in Sep 2019 to adjust for data artifact in FL hunting data
#' 
#' @param df_all summary results in data frame
#' @param yrs years that will be used for linear trend estimation
#' @param met selected metric (from df_all$metric)
#' @param grp selected group (from df_all$group)
#' @param cats selected category (from df_all$category)
#' @family functions to adjust state results
#' @export
est_lm <- function(df_all, yrs, met, grp, cats) {
    df <- df_all %>%
        filter(metric == met, group == grp, year %in% yrs, category %in% cats)
    split(df, df$category) %>%
        lapply(function(x) lm(value ~ year, x))
} 

#' Apply smooothing based on linear model
#' 
#' Developed in Sep 2019 to adjust for data artifact in FL hunting data
#' 
#' @inheritParams est_lm
#' @param mod linear model produced by \code{\link{est_lm}} 
#' @param yrs years to be estimated using linear model
#' @family functions to adjust state results
#' @export
predict_lm <- function(
    df_all, mod, yrs, met, grp, cats
) {
    est_cat <- function(mod, df) {
        x <- filter(df, metric == met, group == grp, year %in% yrs, category %in% cats)
        if (nrow(x) == 0) return(df)
        x$value <- predict(mod, x)
        df %>%
            anti_join(x, by = c("timeframe", "group", "segment", "category", "metric", "year")) %>%
            bind_rows(x)
    }
    out <- split(df_all, df_all$category)
    sapply(names(out), function(cat) est_cat(mod[[cat]], out[[cat]]), simplify = FALSE) %>%
        bind_rows()
} 
