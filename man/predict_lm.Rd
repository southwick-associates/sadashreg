% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/adjustments.R
\name{predict_lm}
\alias{predict_lm}
\title{Apply smooothing based on linear model}
\usage{
predict_lm(df_all, mod, yrs, met, grp, cats)
}
\arguments{
\item{df_all}{summary results in data frame}

\item{mod}{linear model produced by \code{\link{est_lm}}}

\item{yrs}{years to be estimated using linear model}

\item{met}{selected metric (from df_all$metric)}

\item{grp}{selected group (from df_all$group)}

\item{cats}{selected category (from df_all$category)}
}
\description{
Developed in Sep 2019 to adjust for data artifact in FL hunting data
}
\seealso{
Other functions to adjust state results: 
\code{\link{est_lm}()},
\code{\link{est_residents}()},
\code{\link{scale_segs}()}
}
\concept{functions to adjust state results}
