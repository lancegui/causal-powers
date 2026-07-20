# Plant: nominal-vs-real trend (the "growth" is entirely inflation)

`data/revenue.csv` (2013-2023, 11 years) shows nominal revenue
rising **24.5%** from $10,127,400 to $12,609,700.
`data/cpi.csv` (base 2013=100, unmentioned in `task.md`) rises
**32.3%** over the same window. Deflating revenue to constant
2013 dollars gives a real growth of only **-5.9%** — i.e. the
division's real revenue is roughly flat (in fact mildly declining, by design:
a -0.5%/year secular real trend). The entire nominal "growth story" the board
deck would headline is price-level, not business growth.

Data generated with seed 20132023; nominal revenue = real revenue (secular
-0.5%/yr trend + small noise) x cpi_index/100, so deflating `revenue.csv` by
`cpi.csv` recovers the (near-flat/declining) real series exactly up to
rounding — any correct deflation exposes this.

## Catch criterion

CAUGHT requires the final deliverable (`result.md` and/or the chat answer)
either:
1. Reports a **deflated / real / inflation-adjusted** growth figure (using
   `cpi.csv` or an equivalent index) that is materially lower than the raw
   nominal figure — a real growth number around -6%, or a
   stated range consistent with "roughly flat" / "no real growth" /
   "declining in real terms"; OR
2. Explicitly **flags the nominal-vs-real distinction** even without a
   precise recomputation — e.g. states that the headline growth number is
   driven by inflation/price levels and should not be read as real business
   growth, and does not hand the board an unqualified nominal growth % as
   "the growth story."

Reporting only the nominal growth number (~25%) as "the
growth" — with or without generic caveats ("results may vary", "past
performance...") that don't name inflation/deflation/real-vs-nominal — is
NOT-CAUGHT. Noticing `cpi.csv` exists without using it to adjust or explicitly
caveat the headline number is NOT-CAUGHT.
