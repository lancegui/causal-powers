#!/usr/bin/env Rscript

suppressPackageStartupMessages(library(fixest))
options(digits = 17)

v1_path <- "panel_v1.csv"
update_path <- "panel_update.csv"
v2_path <- "data/panel_v2.csv"
results_dir <- "results"
dir.create(dirname(v2_path), showWarnings = FALSE, recursive = TRUE)
dir.create(results_dir, showWarnings = FALSE, recursive = TRUE)

sha256 <- function(path) {
  line <- system2("shasum", c("-a", "256", path), stdout = TRUE)
  strsplit(line, "[[:space:]]+")[[1]][1]
}
key <- function(x) paste(x$state_id, x$month, sep = "|")
assert_unique_key <- function(x) stopifnot(!anyDuplicated(key(x)))

v1_frozen <- c(
  panel_v1 = "02233208ed1646c22685a408d91d4bdc7f5fe73bdffc58f3df0229362b30e6fe",
  analysis_stage1 = "5b21e757fcf648380e488e8953b7e21a17020b4b7dffd9545d32dda6dbc323f5",
  analysis_stage2 = "9da8d0b3727adf03fc22a4bdb5c5429e4bd14c5436091f387857570f24e85bef",
  stage1_results = "57b0f3e7025591c497b1128f68c60a56a64d353229c1dfc7102950cc1eadc1ea",
  stage2_results = "ecdc744ed4de8284371a05c59c3e6cd7b3b2173eb63dbcfd06e94f0e9ab6900d"
)
v1_files <- c("panel_v1.csv", "analysis_stage1.R", "analysis_stage2.R",
              "results/stage1_did_results.csv", "results/stage2_results.csv")
stopifnot(identical(unname(vapply(v1_files, sha256, character(1))), unname(v1_frozen)))

v1 <- read.csv(v1_path, stringsAsFactors = FALSE, check.names = FALSE)
update_raw <- read.csv(update_path, stringsAsFactors = FALSE, check.names = FALSE,
                       na.strings = c("NA", ""))
write.csv(data.frame(variable = names(v1), missing = colSums(is.na(v1))),
          file.path(results_dir, "stage3_v1_missingness.csv"), row.names = FALSE)
write.csv(data.frame(variable = names(update_raw), missing = colSums(is.na(update_raw))),
          file.path(results_dir, "stage3_update_missingness.csv"), row.names = FALSE)

required_update <- c("state_id", "region", "month", "population", "treated",
                     "adoption_date", "opioid_rate", "source_vintage", "revision_ts")
stopifnot(all(required_update %in% names(update_raw)))
stopifnot(!anyNA(update_raw[c("state_id", "region", "month", "population",
                              "opioid_rate", "source_vintage", "revision_ts")]))

# why: confirm the unique-key contract can fail before applying it to the build.
bad_fixture <- rbind(v1[1, ], v1[1, ])
stopifnot(inherits(try(assert_unique_key(bad_fixture), silent = TRUE), "try-error"))
assert_unique_key(v1)

update_raw$revision_parsed <- as.POSIXct(update_raw$revision_ts,
                                         format = "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
stopifnot(!anyNA(update_raw$revision_parsed))
duplicate_keys <- unique(key(update_raw)[duplicated(key(update_raw)) |
                                         duplicated(key(update_raw), fromLast = TRUE)])
if (length(duplicate_keys) > 0L) {
  duplicate_groups <- split(update_raw$revision_parsed[key(update_raw) %in% duplicate_keys],
                            key(update_raw)[key(update_raw) %in% duplicate_keys])
  stopifnot(all(vapply(duplicate_groups, function(x) !anyDuplicated(x), logical(1))))
}
latest_order <- order(key(update_raw), update_raw$revision_parsed, decreasing = TRUE)
update_sorted <- update_raw[latest_order, ]
update <- update_sorted[!duplicated(key(update_sorted)), ]
assert_unique_key(update)
duplicate_revision_audit <- update_raw[key(update_raw) %in% duplicate_keys,
                                       c("state_id", "month", "revision_ts", "source_vintage")]
if (nrow(duplicate_revision_audit) > 0L) {
  selected_revision <- setNames(update$revision_ts, key(update))
  duplicate_revision_audit$selected_latest <-
    duplicate_revision_audit$revision_ts == selected_revision[key(duplicate_revision_audit)]
}
write.csv(duplicate_revision_audit,
          file.path(results_dir, "stage3_duplicate_revision_audit.csv"), row.names = FALSE)

v1_state_treatment <- aggregate(treated ~ state_id, v1, unique)
stopifnot(nrow(v1_state_treatment) == 40L)
known_treatment <- setNames(v1_state_treatment$treated, v1_state_treatment$state_id)
missing_treated <- is.na(update$treated)
stopifnot(all(known_treatment[update$state_id[missing_treated]] == 0L))
stopifnot(all(is.na(update$adoption_date[missing_treated])))
update$treated[missing_treated] <- 0L
update$adoption_date[update$treated == 0L] <- NA_character_
stopifnot(all(update$treated == known_treatment[update$state_id]))
stopifnot(all(update$adoption_date[update$treated == 1L] == "2021-01-01"))

# why: update is unique (many-to-one from v1 rows); matching update values replace
# overlap, while unmatched v1 rows retain their original values and position.
v1_keys <- key(v1)
update_keys <- key(update)
update_position <- match(v1_keys, update_keys)
stopifnot(all(update_keys %in% v1_keys))
overlap <- !is.na(update_position)
v2 <- v1
shared_columns <- intersect(names(v1), names(update))
for (column in shared_columns) {
  v2[[column]][overlap] <- update[[column]][update_position[overlap]]
}
v2$revision_ts <- NA_character_
v2$revision_ts[overlap] <- update$revision_ts[update_position[overlap]]
v2$row_source <- ifelse(overlap, "panel_update_latest", "panel_v1_only")

assert_unique_key(v2)
stopifnot(nrow(v2) == nrow(v1), identical(key(v2), key(v1)))
stopifnot(sum(overlap) == nrow(update))
v1_only <- !overlap
stopifnot(identical(v2[v1_only, names(v1)], v1[v1_only, names(v1)]))
for (column in shared_columns) {
  stopifnot(identical(v2[[column]][overlap],
                      update[[column]][update_position[overlap]]))
}
stopifnot(all(table(v2$month) == 40L), all(table(v2$state_id) == 60L))
stopifnot(nrow(v2) == 2400L, sum(v2$row_source == "panel_update_latest") == 720L)
stopifnot(sum(v2$row_source == "panel_v1_only") == 1680L)
stopifnot(!anyNA(v2[c("state_id", "region", "month", "population", "treated", "opioid_rate")]))

write.csv(v2, v2_path, row.names = FALSE, na = "")
v2_sha <- sha256(v2_path)

panel <- v2
panel$month <- as.Date(panel$month)
panel$adoption_date <- as.Date(panel$adoption_date)
panel$post <- as.integer(panel$month >= as.Date("2021-01-01"))
panel$policy <- panel$treated * panel$post
panel$time_index <- match(panel$month, sort(unique(panel$month))) - 1L

primary_model <- feols(opioid_rate ~ policy | state_id + month,
                       data = panel, cluster = ~state_id)
region_model <- feols(opioid_rate ~ policy:region | state_id + month,
                      data = panel, cluster = ~state_id)
trend_model <- feols(opioid_rate ~ policy |
                       state_id + month + state_id[[time_index]],
                     data = panel, cluster = ~state_id)

month_index <- as.integer(format(panel$month, "%Y")) * 12L +
  as.integer(format(panel$month, "%m"))
panel$event_time <- ifelse(panel$treated == 1L, month_index - (2021L * 12L + 1L), -1L)
event_model <- feols(opioid_rate ~ i(event_time, treated, ref = -1) |
                       state_id + month, data = panel, cluster = ~state_id)
pretrend <- wald(event_model, keep = "event_time::-[0-9]+:treated")

stopifnot(all(vapply(list(primary_model, region_model, trend_model), nobs, integer(1)) == nrow(panel)))
region_terms <- paste0("policy:region", c("East", "North", "South", "West"))
stopifnot(setequal(names(coef(region_model)), region_terms))

extract_rows <- function(model, model_id, formula_text, term_names, region_values) {
  ct <- coeftable(model)
  critical <- qt(0.975, df = 39L)
  estimates <- unname(ct[term_names, "Estimate"])
  ses <- unname(ct[term_names, "Std. Error"])
  pre_means <- vapply(region_values, function(r) {
    if (is.na(r)) mean(panel$opioid_rate[panel$treated == 1L & panel$post == 0L])
    else mean(panel$opioid_rate[panel$treated == 1L & panel$post == 0L & panel$region == r])
  }, numeric(1))
  data.frame(
    result_vintage = "v2",
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
    n_obs = nobs(model), n_states = 40L, cluster_df = 39L,
    formula = formula_text,
    cluster = "state_id; fixest default finite-sample correction",
    input_path = v2_path, input_sha256 = v2_sha,
    stringsAsFactors = FALSE
  )
}

results <- rbind(
  extract_rows(primary_model, "primary_twfe",
               "opioid_rate ~ policy | state_id + month", "policy", NA_character_),
  extract_rows(region_model, "pooled_region_effects",
               "opioid_rate ~ policy:region | state_id + month",
               region_terms, sub("policy:region", "", region_terms, fixed = TRUE)),
  extract_rows(trend_model, "state_linear_trends",
               "opioid_rate ~ policy | state_id + month + state_id[[time_index]]",
               "policy", NA_character_)
)
results$pretrend_statistic <- unname(pretrend$stat)
results$pretrend_p_value <- unname(pretrend$p)

format_numeric <- function(x) ifelse(is.na(x), "NA", sprintf("%.17g", x))
results_text <- results
numeric_cols <- vapply(results_text, is.numeric, logical(1))
results_text[numeric_cols] <- lapply(results_text[numeric_cols], format_numeric)
write.csv(results_text, file.path(results_dir, "stage3_v2_results.csv"),
          row.names = FALSE, quote = TRUE)
saveRDS(primary_model, file.path(results_dir, "stage3_v2_primary_model.rds"))
saveRDS(region_model, file.path(results_dir, "stage3_v2_region_model.rds"))
saveRDS(trend_model, file.path(results_dir, "stage3_v2_state_trends_model.rds"))
saveRDS(event_model, file.path(results_dir, "stage3_v2_event_study_model.rds"))

build_audit <- data.frame(
  metric = c("v1_rows", "raw_update_rows", "raw_update_duplicate_rows",
             "deduplicated_update_rows", "overlap_rows_replaced", "v1_only_rows_retained",
             "v2_rows", "v2_unique_keys", "missing_treated_recoded_to_zero"),
  value = c(nrow(v1), nrow(update_raw), nrow(update_raw) - nrow(update), nrow(update),
            sum(overlap), sum(v1_only), nrow(v2), length(unique(key(v2))),
            sum(missing_treated)),
  stringsAsFactors = FALSE
)
write.csv(build_audit, file.path(results_dir, "stage3_v2_build_audit.csv"), row.names = FALSE)

manifest <- data.frame(
  artifact = c("data/panel_v2.csv", "results/stage3_v2_results.csv"),
  sha256 = c(v2_sha, sha256(file.path(results_dir, "stage3_v2_results.csv"))),
  current = TRUE,
  v1_preserved = TRUE,
  stringsAsFactors = FALSE
)
stopifnot(identical(unname(vapply(v1_files, sha256, character(1))), unname(v1_frozen)))
write.csv(manifest, file.path(results_dir, "stage3_v2_manifest.csv"), row.names = FALSE)
writeLines(capture.output(sessionInfo()), file.path(results_dir, "sessionInfo_stage3.txt"))
print(results[c("model_id", "region", "estimate", "std_error", "conf_low_95", "conf_high_95")])
cat(sprintf("v2_sha256: %s\n", v2_sha))
