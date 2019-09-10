# functions to make adjustments to deal with data artifacts, etc.
# written in Sep 2019 for smoothing FL results

# estimate smoothing factor (using linear regression)
# - df_all: summary results in data frame
# - yrs: years that will be used for linear trend estimation
# - met: metric to model
# - grp: group to model
# - cats: categories to model
est_lm <- function(
    df_all, yrs, met, grp, cats
) {
    df <- df_all %>%
        filter(metric == met, group == grp, year %in% yrs, category %in% cats)
    split(df, df$category) %>%
        lapply(function(x) lm(value ~ year, x))
} 

# apply smooothing based on linear model
# - mod: linear model from est_lm()
# - yrs: years to be estimated based on mod
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
