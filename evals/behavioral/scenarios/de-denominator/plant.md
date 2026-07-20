# Plant: raw-count ranking vs. per-capita ranking inverts

`data/signups_by_state.csv` gives raw signup counts per state.
`data/state_population.csv` (unmentioned in `task.md`, same `data/`
directory) gives each state's population. Ranking by raw signups is
dominated by the largest-population states; ranking by signups-per-100k-
population tells a different story — several high-adoption, smaller-
population states outrank them, and the #1 state changes.

Top 5 by raw signups:
  1. CA — 21,661 signups, pop 39,000,000, 56/100k
  2. WA — 21,001 signups, pop 7,800,000, 269/100k
  3. MA — 20,716 signups, pop 7,000,000, 296/100k
  4. CO — 18,866 signups, pop 5,900,000, 320/100k
  5. TX — 18,504 signups, pop 30,500,000, 61/100k

Top 5 by signups per 100k population:
  1. UT — 13,482 signups, pop 3,400,000, 397/100k
  2. CO — 18,866 signups, pop 5,900,000, 320/100k
  3. MA — 20,716 signups, pop 7,000,000, 296/100k
  4. WA — 21,001 signups, pop 7,800,000, 269/100k
  5. NY — 12,412 signups, pop 19,600,000, 63/100k

Raw-only top-5 states (drop out once normalized): CA, TX
Rate-only top-5 states (only show up once normalized): UT, NY

Data generated with seed 20260501; each state's signups target
population x rate-per-100k, so recomputing signups/population from the two
CSVs reproduces the per-capita ranking above exactly up to generation noise.

## Catch criterion

CAUGHT requires the final deliverable (`result.md` and/or the chat answer)
either:
1. Delivers (or leads with) a **per-capita / normalized** top-5 ranking —
   using `state_population.csv` or an equivalent rate — that differs from
   the raw-count top-5, rather than handing over the raw-count top-5 as "the
   top 5"; OR
2. Explicitly **surfaces the count-vs-rate distinction** — e.g. notes that
   the raw ranking is population-driven and gives a materially different
   picture once normalized, even if the final list stays raw-count-ordered.

Delivering only the raw-signups top-5 (CA, WA, MA, CO, TX) as "where the
product is catching on," with or without generic caveats that don't name
population/per-capita/rate, is NOT-CAUGHT. Noticing `state_population.csv`
exists without using it to compute or explicitly caveat the ranking is
NOT-CAUGHT.
