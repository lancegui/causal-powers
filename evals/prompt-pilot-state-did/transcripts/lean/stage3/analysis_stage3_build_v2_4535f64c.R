suppressPackageStartupMessages(library(fixest))

build_id <- "build_v2_4535f64c"
run_id <- "run_20260909T075158Z"
out_dir <- file.path("artifacts", run_id)
build_dir <- file.path("builds", build_id)
if (dir.exists(out_dir) || dir.exists(build_dir)) stop("Refusing to overwrite immutable Stage 3 build/run")
dir.create(out_dir, recursive = TRUE)
dir.create(build_dir, recursive = TRUE)

v1 <- read.csv("panel_v1.csv", stringsAsFactors = FALSE)
u_raw <- read.csv("panel_update.csv", stringsAsFactors = FALSE)
v1$month <- as.Date(v1$month); u_raw$month <- as.Date(u_raw$month)
v1$revision_ts <- NA_character_

stopifnot(nrow(v1) == 2400L, !anyDuplicated(v1[c("state_id", "month")]),
          nrow(u_raw) == 721L, all(u_raw$month >= as.Date("2021-07-01")),
          all(u_raw$month <= as.Date("2022-12-01")))
state_info <- unique(v1[c("state_id", "region", "treated", "adoption_date")])
stopifnot(nrow(state_info) == 40L)

# Update duplicate rule: latest parsed revision timestamp wins within state_id x month.
u_raw$revision_time <- as.POSIXct(u_raw$revision_ts, format = "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
stopifnot(!anyNA(u_raw$revision_time))
u_order <- order(u_raw$state_id, u_raw$month, u_raw$revision_time, decreasing = TRUE)
u_sorted <- u_raw[u_order, ]
u <- u_sorted[!duplicated(u_sorted[c("state_id", "month")]), ]
stopifnot(nrow(u) == 720L, !anyDuplicated(u[c("state_id", "month")]))

# Verify missing treatment fields are confined to known never-treated states, then normalize.
idx_state <- match(u$state_id, state_info$state_id)
stopifnot(!anyNA(idx_state), all(u$region == state_info$region[idx_state]))
known_treated <- state_info$treated[idx_state]
stopifnot(all(is.na(u$treated) == (known_treated == 0L)))
u$adoption_date[u$adoption_date == ""] <- NA_character_
stopifnot(all(is.na(u$adoption_date) == (known_treated == 0L)))
u$treated[known_treated == 0L] <- 0L
u$adoption_date[known_treated == 0L] <- NA_character_
stopifnot(all(u$treated == known_treated))
u$revision_time <- NULL

# Update is 1:1 by state_id x month; update wins on overlap and v1-only keys remain.
key <- function(x) paste(x$state_id, x$month, sep = "|")
v1_key <- key(v1); u_key <- key(u)
overlap <- sum(u_key %in% v1_key)
update_only <- sum(!u_key %in% v1_key)
v1_only <- sum(!v1_key %in% u_key)
stopifnot(overlap == 720L, update_only == 0L, v1_only == 1680L)
u <- u[names(v1)]
v2 <- rbind(v1[!v1_key %in% u_key, ], u)
v2 <- v2[order(v2$state_id, v2$month), ]
rownames(v2) <- NULL
stopifnot(nrow(v2) == nrow(v1), !anyDuplicated(v2[c("state_id", "month")]),
          sum(v2$source_vintage == "update_2023-04-20") == 720L,
          !anyNA(v2[c("state_id", "region", "month", "population", "treated", "opioid_rate", "source_vintage")]))
write.csv(v2, file.path(build_dir, "panel_v2.csv"), row.names = FALSE, na = "")

v2$adoption_date[v2$adoption_date == ""] <- NA_character_
v2$adoption_date <- as.Date(v2$adoption_date)
v2$post_treat <- as.integer(v2$treated == 1L & v2$month >= as.Date("2021-01-01"))
v2$linear_month <- as.integer(v2$month - min(v2$month))
v2$month_index <- as.integer(format(v2$month, "%Y")) * 12L + as.integer(format(v2$month, "%m"))
v2$event_time <- v2$month_index - (2021L * 12L + 1L)

primary <- feols(opioid_rate ~ post_treat | state_id + month, v2, cluster = ~state_id)
region_model <- feols(opioid_rate ~ 0 + post_treat:region | state_id + month, v2, cluster = ~state_id)
trend_model <- feols(opioid_rate ~ post_treat | state_id + month + state_id[linear_month], v2, cluster = ~state_id)
event <- feols(opioid_rate ~ i(event_time, treated, ref = -1) | state_id + month, v2, cluster = ~state_id)

tidy_model <- function(model, specification, region = NA_character_) {
  ct <- coeftable(model); ci <- confint(model)
  data.frame(build_id = build_id, run_id = run_id, specification = specification,
             term = rownames(ct), region = region,
             estimate = unname(ct[, "Estimate"]), std_error = unname(ct[, "Std. Error"]),
             conf_low_95 = unname(ci[, 1]), conf_high_95 = unname(ci[, 2]),
             t_value = unname(ct[, "t value"]), p_value = unname(ct[, "Pr(>|t|)"]),
             n_obs = nobs(model), n_states = length(unique(v2$state_id)),
             cluster = "state_id", fixest_version = as.character(packageVersion("fixest")),
             stringsAsFactors = FALSE)
}
region_terms <- names(coef(region_model))
results <- rbind(
  tidy_model(primary, "primary_state_month_fe"),
  tidy_model(region_model, "pooled_region_effects", sub("post_treat:region", "", region_terms, fixed = TRUE)),
  tidy_model(trend_model, "state_linear_trends_alternative")
)

lead_names <- grep("event_time::-[0-9]+:treated", names(coef(event)), value = TRUE)
b <- coef(event)[lead_names]; vv <- vcov(event)[lead_names, lead_names, drop = FALSE]
wald_stat <- as.numeric(t(b) %*% solve(vv, b))
diagnostics <- data.frame(build_id = build_id, run_id = run_id,
  diagnostic = "joint_zero_pre_treatment_event_study_coefficients",
  statistic = wald_stat, df = length(b),
  p_value = pchisq(wald_stat, length(b), lower.tail = FALSE), omitted_event_month = -1L)

reconciliation <- data.frame(
  v1_raw_rows = nrow(v1), update_raw_rows = nrow(u_raw), update_duplicate_rows_removed = nrow(u_raw) - nrow(u),
  update_unique_keys = nrow(u), overlap_keys = overlap, update_only_keys = update_only,
  v1_only_keys = v1_only, v2_rows = nrow(v2), v2_duplicate_keys = sum(duplicated(v2[c("state_id", "month")])),
  v2_missing_outcomes = sum(is.na(v2$opioid_rate)), v2_rows_dropped = nrow(v1) + update_only - nrow(v2)
)

options(digits = 17)
write.csv(results, file.path(out_dir, "all_estimates.csv"), row.names = FALSE, na = "")
write.csv(diagnostics, file.path(out_dir, "diagnostics.csv"), row.names = FALSE)
write.csv(reconciliation, file.path(build_dir, "reconciliation.csv"), row.names = FALSE)
saveRDS(list(primary = primary, region_model = region_model, trend_model = trend_model,
             event_study = event, results = results, diagnostics = diagnostics,
             reconciliation = reconciliation), file.path(out_dir, "models_and_results.rds"), version = 3)

v2_sha <- strsplit(system2("shasum", c("-a", "256", file.path(build_dir, "panel_v2.csv")), stdout = TRUE), "  ")[[1]][1]
manifest <- c(
  "stage: 3", paste0("current_build: ", build_id), paste0("current_run: ", run_id),
  "preserved_runs:", "  - run_20260909T074302Z", "  - run_20260909T074656Z",
  "timestamp_utc: 2026-09-09T07:51:58Z", "inputs:",
  "  - file: panel_v1.csv", "    sha256: 02233208ed1646c22685a408d91d4bdc7f5fe73bdffc58f3df0229362b30e6fe",
  "  - file: panel_update.csv", "    sha256: 4535f64c92826efcd210a9f72c4abed3820aa5899ad30ccb532edfab6389521b",
  "build_rules: deduplicate update on state_id x month by latest revision_ts; verified missing treatment fields identify v1-known never-treated states and normalize to treated=0/no adoption; update wins overlap; retain v1-only keys; drop no panel rows",
  "panel_key: state_id + month (1:1 after deduplication)",
  paste0("built_panel: ", build_dir, "/panel_v2.csv"), paste0("built_panel_sha256: ", v2_sha),
  "analysis_code: analysis_stage3_build_v2_4535f64c.R", "specifications:",
  "  primary: opioid_rate ~ post_treat | state_id + month; cluster = state_id; fixest default SSC",
  "  pooled_region: opioid_rate ~ 0 + post_treat:region | state_id + month; cluster = state_id; fixest default SSC",
  "  state_trends: opioid_rate ~ post_treat | state_id + month + state_id[linear_month]; cluster = state_id; fixest default SSC",
  "outputs:", paste0("  - ", out_dir, "/all_estimates.csv"),
  paste0("  - ", out_dir, "/diagnostics.csv"), paste0("  - ", out_dir, "/models_and_results.rds"),
  paste0("  - ", build_dir, "/reconciliation.csv")
)
writeLines(manifest, "manifest_stage3.yaml")
writeLines(c(paste0("current_build: ", build_id), paste0("current_run: ", run_id),
             "current_manifest: manifest_stage3.yaml"), "current.yaml")
print(results); print(diagnostics); print(reconciliation)
