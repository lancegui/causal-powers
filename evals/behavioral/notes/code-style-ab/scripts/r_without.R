# Stock_Out_By_Chain.R
# ---------------------------------------------------------------------------
# Stylized fact: do chain pharmacies stock out of buprenorphine (MOUD) less
# often than independents?
#
# Pipeline
#   1. Keep MOUD shipments only (ndc.csv flag).
#   2. Map BUYER_DEA_NO -> pharmacy_id (pharm_link.csv, many DEA : one pharmacy).
#   3. Aggregate to pharmacy x month grams.
#   4. Fill months with no shipment with 0 g, from each pharmacy's first MOUD
#      shipment month through 2019-12.
#   5. Stock-out month := month with zero grams. Stock-out share := share of a
#      pharmacy's months (first month..2019-12) that are stock-outs.
#   6. Join CHAIN and zip; regress stock-out share on CHAIN with zip FE.
#   7. Save pharmacy table (RDS) and a density plot by chain status (PNG).
#
# Run from the project root:  Rscript Stylized_Facts/Stock_Out_By_Chain.R
# ---------------------------------------------------------------------------

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(tidyr)
  library(lubridate)
  library(fixest)
  library(ggplot2)
  library(ggthemes)
})

options(dplyr.summarise.inform = FALSE)

# --- paths ------------------------------------------------------------------
data_dir <- "Data"
out_rds  <- file.path("Temp_Analysis_Data", "stock_out_by_pharmacy.RDS")
out_png  <- file.path("Plots", "stock_out_rate_by_chain.png")
dir.create(dirname(out_rds), showWarnings = FALSE, recursive = TRUE)
dir.create(dirname(out_png), showWarnings = FALSE, recursive = TRUE)

panel_end <- as.Date("2019-12-01")   # last month of the fill window

# --- small helpers -----------------------------------------------------------
assert_that <- function(cond, msg) {
  if (!isTRUE(cond)) stop("ASSERTION FAILED: ", msg, call. = FALSE)
  invisible(TRUE)
}
assert_unique_key <- function(df, key, name) {
  n_dup <- sum(duplicated(df[[key]]))
  assert_that(n_dup == 0, sprintf("%s: %d duplicated %s", name, n_dup, key))
}
fmt_g <- function(x) format(round(x, 3), big.mark = ",", nsmall = 3)

# ============================================================================
# 1. Load inputs with explicit column types; validate at the data boundary
# ============================================================================
shipments <- read_csv(
  file.path(data_dir, "shipments.csv"),
  col_types = cols(
    BUYER_DEA_NO        = col_character(),
    TRANSACTION_DATE    = col_date(format = "%Y-%m-%d"),
    NDC_NO              = col_character(),
    CALC_BASE_WT_IN_GM  = col_double()
  )
)
pharm_link <- read_csv(
  file.path(data_dir, "pharm_link.csv"),
  col_types = cols(pharmacy_id = col_integer(), BUYER_DEA_NO = col_character())
)
pharmacies <- read_csv(
  file.path(data_dir, "pharmacies.csv"),
  col_types = cols(pharmacy_id = col_integer(), zip = col_character(),
                   CHAIN = col_integer(), lat = col_double(), lon = col_double())
)
ndc <- read_csv(
  file.path(data_dir, "ndc.csv"),
  col_types = cols(NDC_NO = col_character(), Drug_Name = col_character(),
                   MOUD = col_character(), formulation = col_character())
)

cat("== Inputs\n")
cat(sprintf("shipments : %6d rows, %s g, %s .. %s\n",
            nrow(shipments), fmt_g(sum(shipments$CALC_BASE_WT_IN_GM)),
            min(shipments$TRANSACTION_DATE), max(shipments$TRANSACTION_DATE)))
cat(sprintf("pharm_link: %6d rows (%d DEA -> %d pharmacies)\n",
            nrow(pharm_link), n_distinct(pharm_link$BUYER_DEA_NO),
            n_distinct(pharm_link$pharmacy_id)))
cat(sprintf("pharmacies: %6d rows, %d zips, %d chain / %d independent\n",
            nrow(pharmacies), n_distinct(pharmacies$zip),
            sum(pharmacies$CHAIN == 1), sum(pharmacies$CHAIN == 0)))
cat(sprintf("ndc       : %6d rows, MOUD = {%s}\n",
            nrow(ndc), paste(sort(unique(ndc$MOUD)), collapse = ", ")))

# NA map at the boundary
na_counts <- sapply(shipments, function(x) sum(is.na(x)))
assert_that(all(na_counts == 0),
            paste("shipments has NAs:", paste(names(na_counts), na_counts, collapse = " ")))
assert_that(all(shipments$CALC_BASE_WT_IN_GM >= 0), "negative shipment weights")
n_zero_wt <- sum(shipments$CALC_BASE_WT_IN_GM == 0)
cat(sprintf("shipments with exactly 0 g: %d\n", n_zero_wt))

# Lookup keys must be unique for the m:1 joins below to be m:1
assert_unique_key(ndc,        "NDC_NO",       "ndc")
assert_unique_key(pharm_link, "BUYER_DEA_NO", "pharm_link")
assert_unique_key(pharmacies, "pharmacy_id",  "pharmacies")
assert_that(all(ndc$MOUD %in% c("True", "False")), "ndc$MOUD not in {True, False}")
assert_that(all(pharmacies$CHAIN %in% c(0L, 1L)), "CHAIN not in {0, 1}")
assert_that(all(!is.na(pharmacies$zip)), "pharmacies has NA zip")
assert_that(all(pharm_link$pharmacy_id %in% pharmacies$pharmacy_id),
            "pharm_link pharmacy_id not in pharmacies")

g_total_raw <- sum(shipments$CALC_BASE_WT_IN_GM)

# ============================================================================
# 2. Keep MOUD shipments only  (join m:1 on NDC_NO; must match every row)
# ============================================================================
n_before <- nrow(shipments)
shipments <- shipments %>%
  left_join(ndc %>% select(NDC_NO, MOUD), by = "NDC_NO", relationship = "many-to-one")
assert_that(nrow(shipments) == n_before, "ndc join changed row count")
assert_that(all(!is.na(shipments$MOUD)), "shipment NDC_NO not found in ndc.csv")

moud <- shipments %>% filter(MOUD == "True")
g_total_moud <- sum(moud$CALC_BASE_WT_IN_GM)
cat(sprintf("\n== MOUD filter: %d of %d shipments kept (%.1f%%); %s of %s g (%.1f%%)\n",
            nrow(moud), n_before, 100 * nrow(moud) / n_before,
            fmt_g(g_total_moud), fmt_g(g_total_raw), 100 * g_total_moud / g_total_raw))
assert_that(nrow(moud) > 0, "no MOUD shipments after filter")

# ============================================================================
# 3. Map to pharmacy_id  (join m:1 on BUYER_DEA_NO; must match every row)
# ============================================================================
n_before <- nrow(moud)
moud <- moud %>%
  left_join(pharm_link, by = "BUYER_DEA_NO", relationship = "many-to-one")
assert_that(nrow(moud) == n_before, "pharm_link join changed row count")
assert_that(all(!is.na(moud$pharmacy_id)), "shipment BUYER_DEA_NO not found in pharm_link")
assert_that(abs(sum(moud$CALC_BASE_WT_IN_GM) - g_total_moud) < 1e-6,
            "grams changed across pharm_link join")
cat(sprintf("mapped to %d pharmacies (of %d in pharmacies.csv)\n",
            n_distinct(moud$pharmacy_id), nrow(pharmacies)))

# ============================================================================
# 4. Aggregate to pharmacy x month
# ============================================================================
pm_obs <- moud %>%
  mutate(month = floor_date(TRANSACTION_DATE, unit = "month")) %>%
  group_by(pharmacy_id, month) %>%
  summarise(grams = sum(CALC_BASE_WT_IN_GM), n_ship = n(), .groups = "drop")
assert_unique_key(pm_obs %>% mutate(k = paste(pharmacy_id, month)), "k", "pharmacy x month")
assert_that(abs(sum(pm_obs$grams) - g_total_moud) < 1e-6,
            "grams not reconciled after monthly aggregation")
assert_that(max(pm_obs$month) <= panel_end, "shipment month after panel end")
cat(sprintf("\n== pharmacy x month cells with a shipment: %d (%s .. %s)\n",
            nrow(pm_obs), min(pm_obs$month), max(pm_obs$month)))

# ============================================================================
# 5. Fill: every month from each pharmacy's first MOUD shipment month .. 2019-12
# ============================================================================
first_month <- pm_obs %>%
  group_by(pharmacy_id) %>%
  summarise(first_month = min(month), .groups = "drop")

grid <- first_month %>%
  rowwise() %>%
  mutate(month = list(seq(first_month, panel_end, by = "month"))) %>%
  ungroup() %>%
  unnest(month)

panel <- grid %>%
  left_join(pm_obs, by = c("pharmacy_id", "month"), relationship = "one-to-one") %>%
  mutate(grams  = replace_na(grams, 0),
         n_ship = replace_na(n_ship, 0L),
         stock_out = grams == 0)

# Invariants of the fill
exp_months <- first_month %>%
  mutate(n_exp = 12L * (year(panel_end) - year(first_month)) +
                 (month(panel_end) - month(first_month)) + 1L)
got_months <- panel %>% count(pharmacy_id, name = "n_got")
chk <- exp_months %>% inner_join(got_months, by = "pharmacy_id")
assert_that(nrow(chk) == nrow(first_month) && all(chk$n_exp == chk$n_got),
            "filled panel month counts do not match first_month..2019-12")
assert_that(abs(sum(panel$grams) - g_total_moud) < 1e-6,
            "grams not reconciled after fill")
assert_that(sum(panel$n_ship > 0) == nrow(pm_obs),
            "fill lost or invented shipment months")
cat(sprintf("filled panel: %d pharmacy-months, %d (%.1f%%) with zero grams\n",
            nrow(panel), sum(panel$stock_out), 100 * mean(panel$stock_out)))

# ============================================================================
# 6. Pharmacy-level stock-out share; join chain status and zip (1:1)
# ============================================================================
by_pharm <- panel %>%
  group_by(pharmacy_id) %>%
  summarise(first_month     = min(month),
            n_months        = n(),
            n_stockout      = sum(stock_out),
            stockout_share  = n_stockout / n_months,
            total_grams     = sum(grams),
            .groups = "drop")

n_before <- nrow(by_pharm)
by_pharm <- by_pharm %>%
  left_join(pharmacies %>% select(pharmacy_id, zip, CHAIN),
            by = "pharmacy_id", relationship = "one-to-one") %>%
  mutate(chain_lab = factor(CHAIN, levels = c(0, 1), labels = c("Independent", "Chain")))
assert_that(nrow(by_pharm) == n_before, "pharmacies join changed row count")
assert_that(all(!is.na(by_pharm$CHAIN)) && all(!is.na(by_pharm$zip)),
            "pharmacy without CHAIN / zip after join")
assert_that(all(by_pharm$stockout_share >= 0 & by_pharm$stockout_share <= 1),
            "stock-out share outside [0, 1]")

n_unshipped <- sum(!pharmacies$pharmacy_id %in% by_pharm$pharmacy_id)
cat(sprintf("\n== Pharmacy table: %d pharmacies (%d in pharmacies.csv never shipped MOUD and are excluded)\n",
            nrow(by_pharm), n_unshipped))

desc <- by_pharm %>%
  group_by(chain_lab) %>%
  summarise(n = n(),
            mean_share   = mean(stockout_share),
            median_share = median(stockout_share),
            sd_share     = sd(stockout_share),
            share_never  = mean(n_stockout == 0),
            mean_months  = mean(n_months),
            .groups = "drop")
cat("Stock-out share by chain status:\n")
print(as.data.frame(desc), digits = 3, row.names = FALSE)

# ============================================================================
# 7. Regression: stock-out share on CHAIN with zip fixed effects
# ============================================================================
n_zip <- n_distinct(by_pharm$zip)
m_fe   <- feols(stockout_share ~ CHAIN | zip, data = by_pharm, cluster = ~zip)
m_fe_h <- feols(stockout_share ~ CHAIN | zip, data = by_pharm, vcov = "hetero")
m_raw  <- feols(stockout_share ~ CHAIN,       data = by_pharm, vcov = "hetero")

cat(sprintf("\n== Regression: stockout_share ~ CHAIN | zip  (N = %d, %d zip FE)\n",
            nobs(m_fe), n_zip))
etable(m_raw, m_fe_h, m_fe,
       headers = c("No FE, HC1", "Zip FE, HC1", sprintf("Zip FE, cl. zip (%d)", n_zip)),
       digits = 3, fitstat = ~ n + r2 + wr2)

b      <- coef(m_fe)[["CHAIN"]]
indep_mean <- desc$mean_share[desc$chain_lab == "Independent"]
cat(sprintf(paste0(
  "\nInterpretation: within zip, chains' stock-out share is %+.1f percentage points\n",
  "vs independents, i.e. %+.0f%% of the independent mean (%.1f%% of months).\n"),
  100 * b, 100 * b / indep_mean, 100 * indep_mean))
cat(sprintf("Note: %d zip clusters is few; the HC1 column is the comparison SE.\n", n_zip))

# ============================================================================
# 8. Save pharmacy-level table
# ============================================================================
by_pharm_out <- by_pharm %>%
  select(pharmacy_id, zip, CHAIN, first_month, n_months, n_stockout,
         stockout_share, total_grams)
saveRDS(by_pharm_out, out_rds)
cat(sprintf("\nSaved %s (%d rows x %d cols)\n", out_rds, nrow(by_pharm_out), ncol(by_pharm_out)))

# ============================================================================
# 9. Density of stock-out share, chain vs independent
# ============================================================================
tol_cols <- c("Independent" = "#4477AA", "Chain" = "#EE6677")   # Paul Tol bright
x_max <- min(1, ceiling(max(by_pharm$stockout_share) * 10) / 10 + 0.1)  # pad past max

p <- ggplot(by_pharm, aes(x = stockout_share, colour = chain_lab,
                          fill = chain_lab, linetype = chain_lab)) +
  geom_density(alpha = 0.25, linewidth = 0.9, bounds = c(0, 1)) +
  scale_colour_manual(values = tol_cols, name = NULL) +
  scale_fill_manual(values = tol_cols, name = NULL) +
  scale_linetype_manual(values = c("Independent" = "solid", "Chain" = "dashed"), name = NULL) +
  scale_x_continuous(labels = scales::percent_format(accuracy = 1),
                     breaks = seq(0, 1, by = 0.2), expand = expansion(mult = c(0, 0))) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.05))) +
  # density is estimated on [0, 1]; display stops where the mass stops
  coord_cartesian(xlim = c(0, x_max)) +
  labs(x = "Share of months with no MOUD shipment", y = NULL) +
  theme_few(base_size = 16.5) +
  theme(legend.position = c(0.98, 0.98),
        legend.justification = c(1, 1),
        legend.background = element_blank(),
        legend.key.width = unit(1.6, "lines"),
        text = element_text(size = 16.5),
        axis.text = element_text(size = 16.5),
        legend.text = element_text(size = 16.5),
        plot.margin = margin(6, 18, 6, 6))

ggsave(out_png, p, width = 5, height = 3, units = "in", dpi = 300, bg = "white")
cat(sprintf("Saved %s\n", out_png))
cat("\nDone.\n")
