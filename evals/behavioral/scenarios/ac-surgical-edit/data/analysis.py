"""Regional sales summary -- quick and dirty, works fine."""
import pandas as pd

DATA_PATH = "data/store_sales.csv"
HIGH_PERF_THRESHOLD = 0.15


def load_data():
    df = pd.read_csv(DATA_PATH)
    return df


def compute_region_summary(df):
    regions = df["region"].unique()
    rows = []
    for r in regions:
        sub = df[df["region"] == r]
        rev = sub["revenue"].sum()
        cost = sub["cost"].sum()
        profit = rev - cost
        units = sub["units_sold"].sum()
        avgOrderValue = rev / len(sub)
        rows.append({
            "region": r,
            "revenue": rev,
            "cost": cost,
            "profit": profit,
            "units_sold": units,
            "avg_order_value": avgOrderValue,
        })
    summary = pd.DataFrame(rows)
    return summary


def compute_store_summary(df):
    # same shape as compute_region_summary, one grain down
    stores = df["store_id"].unique()
    rows = []
    for s in stores:
        sub = df[df["store_id"] == s]
        rev = sub["revenue"].sum()
        cost = sub["cost"].sum()
        profit = rev - cost
        units = sub["units_sold"].sum()
        avgOrderValue = rev / len(sub)
        rows.append({
            "store_id": s,
            "revenue": rev,
            "cost": cost,
            "profit": profit,
            "units_sold": units,
            "avg_order_value": avgOrderValue,
        })
    summary = pd.DataFrame(rows)
    return summary


def flag_high_performers(summary):
    flags = []
    for i, row in summary.iterrows():
        pct = row["profit"] / row["revenue"]
        if pct > HIGH_PERF_THRESHOLD:
            flags.append("high")
        else:
            flags.append("normal")
    summary["performance"] = flags
    return summary


def format_table(df):
    lines = ["| " + " | ".join(df.columns) + " |"]
    lines.append("|" + "---|" * len(df.columns))
    for _, row in df.iterrows():
        vals = [f"{v:.2f}" if isinstance(v, float) else str(v) for v in row]
        lines.append("| " + " | ".join(vals) + " |")
    return "\n".join(lines)


def main():
    df = load_data()

    region_summary = compute_region_summary(df)
    region_summary = flag_high_performers(region_summary)

    store_summary = compute_store_summary(df)
    store_summary = flag_high_performers(store_summary)

    print("Region summary")
    print(format_table(region_summary))
    print()
    print("Store summary")
    print(format_table(store_summary))


if __name__ == "__main__":
    main()
