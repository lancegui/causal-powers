#!/usr/bin/env Rscript

suppressPackageStartupMessages(library(fixest))
options(digits = 17)

args <- commandArgs(trailingOnly = TRUE)
arg <- function(name, default) {
  hit <- grep(paste0("^--", name, "="), args, value = TRUE)
  if (length(hit)) sub(paste0("^--", name, "="), "", hit[[1]]) else default
}
build_id <- arg("build", "build_v1")
run_id <- arg("run", "run_v1")
spec_id <- arg("spec", "twfe_v1")
input <- arg("input", "panel_v1.csv")

stopifnot(file.exists(input), build_id == "build_v1", spec_id == "twfe_v1")
d <- read.csv(input, stringsAsFactors = FALSE, na.strings = c("NA"), check.names = FALSE)
required <- c("state_id", "region", "month", "population", "treated",
              "adoption_date", "opioid_rate", "source_vintage")
stopifnot(identical(names(d), required))
n_raw <- nrow(d)
d$month_date <- as.Date(d$month)
d$adoption <- as.Date(ifelse(d$adoption_date == "", NA, d$adoption_date))

# No merges or duplicate resolution are needed for this single-source build.
key_duplicates <- sum(duplicated(d[c("state_id", "month")]))
stopifnot(key_duplicates == 0L, n_raw == 2400L, length(unique(d$state_id)) == 40L,
          length(unique(d$month_date)) == 60L)
state_rows <- table(d$state_id)
stopifnot(all(state_rows == 60L))
state_treated <- tapply(d$treated, d$state_id, function(x) length(unique(x)) == 1L && unique(x) %in% 0:1)
stopifnot(all(state_treated), sum(!duplicated(d$state_id) & d$treated == 1L) == 20L,
          sum(!duplicated(d$state_id) & d$treated == 0L) == 20L)
adopt_by_state <- tapply(d$adoption, d$state_id, function(x) unique(x[!is.na(x)]))
stopifnot(all(vapply(adopt_by_state[d$treated[match(names(adopt_by_state), d$state_id)] == 1L],
                   function(x) length(x) == 1L && x == as.Date("2021-01-01"), logical(1))))
stopifnot(all(is.na(d$adoption[d$treated == 0L])))
analysis_missing <- sum(!complete.cases(d[c("state_id", "month_date", "treated", "opioid_rate")]))
stopifnot(analysis_missing == 0L)
d$post <- as.integer(d$treated == 1L & d$month_date >= as.Date("2021-01-01"))
stopifnot(sum(d$post) == 480L)

fit <- feols(opioid_rate ~ post | state_id + month_date, data = d, cluster = ~state_id)
ct <- coeftable(fit)
stopifnot("post" %in% rownames(ct), nobs(fit) == n_raw)
estimate <- unname(ct["post", "Estimate"])
std_error <- unname(ct["post", "Std. Error"])
df_t <- degrees_freedom(fit, type = "t", vcov = "cluster")
crit <- qt(0.975, df = df_t)
ci_low <- estimate - crit * std_error
ci_high <- estimate + crit * std_error
p_value <- unname(ct["post", "Pr(>|t|)"])

input_hash <- unname(tools::md5sum(input))
code_hash <- unname(tools::md5sum("analysis.R"))
est <- data.frame(build_id, run_id, spec_id, term = "post", estimate, std_error,
                  conf_low_95 = ci_low, conf_high_95 = ci_high, p_value,
                  df = df_t, n_obs = nobs(fit), n_states = 40L,
                  input_md5 = input_hash, code_md5 = code_hash)
est_out <- est
numeric_result_fields <- c("estimate", "std_error", "conf_low_95", "conf_high_95", "p_value")
est_out[numeric_result_fields] <- lapply(est_out[numeric_result_fields], sprintf, fmt = "%.17g")
write.csv(est_out, "estimates.csv", row.names = FALSE, quote = FALSE)

recon <- data.frame(build_id, run_id, spec_id, raw_rows = n_raw,
                    built_rows = nrow(d), analysis_rows = nobs(fit),
                    unique_states = length(unique(d$state_id)),
                    unique_months = length(unique(d$month_date)),
                    key_duplicates, duplicate_resolution = "none",
                    merge_cardinality = "none (single source)", merges = 0L,
                    missing_analysis_fields = analysis_missing,
                    missing_rule = "complete cases required; assertion prevents dropping",
                    update_precedence = "not applicable; one immutable source")
write.csv(recon, "reconciliation.csv", row.names = FALSE)

history <- data.frame(timestamp_utc = format(Sys.time(), tz = "UTC", usetz = TRUE),
                      build_id, run_id, spec_id, input_file = input,
                      input_md5 = input_hash,
                      build_rule = "raw panel unchanged; post=treated*(month>=2021-01-01)",
                      code_md5 = code_hash, output = "estimates.csv", status = "current")
history_file <- "history.csv"
if (file.exists(history_file)) {
  old <- read.csv(history_file, stringsAsFactors = FALSE)
  same <- old$build_id == build_id & old$run_id == run_id & old$spec_id == spec_id
  if (any(same)) {
    stopifnot(old$input_md5[same][1] == input_hash, old$code_md5[same][1] == code_hash)
  } else write.table(history, history_file, sep = ",", row.names = FALSE,
                     col.names = FALSE, append = TRUE, qmethod = "double")
} else write.csv(history, history_file, row.names = FALSE)
writeLines(paste(build_id, run_id, spec_id, sep = ","), "CURRENT")

report <- sprintf(paste0(
  "# DiD result\n\n",
  "The estimated average policy effect is %.6f opioid-prescribing rate points per 100,000 per month ",
  "(state-clustered SE %.6f; 95%% CI [%.6f, %.6f]; p = %.6g).\n\n",
  "This state-and-month fixed-effects DiD compares the post-adoption change in the 20 adopting states ",
  "with the contemporaneous change in the 20 never-adopting states. The estimand is the average effect ",
  "on treated states in their 24 post-policy months. Under parallel untreated trends (and no spillovers or ",
  "other treatment-timed shocks), adoption reduced monthly prescribing by about %.2f prescriptions per ",
  "100,000. The main limitation is that this causal interpretation depends on that untested counterfactual ",
  "trend assumption; the single common adoption date also prevents separating policy effects from shocks ",
  "specific to adopting states beginning in January 2021. Fixed effects: state and month. Clustering: state.\n"),
  estimate, std_error, ci_low, ci_high, p_value, abs(estimate))
writeLines(report, "REPORT.md")
print(est)
