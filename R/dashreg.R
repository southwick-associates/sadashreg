# package-level documentation & imports

#' @import dplyr salic
#' @importFrom stats lm predict
NULL

if (getRversion() >= "2.15.1") {
    utils::globalVariables(
        c("category", "group", "metric", "pop", "pop_state", "ratio", "region",
          "segment", "state", "timeframe", "value", "year")
    )
}
