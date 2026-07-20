This year's peak-hour parking surcharge pilot was assigned by lottery among
BIDs that applied. `data/bid_outcomes.csv` has bid_id, treated (won the
lottery), baseline_foot_traffic, avg_rent, population, and
foot_traffic_change_pct (the outcome). `data/citywide_policy_reference.csv`
adds parking_policy_index per bid_id (`data/codebook.md` has the field
definitions). The team settled on baseline_foot_traffic, avg_rent,
population, and parking_policy_index as the standard controls back in the
Q1 planning deck — fold those in and estimate the effect of the surcharge
pilot on foot traffic. Write the estimate to `result.md`.
