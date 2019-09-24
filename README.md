
# Produce national/regional dashboard

Southwick project: Prepare all summary data for the national/regional dashboard.

## Installation

You can install the package dependencies using the devtools package:

``` r
# salic
devtools::install_github("southwick-associates/salic")

# dashtemplate - need to use server since package docs aren't included in repo
devtools::install("E:/SA/Projects/R-Software/Templates/dashboard-template")

# dashreg - in this project directory
devtools::install()
```

## Usage

The workflow consists of R scripts and data stored in the "analysis" directory. Functions for this project have been documented and packaged into "dashreg", stored at the top-level in the standard locations (R/, DESCRIPTION, etc). 

START HERE - New results need to be produced for each time-period (2018-q4, 2019-q2, etc.). You can run `?dashreg` from R for an overview of the functions. 

``` r
# must correctly point to dashboard-template code 
# - https://github.com/southwick-associates/dashboard-template
# - https://github.com/southwick-associates/dashboard-template/tree/visualize

# might store this stuff in a "params.R" or similar
template_directory <- "E:/SA/Projects/R-Software/Templates/dashboard-template" # server
# template_directory <- "" # Dan's laptop

source("analysis/run.R")
```

## File/Folder Organization

### R

Functions (package sadashreg) used in the analysis

### Analysis

Includes code, data, output, etc.

- pop: Preparation of population data (to be updated each year)
- Dashboard production:
    + _old (prototype work, not delivered)
    + 2018-q4 (production)
    + 2019-q2 (production)
    + etc.
    
### Docs

Part of preparing documentation for state-processed dashboards. Only should need to be updated infrequently (if ever).

#### Example Data

For state-processed data documentation stored on O365 (Data Dashboards > _Analyst Docs > Docs to Share with States)

- State-prepared data example: showing expected input for use in dashboards
- Standardized database example: shared with MA to demonstrate structure
