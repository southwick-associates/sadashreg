# pull & prepare census population data
# this should be updated each year

library(plyr)
library(tidyverse)
library(salic)

source("analysis/R/part-rate.R")

# Pull Pop Data -----------------------------------------------------------

# by age-sex for each state
pop_seg <- read_csv("E:/SA/Projects/R-Software/Templates/census-template/censusapi/pop-out.csv")
pop_seg <- filter(pop_seg, state %in% state.name) # drop non-states

# total pop by state
pop <- bind_rows(
    get_pop("analysis/pop/data/st-est00int-01.xls", 
            c("state", "drop1", 2000:2009, "drop2", "drop3")),
    get_pop("analysis/pop/data/nst-est2018-01.xlsx", 
            c("state", "drop1", "drop2", 2010:2018))
)

# 2019-specific: extrapolate forward for missing year
pop <- extrapolate_yr(pop, 2019)

# check state-level totals in pop_seg
discrepancy <- group_by(pop_seg, state, year) %>%
    summarise(pop = sum(pop)) %>%
    left_join(pop, by = c("state", "year")) %>%
    mutate( pct_diff = (pop - pop_state) / pop * 100 )
arrange(discrepancy, desc(abs(pct_diff)))

# Prepare Pop Data --------------------------------------------------------

# adjust to match census totals
adjust <- discrepancy %>%
    mutate(ratio = pop_state / pop) %>%
    select(state, year, ratio)

pop_seg <- left_join(pop_seg, adjust, by = c("state", "year")) %>%
    mutate(pop = pop * ratio) %>%
    select(-ratio)

# extrapolate segments for years missing from B01001 table
pop_seg <- bind_rows(pop_seg, extrapolate_yr_seg(pop_seg, pop, 2018, "forward"))
pop_seg <- bind_rows(pop_seg, extrapolate_yr_seg(pop_seg, pop, 2019, "forward"))
pop_seg <- bind_rows(extrapolate_yr_seg(pop_seg, pop, 2009, "back"), pop_seg)
pop_seg <- bind_rows(extrapolate_yr_seg(pop_seg, pop, 2008, "back"), pop_seg)
count(pop_seg, year)

# convert sex/age to dashboard categories
pop_seg <- pop_seg %>% mutate(
    sex_acs = sex, age_acs = age,
    sex = ifelse(sex == "Male", 1L, 2L) %>% factor_sex(),
    agecat = plyr::mapvalues(age, age_map$acs_age, age_map$lic_age) %>% 
        as.integer() %>%
        factor_age()
)
count(pop_seg, agecat, age_acs) %>% data.frame()
count(pop_seg, sex, sex_acs)

# collapse to 7 age categories
pop_seg <- group_by(pop_seg, state, year, sex, agecat) %>%
    summarise(pop = sum(pop)) %>%
    ungroup()

# add state abbreviations
state_names <- data.frame(state_name = state.name, state = state.abb, stringsAsFactors = FALSE)
pop_seg <- pop_seg %>%
    rename(state_name = state) %>%
    left_join(state_names, by = "state_name") %>%
    select(state, year, sex, agecat, pop)

# visualize
group_by(pop_seg, state, year) %>%
    summarise(pop = sum(pop)) %>%
    ggplot(aes(state, pop, color = year)) +
    geom_point() + 
    coord_flip() +
    ggtitle("Total state populations by year")

# Output to CSV -----------------------------------------------------------

write_csv(pop_seg, "analysis/pop/pop_seg.csv")
write_csv(pop, "analysis/pop/pop.csv")
