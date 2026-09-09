suppressPackageStartupMessages(library(fixest))

build_id <- "build_b02233208"
run_id <- "run_20260909T074302Z"
input_file <- "panel_v1.csv"
input_sha256 <- "02233208ed1646c22685a408d91d4bdc7f5fe73bdffc58f3df0229362b30e6fe"
out_dir <- file.path("artifacts", run_id)
if (dir.exists(out_dir)) stop("Refusing to overwrite immutable run: ", run_id)
dir.create(out_dir, recursive = TRUE)

d <- read.csv(input_file, stringsAsFactors = FALSE)
d$month <- as.Date(d$month)
d$adoption_date[d$adoption_date == ""] <- NA_character_
d$adoption_date <- as.Date(d$adoption_date)

required <- c("state_id", "month", "treated", "adoption_date", "opioid_rate")
stopifnot(all(required %in% names(d)))
stopifnot(nrow(d) == 2400L, length(unique(d$state_id)) == 40L,
          length(unique(d$month)) == 60L)
stopifnot(!anyDuplicated(d[c("state_id", "month")])) # panel key is 1:1
stopifnot(!anyNA(d[required[c(1, 2, 3, 5)]]))
state_treatment <- unique(d[c("state_id", "treated", "adoption_date")])
stopifnot(nrow(state_treatment) == 40L, sum(state_treatment$treated == 1L) == 20L,
          sum(state_treatment$treated == 0L) == 20L)
stopifnot(all(state_treatment$adoption_date[state_treatment$treated == 1L] == as.Date("2021-01-01")),
          all(is.na(state_treatment$adoption_date[state_treatment$treated == 0L])))

d$post_treat <- as.integer(d$treated == 1L & d$month >= as.Date("2021-01-01"))
d$month_index <- as.integer(format(d$month, "%Y")) * 12L + as.integer(format(d$month, "%m"))
adoption_index <- 2021L * 12L + 1L
d$event_time <- d$month_index - adoption_index

main <- feols(opioid_rate ~ post_treat | state_id + month, data = d,
              cluster = ~state_id)

# Required parallel-trends diagnostic: event study with month -1 omitted.
event <- feols(opioid_rate ~ i(event_time, treated, ref = -1) |
                 state_id + month, data = d, cluster = ~state_id)
lead_names <- grep("event_time::-[0-9]+:treated", names(coef(event)), value = TRUE)
b_lead <- coef(event)[lead_names]
v_lead <- vcov(event)[lead_names, lead_names, drop = FALSE]
wald_stat <- as.numeric(t(b_lead) %*% solve(v_lead, b_lead))
wald_df <- length(b_lead)
wald_p <- pchisq(wald_stat, df = wald_df, lower.tail = FALSE)

ct <- coeftable(main)
estimate <- unname(ct["post_treat", "Estimate"])
se <- unname(ct["post_treat", "Std. Error"])
df_t <- attr(vcov(main), "dof.K")
if (is.null(df_t)) df_t <- length(unique(d$state_id)) - 1L
crit <- qt(0.975, df = length(unique(d$state_id)) - 1L)

results <- data.frame(
  build_id = build_id, run_id = run_id, term = "post_treat",
  estimate = estimate, std_error = se,
  conf_low_95 = estimate - crit * se, conf_high_95 = estimate + crit * se,
  t_value = unname(ct["post_treat", "t value"]),
  p_value = unname(ct["post_treat", "Pr(>|t|)"]),
  n_obs = nobs(main), n_states = length(unique(d$state_id)),
  outcome = "monthly opioid-prescribing rate per 100,000",
  fixed_effects = "state_id + month", cluster = "state_id",
  fixest_version = as.character(packageVersion("fixest")),
  stringsAsFactors = FALSE
)
diagnostics <- data.frame(
  build_id = build_id, run_id = run_id,
  diagnostic = "joint_zero_pre_treatment_event_study_coefficients",
  statistic = wald_stat, df = wald_df, p_value = wald_p,
  omitted_event_month = -1L, stringsAsFactors = FALSE
)
validation <- data.frame(
  rows = nrow(d), states = length(unique(d$state_id)),
  months = length(unique(d$month)), treated_states = sum(state_treatment$treated == 1L),
  never_treated_states = sum(state_treatment$treated == 0L),
  duplicate_state_month_keys = sum(duplicated(d[c("state_id", "month")])),
  missing_outcomes = sum(is.na(d$opioid_rate)), source_vintages = length(unique(d$source_vintage))
)

options(digits = 17)
write.csv(results, file.path(out_dir, "main_estimate.csv"), row.names = FALSE, na = "")
write.csv(diagnostics, file.path(out_dir, "diagnostics.csv"), row.names = FALSE, na = "")
write.csv(validation, file.path(out_dir, "validation.csv"), row.names = FALSE, na = "")
saveRDS(list(main_model = main, event_study = event, results = results,
             diagnostics = diagnostics, validation = validation),
        file.path(out_dir, "models_and_results.rds"), version = 3)

manifest <- c(
  paste0("canonical_run: ", run_id),
  paste0("build_id: ", build_id),
  paste0("timestamp_utc: 2026-09-09T07:43:02Z"),
  "inputs:",
  paste0("  - file: ", input_file),
  paste0("    sha256: ", input_sha256),
  paste0("build_code: analysis_build_b02233208.R"),
  "specification: opioid_rate ~ post_treat | state_id + month; cluster = state_id; fixest default SSC",
  "estimand: average post-adoption policy effect on monthly opioid-prescribing rate per 100,000 among adopting states",
  "comparison: adopting versus never-adopting states, before versus after 2021-01-01",
  "identifying_assumption: absent adoption, mean outcome trends would have been parallel across adopting and never-adopting states",
  "missing_value_rule: fail validation for missing state, month, treated, or outcome; no rows dropped",
  "panel_key: state_id + month (1:1; asserted unique)",
  "outputs:",
  paste0("  - ", out_dir, "/main_estimate.csv"),
  paste0("  - ", out_dir, "/diagnostics.csv"),
  paste0("  - ", out_dir, "/validation.csv"),
  paste0("  - ", out_dir, "/models_and_results.rds")
)
writeLines(manifest, "manifest.yaml")
print(results)
print(diagnostics)
