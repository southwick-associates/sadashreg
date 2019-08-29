# Run by-permission Tableau Production
# Only to be run in the "Build Tableau" section of 1-run-dash.R

# Parameters --------------------------------------------------------------
# Intended to be commented out for production runs

priv_nm <- "hunt"
yrs <- 2009:2018


# Get Data ----------------------------------------------------------------

## 1. Permission-specific Data
con <- dbConnect(RSQLite::SQLite(), file.path(dir_data, state, "history.sqlite3"))
priv <- dbGetQuery(con, paste("SELECT cust_id, year, res, lapse, R3 FROM", priv_nm)) %>%
    filter(year %in% yrs) %>%
    left_join(cust, by = "cust_id") %>%
    label_categories() %>%
    recode_agecat() %>%
    select(cust_id, year, res, lapse, R3, sex, agecat)
dbDisconnect(con)

## 2. Apply Quarterly Filter
# If quarter != 4, need to pull in sales data & filter (see OR 2018-q3 code)

## 3. Apply Age Filter 
# For nat/reg, exclude 0-17 and 65+ 
# TODO: In the future, might need a function if we need special treatment for edge effects
priv <- priv %>%
    filter(agecat != "0-17", agecat != "65+")

## 4. Extrapolate State-specific Population estimates
pop_state <- pop_acs %>%
    filter(state_abbrev == state) %>%
    extrapolate_pop(yrs)


# Estimate ----------------------------------------------------------------

# TODO: still need some conditionals for certain permissions
# - using overall part counts for rates in privileges (doesn't apply to nat/reg though)
# - not running recruit results if there aren't > 5 years of data (probably won't apply to nat/reg)
# - no county breakouts for nonres-specific permissions (again, doesn't apply to nat/reg)


## 1. Participants
part <- list(
    "tot" = est_part(priv)
)
for (i in c("res", "sex", "agecat")) {
    part[[i]] <- est_part(priv, i, flag_change = 13) %>% 
        scaleup_part(part[["tot"]])
}

## 2. Resident Participants
# (mostly an intermediate results for rate estimation)
priv_resident <- priv %>%
    filter(res == "Resident")

part_resident <- list(
    "tot" = filter(part[["res"]], res == "Resident") %>% select(-res)
)
for (i in c("sex", "agecat")) {
    part_resident[[i]] <- est_part(priv_resident, i, flag_change = 15) %>% 
        scaleup_part(part_resident[["tot"]], flag_na = 10)
} 

## 3. Participation rate
rate <- list()
for (i in names(part_resident)) {
    pop <- est_pop(pop_state, i)
    rate[[i]] <- est_rate(part_resident[[i]], pop)
}

# residency-specific rates are also included, which is a bit weird but helps on the Tableau end
rate[["res"]] <- part[["res"]] %>%
    left_join(select(rate[["tot"]], year, rate), by = "year") %>%
    mutate(rate = ifelse(res == "Nonresident", 0, rate))

## 4. New recruits
priv_recruit <- priv %>%
    filter(!is.na(R3), R3 == "Recruit")

part_recruit <- list(
    "tot" = est_part(priv_recruit)
)
for (i in c("res", "sex", "agecat")) {
    part_recruit[[i]] <- est_part(priv_recruit, i, flag_change = 15) %>% 
        scaleup_part(part_recruit[["tot"]])
} 

## 5. churn rate
churn <- list(
    "tot" = est_churn(priv)
)
for (i in c("res", "sex", "agecat")) {
    churn[[i]] <- est_churn(priv, i, flag_change = 15)
}


# Save to RDATA -----------------------------------------------------------

# TODO: Is this step actually needed?
# It seems potentially useful to have...but in reality?
# MO-hunt.rds, MO-fish.rds, IA-hunt.rds, ...
# maybe more useful to output a single tableau-formatted table at this stage

# results <- list(part, rate, part_recruit, churn)
# names(results) <- c("part", "rate", "recruit", "churn")
# write_rds(results, "file location with permission name")


# Format for Tableau ------------------------------------------------------

# Can probably do something quite similar to the format_metric(), format_grp()
# functions used in the previous iteration

# could potentially leave it to the very end (after all permissions are run)
# this makes for (potentially) more easily-accessible estimates
# at least for a program (e.g., a simple dashboard)



