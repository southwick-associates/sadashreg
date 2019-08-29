# stack together all states

library(tidyverse)

get_state <- function(f) {
    st <- str_sub(f, end = 2)
    read_csv(file.path("out", f)) %>%
        mutate(state = st)
}
infiles <- list.files("out")
x <- sapply(infiles, get_state, simplify = FALSE) %>% bind_rows()
count(x, state, year) %>%
    spread(year, n)

x <- x %>% 
    mutate_at(vars(group, segment, category, metric), "tolower") %>%
    mutate(category = ifelse(category == "non-resident", "nonresident", category))

count(x, group)
count(x, segment)
count(x, category)
count(x, metric)
count(x, year)

# write to output
write_csv(x, file.path("../out", "full-year2018.csv"))
