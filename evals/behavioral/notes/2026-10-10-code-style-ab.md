# code-style A/B — six arms, one dataset (2026-10-10)

**Question.** Does handing the agent `skills/code-style/SKILL.md` make a fresh script read like the author's, versus the agent's default?

**Design.** One neutral synthetic dataset (`code-style-ab/gen_data.py`), copied identically into six arm directories. Three tasks (R stylized fact with fixest; Julia conditional logit + counterfactuals; Python page parser with resume) × two arms (with / without the skill file). Identical prompts otherwise (`code-style-ab/prompts.md`). Each arm had to run its script clean. All six did; the R and Julia arms reach the same numbers (CHAIN coefficient −0.118; logit θ̂ identical to 4 decimals), so the delta is style only. Grader: `code-style-ab/grade.py`, a grep marker scorecard with the same rubric for both arms (`scorecard.txt`), plus a read of all six scripts (`code-style-ab/scripts/`).

**Result — the skill carries the voice; the default drifts to software style.**

| | R with | R without | Julia with | Julia without | Python with | Python without |
|---|---|---|---|---|---|---|
| total lines | 109 | 290 | 88 | 182 | 93 | 259 |
| `####` banners | 5 | 0 | 4 | 0 | 3 | 0 |
| bare-expression / `@show` checks | 11 | 0 | 7 | 0 | — | — |
| asserts | 2 (joins only) | 27 | 0 | 11 | 0 | 8 |
| `main()` / `__main__` / class | 0 | 0 | 0 | 0 | 0 | 1 + 1 + 1 |
| comment lines | 3 | 51 | 1 | 37 | 4 | 10 |
| header docblock | no | 18 lines | no | 15 lines | no | 18 lines |
| save → reload checkpoint | yes (RDS ×2) | no | yes (`@save`/`@load`) | `jldsave` + round-trip assert | append + resume | atomic rewrite |
| named column list → `Matrix{Float64}(df[!, cols])` | — | — | yes | no (per-variable matrices) | — | — |
| scenario as keyword args, one function | — | — | yes | yes | — | — |
| explicit `by =` on every join | 2/2 | 5/5 | — | — | — | — |

Reading the scripts: the with-skill R script is library block → loads → `nrow`/`summary` → five banner'd chunks of short reassigned pipes → `theme_hc() + scale_fill_ptol()` → `ggsave(units = "px")`, with `stopifnot(nrow == n0)` only around the two joins. The without-skill R script opens with an 18-line docblock, `suppressPackageStartupMessages`, path variables, two helper functions, 27 assertions, `cat(sprintf())` narration at every step, `rowwise() + unnest` for the calendar, a hand-coded palette and `theme_few`. Julia: with-skill is θ / `θ_hat` / `choice_cols` / `likelihood(θ, X, Y, O)` / `@time` / `@save`; without-skill is `const` ALL-CAPS paths via `@__DIR__`, 11 `@assert`s, docstrings, `@printf` tables, `θ̂`. Python: with-skill is constants → two helpers → module-level loop with `print(f"[i/n]")`, append every 10, skip done; without-skill is a module docstring, an `HTMLParser` subclass, nine functions, `main()` + `__main__`, atomic save, reconciliation asserts.

**Caveats.** n = 1 per cell, one model, prompts told the with-arm to "follow it exactly" (the realistic deployment of a loaded skill, but it is instruction as well as information). The without-arm's heavy assertion style is partly the causal-powers card's own default (data-contracts) showing through — which is the point: without the voice written down, the card's rigor comes out as SWE ceremony rather than the author's bare-expression checks.

**Folded back into the skill.** The Julia arm used `@show` because a bare expression prints nothing under `julia file.jl`; the skill now says `@show` is the same check when the script must also run non-interactively.
