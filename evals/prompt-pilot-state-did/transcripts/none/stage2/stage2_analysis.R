suppressPackageStartupMessages(library(fixest))

options(digits = 17)
input_file <- "panel_v1.csv"
input_md5 <- unname(tools::md5sum(input_file))
d <- read.csv(input_file, stringsAsFactors = FALSE, check.names = FALSE)

required <- c("state_id", "region", "month", "treated", "adoption_date", "opioid_rate")
stopifnot(all(required %in% names(d)), !anyNA(d[required]))
d$month_date <- as.Date(d$month)
d$adoption_date_parsed <- as.Date(d$adoption_date)
d$time_index <- as.integer(factor(d$month_date, levels = sort(unique(d$month_date)))) - 1L
d$region <- factor(d$region, levels = c("North", "South", "East", "West"))
d$policy_on <- as.integer(
  d$treated == 1L & !is.na(d$adoption_date_parsed) &
    d$month_date >= d$adoption_date_parsed
)

stopifnot(
  nrow(d) == 2400L,
  length(unique(d$state_id)) == 40L,
  length(unique(d$month_date)) == 60L,
  !anyDuplicated(d[c("state_id", "month_date")]),
  all(table(d$state_id) == 60L),
  all(table(d$month_date) == 40L),
  identical(levels(d$region), c("North", "South", "East", "West")),
  !anyNA(d$region),
  sum(d$policy_on) == 480L
)

state_info <- unique(d[c("state_id", "region", "treated", "adoption_date_parsed")])
region_composition <- as.data.frame.matrix(
  xtabs(~ region + treated, data = state_info), stringsAsFactors = FALSE
)
region_composition$region <- rownames(region_composition)
rownames(region_composition) <- NULL
names(region_composition)[names(region_composition) == "0"] <- "never_treated_states"
names(region_composition)[names(region_composition) == "1"] <- "treated_states"
region_composition <- region_composition[c("region", "treated_states", "never_treated_states")]
stopifnot(all(region_composition$treated_states > 0L), all(region_composition$never_treated_states > 0L))

heterogeneity_formula <- opioid_rate ~ policy_on:region | state_id + month_date
trend_formula <- opioid_rate ~ policy_on | month_date + state_id[time_index]

heterogeneity_model <- feols(
  heterogeneity_formula, data = d, cluster = ~state_id
)
trend_model <- feols(
  trend_formula, data = d, cluster = ~state_id
)

extract_result <- function(model, specification, formula_text) {
  s <- summary(model)
  ct <- coeftable(s)
  ci <- confint(s, level = 0.95)
  out <- data.frame(
    specification = specification,
    term = rownames(ct),
    estimate = unname(ct[, "Estimate"]),
    std_error = unname(ct[, "Std. Error"]),
    t_value = unname(ct[, "t value"]),
    p_value = unname(ct[, "Pr(>|t|)"]),
    conf_low_95 = unname(ci[, 1L]),
    conf_high_95 = unname(ci[, 2L]),
    n_obs = nobs(model),
    n_states = length(unique(d$state_id)),
    formula = formula_text,
    cluster_variable = "state_id",
    input_file = input_file,
    input_md5 = input_md5,
    fixest_version = as.character(packageVersion("fixest")),
    ssc_K_adj = TRUE,
    ssc_K_fixef = "nonnested",
    ssc_G_adj = TRUE,
    ssc_G_df = "min",
    ssc_t_df = "min",
    inference_df = attr(s$cov.scaled, "df.t"),
    stringsAsFactors = FALSE
  )
  out
}

results <- rbind(
  extract_result(
    heterogeneity_model,
    "pooled_region_specific",
    "opioid_rate ~ policy_on:region | state_id + month_date"
  ),
  extract_result(
    trend_model,
    "state_specific_linear_trends",
    "opioid_rate ~ policy_on | month_date + state_id[time_index]"
  )
)

numeric_stats <- c("estimate", "std_error", "t_value", "p_value", "conf_low_95", "conf_high_95")
results_export <- results
results_export[numeric_stats] <- lapply(results_export[numeric_stats], sprintf, fmt = "%.17g")

write.csv(results_export, "stage2_results_full_precision.csv", row.names = FALSE, na = "")
write.csv(region_composition, "stage2_region_composition.csv", row.names = FALSE, na = "")
saveRDS(heterogeneity_model, "stage2_region_model.rds")
saveRDS(trend_model, "stage2_trend_model.rds")
writeLines(capture.output(sessionInfo()), "stage2_session_info.txt")
print(region_composition)
print(results)
