# estimate participation rates
# overwrites existing CSV files (temporary laziness)

library(tidyverse)
library(salic)

source("R/part-rate.R")
indir <- "2018-q4/out"

# Load Data ----------------------------------------------------------------

# load pop data
pop_seg <- read_csv("data/census/pop_seg.csv") %>%
    filter(!agecat %in% c("0-17", "65+"))

# load summary data
get_state <- function(f) {
    st <- str_sub(f, end = 2)
    x <- read_csv(file.path(indir, f)) %>%
        # apply some standardization
        mutate_at(vars(group, segment, category, metric), "tolower") %>%
        mutate(
            state = st,
            category = ifelse(category == "non-resident", "nonresident", category)
        )
    # some cleanup from previous script
    x$value_sum <- NULL
    x$value_tot <- NULL
    x
}
infiles <- list.files(indir)
x <- sapply(infiles, get_state, simplify = FALSE)

# some checking
df <- bind_rows(x)
count(df, group)
count(df, segment)
count(df, category)
count(df, metric)
count(df, year)

# Estimate Rates ----------------------------------------------------------

state_names <- data.frame(state_name = state.name, state = state.abb, stringsAsFactors = FALSE)
pop_seg <- mutate(pop_seg, sex = tolower(sex))

# summarize population for joining
summarize_pop <- function(df, seg = "gender", var = "sex") {
    if (seg == "all") {
        df$category <- "all"
    } else {
        df$category <- df[[var]]
    }
    group_by(df, state, year, category) %>% 
        summarise(pop = sum(pop)) %>%
        mutate(segment = seg) %>%
        ungroup()
}
pop <- bind_rows(
    summarize_pop(pop_seg, "gender", "sex"),
    summarize_pop(pop_seg, "age", "agecat"),
    summarize_pop(pop_seg, "all", "all")
) %>%
    rename(state_name = state) %>%
    left_join(state_names, by = "state_name") %>%
    select(-state_name)

# estimate part rate for each state
est_rate <- function(df) {
    rate <- filter(df, metric == "participants", segment != "residency") %>%
        left_join(pop) %>%
        mutate(metric = "rate", value = value / pop) %>%
        arrange(group, segment, category, year) %>%
        select(-pop)
    bind_rows(df, rate)
}
x <- lapply(x, est_rate)

# Save Results ------------------------------------------------------------

dir.create("2018-q4/out-rate", showWarnings = FALSE)
for (i in names(x)) write_csv(x[[i]], file.path("2018-q4", "out-rate", i))
