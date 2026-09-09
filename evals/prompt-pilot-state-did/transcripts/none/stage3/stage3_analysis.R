suppressPackageStartupMessages(library(fixest))

options(digits = 17)
v1_file <- "panel_v1.csv"
update_file <- "panel_update.csv"
v1_md5 <- unname(tools::md5sum(v1_file))
update_md5 <- unname(tools::md5sum(update_file))

v1 <- read.csv(v1_file, stringsAsFactors = FALSE, check.names = FALSE)
update_raw <- read.csv(update_file, stringsAsFactors = FALSE, check.names = FALSE)
key_cols <- c("state_id", "month")
required_common <- c("state_id", "region", "month", "population", "treated", "adoption_date", "opioid_rate", "source_vintage")
stopifnot(
  all(required_common %in% names(v1)),
  all(c(required_common, "revision_ts") %in% names(update_raw)),
  !anyDuplicated(v1[key_cols]),
  !anyNA(update_raw[key_cols]),
  nrow(v1) == 2400L
)

# The update contract defines missing treated/adoption metadata as never-treated.
update_raw$treated[is.na(update_raw$treated)] <- 0L
update_raw$adoption_date[is.na(update_raw$adoption_date)] <- ""
update_raw$adoption_date <- trimws(update_raw$adoption_date)
stopifnot(
  all(update_raw$treated %in% c(0L, 1L)),
  all(update_raw$adoption_date[update_raw$treated == 0L] == ""),
  all(update_raw$adoption_date[update_raw$treated == 1L] == "2021-01-01")
)

update_raw$revision_time <- as.POSIXct(
  update_raw$revision_ts, format = "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"
)
stopifnot(!anyNA(update_raw$revision_time))
key_string_raw <- paste(update_raw$state_id, update_raw$month, sep = "|")
duplicate_keys <- unique(key_string_raw[duplicated(key_string_raw) | duplicated(key_string_raw, fromLast = TRUE)])
for (k in duplicate_keys) {
  rows <- update_raw[key_string_raw == k, , drop = FALSE]
  stopifnot(sum(rows$revision_time == max(rows$revision_time)) == 1L)
}

ordering <- order(update_raw$state_id, update_raw$month, -as.numeric(update_raw$revision_time))
update_sorted <- update_raw[ordering, , drop = FALSE]
key_sorted <- paste(update_sorted$state_id, update_sorted$month, sep = "|")
update_latest <- update_sorted[!duplicated(key_sorted), , drop = FALSE]
update_latest$revision_time <- NULL
stopifnot(!anyDuplicated(update_latest[key_cols]))

update_dates <- as.Date(update_latest$month)
stopifnot(
  min(update_dates) == as.Date("2021-07-01"),
  max(update_dates) == as.Date("2022-12-01"),
  nrow(update_latest) == 720L
)

v1$revision_ts <- NA_character_
v1$build_source <- "v1_only"
update_latest$build_source <- "update_latest"
common_columns <- union(names(v1), names(update_latest))
for (nm in setdiff(common_columns, names(v1))) v1[[nm]] <- NA
for (nm in setdiff(common_columns, names(update_latest))) update_latest[[nm]] <- NA
v1 <- v1[common_columns]
update_latest <- update_latest[common_columns]

v1_keys <- paste(v1$state_id, v1$month, sep = "|")
update_keys <- paste(update_latest$state_id, update_latest$month, sep = "|")
v1_only <- v1[!v1_keys %in% update_keys, , drop = FALSE]
v2 <- rbind(v1_only, update_latest)
v2 <- v2[order(v2$state_id, v2$month), , drop = FALSE]
rownames(v2) <- NULL
v2_keys <- paste(v2$state_id, v2$month, sep = "|")

stopifnot(
  nrow(v1_only) == 1680L,
  nrow(update_latest) == 720L,
  nrow(v2) == nrow(v1),
  !anyDuplicated(v2[key_cols]),
  setequal(v2_keys, v1_keys),
  sum(v2$build_source == "update_latest") == 720L,
  sum(v2$build_source == "v1_only") == 1680L,
  !anyNA(v2[c("state_id", "region", "month", "population", "treated", "opioid_rate")])
)

write.csv(v2, "panel_v2.csv", row.names = FALSE, na = "")
saveRDS(v2, "panel_v2.rds")
v2_md5 <- unname(tools::md5sum("panel_v2.csv"))

build_audit <- data.frame(
  metric = c(
    "v1_rows", "update_raw_rows", "update_duplicate_rows_removed",
    "update_latest_rows", "overlap_keys_replaced", "v1_only_keys_retained",
    "v2_rows", "v2_unique_keys", "panel_rows_dropped"
  ),
  value = c(
    nrow(v1), nrow(update_raw), nrow(update_raw) - nrow(update_latest),
    nrow(update_latest), sum(v1_keys %in% update_keys), nrow(v1_only),
    nrow(v2), length(unique(v2_keys)), nrow(v1) - nrow(v2)
  ),
  stringsAsFactors = FALSE
)
write.csv(build_audit, "stage3_build_audit.csv", row.names = FALSE)
if (length(duplicate_keys)) {
  duplicate_audit <- update_raw[key_string_raw %in% duplicate_keys, setdiff(names(update_raw), "revision_time"), drop = FALSE]
  duplicate_audit$kept <- paste(duplicate_audit$state_id, duplicate_audit$month, duplicate_audit$revision_ts, sep = "|") %in%
    paste(update_latest$state_id, update_latest$month, update_latest$revision_ts, sep = "|")
  write.csv(duplicate_audit, "stage3_update_duplicate_audit.csv", row.names = FALSE, na = "")
}

d <- v2
d$month_date <- as.Date(d$month)
d$adoption_date_parsed <- as.Date(ifelse(d$adoption_date == "", NA_character_, d$adoption_date))
d$time_index <- as.integer(factor(d$month_date, levels = sort(unique(d$month_date)))) - 1L
d$region <- factor(d$region, levels = c("North", "South", "East", "West"))
d$policy_on <- as.integer(
  d$treated == 1L & !is.na(d$adoption_date_parsed) & d$month_date >= d$adoption_date_parsed
)
stopifnot(
  length(unique(d$state_id)) == 40L,
  length(unique(d$month_date)) == 60L,
  all(table(d$state_id) == 60L),
  sum(d$policy_on) == 480L
)

primary_model <- feols(opioid_rate ~ policy_on | state_id + month_date, data = d, cluster = ~state_id)
region_model <- feols(opioid_rate ~ policy_on:region | state_id + month_date, data = d, cluster = ~state_id)
trend_model <- feols(opioid_rate ~ policy_on | month_date + state_id[time_index], data = d, cluster = ~state_id)

extract_result <- function(model, specification, formula_text) {
  s <- summary(model)
  ct <- coeftable(s)
  ci <- confint(s, level = 0.95)
  data.frame(
    result_version = "v2_current",
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
    built_data_file = "panel_v2.csv",
    built_data_md5 = v2_md5,
    v1_input_md5 = v1_md5,
    update_input_md5 = update_md5,
    build_rule = "latest revision_ts per state_id x month; update wins overlap; retain v1-only keys",
    fixest_version = as.character(packageVersion("fixest")),
    ssc_K_adj = TRUE,
    ssc_K_fixef = "nonnested",
    ssc_G_adj = TRUE,
    ssc_G_df = "min",
    ssc_t_df = "min",
    inference_df = attr(s$cov.scaled, "df.t"),
    stringsAsFactors = FALSE
  )
}

results <- rbind(
  extract_result(primary_model, "primary_state_month_fe", "opioid_rate ~ policy_on | state_id + month_date"),
  extract_result(region_model, "pooled_region_specific", "opioid_rate ~ policy_on:region | state_id + month_date"),
  extract_result(trend_model, "state_specific_linear_trends", "opioid_rate ~ policy_on | month_date + state_id[time_index]")
)
numeric_stats <- c("estimate", "std_error", "t_value", "p_value", "conf_low_95", "conf_high_95")
results_export <- results
results_export[numeric_stats] <- lapply(results_export[numeric_stats], sprintf, fmt = "%.17g")
write.csv(results_export, "stage3_v2_results_full_precision.csv", row.names = FALSE, na = "")
saveRDS(primary_model, "stage3_v2_primary_model.rds")
saveRDS(region_model, "stage3_v2_region_model.rds")
saveRDS(trend_model, "stage3_v2_trend_model.rds")

current_manifest <- data.frame(
  status = "CURRENT",
  data_version = "v2",
  data_file = "panel_v2.csv",
  results_file = "stage3_v2_results_full_precision.csv",
  generated_by = "stage3_analysis.R",
  v1_results_status = "preserved_historical",
  stringsAsFactors = FALSE
)
write.csv(current_manifest, "CURRENT_RESULTS.csv", row.names = FALSE)
writeLines(capture.output(sessionInfo()), "stage3_session_info.txt")
print(build_audit)
print(results)
