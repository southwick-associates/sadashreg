# pull & prepare census population data

library(plyr)
library(tidyverse)
library(salic)

source("R/part-rate.R")

# Pull Pop Data -----------------------------------------------------------

# by age-sex for each state
pop_seg <- read_csv("../census-template/censusapi/pop-out.csv")

# total pop by state
pop <- bind_rows(
    get_pop("2018-q4/data/nst-est2018-01.xlsx", c("state", "drop1", "drop2", 2010:2018)),
    get_pop("2018-q4/data/st-est00int-01.xls", c("state", "drop1", 2000:2009, "drop2", "drop3"))
)

# check state-level totals
discrepancy <- group_by(pop_seg, state, year) %>%
    summarise(pop = sum(pop)) %>%
    left_join(pop, by = c("state", "year")) %>%
    mutate( pct_diff = (pop - pop_state) / pop * 100 )
arrange(discrepancy, desc(abs(pct_diff)))

# Prepare Pop Data --------------------------------------------------------

# only include 50 states (i.e., exclude Puerto Rico & DC)
pop_seg <- filter(pop_seg, state %in% state.name)

# adjust to match census totals
adjust <- discrepancy %>%
    mutate(ratio = pop_state / pop) %>%
    select(state, year, ratio)

pop_seg <- left_join(pop_seg, adjust, by = c("state", "year")) %>%
    mutate(pop = pop * ratio) %>%
    select(-ratio)

# extrapolate segments for years missing from B01001 table
pop_seg <- bind_rows(pop_seg, extrapolate_yr(pop_seg, pop, 2018, "forward"))
pop_seg <- bind_rows(extrapolate_yr(pop_seg, pop, 2009, "back"), pop_seg)
pop_seg <- bind_rows(extrapolate_yr(pop_seg, pop, 2008, "back"), pop_seg)

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
    summarise(pop = sum(pop))

# visualize
group_by(pop_seg, state, year) %>%
    summarise(pop = sum(pop)) %>%
    ggplot(aes(state, pop, color = year)) +
    geom_point() + 
    coord_flip() +
    ggtitle("Total state populations by year")

# Output to CSV -----------------------------------------------------------

dir.create("data/census", showWarnings = FALSE)
write_csv(pop_seg, "data/census/pop_seg.csv")
