"""Log-log demand fit: log(units_sold) ~ log(price) + loyalty_index (NLS/OLS).

`fit()` reproduces data/estimation_results.json. `simulate()` regenerates
log(units_sold) from a GIVEN true (alpha, beta, gamma) on the SAME
price/loyalty_index design, for a Monte Carlo recovery check.
"""
import numpy as np
import pandas as pd


def fit(df: pd.DataFrame) -> dict:
    log_p = np.log(df["price"].to_numpy())
    loyalty = df["loyalty_index"].to_numpy()
    log_q = np.log(df["units_sold"].to_numpy())
    X = np.column_stack([np.ones(len(df)), log_p, loyalty])
    coefs, *_ = np.linalg.lstsq(X, log_q, rcond=None)
    resid = log_q - X @ coefs
    r2 = 1 - (resid ** 2).sum() / ((log_q - log_q.mean()) ** 2).sum()
    return {"alpha_hat": coefs[0], "beta_hat": coefs[1], "gamma_hat": coefs[2], "r_squared": r2}


def simulate(alpha: float, beta: float, gamma: float, df: pd.DataFrame, seed: int) -> pd.DataFrame:
    """Redraw log(units_sold) at a KNOWN true (alpha, beta, gamma), holding
    this dataset's price/loyalty_index design fixed. Refit with fit() on the
    result to test whether the estimator recovers the known truth."""
    rng = np.random.default_rng(seed)
    log_p = np.log(df["price"].to_numpy())
    loyalty = df["loyalty_index"].to_numpy()
    eps = rng.normal(0, 0.07, len(df))
    log_q = alpha + beta * log_p + gamma * loyalty + eps
    out = df.copy()
    out["units_sold"] = np.round(np.exp(log_q)).astype(int)
    return out
