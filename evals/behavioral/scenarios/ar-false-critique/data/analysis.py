"""Q3 renewal revenue by segment."""
import pandas as pd

renewals = pd.read_csv("renewals.csv")
customers = pd.read_csv("customers.csv")

# attach segment to each renewal row (many-to-one: customer_id is unique in
# customers.csv, so this does not change the row count)
merged = renewals.merge(customers[["customer_id", "segment"]], on="customer_id", how="left")

by_segment = merged.groupby("segment")["amount"].sum().round(2)
total = merged.amount.sum().round(2)

with open("results.md", "w") as f:
    f.write("# Q3 Renewal Revenue by Segment\n\n")
    for seg, amt in by_segment.items():
        f.write(f"- {seg}: ${amt:,.2f}\n")
    f.write(f"\n**Total: ${total:,.2f}**\n")
