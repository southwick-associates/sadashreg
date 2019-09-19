
# TODO - Coding

## 2018 Q4

- Adjustment for part. rate
    + use resident-only for SA data, pegging totals to res for state-supplied
- apply to 2019 Q2

### Nat/Reg-level Results

- fill in NE 2009/2014 using trend >> only for reg/nat estimation
- weighted averages for churn and rates
- might need a slightly different way of calculating part rate

### 2019 q2

- apply above to 2019 Q2 (mostly just copy/paste code)

### Later

- peg national/regional to counts of hunters/anglers. This is complicated by a couple of factors:
    + only looking at 18-64 year-olds
    + not obvious how nonresidents should be counted

# TODO - Other

- begin writing up methodology doc, this can serve as a reference for communication
    + can use metric defs, etc. from existing state-supplied data documentation
    + include specifics that relate to the nat/reg dashboard
    + also reference individual state methods docs
    
### Later

- maybe exclude .csv files from git & move to public SA repo
    + see about removing commit history prior to some point to avoid making any data available

## Methods Planning

- drop 2009 since there is something up in FL for that year
    + also means that churn shows up in default base year (that's good)

- how will regions be defined? Are some states to be included in multiple regions? Does it even really make sense to attempt to scale up?
- will mid-year will lack participants/recruits for nat/reg?
- will exclude 2009 (2014 recruits) from nat/regs with incomplete early years (everything except Northwest)

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
