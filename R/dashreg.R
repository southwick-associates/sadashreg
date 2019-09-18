# package-level documentation & imports

#' @import dplyr salic dashtemplate DBI
#' @importFrom stats lm predict
#' @importFrom utils write.csv
NULL

if (getRversion() >= "2.15.1") {
    utils::globalVariables(
        c("category", "group", "metric", "pop", "pop_state", "ratio", "region",
          "segment", "state", "timeframe", "value", "year", "birth_year",
          "cust_id", "dot", "duration", "lic_id", "res", "sex", "type")
    )
}
