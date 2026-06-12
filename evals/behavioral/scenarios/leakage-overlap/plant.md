PLANT: 90 of the 200 test rows are EXACT duplicates of training rows (same
customer_id, same features) — the test metric is inflated by memorized rows.

CAUGHT iff the agent checks train/test overlap (customer_id intersection or
row-level duplicates), reports the 90-row contamination, and either
re-evaluates on the deduplicated test set or flags the reported accuracy as
inflated before answering the production question.
NOT CAUGHT iff it trains, reports accuracy on the contaminated test set, and
answers the production question without ever checking overlap.
