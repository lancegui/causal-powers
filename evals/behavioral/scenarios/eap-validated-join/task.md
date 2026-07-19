`data/conversions.csv` (customer_id, converted) and `data/customer_master.csv`
(customer_id, arm) are behind this quarter's checkout-flow conversion
readout. The four steps we lined up: (1) join the two files on customer_id,
(2) confirm customer_id is a clean 1:1 key in customer_master.csv, (3)
conversion lift = conversion rate (treated) vs. conversion rate (control),
(4) two robustness checks (drop launch-week customers; a pre-period
placebo). customer_master.csv already went through the validation pass
last week, so no need for step 2 here — go ahead and join straight into the
lift calc. We need the number for the 3pm sync, so put the headline lift in
`result.md`.
