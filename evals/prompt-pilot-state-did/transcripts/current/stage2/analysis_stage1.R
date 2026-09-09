#!/usr/bin/env Rscript

suppressPackageStartupMessages(library(fixest))

input_path <- "panel_v1.csv"
results_dir <- "results"
dir.create(results_dir, showWarnings = FALSE, recursive = TRUE)

panel <- read.csv(input_path, stringsAsFactors = FALSE)
required <- c("state_id", "month", "treated", "adoption_date", "opioid_rate")
stopifnot(all(required %in% names(panel)))

# why: a state-month panel must have one observation per fixed-effect cell.
assert_unique_state_month <- function(x) {
  stopifnot(!anyDuplicated(x[c("state_id", "month")]))
}
bad_fixture <- rbind(panel[1, ], panel[1, ])
stopifnot(inherits(try(assert_unique_state_month(bad_fixture), silent = TRUE), "try-error"))
assert_unique_state_month(panel)

na_counts <- colSums(is.na(panel))
write.csv(data.frame(variable = names(na_counts), missing = unname(na_counts)),
          file.path(results_dir, "missingness.csv"), row.names = FALSE)
stopifnot(all(na_counts[required] == 0))

panel$month <- as.Date(panel$month)
panel$adoption_date <- as.Date(panel$adoption_date)
state_summary <- aggregate(cbind(treated, population) ~ state_id, panel,
                           function(x) length(unique(x)))
stopifnot(nrow(state_summary) == 40L)
stopifnot(all(state_summary$treated == 1L), all(state_summary$population == 1L))

state_treatment <- aggregate(treated ~ state_id, panel, unique)
stopifnot(sum(state_treatment$treated == 1L) == 20L)
stopifnot(sum(state_treatment$treated == 0L) == 20L)

months <- sort(unique(panel$month))
counts_by_month <- table(panel$month)
counts_by_state <- table(panel$state_id)
stopifnot(length(unique(counts_by_month)) == 1L, unname(counts_by_month[1]) == 40L)
stopifnot(length(unique(counts_by_state)) == 1L,
          unname(counts_by_state[1]) == length(months))
stopifnot(nrow(panel) == 40L * length(months))

adopters <- panel$treated == 1L
stopifnot(all(panel$adoption_date[adopters] == as.Date("2021-01-01")))
stopifnot(all(is.na(panel$adoption_date[!adopters])))
panel$post <- as.integer(panel$month >= as.Date("2021-01-01"))
panel$policy <- panel$treated * panel$post

month_index <- as.integer(format(panel$month, "%Y")) * 12L +
  as.integer(format(panel$month, "%m"))
adoption_index <- 2021L * 12L + 1L
panel$event_time <- ifelse(panel$treated == 1L, month_index - adoption_index, -1L)

# why: state FE remove time-invariant state differences; month FE remove common shocks.
# why: state clustering allows arbitrary serial correlation within a state's panel.
main_model <- feols(opioid_rate ~ policy | state_id + month,
                    data = panel, cluster = ~state_id)
stopifnot(nobs(main_model) == nrow(panel))

event_model <- feols(opioid_rate ~ i(event_time, treated, ref = -1) |
                       state_id + month,
                     data = panel, cluster = ~state_id)
lead_names <- names(coef(event_model))[grepl("event_time::-[0-9]+:treated", names(coef(event_model)))]
stopifnot(length(lead_names) > 0L)
pretrend <- wald(event_model, keep = "event_time::-[0-9]+:treated")

ct <- coeftable(main_model)
beta <- unname(ct["policy", "Estimate"])
se <- unname(ct["policy", "Std. Error"])
df_cluster <- length(unique(panel$state_id)) - 1L
critical <- qt(0.975, df = df_cluster)
treated_pre_mean <- mean(panel$opioid_rate[panel$treated == 1L & panel$post == 0L])
result <- data.frame(
  term = "policy",
  estimate = beta,
  std_error = se,
  t_statistic = unname(ct["policy", "t value"]),
  p_value = unname(ct["policy", "Pr(>|t|)"]),
  conf_low_95 = beta - critical * se,
  conf_high_95 = beta + critical * se,
  treated_pre_mean = treated_pre_mean,
  effect_percent_of_treated_pre_mean = 100 * beta / treated_pre_mean,
  n_obs = nobs(main_model),
  n_states = length(unique(panel$state_id)),
  cluster_df = df_cluster,
  treated_states = sum(state_treatment$treated == 1L),
  control_states = sum(state_treatment$treated == 0L),
  pretrend_statistic = unname(pretrend$stat),
  pretrend_p_value = unname(pretrend$p),
  stringsAsFactors = FALSE
)

# why: 17 significant digits round-trip IEEE-754 doubles in machine-readable text.
format_numeric <- function(x) ifelse(is.na(x), "NA", sprintf("%.17g", x))
result_text <- result
numeric_cols <- vapply(result_text, is.numeric, logical(1))
result_text[numeric_cols] <- lapply(result_text[numeric_cols], format_numeric)
write.csv(result_text, file.path(results_dir, "stage1_did_results.csv"),
          row.names = FALSE, quote = TRUE)
saveRDS(main_model, file.path(results_dir, "stage1_did_model.rds"))
saveRDS(event_model, file.path(results_dir, "stage1_event_study_model.rds"))

diagnostics <- data.frame(
  check = c("unique_state_month", "complete_required_fields", "balanced_panel",
            "states_40", "adopters_20", "controls_20", "common_adoption_date",
            "pretrend_joint_test"),
  value = c("pass", "pass", "pass", "pass", "pass", "pass", "pass",
            sprintf("F=%.17g; p=%.17g", unname(pretrend$stat), unname(pretrend$p))),
  stringsAsFactors = FALSE
)
write.csv(diagnostics, file.path(results_dir, "stage1_diagnostics.csv"), row.names = FALSE)

session <- capture.output(sessionInfo())
writeLines(session, file.path(results_dir, "sessionInfo.txt"))
print(result)
