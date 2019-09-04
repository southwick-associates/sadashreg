
# TODO

- Get updated dataset to Ben (combine.R)
    + exclude 2009 from national results (and regional when not present for 1 or more states). Probably can code this into the aggregation function actually
    + stack in mid-year results (probably use timeframe instead of quarter column)
    
- Follow-up with FL, MA, etc. (maybe give the southeast states a bit of extra time)
    + hopefully an easy fix, analysts from both states used R, so that is a big plus
- determine how missing values will be dealt with (probably just exclude 2009)

## Data Status Notes: 14 states

Missing data is particularly relevant for national/regional averages.

### Awaiting data pulls

- AK: just waiting
- GA: missing 2009 (2014 for recruits) & 2017/2018
- IA: hunting numbers are a bit underestimated
- MA: probably will exclude for now
- PA: i doubt we'll get data from them
- TX: summary data expected in the next 2 weeks
- WI: missing 2016, 2017, 2018

### States with (mostly) finalized data

- FL: data artifact for 2015, I can smooth it out, but will discuss with FL folks
- MO: no missings
- NE: missing 2009 (2014 for recruits)
- OR: no missings
- SC: no missings
- TN: only includes all_sports group
- VA: no missings

## Mid-Year

Need to get more data for this, we'll see

## Validation

- sniff test to make sure things don't look off
- are the measures complete?
- do segments all sum to totals?

## Averages with missing values

Presenting avgs is a problem with all the missing data. My thinking is that for any particular measure, we can assume that the missing values moved in the same way as the values that we have. For example, if we don't have participation rate for TN in 2008, we assume the TN impact on the average is the same as TN's impact in 2009 (i.e., the states without missing values are essentially estimating a % change measure)


## State Notes (Temporary)

### MA

- no all_sports
- no mid-year
- any data issues?

### NE

- data are incomplete
- churn doesn't follow year conventions (missing for 2018), probably means it needs to be set forward one year
- all_sports is missing certain data (at least participants)
- any other issues?

### FL

- will take a look

### TN

- only all sports

### IA

- hunting data has some issues (still awaiting response)
- no fishing nonresidents in 2008 (basically IA doesn't seem to have much of any nonres fishing licenses)
