suppressPackageStartupMessages(library(fixest))

options(digits = 17)

input_file <- "panel_v1.csv"
d <- read.csv(input_file, stringsAsFactors = FALSE, check.names = FALSE)

required <- c("state_id", "month", "treated", "adoption_date", "opioid_rate")
stopifnot(all(required %in% names(d)))

d$month_date <- as.Date(d$month)
d$adoption_date_parsed <- as.Date(d$adoption_date)

stopifnot(
  nrow(d) == 2400L,
  length(unique(d$state_id)) == 40L,
  length(unique(d$month_date)) == 60L,
  !anyDuplicated(d[c("state_id", "month_date")]),
  !anyNA(d[required]),
  all(table(d$state_id) == 60L),
  all(table(d$month_date) == 40L),
  all(d$treated %in% c(0L, 1L)),
  all(vapply(split(d$treated, d$state_id), function(x) length(unique(x)) == 1L, logical(1)))
)

state_treatment <- unique(d[c("state_id", "treated", "adoption_date_parsed")])
stopifnot(
  nrow(state_treatment) == 40L,
  sum(state_treatment$treated == 1L) == 20L,
  sum(state_treatment$treated == 0L) == 20L,
  all(state_treatment$adoption_date_parsed[state_treatment$treated == 1L] == as.Date("2021-01-01")),
  all(is.na(state_treatment$adoption_date_parsed[state_treatment$treated == 0L]))
)

d$policy_on <- as.integer(
  d$treated == 1L &
    !is.na(d$adoption_date_parsed) &
    d$month_date >= d$adoption_date_parsed
)
stopifnot(sum(d$policy_on) == 20L * 24L)

# fixest's default small-sample correction is deliberately left unchanged.
model <- feols(
  opioid_rate ~ policy_on | state_id + month_date,
  data = d,
  cluster = ~state_id
)
model_summary <- summary(model)
ct <- coeftable(model_summary)
ci <- confint(model_summary, level = 0.95)

result <- data.frame(
  term = rownames(ct),
  estimate = unname(ct[, "Estimate"]),
  std_error = unname(ct[, "Std. Error"]),
  t_value = unname(ct[, "t value"]),
  p_value = unname(ct[, "Pr(>|t|)"]),
  conf_low_95 = unname(ci[, 1L]),
  conf_high_95 = unname(ci[, 2L]),
  n_obs = nobs(model),
  n_states = length(unique(d$state_id)),
  n_months = length(unique(d$month_date)),
  cluster_variable = "state_id",
  fixed_effects = "state_id + month_date",
  outcome = "opioid_rate",
  outcome_units = "monthly opioid-prescribing rate per 100,000",
  fixest_version = as.character(packageVersion("fixest")),
  ssc_K_adj = TRUE,
  ssc_K_fixef = "nonnested",
  ssc_G_adj = TRUE,
  ssc_G_df = "min",
  ssc_t_df = "min",
  inference_df = attr(model_summary$cov.scaled, "df.t"),
  stringsAsFactors = FALSE
)

diagnostics <- data.frame(
  check = c(
    "rows", "states", "months", "duplicate_state_month_rows",
    "missing_required_cells", "treated_states", "never_treated_states",
    "treated_state_months", "model_observations"
  ),
  value = c(
    nrow(d), length(unique(d$state_id)), length(unique(d$month_date)),
    anyDuplicated(d[c("state_id", "month_date")]), sum(is.na(d[required])),
    sum(state_treatment$treated == 1L), sum(state_treatment$treated == 0L),
    sum(d$policy_on), nobs(model)
  ),
  stringsAsFactors = FALSE
)

result_export <- result
numeric_stat_columns <- c(
  "estimate", "std_error", "t_value", "p_value", "conf_low_95", "conf_high_95"
)
result_export[numeric_stat_columns] <- lapply(
  result_export[numeric_stat_columns], sprintf, fmt = "%.17g"
)
write.csv(result_export, "did_results_full_precision.csv", row.names = FALSE, na = "")
write.csv(diagnostics, "validation_diagnostics.csv", row.names = FALSE, na = "")
saveRDS(model, "did_model.rds")
writeLines(capture.output(sessionInfo()), "session_info.txt")

print(result)
