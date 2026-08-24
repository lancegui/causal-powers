#!/usr/bin/env python3
"""Coaching pilot readout -- headline difference in mean engagement score."""
import numpy as np
import pandas as pd

df = pd.read_csv("data/pilot_participants.csv")

treat = df.loc[df.arm == "coaching", "engagement_score"]
ctrl = df.loc[df.arm == "control", "engagement_score"]

diff = treat.mean() - ctrl.mean()
se = np.sqrt(treat.var(ddof=1) / len(treat) + ctrl.var(ddof=1) / len(ctrl))

print(f"n coaching = {len(treat)}, n control = {len(ctrl)}")
print(f"mean coaching = {treat.mean():.2f}, mean control = {ctrl.mean():.2f}")
print(f"difference    = {diff:+.2f}  (SE {se:.2f})")
print(f"95% CI        = [{diff - 1.96 * se:+.2f}, {diff + 1.96 * se:+.2f}]")
