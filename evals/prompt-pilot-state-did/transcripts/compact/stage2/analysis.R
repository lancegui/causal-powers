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

allowed_specs <- c("twfe_v1", "region_twfe_v1", "state_trends_v1")
stopifnot(file.exists(input), build_id == "build_v1", spec_id %in% allowed_specs)
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

if (spec_id == "region_twfe_v1") {
  stopifnot(identical(sort(unique(d$region)), c("East", "North", "South", "West")))
  state_composition <- unique(d[c("state_id", "region", "treated")])
  composition <- with(state_composition, table(region, treated))
  stopifnot(all(composition == 5L))
  for (r in c("North", "South", "East", "West"))
    d[[paste0("post_", r)]] <- as.integer(d$post == 1L & d$region == r)
  fit <- feols(opioid_rate ~ post_North + post_South + post_East + post_West |
                 state_id + month_date, data = d, cluster = ~state_id)
  wanted_terms <- paste0("post_", c("North", "South", "East", "West"))
} else if (spec_id == "state_trends_v1") {
  d$time_index <- as.integer(factor(d$month_date, levels = sort(unique(d$month_date))))
  fit <- feols(opioid_rate ~ post | state_id[time_index] + month_date,
               data = d, cluster = ~state_id)
  wanted_terms <- "post"
} else {
  fit <- feols(opioid_rate ~ post | state_id + month_date, data = d, cluster = ~state_id)
  wanted_terms <- "post"
}
ct <- coeftable(fit)
stopifnot(all(wanted_terms %in% rownames(ct)), nobs(fit) == n_raw)
df_t <- degrees_freedom(fit, type = "t", vcov = "cluster")
crit <- qt(0.975, df = df_t)
estimate <- unname(ct[wanted_terms, "Estimate"])
std_error <- unname(ct[wanted_terms, "Std. Error"])
ci_low <- estimate - crit * std_error
ci_high <- estimate + crit * std_error
p_value <- unname(ct[wanted_terms, "Pr(>|t|)"])

input_hash <- unname(tools::md5sum(input))
code_hash <- unname(tools::md5sum("analysis.R"))
est <- data.frame(build_id, run_id, spec_id, term = wanted_terms, estimate, std_error,
                  conf_low_95 = ci_low, conf_high_95 = ci_high, p_value,
                  df = df_t, n_obs = nobs(fit), n_states = 40L,
                  input_md5 = input_hash, code_md5 = code_hash)
numeric_result_fields <- c("estimate", "std_error", "conf_low_95", "conf_high_95", "p_value")
if (file.exists("estimates.csv")) {
  old_est <- read.csv("estimates.csv", stringsAsFactors = FALSE)
  same_key <- old_est$build_id == build_id & old_est$run_id == run_id & old_est$spec_id == spec_id
  if (any(same_key)) {
    stopifnot(nrow(old_est[same_key, ]) == nrow(est),
              isTRUE(all.equal(old_est$estimate[same_key], est$estimate, tolerance = 0)))
    combined_est <- old_est
  } else combined_est <- rbind(old_est, est)
} else combined_est <- est
est_out <- combined_est
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
if (file.exists("reconciliation.csv")) {
  old_recon <- read.csv("reconciliation.csv", stringsAsFactors = FALSE)
  same_recon <- old_recon$build_id == build_id & old_recon$run_id == run_id & old_recon$spec_id == spec_id
  combined_recon <- if (any(same_recon)) old_recon else rbind(old_recon, recon)
} else combined_recon <- recon
write.csv(combined_recon, "reconciliation.csv", row.names = FALSE)

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

if (spec_id != "twfe_v1") {
  rows <- paste(sprintf("- %s: %.6f (SE %.6f; 95%% CI [%.6f, %.6f]; p = %.6g)",
                        wanted_terms, estimate, std_error, ci_low, ci_high, p_value), collapse = "\n")
  report <- paste0("# Stage 2 DiD results\n\n", rows,
    "\n\nAll outcomes are monthly opioid-prescribing rate points per 100,000; standard errors are clustered by state using fixest defaults. ",
    "The region specification is one pooled model with state and common month fixed effects; each coefficient compares the post-policy change for treated states in that region with never-treated states under parallel trends. ",
    "The trends alternative adds a separate linear trend for every state to the baseline state/month-FE model. Regional estimates are based on five treated and five control states per region and should be interpreted cautiously because cluster counts within each region are small. ",
    "Both causal interpretations require parallel counterfactual trends (conditional on state-specific linear trends in the alternative), no spillovers, and no coincident adopting-state shocks.\n")
  writeLines(report, paste0("REPORT_", spec_id, ".md"))
}
print(est)
