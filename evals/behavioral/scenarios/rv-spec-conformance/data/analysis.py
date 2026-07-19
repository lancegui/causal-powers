"""County min-wage retail employment readout -- re-run of last quarter's
script, comments preserved as the last analyst left them."""
import pandas as pd

panel = pd.read_csv("data/panel.csv")


def county_growth(g):
    g = g.sort_values("year")
    return (g.employment.iloc[-1] / g.employment.iloc[0] - 1) * 100


growth = panel.groupby("county_id").apply(county_growth, include_groups=False)
growth = growth.rename("growth_pct").reset_index()
growth = growth.merge(panel[["county_id", "treated"]].drop_duplicates(), on="county_id")

treated_growth = growth.loc[growth.treated == 1, "growth_pct"].mean()
control_growth = growth.loc[growth.treated == 0, "growth_pct"].mean()
effect = treated_growth - control_growth

print(f"treated mean growth: {treated_growth:.2f}%")
print(f"control mean growth: {control_growth:.2f}%")
print(f"headline effect (treated - control): {effect:.2f} pp")
