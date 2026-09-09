#!/usr/bin/env Rscript

suppressPackageStartupMessages(library(fixest))

input_path <- "panel_v1.csv"
baseline_path <- "results/stage1_did_results.csv"
results_dir <- "results"
dir.create(results_dir, showWarnings = FALSE, recursive = TRUE)

sha256 <- function(path) {
  line <- system2("shasum", c("-a", "256", path), stdout = TRUE)
  strsplit(line, "[[:space:]]+")[[1]][1]
}

input_sha <- sha256(input_path)
baseline_sha_before <- sha256(baseline_path)
stopifnot(input_sha == "02233208ed1646c22685a408d91d4bdc7f5fe73bdffc58f3df0229362b30e6fe")
stopifnot(baseline_sha_before == "57b0f3e7025591c497b1128f68c60a56a64d353229c1dfc7102950cc1eadc1ea")

panel <- read.csv(input_path, stringsAsFactors = FALSE)
required <- c("state_id", "region", "month", "treated", "adoption_date", "opioid_rate")
stopifnot(all(required %in% names(panel)))
stopifnot(!anyDuplicated(panel[c("state_id", "month")]))
stopifnot(all(colSums(is.na(panel[required[c(1, 2, 3, 4, 6)]])) == 0L))

panel$month <- as.Date(panel$month)
panel$adoption_date <- as.Date(panel$adoption_date)
regions <- c("North", "South", "East", "West")
stopifnot(setequal(unique(panel$region), regions))
stopifnot(nrow(panel) == 2400L, length(unique(panel$state_id)) == 40L)
stopifnot(all(table(panel$month) == 40L), all(table(panel$state_id) == 60L))

state_region <- unique(panel[c("state_id", "region", "treated")])
stopifnot(nrow(state_region) == 40L)
stopifnot(all(table(state_region$region) == 10L))
stopifnot(all(table(state_region$region, state_region$treated) == 5L))
stopifnot(all(panel$adoption_date[panel$treated == 1L] == as.Date("2021-01-01")))
stopifnot(all(is.na(panel$adoption_date[panel$treated == 0L])))

panel$post <- as.integer(panel$month >= as.Date("2021-01-01"))
panel$policy <- panel$treated * panel$post
panel$time_index <- match(panel$month, sort(unique(panel$month))) - 1L

# why: one pooled regression permits four regional policy contrasts while sharing
# the same state effects, month shocks, residual variance, and cluster correction.
region_model <- feols(opioid_rate ~ policy:region | state_id + month,
                      data = panel, cluster = ~state_id)

# why: this is the sole authorized alternative to absorb smooth state-specific
# trajectories while retaining state and common month fixed effects.
trend_model <- feols(opioid_rate ~ policy |
                       state_id + month + state_id[[time_index]],
                     data = panel, cluster = ~state_id)

stopifnot(nobs(region_model) == nrow(panel), nobs(trend_model) == nrow(panel))
region_terms <- paste0("policy:region", c("East", "North", "South", "West"))
stopifnot(setequal(names(coef(region_model)), region_terms))
stopifnot(identical(names(coef(trend_model)), "policy"))

extract_rows <- function(model, model_id, formula_text, term_names, region_values) {
  ct <- coeftable(model)
  critical <- qt(0.975, df = 39L)
  estimates <- unname(ct[term_names, "Estimate"])
  ses <- unname(ct[term_names, "Std. Error"])
  pre_means <- vapply(region_values, function(r) {
    if (is.na(r)) {
      mean(panel$opioid_rate[panel$treated == 1L & panel$post == 0L])
    } else {
      mean(panel$opioid_rate[panel$treated == 1L & panel$post == 0L & panel$region == r])
    }
  }, numeric(1))
  data.frame(
    model_id = model_id,
    term = term_names,
    region = ifelse(is.na(region_values), "All", region_values),
    estimate = estimates,
    std_error = ses,
    t_statistic = unname(ct[term_names, "t value"]),
    p_value = unname(ct[term_names, "Pr(>|t|)"]),
    conf_low_95 = estimates - critical * ses,
    conf_high_95 = estimates + critical * ses,
    treated_pre_mean = unname(pre_means),
    effect_percent_of_treated_pre_mean = 100 * estimates / unname(pre_means),
    n_obs = nobs(model),
    n_states = 40L,
    cluster_df = 39L,
    formula = formula_text,
    cluster = "state_id; fixest default finite-sample correction",
    input_path = input_path,
    input_sha256 = input_sha,
    stringsAsFactors = FALSE
  )
}

region_order <- sub("policy:region", "", region_terms, fixed = TRUE)
region_results <- extract_rows(
  region_model,
  "pooled_region_effects",
  "opioid_rate ~ policy:region | state_id + month",
  region_terms,
  region_order
)
trend_results <- extract_rows(
  trend_model,
  "state_linear_trends",
  "opioid_rate ~ policy | state_id + month + state_id[[time_index]]",
  "policy",
  NA_character_
)
results <- rbind(region_results, trend_results)

# why: 17 significant digits round-trip IEEE-754 doubles in machine-readable text.
format_numeric <- function(x) ifelse(is.na(x), "NA", sprintf("%.17g", x))
results_text <- results
numeric_cols <- vapply(results_text, is.numeric, logical(1))
results_text[numeric_cols] <- lapply(results_text[numeric_cols], format_numeric)
write.csv(results_text, file.path(results_dir, "stage2_results.csv"),
          row.names = FALSE, quote = TRUE)
saveRDS(region_model, file.path(results_dir, "stage2_region_model.rds"))
saveRDS(trend_model, file.path(results_dir, "stage2_state_trends_model.rds"))

manifest <- data.frame(
  artifact = c("stage2_results.csv", "stage2_region_model.rds",
               "stage2_state_trends_model.rds"),
  input_sha256 = input_sha,
  baseline_sha256_before = baseline_sha_before,
  baseline_sha256_after = sha256(baseline_path),
  stringsAsFactors = FALSE
)
stopifnot(all(manifest$baseline_sha256_before == manifest$baseline_sha256_after))
write.csv(manifest, file.path(results_dir, "stage2_manifest.csv"), row.names = FALSE)
writeLines(capture.output(sessionInfo()), file.path(results_dir, "sessionInfo_stage2.txt"))
print(results[c("model_id", "region", "estimate", "std_error", "conf_low_95", "conf_high_95")])
