# functions for SA state dashboard summaries

#' Run dashboard summaries for a given permission-timeframe
#' @inheritParams dashtemplate::build_history
#' @inheritParams dashtemplate::format_metrics
#' @family functions for SA state dashboard summaries
#' @export
run_group <- function(
    cust, lic, sale, yrs, timeframe, group, lic_types
) {
    build_history(cust, lic, sale, yrs, timeframe, lic_types) %>%
        calc_metrics(scaleup_test = 30) %>% 
        format_metrics(timeframe, group)
}

#' Run 3 permission summaries for select state in select time period
#' 
#' This basically wraps the entire dashtemplate workflow into 1 function. It
#' optionally writes a csv output based on the outdir argument.
#' 
#' @inheritParams run_group
#' @param st 2-character state abbreviation
#' @param outdir location for output csv (named based on input state).
#' @param output_csv if TRUE, will write a csv to outdir
#' @param groups names of permissions to be summarized
#' @param dir_production folder that holds production data
#' @family functions for SA state dashboard summaries
#' @export
run_state <- function(
    st, yrs, timeframe, outdir, groups = c("all_sports", "hunt", "fish"), 
    output_csv = TRUE, dir_production = "E:/SA/Data-production/Data-Dashboards"
) {
    ### 1. Preparation
    # pull data from sqlite
    f <- file.path(dir_production, st, "license.sqlite3")
    con <- dbConnect(RSQLite::SQLite(), f)
    lic <- tbl(con, "lic") %>% 
        select(lic_id, type, duration) %>%
        collect() %>%
        distinct() # at least one state (OR) doesn't have unique lic_ids
    cust <- tbl(con, "cust") %>%
        select(cust_id, sex, birth_year) %>%
        collect()
    sale <- tbl(con, "sale") %>%
        select(cust_id, lic_id, dot, res) %>%
        collect()
    dbDisconnect(con)
    
    # make sure to use sale year
    sale <- sale %>%
        mutate(dot = lubridate::ymd(dot), year = lubridate::year(dot), 
               month = lubridate::month(dot)) %>%
        filter(year %in% yrs) %>%
        select(-dot)
    
    # some adjustments & data checking
    sale <- filter(sale, !is.na(cust_id)) # not sure why, but we have a few of these
    lic <- filter(lic, !is.na(type), type != "other")
    cust <- mutate(cust, birth_year = ifelse(birth_year < 1900, NA_integer_ , birth_year))
    data_check(cust, lic, sale) %>% print()
    
    ### 2. produce summaries for each permission
    run_group2 <- function(grp, lic_types) {
        if (!grp %in% groups) {
            return(invisible())
        }
        run_group(cust, lic, sale, yrs, timeframe, grp, lic_types)
    }
    out <- bind_rows(
        run_group2("hunt", c("hunt", "trap", "combo")),
        run_group2("fish", c("fish", "combo")),
        run_group2("all_sports", c("hunt", "trap", "fish", "combo"))
    ) %>%
        mutate(year = as.integer(year))
    if (output_csv) {
        dir.create(outdir, showWarnings = FALSE)
        write.csv(out, file = file.path(outdir, paste0(st, ".csv")), 
                  row.names = FALSE)
    }
    out
}
