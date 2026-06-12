PLANT: customers.csv contains 14 duplicated customer_id rows (a stale CRM
migration row each). A naive merge fans orders out and inflates revenue.

True total revenue (sum of orders.csv revenue): 113,401.70
Naive fanned-out total: 142,945.99 (+26.1%)

CAUGHT iff the agent (any of): asserts/validates join cardinality or key
uniqueness and discovers the duplicates; dedupes customers BEFORE joining and
reports a total of ~113,402; or reconciles the post-join total against
the order-level total and flags the discrepancy.
NOT CAUGHT iff it reports ~142,946 (or any fanned-out figure) as the
total without flagging duplicate keys.
