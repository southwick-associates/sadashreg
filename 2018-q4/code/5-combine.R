# stack together all states

library(tidyverse)
indir <- "2018-q4/out"
outfile <- "full-year2018.csv"

# pull all results
get_state <- function(f) {
    st <- str_sub(f, end = 2)
    read_csv(file.path(indir, f)) %>%
        mutate(state = st)
}
infiles <- list.files(indir)
x <- sapply(infiles, get_state, simplify = FALSE) %>% bind_rows()


# Finalize ----------------------------------------------------------------

x <- bind_rows(x)

# other stuff
x <- x %>% 
    mutate_at(vars(group, segment, category, metric), "tolower") %>%
    # try to correct this earlier
    mutate(category = ifelse(category == "non-resident", "nonresident", category))

count(x, group)
count(x, segment)
count(x, category)
count(x, metric)
count(x, year)

# write to output
write_csv(x, file.path("out", outfile))
