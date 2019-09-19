# Workflow to smooth out FL hunting data artifact beginning in 2015
# hopefully won't be needed in 2019-q4 (will want repull of 2019-q2 as well)

### To be called from 2-other-states.R ###

# Notes -------------------------------------------------------------------

### Hunting
# applies to most categories (all, 45+, resident, female, male)
# applies to mid-year & full-year

# churn in 2015: avg of 2014/2016 
# part in 2015+: extrapolate based on linear trend from 2009 to 2014
# recruit in 2015+: extrapolate based on participants trend (used above)

### Fishing & overall? (for 2019)
# alternative 1: apply smoothing for 2009, similar to what is done for hunt below
# alternative 2: exclude 2009 for all national/regional trends (and FL)
# alternative 3: leave it be (probably don't want this)

# Perform Adjustment -----------------------------------------------------------

# FL summary
df <- x

ignore_cats <- c("Nonresident", "18-24", "25-34")
cats <- setdiff(unique(df$category), ignore_cats)

# adjust full-year churn
if (timeframe == "full-year") {
    new16 <- df %>%
        filter(metric == "churn", !category %in% ignore_cats, year %in% c(2015, 2017)) %>%
        group_by(timeframe, group, segment, category, metric) %>%
        summarise(value = mean(value)) %>% 
        ungroup() %>%
        mutate(year = 2016)
    df <- df %>%
        anti_join(new16, by = c("timeframe", "group", "segment", "category", "metric", "year")) %>%
        bind_rows(new16)
}

# adjust participants
yrs_ref <- 2010:2014
yrs_adjust <- setdiff(yrs, c(2009, yrs_ref))

if (timeframe == "full-year") {
    mod_lm <- est_lm(df, yrs_ref, "participants", "hunt", cats)
    df <- predict_lm(df, mod_lm, yrs_adjust, "participants", "hunt", cats)
    
    # adjust recruits
    df <- predict_lm(df, mod_lm, yrs_adjust, "recruits", "hunt", cats)
    grps <- "hunt"
    
} else {
    # being a bit repetitive for expediency
    grps <- c("hunt", "fish", "all_sports")
    for (i in grps) {
        mod_lm <- est_lm(df, yrs_ref, "participants", i, cats)
        df <- predict_lm(df, mod_lm, yrs_adjust, "participants", i, cats)
        df <- predict_lm(df, mod_lm, yrs_adjust, "recruits", i, cats)
    }
    
}

# - additional adjustment needed since we are using a participant-based model
adjust <- filter(df, year == 2014, metric %in% c("recruits", "participants"), 
                 !category %in% ignore_cats, group %in% grps) %>%
    spread(metric, value) %>%
    mutate(adjust = recruits / participants) %>%
    select(-recruits, -participants, -year) %>%
    mutate(metric = "recruits")

df <- left_join(df, adjust) %>%
    mutate(value = ifelse(is.na(adjust) | year == 2014, value, value * adjust)) %>%
    select(-adjust)

x <- df