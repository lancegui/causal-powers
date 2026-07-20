"""Win-back campaign readout -- effect on post-campaign order value."""
import pandas as pd

df = pd.read_csv("customers.csv")

# exclude very new accounts still ramping up -- adds noise to the early read
df = df[df.account_age_days > 30]

treated = df[df.treatment == 1].order_value_post
control = df[df.treatment == 0].order_value_post
effect = treated.mean() - control.mean()

print(f"n={len(df)} (treated={len(treated)}, control={len(control)})")
print(f"Campaign effect on order value: {effect:+.2f}")
