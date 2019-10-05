# package-level documentation & imports

#' @import dplyr salic
#' @importFrom stats lm predict
#' @importFrom utils write.csv
NULL

if (getRversion() >= "2.15.1") {
    utils::globalVariables(
        c("category", "group", "metric", "pop", "pop_state", "ratio", "region",
          "segment", "state", "timeframe", "value", "year", "birth_year",
          "cust_id", "dot", "duration", "lic_id", "res", "sex", "type",
          "value_ref", "value_sum")
    )
}

#' dashreg: Produce national/regional dashboards
#' 
#' Overview of the core functions for each step in dashboard production
#' 
#' @section 1. Prepare summaries using license data (sa-states):
#' \itemize{
#'   \item use \code{\link{run_state}} to produce dashboard metrics for selected
#'   state (which is partly a wrapper for \code{\link{run_group}})
#'   \item based on the dashtemplate package functions 
#'   \code{\link[dashtemplate]{build_history}}, 
#'   \code{\link[dashtemplate]{calc_metrics}}, 
#'   and \code{\link[dashtemplate]{format_metrics}}
#' }
#' 
#' @section 2. Prepare summaries provided directly by states:
#' \itemize{
#'   \item use \code{\link{scale_segs}} if provided segments don't scale to the total.
#'   \item use \code{\link{est_residents}} if resident breakouts weren't provided.
#'   \item use \code{\link{est_lm}} with \code{\link{predict_lm}} if you need to
#'   smooth out artifacts (see 2018-q4 for an example using Florida)
#' }
#' 
#' @section 3. Participation rates:
#' \itemize{
#'   \item use \code{\link{aggregate_pop}} to prepare population data for rate calculation.
#'   \item use \code{\link{est_rate}} to estimate participation rates
#' }
#'
#' @section 4. Combine states and Compute National/Regional Metrics:
#' \itemize{
#'   \item use \code{\link{agg_region_all}} to build regional aggregations
#'   \item this calls \code{\link{agg_region}}
#' }
#'
#' @section Prepare ACS population data for participation rate estimates:
#' \itemize{
#'   \item use \code{\link{get_pop}} to pull the reference state totals from
#'   census "popest" data stored in excel files
#'   \item use \code{\link{extrapolate_yr}} to impute demographic estimates
#'   based on state-level totals
#' }
#' 
#' @docType package
#' @name dashreg
NULL
