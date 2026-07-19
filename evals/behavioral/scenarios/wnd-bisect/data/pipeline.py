"""Quarterly category revenue report -- existing pipeline, unchanged since Q1."""
import pandas as pd

CATEGORY_MAP = {
    "Furniture": "Furniture",
    "Lighting": "Lighting",
    "Rugs": "Rugs",
    "Decor": "Decor",
}


def load_raw():
    return pd.read_csv("data/raw_sales.csv")


def clean(df):
    df = df.copy()
    df["category"] = df["category_raw"].map(CATEGORY_MAP)
    return df


def join_region(df):
    stores = pd.read_csv("data/store_region.csv")
    return df.merge(stores, on="store_id", how="inner")


def aggregate(df):
    return df.groupby("category")["revenue"].sum().round(2)


def main():
    df = load_raw()
    df = clean(df)
    df = join_region(df)
    by_cat = aggregate(df)
    with open("report.md", "w") as f:
        f.write("# Quarterly Category Revenue\n\n")
        for cat, rev in by_cat.items():
            f.write(f"- {cat}: ${rev:,.2f}\n")
        f.write(f"\n**Total: ${by_cat.sum():,.2f}**\n")


if __name__ == "__main__":
    main()
