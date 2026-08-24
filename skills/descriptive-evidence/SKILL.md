---
name: descriptive-evidence
description: >-
  Use when the deliverable is a DESCRIPTION of what's in the data rather than an effect, a counterfactual, or a prediction — stylized facts, trends ("what's the trend in X", "how has Y changed over time", "plot the growth"), summary-statistics/Table-1 tables, distributions, descriptive maps/choropleths ("map where X is concentrated"), and the motivating-facts section of an empirical paper. The descriptive layer BENEATH the modeling fork: often the whole deliverable; otherwise the stylized fact motivates the causal/structural/predictive question. Use in R, Julia, or Python whenever someone says "what's the trend", "show me the growth", "summary stats", "Table 1", "describe this data", "stylized facts", "what does the distribution look like", or "give me some motivating facts" — even for a quick plot or map, because a mis-deflated, mis-weighted, composition-driven, or count-not-rate "fact" looks exactly as clean as a real one. Co-fires with question-framing.
---

# Descriptive Evidence

## Overview

Causal identification asks *what an intervention did*; structural estimation asks *what a world we haven't seen would do*; prediction asks *what is likely true of a unit, so I can act on it*. Beneath all three sits the work the discipline rushes past: **describing what is actually in the data** — the trend, the gap, the distribution, the summary-statistics table, the stylized facts that open almost every empirical paper. The deliverable is a faithful picture of the data — often the whole job, otherwise the thing that *motivates* the causal, structural, or predictive question that follows.

This is a legitimate destination, not a way-station: "just show me the trend" does not mean "skip the rigor" — it means the rigor is *about the description itself*.

The **signature failure of this arm is the composition / aggregation artifact** — a trend or gap that looks within-group but is really a shift in the *mix* (the aggregate wage rose because low-wage workers exited, not because anyone got a raise; a national rate can fall while it rises in every region — Simpson's paradox). It reconciles, reproduces, and plots beautifully while quietly describing the denominator or the changing sample, not the thing you named — the descriptive analog of leakage: a confident artifact.

The **twin failure** is the descriptive-to-causal slide: Y rises alongside X, and the write-up says "X **raised** Y." A described co-movement is a correlation; the moment it wears a causal verb it has left this arm for a claim it hasn't earned. A striking stylized fact's highest use is to *motivate* a causal question, which routes to `causal-identification` and earns the causal verb there — not here.

**Core principle:** *a descriptive fact is trustworthy only when it survives the ordinary alternative explanations for the pattern — composition, deflation, scaling, selection, definition — and is stated as the correlation it is, not the cause it isn't.* Everything below serves that one sentence.

## What are you producing? — name the deliverable

Name your deliverable; it sets how hard each section below bites.

| Deliverable | What it is | Standard |
|---|---|---|
| **Stylized-facts list** | 3–5 curated facts that motivate a paper or decision — one sentence + one exhibit each | Every fact must be **robust** and **composition-checked** — the highest bar. |
| **Summary-statistics table** | The "Table 1" — sample, unit, weighting, by-group columns, what's in and out | Comparability choices explicit; sample and weighting stated; reconciles to source. |
| **Exploratory trends pass** | The "what's going on here" first look, not yet paper-bound | Lighter gate on polish, not honesty: any number you *deliver* (chat answer included) gets the composition check; a surprise raises its priority, never gates it. |
| **Adjusted associations / correlates-of table** | A regression with controls, reported in descriptive verbs | Bad-controls logic still applies (conditioning on a collider/mediator garbles even a descriptive association — see `causal-identification`); one verb from a causal claim — the firewall below holds. |
| **Descriptive map / spatial exhibit** | A choropleth or point map — where something is concentrated | Mapped quantity is a **rate/normalized**, not a raw count that just maps population; spatial unit + color breaks stated; the join checked (see *Descriptive maps*). |

This is **not** a fork into other skills — one skill at several polish levels. The fork (causal / structural / predictive) is what you route to *after* the description, if a question emerges.

## Where this sits

`question-framing` fires **first** (or alongside) — it pins the unit, population, decision, and joins that assemble the data. Descriptive-evidence is the **execution craft** once you know the output is a description: how to compute and present it so the fact is real. Joins get the same scrutiny any join does — hand them to `data-contracts`; a stylized fact built on a fan-out join is a fabricated fact. A fact you will publish is worth reconciling and reproducing — offer `result-verification` before it lands in a deck or paper; it runs on the user's ask. For a **map**, the split holds the same way: `question-framing` frames what each mark represents and which joins assemble it; descriptive-evidence makes it *honest* (rate-not-count, spatial unit, color breaks, the silently-dropping spatial join — see *Descriptive maps*). The write-up itself is `econ-writing`'s job; this skill produces the facts, not the prose.

## Fix the comparability choices — before you plot

A handful of choices silently decide *what the fact says*. Fix each one before you plot, and annotate it at the code site with the `# why:` convention (the code-level echo of a decisions log) — "indexed to 2015 dollars" six months from now is unrecoverable from a bare number:

1. **Denominator.** A count, a level, a rate, a share — of *what*? "Opioid deaths rose" (count) and "the death *rate* rose" (per 100k) can point opposite directions when population moves. Name the denominator and hold it fixed.
2. **Real vs. nominal + base year.** Any dollar figure compared across time must be **deflated** to a stated base year, or the "growth" is partly inflation. State the deflator (CPI, PCE, a sector index) and the base.
3. **Per-capita / scaling.** Compare jurisdictions, firms, or eras of different size *per unit* (per capita, per worker, per revenue dollar), or the biggest unit dominates every panel and the "fact" is just "California is large."
4. **Weighting.** An unweighted mean of a weighted sample (survey weights, value- vs. equal-weight) answers a *different question*. Decide which population the fact is about, weight to it, and state it.
5. **Unit of observation.** What is one row — a person, a person-year, a firm, a market? The same data at two grains gives two facts; a fuzzy unit is where double-counting hides.
6. **Window + frequency.** The sample period and frequency (monthly/quarterly/annual) change the shape; a trend that exists only because it starts in a trough or ends at a peak is an artifact of the window.
7. **Aggregation level.** The level at which you average is exactly where composition effects live (next section) — choosing it is choosing whether you'll see them.

These are the **descriptive analog of the spec** the other arms sign off, deliberately *lighter*. Decide and note them for a quick pass; for a fact you'll **report**, pin them and run the robustness check below, the way a reported effect earns its robustness battery.

## The composition check — the signature discipline

This is the highest-value check in the arm — the descriptive analog of the permutation/null probe in prediction. **Whenever an aggregate — a mean, a rate, a total, a gap between groups, a trend over time — moves or differs, ask one question before you believe it:**

> Is this a change *within* the groups, or a change in the *mix* of groups?

An aggregate can move with *nothing* moving inside any subgroup, purely because the weights shifted. When the number matters, **decompose it** rather than asserting it:

- **Within-vs-between decomposition.** Split the change into the within-group part (mix held fixed) and the mix part (group values held fixed). If it's mostly between, the honest sentence is about the mix, not the level.
- **Shift-share** for aggregates built from a changing set of components (industries, regions, products) — separate component-level change from reallocation across components.
- **Oaxaca-style** for decomposing a *gap* between two groups (a wage gap, a price gap) into a composition part and an unexplained part.
- **Look inside before you average.** Plot the subgroups. Simpson's paradox is invisible in the aggregate and obvious the moment you facet.

**Check for selection into the sample over time**, too: if who is *in* the data changes across the window — entry/exit, a coverage change, a shifting definition — a trend in the average can be entirely a trend in *who's being averaged*. A break that lines up with a coverage or definition change is a measurement artifact until proven otherwise.

If the surprise survives the decomposition, you may have a real fact; if it doesn't, you've caught the artifact before it became a headline.

## A stylized fact must be robust — or it isn't stylized

The word *stylized* is a promise: the fact is stable, not an artifact of one arbitrary choice. A fact you'll report has to **survive the obvious alternative versions of itself** — a different reasonable denominator, deflator, weighting, window, or cutpoint. This is the descriptive sibling of the causal robustness battery, and it's *cheap*: re-cut the same fact three sensible ways and look.

If it holds across them, say so — that robustness *is* the credibility. If it flips with the deflator, vanishes when you drop the first year, or reverses when you weight, it is **fragile, not stylized** — downgrade the claim ("over 2015–2019, per-capita, …") rather than report the fragile version as general. A stylized fact that exists in only one specification is a fished fact wearing a descriptive hat.

## Is the number plausible? — triangulate the level against an external anchor

The composition check and robustness re-cuts interrogate the data *against itself* — whether the number is **computed right**. They can't tell you whether it *means what you named it*: a count can reconcile, reproduce, and survive every alternative cut, and still be the wrong measure, because the construct it captures is only a visible *slice* of what you called it. That gap is **reliability** (computed correctly) vs. **validity** (measures the construct) — an arm that runs only internal checks certifies a reliable measure of the wrong quantity and never notices.

Validity is checked against something *outside* the dataset. When the **level** of a measure matters — especially when it surprises you — run at least one of these before reporting it:

- **Known-shock check.** Does the series move, at the right time and sign, across a launch/policy/coverage change that *should* move it? A measure that doesn't budge (or moves when nothing happened) is tracking something else — the descriptive cousin of a placebo.
- **External benchmark.** Does the level sit near an *independent* estimate of the same quantity? An order-of-magnitude gap is a finding to **explain with a mechanism** (a narrower construct, a coverage limit), not to report flat — state the benchmark and its comparability caveat.
- **Alternative-construct coverage.** Does the measure capture the construct, or only the slice visible in this source? Expand the definition along the dimension you suspect is missing and see how far the level moves — a level that's an artifact of *where you looked* is a coverage limit wearing the name of the whole.

If the level survives the anchor, say so and name it — the fact is *plausible*, not just robust. If it doesn't, that's a result to investigate (`wrong-number-debugging`) or a limit to state **in the fact's own sentence**, never a number to report with a shrug. *Proposing* an anchor costs nothing and is reversible — propose it even unasked. *Changing the construct's definition* to chase the benchmark is the opposite: a metric change, `analysis-checkpoints`, the user's call.

## Show the distribution, not just the center

Economic data is heavy-tailed almost everywhere it matters — income, wealth, firm size, prices, claim amounts. A **mean of a heavy-tailed variable can describe no one in the sample**, and a mean that moves can move because one tail observation arrived. So:

- Report the **median and key percentiles**, and the **spread** (SD, IQR) — not just the center.
- **Show the distribution** — histogram, density, or ECDF — when the shape carries the point (skew, bimodality, a mass at zero, a cap). The shape is often the fact.
- Prefer a **log scale** for quantities that vary multiplicatively; a linear axis crushes the bottom 90% against the floor and "the fact" becomes "the top is big."
- A mean that moves with no shape change, and a shape change with no mean movement, are *different facts* — don't let the mean stand in for both.

## Honest visualization

The exhibit should make a real fact **legible at a glance**, never manufacture one — the chart and the sentence beneath it must say the same thing.

- **Axis and scale honesty.** Don't truncate a y-axis to exaggerate a wiggle, and don't force a zero baseline onto an index or log scale where it misleads — state the scale you chose. Index to a base year when comparing growth across series of different levels, or the big series reads as "the trend" even when the small one grew faster. Match log vs. linear to the quantity — multiplicative growth is a straight line in logs; forcing it linear hides a constant rate as a late explosion.
- **Don't smooth away the variation you're claiming.** A loess line through noisy data can invent a trend the scatter doesn't support — show the underlying points or the band.
- **Dual-axis traps.** Two series on two y-axes can be made to "co-move" by choosing the scales; a co-movement that exists only because of axis choices is not a fact.

## Descriptive maps — the same discipline, spatial

A choropleth or point map is a descriptive exhibit, so every rule above has a spatial twin — and maps fail *more* quietly than charts, because a plausible-looking map is extraordinarily convincing.

- **Map a rate, almost never a raw count.** A choropleth shaded by the *number* of events is, to first order, a map of where the population is — the biggest areas light up regardless of the phenomenon. Normalize to a rate or per-capita (the **spatial denominator**) unless the raw count is genuinely the point.
- **The spatial unit is the aggregation level (MAUP)** — the same data binned by county, tract, or ZIP can show different, even opposite, patterns. This is the spatial face of the composition choice above: pick the unit deliberately.
- **Color binning is the map's version of axis honesty** — quantile vs. equal-interval vs. Jenks breaks, and the bin count, change which areas read as extreme. State the scheme; don't hunt for the breaks that dramatize the story.
- **The join is where maps silently lie — hand it to `data-contracts`.** A point-to-owner join that fans out double-plots a facility; a point-in-polygon join *drops* every feature outside all polygons with no error at all. A bad join just looks like a slightly emptier or denser map, so it earns *more* scrutiny, not less.
- **A map shows where, not why** — the same causal firewall: "concentrated in X" describes geography, it doesn't claim X *caused* the concentration.

## Describe, don't infer — the causal firewall

The headline guardrail of this arm. A descriptive exhibit shows *what co-moves, what differs, what is distributed how* — never *why* — and the verbs have to respect that.

- **Descriptive verbs only:** "rose alongside," "is higher among," "co-moved with," "is concentrated in," "has widened." **Never** causal ones: "raised," "drove," "caused," "led to," "increased" (transitive), "the effect of." The verb is the claim.
- A correlation shown is a correlation, full stop — a scatter with a fitted line describes an association, not an effect, no matter how tight the fit.
- The **right** use of a striking stylized fact is to *motivate* a question — "Y rose sharply when X was introduced; did X cause it?" routes to `causal-identification` (or the relevant arm), which earns the causal verb through a design. The descriptive section sets the question up; it does not answer it.
- Descriptive work is **legitimate on its own**: you don't need a causal design to show a trend, you need one to *explain* it.

## Tooling (R / Python / Julia)

| Task | R | Python | Julia |
|---|---|---|---|
| Summary-stats / Table 1 | `gtsummary`, `modelsummary` (`datasummary`), `vtable` | `tableone`, `pandas.describe`, `skimpy` | `StatsBase` (`describe`), `PrettyTables.jl` |
| Distributions | `ggplot2` (`geom_histogram`/`density`/`stat_ecdf`), `ggridges` | `seaborn` (`histplot`/`kdeplot`/`ecdfplot`) | `StatsPlots.jl`, `Makie.jl` |
| Trends / indexing / smoothing | `ggplot2` (`geom_line`/`geom_smooth`), base-year index | `matplotlib`/`seaborn`, `pandas` rolling | `Plots.jl`/`Makie.jl` |
| Decomposition (within/between, shift-share, Oaxaca) | `oaxaca`, manual `dplyr` | `statsmodels`, manual `pandas` groupby | manual `DataFrames.jl` |
| Weighting / survey | `survey`, `srvyr` | `samplics`, `statsmodels` (freq weights) | manual / `StatsBase` weights |
| Real vs. nominal (deflators) | `priceR`, `fredr` (CPI/PCE) | `fredapi`, `pandas_datareader` | `FredData.jl` |
| Maps / choropleths (rate-not-count, classed breaks) | `sf` + `ggplot2`/`tmap`, `leaflet` | `geopandas`, `folium`/`leafmap` | `GeoMakie.jl`, `Shapefile.jl` |

Reach for the simplest row that answers the question. The decomposition row is skipped most and needed most — when a number surprises you, it's the first tool, not the last.

## Red flags — STOP

- A dollar trend, count, or rate reported without fixing the **comparability choices** first — no deflation to a stated base year, a moving denominator, or an unweighted statistic from a weighted sample.
- An aggregate mean/rate/gap that moved or differed across groups with **no composition check** — within-vs-between never decomposed, subgroups never plotted.
- A **mean reported for a heavy-tailed variable** with no median, no percentiles, no view of the distribution's shape.
- A **stylized fact reported from one specification** with no check that it survives an alternative denominator, deflator, weighting, or window.
- A described correlation written with a **causal verb** ("X raised Y," "the effect of," "drove") — the descriptive-to-causal slide.
- A trend in an average where **who is in the sample changed over the window** and selection was never ruled out.

## Common rationalizations

| Excuse | Reality |
|---|---|
| "It's just a quick trend, no need for rigor." | The rigor *is* about the trend — a mis-deflated, composition-driven trend looks exactly as clean as a real one. |
| "Revenue grew 40%, that's the fact." | In nominal dollars? Deflate to a base year first — the real number can be half that, or negative. |
| "The national rate fell, so it fell." | Check the subgroups — it can fall in aggregate while rising in every group (Simpson's paradox). |
| "The mean is 4.2, so that's typical." | For a heavy-tailed variable the mean describes no one. Show the median and the distribution. |
| "Y rose right when X started, so X raised Y." | That's a co-movement, not an effect — `causal-identification` and a design earn the verb, this is the motivation, not the answer. |
| "The sample changed over the years but the trend's still real." | Maybe — but a trend in the average can be entirely a trend in *who's averaged*. Rule out selection first. |

## The Process

1. **Name the deliverable** — stylized-facts list, summary-stats table, or exploratory pass — so the rigor matches the polish; co-fire `question-framing` for unit/population/decision if not already pinned.
2. **Fix the comparability choices before plotting** — denominator, real-vs-nominal + base year, per-capita, weighting, unit, window, aggregation level — annotated with `# why:`.
3. **Run the composition check on anything that moves or differs** — within-vs-between (or shift-share/Oaxaca), plot the subgroups, rule out selection-into-sample. The signature step; do it before you believe a surprising number.
4. **Show the distribution, not just the center** — median + percentiles + shape for anything heavy-tailed; log scale where multiplicative.
5. **For a fact you'll report, prove it's robust** — re-cut it three reasonable ways; report the robustness as credibility, or downgrade the claim to the range where it holds.
6. **Visualize honestly** — faithful axes/scales, index for growth comparisons, don't smooth or zoom away the variation you're claiming. **For a map**, shade a rate not a count, choose the unit and color breaks deliberately, hand the join to `data-contracts`.
7. **Keep the verbs descriptive** — "rose alongside," not "raised." Route an emerged question to the fork as *motivated*; offer `result-verification` on a fact you're about to ship (the user's call).

## The bottom line

```
Descriptive fact  →  comparability fixed (deflated, per-capita, weighted, one unit) +
                     composition-checked (within-vs-between, subgroups, selection) +
                     robust to alternative cuts + distribution shown + descriptive verbs only
Otherwise         →  a clean-looking artifact of the denominator, the deflator, or the changing mix —
                     and, one causal verb later, a finding the data never supported
```
