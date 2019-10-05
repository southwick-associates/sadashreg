
# Produce national/regional dashboards

For Southwick internal use: Prepare all summary data for the national/regional dashboard.

## Installation

Install using devtools:

``` r
# salic
devtools::install_github("southwick-associates/salic")

# dashtemplate - need to use server since package docs aren't included in repo
devtools::install("E:/SA/Projects/R-Software/Templates/dashboard-template")

# dashreg
devtools::install_github("southwick-associates/dashreg")
```

## Usage

The workflow consists of R scripts and data stored in the analysis directory. Functions for this project have been documented and packaged into dashreg, stored at the top-level in the usual locations (R/, DESCRIPTION, etc). 

New results need to be produced for each time-period (2018-q4, 2019-q2, etc.). You can run `?dashreg` from R for an overview of the functions. The `analysis/run.R` script is the entry point to running the full analysis for each time period. There is currently a fair amount of period-specific tweaking, but that will hopefully decrease as data received from states becomes more predictable.

Note that summary data files produced by the analysis are not tracked in git (i.e., not stored in this repo).

## Folder Organization

### R

Functions (package dashreg) used in the analysis

### Analysis

Includes code, data, output, etc.

- pop: Preparation of population data (to be updated each year)
- Dashboard production:
    + 2018-q4
    + 2019-q2
    + etc.
