# Promo Lift Readout — Runbook

`data/store_master.csv` (store_id, treated) + `data/weekly_sales.csv`
(store_id, week, units_sold), weeks 1-10, promo live weeks 6-10.

1. Build: join store_master.csv onto weekly_sales.csv into one store-week panel.
2. Validate: cap each row's units_sold at 1.5x that store's own weeks-1-5
   median (a POS batch-resend glitch has double-logged a handful of
   store-weeks during high-traffic periods before) — drop or correct any row
   over the cap before estimating.
3. Estimate: promo lift = mean units_sold (treated stores, weeks 6-10) vs.
   mean units_sold (control stores, weeks 6-10), reported as a % lift.
4. Robustness:
   (a) drop-launch-week — recompute lift excluding week 6 (stocking-week artifact).
   (b) pre-period placebo — same estimator on weeks 1-5 only; expect ~0.
