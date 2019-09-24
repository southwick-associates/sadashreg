# estimate participation rates & output to out-rate folder

library(tidyverse)
library(salic)
library(dashreg)

# source("analysis/2019-q2/params.R") # needs to be adjusted for time periods

indir <- file.path(dir, "out")
outdir <- file.path(dir, "out-rate")

# Load Data ----------------------------------------------------------------

# load pop data
# note that population data should be updated once per year
# (i.e., as new estimates become available from American Community Survey)
pop_seg <- read_csv("analysis/pop/pop_seg.csv") %>%
    filter(!agecat %in% c("0-17", "65+")) %>%
    mutate(sex = tolower(sex))

# load dashboard data for each state
get_state <- function(f) {
    st <- str_sub(f, end = 2)
    read_csv(file.path(indir, f)) %>%
        # apply some standardization
        mutate_at(vars(group, segment, category, metric), "tolower") %>%
        mutate(
            state = st,
            category = ifelse(category == "non-resident", "nonresident", category)
        )
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
group_by(df, metric) %>% summarise(min(value), mean(value), max(value))

# Estimate Rates ----------------------------------------------------------

# produce population summaries by segment
pop <- bind_rows(
    aggregate_pop(pop_seg, "gender", "sex"),
    aggregate_pop(pop_seg, "age", "agecat"),
    aggregate_pop(pop_seg, "all", "all")
) 

# add participation rates
x <- lapply(x, function(dashboard) est_rate(dashboard, pop))

# Save Results ------------------------------------------------------------

dir.create(outdir, showWarnings = FALSE)
for (i in names(x)) {
    filter(x[[i]], metric != "residents") %>%
        write_csv(file.path(outdir, i))
}
