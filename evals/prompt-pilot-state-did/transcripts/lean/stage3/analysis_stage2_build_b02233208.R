suppressPackageStartupMessages(library(fixest))

build_id <- "build_b02233208_stage2"
run_id <- "run_20260909T074656Z"
input_file <- "panel_v1.csv"
input_sha256 <- "02233208ed1646c22685a408d91d4bdc7f5fe73bdffc58f3df0229362b30e6fe"
baseline_run <- "run_20260909T074302Z"
out_dir <- file.path("artifacts", run_id)
if (dir.exists(out_dir)) stop("Refusing to overwrite immutable run: ", run_id)
dir.create(out_dir, recursive = TRUE)

d <- read.csv(input_file, stringsAsFactors = FALSE)
d$month <- as.Date(d$month)
d$adoption_date[d$adoption_date == ""] <- NA_character_
d$adoption_date <- as.Date(d$adoption_date)

stopifnot(nrow(d) == 2400L, length(unique(d$state_id)) == 40L,
          length(unique(d$month)) == 60L,
          !anyDuplicated(d[c("state_id", "month")]),
          !anyNA(d[c("state_id", "region", "month", "treated", "opioid_rate")]),
          identical(sort(unique(d$region)), c("East", "North", "South", "West")))
state_info <- unique(d[c("state_id", "region", "treated", "adoption_date")])
stopifnot(nrow(state_info) == 40L,
          sum(state_info$treated == 1L) == 20L,
          sum(state_info$treated == 0L) == 20L,
          all(state_info$adoption_date[state_info$treated == 1L] == as.Date("2021-01-01")),
          all(is.na(state_info$adoption_date[state_info$treated == 0L])))
region_counts <- as.data.frame.matrix(with(state_info, table(region, treated)))
region_counts$region <- rownames(region_counts)
rownames(region_counts) <- NULL
names(region_counts)[1:2] <- c("never_treated_states", "treated_states")
stopifnot(all(region_counts$never_treated_states > 0L), all(region_counts$treated_states > 0L))

d$post_treat <- as.integer(d$treated == 1L & d$month >= as.Date("2021-01-01"))
d$linear_month <- as.integer(d$month - min(d$month))

region_model <- feols(opioid_rate ~ 0 + post_treat:region | state_id + month,
                      data = d, cluster = ~state_id)
trend_model <- feols(opioid_rate ~ post_treat |
                       state_id + month + state_id[linear_month],
                     data = d, cluster = ~state_id)

tidy_fixest <- function(model, specification, region = NA_character_) {
  ct <- coeftable(model)
  ci <- confint(model)
  data.frame(
    build_id = build_id, run_id = run_id, baseline_run = baseline_run,
    specification = specification, term = rownames(ct), region = region,
    estimate = unname(ct[, "Estimate"]), std_error = unname(ct[, "Std. Error"]),
    conf_low_95 = unname(ci[, 1]), conf_high_95 = unname(ci[, 2]),
    t_value = unname(ct[, "t value"]), p_value = unname(ct[, "Pr(>|t|)"]),
    n_obs = nobs(model), n_states = length(unique(d$state_id)),
    fixed_effects = if (specification == "pooled_region_effects")
      "state_id + month" else "state_id + month + state-specific linear trends",
    cluster = "state_id", fixest_version = as.character(packageVersion("fixest")),
    stringsAsFactors = FALSE
  )
}

region_terms <- names(coef(region_model))
regions <- sub("post_treat:region", "", region_terms, fixed = TRUE)
region_results <- tidy_fixest(region_model, "pooled_region_effects", regions)
trend_results <- tidy_fixest(trend_model, "state_linear_trends_alternative")
results <- rbind(region_results, trend_results)

pre_means <- aggregate(opioid_rate ~ region, d[d$treated == 1L & d$month < as.Date("2021-01-01"), ], mean)
names(pre_means)[2] <- "treated_pre_policy_mean"
region_results <- merge(region_results, pre_means, by = "region", all.x = TRUE, sort = FALSE)
stopifnot(nrow(region_results) == 4L, !anyNA(region_results$treated_pre_policy_mean))
region_results$effect_percent_of_pre_mean <- 100 * region_results$estimate / region_results$treated_pre_policy_mean
results <- rbind(
  region_results,
  transform(trend_results, treated_pre_policy_mean = NA_real_, effect_percent_of_pre_mean = NA_real_)
)

validation <- data.frame(
  rows_before = nrow(d), rows_after = nrow(d), states = length(unique(d$state_id)),
  months = length(unique(d$month)), duplicate_state_month_keys = sum(duplicated(d[c("state_id", "month")])),
  missing_outcomes = sum(is.na(d$opioid_rate)), source_vintages = length(unique(d$source_vintage))
)

options(digits = 17)
write.csv(results, file.path(out_dir, "stage2_estimates.csv"), row.names = FALSE, na = "")
write.csv(region_counts, file.path(out_dir, "region_validation.csv"), row.names = FALSE)
write.csv(validation, file.path(out_dir, "panel_validation.csv"), row.names = FALSE)
saveRDS(list(region_model = region_model, trend_model = trend_model,
             results = results, region_counts = region_counts, validation = validation),
        file.path(out_dir, "models_and_results.rds"), version = 3)

manifest <- c(
  paste0("stage: 2"), paste0("canonical_stage2_run: ", run_id),
  paste0("preserved_baseline_run: ", baseline_run), paste0("build_id: ", build_id),
  "timestamp_utc: 2026-09-09T07:46:56Z", "inputs:",
  paste0("  - file: ", input_file), paste0("    sha256: ", input_sha256),
  "analysis_code: analysis_stage2_build_b02233208.R",
  "specifications:",
  "  pooled_region_effects: opioid_rate ~ 0 + post_treat:region | state_id + month; cluster = state_id; fixest default SSC",
  "  state_linear_trends_alternative: opioid_rate ~ post_treat | state_id + month + state_id[linear_month]; cluster = state_id; fixest default SSC",
  "estimand: region-specific average post-adoption effects and the average effect conditional on state-specific linear trends",
  "comparison: adopting versus never-adopting states, before versus after 2021-01-01",
  "identifying_assumption: conditional parallel trends for each reported specification",
  "missing_value_rule: fail validation for missing state, region, month, treated, or outcome; no rows dropped",
  "panel_key: state_id + month (1:1; asserted unique)", "outputs:",
  paste0("  - ", out_dir, "/stage2_estimates.csv"),
  paste0("  - ", out_dir, "/region_validation.csv"),
  paste0("  - ", out_dir, "/panel_validation.csv"),
  paste0("  - ", out_dir, "/models_and_results.rds")
)
writeLines(manifest, "manifest_stage2.yaml")
print(results[c("specification", "region", "estimate", "std_error", "conf_low_95", "conf_high_95", "p_value", "effect_percent_of_pre_mean")])
print(region_counts)
