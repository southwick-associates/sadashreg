# Shared functions

# TODO: salic: 
#   1. move functions to salic and document well


# Get Census Data ---------------------------------------------------------

## convenience function: collapse to 7 age categories (from larger number of acs age cats)
## TODO: probably won't actually use this
# imports dplyr
# aggregate_pop <- function(pop_county) {
#     group_by(pop_county, county_fips, year, sex, age) %>%
#         summarise(pop = sum(pop)) %>%
#         ungroup()
# }

## convience function: convert numeric category vars to factor
# imports dplyr, salic
label_categories <- function(df) {
    eligible_cats <- c("age", "R3", "sex", "res")
    df_cats <- intersect(eligible_cats, names(df))
    
    for (i in df_cats) {
        f <- get(paste0("df_factor_", i)) # e.g., df_factor_age, etc.
        df <- f(df, i)
    } 
    df
}

## Extrapolate population forward for years in which estimates are not yet available
# imports dplyr
extrapolate_pop <- function(pop_acs, yrs) {
    
    yrs_to_extrapolate <- yrs[yrs > max(pop_acs$year)]
    
    if (length(yrs_to_extrapolate) == 0) {
        return(pop_acs) # no extrapolation needed
    } 
    if (length(yrs_to_extrapolate) > 1) {
        warning(paste(
            "Extrapolating population estimates more than one year forward.", 
            "Newer census estimates may be available (see '_Shared' code)."
        ))
    }
    # estimate statewide % change per year
    # simplistic method, but probably fine if only for 1 year
    growth_rate <- group_by(pop_acs, year) %>%
        summarise(pop = sum(pop)) %>%
        mutate(change = pop / lag(pop)) %>% 
        summarise(mean(change, na.rm = TRUE)) %>%
        pull()

    # extrapolate forward
    extrapolate_yr <- function(yr) {
        yrs_forward <- yr - max(pop_acs$year)
        filter(pop_acs, year == max(year)) %>% 
            mutate(year = yr, pop = pop * growth_rate^yrs_forward)
    }
    lapply(yrs_to_extrapolate, extrapolate_yr) %>% 
        bind_rows(pop_acs)
}



# Estimate ----------------------------------------------------------------

## helper function: print a warning if any records are flagged
# flagged   data frame containing flagged rows
# msg       message to be printed in warning
warn <- function(flagged, msg) {
    flagged <- data.frame(flagged)
    if (nrow(flagged) > 0) {
        warning(msg, "\n", paste(capture.output(print(flagged)), collapse = "\n"), 
                call. = FALSE)
    } 
}

## Estimate participants by year (and optional segment) from history table
# a simple count of records per year with some built-in tests
# expects a correctly standardized history table
est_part <- function(
    priv, segment = NULL, flag_change = 10, show_test_stat = FALSE
) {
    # records where segment (e.g., age) is NA shouldn't be included in this count
    if (!is.null(segment)) priv <- filter(priv, !is.na(!! as.name(segment)))
    
    # participants is a simple count of records by year
    out <- priv %>%
        group_by_at(c(segment, "year")) %>%
        summarise(part = n()) %>%
        mutate(pct_change = (part - lag(part)) / lag(part) * 100)
    
    # warn if the % change threshold is passed in any year
    # a big change in a year, especially compared to other years, is usually a problem
    filter(out, pct_change > flag_change) %>%
        warn(paste0("Annual % change above ", flag_change, "% in at least one year"))
    
    # output
    if (!show_test_stat) out <- select(out, -pct_change) 
    ungroup(out)
}

## Scale demographic estimates to ensure they correctly sum to total participants
# This is necessary since some percentage of customers have missing values
scaleup_part <- function(
    part_segment, part_total, flag_na = 8, show_test_stat = FALSE
) {
    # a scale factor needs to be computed by comparing to total counts by year
    compare <- part_segment %>%
        group_by(year) %>%
        summarise(part_segment = sum(part)) %>%
        left_join(select(part_total, year, part), by = "year") %>%
        mutate(pct_na = (part - part_segment) / part * 100,
               scale_factor = part / part_segment)
    
    # warn if % missing in the segment passes the threshold (for any year)
    # high % calls missing at random assumption into question
    filter(compare, pct_na > flag_na) %>% 
        warn(paste0("Missing ", names(part_segment)[1], " above ", flag_na,  
                    "% in at least one year"))

    # scale to match the total - assumes missing at random
    out <- part_segment %>%
        left_join(select(compare, year, pct_na, scale_factor), by = "year") %>%
        mutate(part = round(part * scale_factor, 0) %>% as.integer()) %>%
        select(-scale_factor)
    
    # a final check of the scaled total
    diff <- abs(sum(out$part) - sum(part_total$part))
    if (diff > 50) { # allows for a small amount of slippage
        warning("Something might have gone wrong in scaling since the segment sum of ",
                sum(out$part), " is different than the total of ", sum(part_total$part))
    }
    
    if (!show_test_stat) out <- select(out, -pct_na) 
    out
}

## Estimate population for given segment
est_pop <- function(pop_acs, segment) {
    if (segment == "tot") segment <- NULL
    pop_acs %>%
        group_by_at(unique(c(segment, "year"))) %>%
        summarise(pop = sum(pop)) %>%
        ungroup()
}

## Estimate rate based on participant and population counts
est_rate <- function(
    part_estimate, pop_estimate, flag_rate = 50
) {
    joincols <- intersect(names(part_estimate), names(pop_estimate))
    
    out <- left_join(part_estimate, pop_estimate, by = joincols) %>%
        mutate(rate = part / pop)
    
    # warn if the rate is above the threshold in any year
    # reasonable thresholds will vary depending on priv and segment
    filter(out, rate > (flag_rate / 100)) %>%
        warn(paste0("Rate above ", flag_rate, "% in at least one year"))
    out
}

## Esimate churn rate
est_churn <- function(
    priv, segment = NULL, flag_change = 10, show_test_stat = FALSE
) {
    # records where segment (e.g., age) is NA shouldn't be included in this estimate
    if (!is.null(segment)) priv <- filter(priv, !is.na(!! as.name(segment)))
    
    # churn is a simple lapse % per year
    out <- priv %>%
        group_by_at(c(segment, "year")) %>%
        summarise(churn = mean(lapse)) %>%
        mutate(pct_change = (churn - lag(churn)) / lag(churn) * 100) %>%
        ungroup()
    
    # shifting one year forward so current year always has a value
    # hence churn = % of last years buyers who didn't renew this year
    lastyr <- max(out$year)
    out <- mutate(out, year = year + 1) %>%
        filter(year != lastyr + 1)
    
    # warn if the % change threshold is passed in any year
    # a big change in a year, especially compared to other years, is usually a problem
    filter(out, pct_change > flag_change) %>%
        warn(paste0("Annual % change above ", flag_change, "% in at least one year"))
    
    # output
    if (!show_test_stat) out <- select(out, -pct_change) 
    ungroup(out)
}
