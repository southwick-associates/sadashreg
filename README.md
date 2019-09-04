
# Produce national/regional dashboard

Southwick work for preparing all summary data for the national/regional dashboard.

## Dependencies

- Makes use of dashboard-template code for producing summaries and visualizing results (you'll need to refer to it's location on your computer)
- The 1-sa-states.R scripts can only be run from the data server

## Usage

Results for each time-period can be competely reproduced using the code below. In practice the first step (SA-processed states) takes by far the longest to run, and can only be run from the Data Server. 

``` r
# must correctly point to dashboard-template code 
# - https://github.com/southwick-associates/dashboard-template
# - https://github.com/southwick-associates/dashboard-template/tree/visualize

# might store this stuff in a "params.R" or similar
template_directory <- "E:/SA/Projects/R-Software/Templates/dashboard-template" # server
# template_directory <- "" # Dan's laptop

source("2018-q4/code/run.R")
source("2019-q2/code/run.R")
```

## File Organization

- analysis: code, data, output, etc.
- R: functions shared between different time periods
- doc: Part of preparing documentation for state-processed dashboards. Only should need to be updated infrequently (if ever).

### Analysis

- pop: Preparation of population data
- Dashboard production:
    + _old (prototype work, not delivered)
    + 2018-q4 (production)
    + 2019-q2 (production)
    + etc.

### Example Data

For state-processed data documentation stored on O365 (Data Dashboards > _Analyst Docs > Docs to Share with States)

- State-prepared data example: showing expected input for use in dashboards
- Standardized database example: shared with MA to demonstrate structure
