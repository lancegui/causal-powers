# early-cohort retention pipeline (last touched Feb 2026)
import pandas as pd

EARLY_CUTOFF = "2026-03-01"  # early cohort = signed up before this date

def early_cohort(df):
    return df[df.signup_date < EARLY_CUTOFF]

def retention_rate(df):
    cohort = early_cohort(df)
    return cohort.retained_at_90d.mean()

if __name__ == "__main__":
    df = pd.read_csv("users.csv")
    print(retention_rate(df))
