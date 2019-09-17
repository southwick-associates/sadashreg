# functions to make adjustments to deal with data artifacts, etc.

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
