
## Tidying up

- use ?dashreg documentation as an entry point (introduction) to the functions
    + probably want to detail the workflow in the Usage section of README
    + maybe organize sections according to files in R/
- take a quick run look through code comments (& documentation generally) to get things ready for the next iteration.

## Prepare Documentation

- write up methodology doc, this can serve as a reference for communication
    + can use metric defs, etc. from existing state-supplied data documentation
    + include specifics that relate to the nat/reg dashboard
    + also reference individual state methods docs
    
- weighted averages for churn & part. rate? (probably we do want this)

## Future Iterations

- probably peg national/regional to counts of hunters/anglers? This is complicated by a couple of factors:
    + only looking at 18-64 year-olds
    + not obvious how nonresidents should be counted
    + no clear way to include mid-year results
- improve dashreg function documentation (e.g., better descriptions)

## Data Status Notes: 14 states (sep 2019)

Missing data is particularly relevant for national/regional averages.

### Awaiting data pulls

- AK: just waiting
- GA: missing 2009 (2014 for recruits) & 2017/2018
- IA: hunting numbers are a bit underestimated
- MA: 
- TX: 

### States with (mostly) finalized data

- FL: data artifact for 2015 (smoothed out by Dan)
- MO: no missings
- NE: missing 2009 (2014 for recruits)
- OR: no missings
- SC: no missings
- TN: only includes all_sports group
- WI: no missings
- VA: no missings
