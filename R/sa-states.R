# functions for SA state dashboard summaries

#' Run dashboard summaries for a given permission-timeframe
#' 
#' This is just a wrapper for 3 functions from package dashtemplate, which store
#' the workflow for producing national/regional summary data from standardized
#' license data.
#' 
#' @inheritParams dashtemplate::build_history
#' @inheritParams dashtemplate::calc_metrics
#' @inheritParams dashtemplate::format_metrics
#' @family functions for SA state dashboard summaries
#' @seealso dashtemplate functions: 
#' \code{\link[dashtemplate]{build_history}} 
#' \code{\link[dashtemplate]{calc_metrics}}
#' \code{\link[dashtemplate]{format_metrics}}
#' @export
run_group <- function(
    cust, lic, sale, yrs, timeframe, group, lic_types,
    tests = c(tot = 20, res = 35, sex = 35, agecat = 35),
    scaleup_test = 30
) {
    dashtemplate::build_history(cust, lic, sale, yrs, timeframe, lic_types) %>%
        dashtemplate::calc_metrics(tests, scaleup_test) %>% 
        dashtemplate::format_metrics(timeframe, group)
}

#' Run 3 permission summaries for select state in select time period
#' 
#' This basically wraps the entire dashtemplate workflow into 1 function by (1)
#' loading sqlite data, (2) applying some minor recoding and data checks, and (3)
#' Applying \code{\link{run_group}} across the provided groups. 
#' It returns a summary dataset (formatted for Tableau) and optionally writes 
#' a csv output based on the outdir argument. The state-level csv files will
#' ultimately be combined into 1 national/regional file.
#' 
#' @inheritParams run_group
#' @param st 2-character state abbreviation
#' @param outdir location for output csv (named based on input state).
#' @param output_csv if TRUE, will write a csv to outdir
#' @param groups names of permissions to be summarized
#' @param db_license file path to production data
#' @param ... additional arguments passed to \code{\link{run_group}}
#' @family functions for SA state dashboard summaries
#' @export
run_state <- function(
    st, yrs, timeframe, outdir, groups = c("all_sports", "hunt", "fish", "bow"), 
    output_csv = TRUE, 
    db_license = file.path("E:/SA/Data-production/Data-Dashboards", st, "license.sqlite3"),
    ...
) {
    ### 1. Preparation
    # pull data from sqlite
    con <- DBI::dbConnect(RSQLite::SQLite(), db_license)
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
    DBI::dbDisconnect(con)
    
    # make sure to use sale year
    sale <- sale %>%
        mutate(
            dot = lubridate::ymd(dot), 
            year = lubridate::year(dot),  
            month = lubridate::month(dot)
        ) %>%
        filter(year %in% yrs) %>%
        select(-dot)
    
    # some adjustments & data checking
    sale <- filter(sale, !is.na(cust_id)) # not sure why, but we have a few of these
    lic <- filter(lic, !is.na(type), type != "other")
    cust <- mutate(cust, birth_year = ifelse(birth_year < 1900, NA_integer_ , birth_year))
    data_check(cust, lic, sale)
    
    ### 2. produce summaries for each permission
    run_group2 <- function(grp, lic_types, ...) {
        if (!grp %in% groups) {
            return(invisible())
        }
        run_group(cust, lic, sale, yrs, timeframe, grp, lic_types, ...)
    }
    out <- bind_rows(
        run_group2("hunt", c("hunt", "trap", "combo"), ...),
        run_group2("fish", c("fish", "combo"), ...),
        run_group2("all_sports", c("hunt", "trap", "fish", "combo"), ...),
        run_group2("bow", c("bow","bowcombo"), ...)
    ) %>%
        mutate(year = as.integer(year))
    if (output_csv) {
        dir.create(outdir, showWarnings = FALSE)
        write.csv(out, file = file.path(outdir, paste0(st, ".csv")), 
                  row.names = FALSE)
    }
    out
}
