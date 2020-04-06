
# sadashreg

An R package to process summary data for national/regional dashboards.

## Installation

From the R console:

``` r
install.packages("remotes")
remotes::install_github("southwick-associates/sadashreg")
```

## Usage

Run `?sadashreg` from the R console for a function reference. A template workflow for processing a single state can be setup using [lictemplate](https://github.com/southwick-associates/lictemplate):

```r
lictemplate::new_project_summary("FL", "2019-q4")
## A new summary data dashboard project has been initialized:
##  E:/SA/Projects/Data-Dashboards/FL/2019-q4
```

Code that pulls all regional results together also makes use of functions in this package, stored on the server: `E:/SA/Projects/Data-Dashboards/_Regional/`
