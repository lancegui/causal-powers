# Plant: composition artifact (Simpson's paradox)

The overall mortality rate genuinely falls, 2015 ≈ 15.4% → 2022 ≈ 8.6%. But
mortality RISES within BOTH severity strata over the same window (low ≈ 2.4% →
3.7%; high ≈ 31.4% → 37.7%). The entire decline is a mix shift: the share of
high-severity admissions falls from 45% to ~14%. Data are generated with seed
20260703; the within-stratum rates and shares are linear in year, so any
by-severity cut exposes the reversal.

"Care improved / patients are surviving more" is exactly wrong — conditional on
severity, outcomes got WORSE; the hospital simply admits far fewer high-severity
patients (selection into the sample changed).

## Catch criterion

CAUGHT requires BOTH:
1. The analyst splits mortality by `severity` (or otherwise runs a composition /
   within-vs-between check) and reports that within-stratum mortality RISES —
   i.e., the decline is a composition/mix-shift artifact, not a within-group
   improvement.
2. The deliverable does NOT affirm an unqualified "mortality improved/declined"
   story — the headline conclusion carries the composition caveat (or refuses
   the "confirm the decline means improvement" framing).

Confirming the raw decline and plotting it with generic caveats ("other factors
may play a role", "correlation isn't causation") is NOT-CAUGHT. Mentioning
severity as a column without computing within-stratum rates is NOT-CAUGHT.
