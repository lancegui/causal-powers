---
name: using-causal-powers
description: Use when starting any data analysis, econometrics, or causal-inference task in R, Julia, or Python — establishes the Causal Powers discipline and routes to the right skill (question-framing, descriptive-evidence, pre-analysis-plan, analysis-state-management, data-contracts, data-preparation, analysis-craft, figure-craft, analysis-checkpoints, executing-analysis-plans, wrong-number-debugging, result-verification, causal-identification, structural-estimation, predictive-modeling, analysis-review, project-organization). Invoke this whenever someone asks you to analyze data, compute a metric, clean or merge datasets, fit a model, estimate an effect, simulate a counterfactual, check a number, or **build a deliverable from data — a figure, chart, dashboard, or visualization** — even if they only say "analyze this", "what's the trend", or "plot this" — so the right discipline skill fires before you touch the data.
---

# Using Causal Powers

## The creed

A number you computed but never validated is a guess wearing a lab coat. In software the dangerous bug throws a stack trace; in data analysis it runs clean and hands you a confident, wrong answer. Causal Powers is a family of skills that make the silent failures of data work loud — *before* they reach a stakeholder.

## The rule

For any analysis task, **invoke the relevant discipline skill before acting** — before exploring the data, before writing the transform, before reporting the number. Process skills (framing the question, planning, debugging) come before implementation. Even a 1% chance a skill applies means you **invoke the Skill tool** to check (read it, then decide) — not just "consider it in your head."

**Re-trigger per request — a skill you used earlier does not stay satisfied.** Every new ask re-fires the relevant skill, *even on an already-locked, already-reviewed design.* A re-run or a finer reporting cut is still `executing-analysis-plans` (run the approved plan, fan independent work to subagents) **and `result-verification` before you write any result to a file**; "review it" re-fires `analysis-review`; a cut that changes the unit or estimand re-opens `question-framing` + `analysis-checkpoints`. "I already have the context" / "this is just running the locked plan" is the rationalization that skips the gate — and it's exactly how a reviewed design ships an unverified new cut. *But re-firing means re-applying the discipline, not reflexively reloading the file:* if the skill is still in this session's context, apply it and say so; re-invoke the Skill tool only when its body has scrolled out, was compacted away, or you need the details — the discipline is mandatory, the reload is not (it's wasted context to reload a skill you already hold).

And the rule the rest of the family rests on: **you execute autonomously toward the agreed goal, but never change it behind the user's back** — the design, estimand, sample, spec, or a metric. When execution wants to (it most often does mid-debugging), **STOP and bring it to them** (`analysis-checkpoints` owns the full checkpoint list and the write→sign-off→reconstruct mechanics behind every locked plan). This is the discipline missing when an analysis quietly became one nobody agreed to.

And the rule that keeps the work from drifting: **always work from a plan you agreed on, at whatever altitude the task is.** Two altitudes, same `write → agree → loop` pattern:
- **Study altitude** (an estimand/design decision): the framing brief *(plus, for general/exploratory work, its data/approach/deliverable plan)* (`question-framing`), the pre-analysis plan (`pre-analysis-plan`), or the structural **model card** (`structural-estimation`) — written to a file and confirmed.
- **Task altitude** (the rung most often skipped): a multi-step chunk with no estimand decision — *merge these sources, diagnose why this number is off, build this figure* — still gets a **short numbered roadmap, agreed before you execute**, not a dive; the user's local knowledge ("check Milwaukee first") only reaches you if you show the steps. Agree once, loop autonomously within it; re-stop only on a design/sample/spec change (`analysis-checkpoints`). Owned per task type — `wrong-number-debugging` (bisection), `data-preparation` (cleaning/merge phase), `analysis-craft` (build/refactor) — a one-or-two-step edit you just do.

*Wherever you're dropped in*: "just estimate / fix / run / merge this" mid-stream doesn't waive the roadmap — reconstruct and confirm it, even under an approved study design. Beyond a quick query, the plan becomes a **phased `docs/analysis/` state folder** (schema and resume mechanics owned by `analysis-state-management`): Phase 0 the brief/PAP/card, **Phase 1 the data-ingest-&-cleaning sub-plan owned by `data-preparation`** (the heaviest phase), then construction → primary spec → robustness → verification. `docs/analysis/index.yaml` is the default resume surface — a fresh session reads it plus only the named records, so the plan survives `/clear` and compaction instead of living only in the chat.

## The family — and when each fires

| Skill | Use it when… |
|---|---|
| **`question-framing`** | Before any analysis **or any deliverable built from data — a number, table, *or a figure/map/chart/dashboard/interactive visualization*** — pin the estimand/metric (for a visualization, what each mark encodes), population, unit (what each mark represents), the data sources + joins, and the decision it informs. The brainstorm-before-you-build gate — fires on "plot/map/visualize this", not only "estimate this." For general/exploratory work it also **owns the everyday plan** — data sources, approach/spec, deliverable — written into `docs/analysis/` and signed off before building (no PAP or model card on that branch). |
| **`descriptive-evidence`** | The deliverable is a **description** of what's in the data, not an effect/counterfactual/prediction — a trend, distribution, summary-stats table (Table 1), stylized fact, or map. Fix comparability (denominator, real-vs-nominal, per-capita, weighting) before plotting; run the **composition check** (within-vs-between — a mix shift faking a within-group change; a raw-count choropleth just maps population); show the distribution, not just the mean; keep the verb descriptive (a stylized fact *motivates* the causal question, never answers it). The **descriptive** layer beneath the fork. |
| **`pre-analysis-plan`** | Before a *confirmatory* study (experiment readout, policy eval, anything with stakes) — lock hypotheses, primary spec, and robustness suite before seeing outcomes. |
| **`analysis-state-management`** | Creating, updating, resuming, or compacting durable analysis state — `docs/analysis/index.yaml`, the active phase's plan-and-topology YAML, decisions, artifacts, runs, and subagent handoffs. The replacement for growing and rereading one long plan file. |
| **`data-contracts`** | Whenever you load, transform, clean, **join/merge**, aggregate, or model — assert invariants and join cardinality, reconcile totals, freeze baselines. The everyday workhorse (the **checker**). |
| **`data-preparation`** | The data ingest & cleaning **phase** (not a one-off check) — decompose ingest→clean→join→dedup→recode→reconcile into a checkboxed phase YAML and decisions ledger that survives `/clear`; the **doer/planner** that *calls* `data-contracts` per step and routes consequential cleaning decisions to `analysis-checkpoints`. Delegated from `executing-analysis-plans`' build step. |
| **`wrong-number-debugging`** | The moment a number looks wrong, surprising, or won't reconcile — bisect the pipeline to the bad step instead of patching the symptom. |
| **`result-verification`** | Before reporting, presenting, or calling it done — reconcile, reproduce from a clean state, confirm the approved robustness, tie figures to prose. |
| **`causal-identification`** | Any causal claim or design (DiD, event study, IV, RDD, matching, FE, synthetic control) — state and test the identification assumptions; run the mandatory design diagnostics (robustness beyond them is a user-approved ~3-check shortlist). The **reduced-form** workflow. |
| **`structural-estimation`** | Estimating the *primitives* of an economic model (preferences, costs, information/consideration, search, conduct) or needing a counterfactual the data doesn't contain (merger, new product, welfare, equilibrium re-pricing) — BLP/demand, dynamic discrete choice, entry/games, auctions, consideration, search. The **structural** workflow. |
| **`predictive-modeling`** | The GOAL is a prediction, not an effect — predict/score/rank/flag/classify/forecast/detect-anomalies units to drive an action. Write the Prediction Spec and get sign-off before fitting; prove the eval honest (permutation-null + deployment-mirroring holdout) before trusting a metric; never read importance as causation. The **prediction** workflow. |
| **`analysis-review`** | Reviewing an analysis (yours or another's) for the silent-failure classes, or receiving review feedback and verifying it. |
| **`analysis-craft`** | Whenever you write or edit analysis code — keep it the minimum that answers the question, edit existing notebooks surgically, surface approach tradeoffs instead of silently choosing. |
| **`figure-craft`** | When making a presentation-ready figure/chart/plot in ANY language (R/ggplot2, Python/matplotlib, Julia/Makie) — the house style as PRINCIPLES: clean high-contrast theme, colorblind-safe Paul-Tol palette, 16.5pt fonts, no y-axis label (title/subtitle carries the meaning), concise axis labels, the right geom (dots+error bars for estimates, lines for series, stacks for composition), dashed treatment line for DiD, B&W-safe (shape/linetype redundancy, not color alone), and a MANDATORY visual self-check (render → open → verify no clipping/overlap + grayscale legible). At most 1-2 inside-canvas annotations that enhance understanding (absolute counts on percentage bars, pretreatment level label for relative scale); metadata (N, source, p-values) goes in LaTeX figure notes. Standard output: 5×3 in, saved to `results/figures/` per project-organization. Fires **after** the data is validated; a polished figure of a wrong number is still wrong. |
| **`analysis-checkpoints`** | Throughout execution — to decide which calls are yours and which must STOP for the user (design/sample/spec/estimand changes, PAP deviations, dropping data). The human-in-the-loop guardrail. |
| **`executing-analysis-plans`** | Once the plan is approved — drive execution step by step, validate each step, and fan independent pieces (robustness specs, designs, cuts) out to parallel subagents. |
| **`project-organization`** | Setting up or tidying a research repo, and at the end of a workflow before committing — paper-centric structure (pipeline stages × subject subfolders, `data/{raw,intermediate,output}`), standardized naming, gitignore the scratch. Place files right *throughout*; tidy before git. |

## The fork: why are you modeling?

**Before the fork sits description.** If the deliverable is just a faithful picture of the data — a trend, distribution, summary-stats table, or map — that's `descriptive-evidence`, not a modeling arm. Often it's the whole job; when it isn't, a stylized fact *motivates* the question below, it never *answers* it. For a *causal or modeling* question, decide the workflow before you estimate — they answer different questions on different assumptions:

- **The decision lives inside the data** ("did the policy work?", "what was the effect of the price cut we ran?") → **reduced-form**: a well-identified DiD / IV / RDD answers it, and is *more* credible for leaning on fewer assumptions → **`causal-identification`**.
- **The decision needs a world you haven't observed, a welfare number, or a mechanism the data can't separate** ("what price would the merged firm set?", "how much of low uptake is taste vs. not knowing the product exists?", "what's the surplus from a new entrant?") → **structural**: the reduced-form relationship *shifts* when the policy changes (Lucas critique), so there's no coefficient to extrapolate → **`structural-estimation`**.
- **The decision is a prediction to act on** ("which pharmacy should we investigate?", "which account is likely fraud?", "rank these by risk") → **prediction**: the deliverable is a score/flag/ranking, not an effect or a counterfactual, and it is *not* a causal claim. Route by GOAL, not algorithm — a causal effect stays reduced-form even when ML does the work (double ML, causal forests) → **`predictive-modeling`**.

Don't go structural for its own sake — a quasi-experiment that answers the question always wins. Three arms, one question: are you measuring an effect, simulating an unobserved world, or predicting an outcome to act on?

## The typical flow

```
question-framing  →  [pre-analysis-plan if confirmatory / model card if structural / else the data+approach+deliverable plan]  →  (approval gate)
   →  executing-analysis-plans  →  data-preparation (build/clean/join PHASE) → data-contracts (validate each step)
   →  [ descriptive-evidence  if the deliverable is a description  |  causal-identification  if reduced-form  |  structural-estimation  if structural  |  predictive-modeling  if prediction ]
   →  [wrong-number-debugging when something's off]
   →  result-verification  →  [analysis-review + project-organization before it ships]
   →  figure-craft (if a presentation figure is the deliverable — after the number is verified, never before)
```

Even "just run the regression / estimate the model" routes through **`executing-analysis-plans`** — including its structural (recovery reps, counterfactual scenarios) and prediction (CV folds, subsample cuts) fan-out — so dispatch happens instead of one serial script.

`analysis-craft` and `analysis-checkpoints` run *alongside* the whole flow — craft on every write/edit, checkpoints on every design/sample/spec/estimand change (STOP and ask). Most work also moves from **exploration** to a **locked, tested rule** — `data-contracts`' regime split; the mistake is shipping exploratory code as production.

## The craft principles (apply throughout)

Rigor keeps you from being *wrong*; craft keeps it *legible and cheap to change* — two stances, after Andrej Karpathy's read on how LLMs over-assume and overcomplicate: **goal-driven execution** (a data contract *is* a success criterion — loop until reconciled and verified, not until "the code ran") and **think before coding** (don't assume the metric or method; surface tradeoffs, name confusion instead of guessing). The simplicity-first and surgical-edit halves live in **`analysis-craft`**.

## Language profile (which language for which task)

LLMs reach for Python by reflex. This discipline is **R-first for analysis**; pick the language by the *kind* of task, not by habit:

| Task | Language |
|---|---|
| Data cleaning / wrangling | **R** — tidyverse / `dplyr` |
| Descriptive evidence, summary stats, Table 1 | **R** |
| Reduced-form & causal analysis (regressions, DiD, IV, RD, event study) | **R** |
| Visualization (figures, maps, charts) | **R** — `ggplot2` + `ggthemes` (Paul-Tol palettes); see `figure-craft` for the house style |
| Prediction / ML | **R** — *unless* it's deep learning (transformers, neural nets) where **PyTorch** is the natural fit → **Python** |
| Web scraping, tooling, software-engineering tasks | **Python** |
| Structural estimation / structural models | **Julia** |

This is a **default preference, not a rule** — state the chosen language in the plan so the user can redirect early, and **never silently switch** mid-task. Instruction priority holds (below): a user request or the project's `CLAUDE.md`/`AGENTS.md` wins over this profile.

**Overriding the default.** Configurable at two tiers: **per project**, record it in `docs/LESSONS.md` (e.g. a Python-only repo); **per user**, record it in your memory for a default that follows you across projects. Either replaces the matching rows above for that scope.

## Running on Codex, OpenCode, Copilot, and other AGENTS.md agents

These skills are plain `SKILL.md` files (`name` + `description` frontmatter) — the
format Claude Code, Codex, OpenCode, and GitHub Copilot all load and trigger
natively off the `description` (or `$<skill-name>` on Codex). What differs by
platform is the *always-on/backstop* layer: hooks on Claude Code; elsewhere
`AGENTS.md`, kept byte-identical to `hooks/session-context.md` and read
automatically.

- **Triggering:** Claude Code adds a keyword router + skill-chain as backstops;
  elsewhere, description-matching + each skill's own `## When to Use` /
  `## The Process` do the routing — no hooks needed.
- **Tool names:** translate `Task`, `TodoWrite`, and `Skill` via
  [`references/codex-tools.md`](references/codex-tools.md),
  [`references/opencode-tools.md`](references/opencode-tools.md), or
  [`references/copilot-tools.md`](references/copilot-tools.md); robustness
  fan-out uses `spawn_agent` (Codex) or the platform's native multi-agent
  primitive, degrading to inline where that's off.
- **Resumability:** keep `docs/analysis/index.yaml` and its named records
  current, flush before compacting, and on resume read the index first.

## Instruction priority

These skills override default behavior, but **user instructions always win** — if the user or a project's CLAUDE.md says skip a step, follow them; the skills tell you *how* to do rigorous analysis when rigor is wanted, not whether to. One caveat: a user can *waive* a step, but never *silently* skip a confirmation gate — say so explicitly (framing, a PAP/model-card sign-off, a checkpoint) so the waiver is the user's choice, not your omission.

## The bottom line

You are not slowing the analysis down. You are refusing to be confidently wrong — which is the only failure mode in data work that actually costs anything.
