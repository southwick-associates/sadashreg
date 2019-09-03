# functions for estimating participation rate

# Estimate part. rate based on participant and population counts
est_rate <- function(
    part_estimate, pop_estimate, flag_rate = 50
) {
    joincols <- intersect(names(part_estimate), names(pop_estimate))
    
    out <- left_join(part_estimate, pop_estimate, by = joincols) %>%
        mutate(rate = part / pop)
    
    # warn if the rate is above the threshold in any year
    # reasonable thresholds will vary depending on priv and segment
    filter(out, rate > (flag_rate / 100)) %>%
        warn(paste0("Rate above ", flag_rate, "% in at least one year"))
    select(out, -pop, -part)
}
