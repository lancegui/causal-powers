---
name: using-causal-powers
description: Use when starting any data analysis, statistics, econometrics, or causal-inference task in R, Julia, or Python — establishes the Causal Powers discipline and routes to the right skill (question-framing, pre-analysis-plan, data-contracts, data-preparation, analysis-craft, analysis-checkpoints, executing-analysis-plans, wrong-number-debugging, result-verification, causal-identification, structural-estimation, analysis-review, project-organization). Invoke this whenever someone asks you to analyze data, compute a metric, clean or merge datasets, fit a model, estimate an effect or a structural model, simulate a counterfactual, check a number, or **build a deliverable from data — a figure, map, chart, dashboard, or interactive visualization** — even if they only say "analyze this", "what's the trend", "did it work", "estimate the model", or "plot/map/visualize this" — so the right discipline skill fires before you touch the data.
---

# Using Causal Powers

## The creed

A number you computed but never validated is a guess wearing a lab coat. In software the dangerous bug throws a stack trace; in data analysis it runs clean and hands you a confident, wrong answer. Causal Powers is a family of skills that make the silent failures of data work loud — *before* they reach a stakeholder.

## The rule

For any analysis task, **invoke the relevant discipline skill before acting** — before exploring the data, before writing the transform, before reporting the number. Process skills (framing the question, planning, debugging) come before implementation. Even a 1% chance a skill applies means you **invoke the Skill tool** to check (read it, then decide) — not just "consider it in your head."

**Re-trigger per request — a skill you used earlier does not stay satisfied.** Every new ask re-fires the relevant skill, *even on an already-locked, already-reviewed design.* A re-run or a finer reporting cut is still `executing-analysis-plans` (run the approved plan, fan independent work to subagents) **and `result-verification` before you write any result to a file**; "review it" re-fires `analysis-review`; a cut that changes the unit or estimand re-opens `question-framing` + `analysis-checkpoints`. "I already have the context" / "this is just running the locked plan" is the rationalization that skips the gate — and it's exactly how a reviewed design ships an unverified new cut.

And the rule that the rest of the family rests on: **you execute autonomously toward the agreed goal, but you never change the goal behind the user's back.** Changing the research design, the estimand, the sample, the spec, or a metric — or deviating from the framed question or pre-analysis plan — is the *user's* decision, not yours. When execution wants to do any of those (it most often does mid-debugging), **STOP and bring it to them** (`analysis-checkpoints`). This is the discipline that was missing when an analysis quietly became one nobody agreed to.

And the rule that keeps the work from drifting: **always work from a written plan, and keep it living on disk.** Before any non-trivial work, commit the plan to a file and confirm it — the framing brief *and, for general/exploratory work, its data/approach/deliverable plan* (`question-framing`), the pre-analysis plan (`pre-analysis-plan`), or the structural **model card** (`structural-estimation`) — *wherever you're dropped in*; "just estimate / fix / run this" mid-stream is not a licence to dive in. For anything beyond a quick query the plan becomes a **phased, checkboxed `analysis-plan.md`** (template ships with `data-preparation`): Phase 0 the brief/PAP/card, **Phase 1 the data-ingest-&-cleaning sub-plan owned by `data-preparation`** (the heaviest phase — plan it, don't treat it as one line), then construction → primary spec → robustness → verification. Treat that file as **disk-as-RAM**: tick boxes and append every consequential decision *with its why* as you go. That is what makes the work **resumable** — it survives `/clear` and auto-compaction, and a `SessionStart`/`PreCompact` hook re-reads it to resume you at the next open step instead of restarting. A plan you can't point to is one that drifts; a plan that lives only in the chat is one that compaction silently deletes.

## The family — and when each fires

| Skill | Use it when… |
|---|---|
| **`question-framing`** | Before any analysis **or any deliverable built from data — a number, table, *or a figure/map/chart/dashboard/interactive viz*** — to pin the estimand/metric (for a visualization, what each mark encodes), population, unit (what each mark represents), the data sources + joins, and the decision it informs. The "what are we actually measuring / building" skill — the brainstorm-before-you-build gate for data work, so it fires on "plot/map/visualize this", not only "estimate this." For general/exploratory work it also **owns the everyday plan** — data sources, approach/spec, deliverable — written to the same file and signed off before building (no PAP or model card on that branch). |
| **`pre-analysis-plan`** | Before a *confirmatory* study (experiment readout, policy eval, anything with stakes) — lock hypotheses, primary spec, and robustness suite before seeing outcomes. |
| **`data-contracts`** | Whenever you load, transform, clean, **join/merge**, aggregate, or model — assert invariants and join cardinality, reconcile totals, freeze baselines. The everyday workhorse (the **checker**). |
| **`data-preparation`** | The data ingest & cleaning **phase** (not a one-off check) — decompose ingest→clean→join→dedup→recode→reconcile into a checkboxed plan with a decisions log that survives `/clear`; the **doer/planner** that *calls* `data-contracts` per step and routes consequential cleaning decisions to `analysis-checkpoints`. Delegated from `executing-analysis-plans`' build step. |
| **`wrong-number-debugging`** | The moment a number looks wrong, surprising, or won't reconcile — bisect the pipeline to the bad step instead of patching the symptom. |
| **`result-verification`** | Before reporting, presenting, or calling it done — reconcile, reproduce from a clean state, attack with robustness, tie figures to prose. |
| **`causal-identification`** | Any causal claim or design (DiD, event study, IV, RDD, matching, FE, synthetic control) — state and test the identification assumptions; run the mandatory robustness battery. The **reduced-form** workflow. |
| **`structural-estimation`** | Estimating the *primitives* of an economic model (preferences, costs, information/consideration, search, conduct) or needing a counterfactual the data doesn't contain (merger, new product, welfare, equilibrium re-pricing) — BLP/demand, dynamic discrete choice, entry/games, auctions, consideration, search. The **structural** workflow. |
| **`analysis-review`** | Reviewing an analysis (yours or another's) for the silent-failure classes, or receiving review feedback and verifying it. |
| **`analysis-craft`** | Whenever you write or edit analysis code — keep it the minimum that answers the question, edit existing notebooks surgically, surface approach tradeoffs instead of silently choosing. |
| **`analysis-checkpoints`** | Throughout execution — to decide which calls are yours and which must STOP for the user (design/sample/spec/estimand changes, PAP deviations, dropping data). The human-in-the-loop guardrail. |
| **`executing-analysis-plans`** | Once the plan is approved — drive execution step by step, validate each step, and fan independent pieces (robustness specs, designs, cuts) out to parallel subagents. |
| **`project-organization`** | Setting up or tidying a research repo, and at the end of a workflow before committing — paper-centric structure (pipeline stages × subject subfolders, `data/{raw,intermediate,output}`), standardized naming, gitignore the scratch. Place files right *throughout*; tidy before git. |

## The fork: reduced-form or structural?

For any *causal or modeling* question, decide which of two workflows you're in before you estimate — they answer different questions and lean on different assumptions:

- **The decision lives inside the data** ("did the policy work?", "what was the effect of the price cut we ran?") → the **reduced-form** workflow. A well-identified DiD / IV / RDD answers it and is *more* credible for leaning on fewer assumptions → **`causal-identification`**.
- **The decision needs a world you haven't observed, a welfare number, or a mechanism the data can't separate** ("what price would the merged firm set?", "how much of low uptake is taste vs. not knowing the product exists?", "what's the surplus from a new entrant?") → the **structural** workflow. The reduced-form relationship *shifts* when the policy changes (Lucas critique), so there's no coefficient to extrapolate → **`structural-estimation`**.

Don't go structural for its own sake — if a quasi-experiment answers it, that wins. The two workflows are partners with genuinely different pipelines: reduced form for effects inside the data, structural for counterfactuals outside it.

## The typical flow

```
question-framing  →  [pre-analysis-plan if confirmatory / model card if structural / else extend the brief into the data+approach+deliverable plan]  →  (approval gate)
   →  executing-analysis-plans  →  data-preparation (build/clean/join PHASE) → data-contracts (validate each step)
   →  [ causal-identification  if reduced-form  |  structural-estimation  if structural ]
   →  [wrong-number-debugging when something's off]
   →  result-verification  →  [analysis-review + project-organization before it ships]
```

After approval, **`executing-analysis-plans`** carries it out — running the dependent spine in order and fanning independent work (robustness specs, designs, cuts; or, structural, recovery reps and counterfactual scenarios) out to parallel subagents. Even when a task arrives as "just run the regression / estimate the model", route execution through it so the spine/fan-out and subagent dispatch actually happen.

`analysis-craft` and `analysis-checkpoints` run *alongside* this whole flow — `analysis-craft` every time you write or edit the code, `analysis-checkpoints` every time a decision would change the design, sample, spec, or estimand (STOP and ask).

Most work flows from **exploration** (hunt for the answer; validate every input and intermediate) into a **reusable, contracted rule** (lock it down with tests and a frozen baseline). The mistake is staying in exploration forever and shipping it as if it were production.

## The craft principles (apply throughout)

Rigor keeps you from being *wrong*; craft keeps the analysis *legible and cheap to change*. Two stances, adapted from Andrej Karpathy's observations on how LLMs over-assume and overcomplicate, run through every skill above:

- **Goal-driven execution.** A data contract *is* a success criterion. State what must be true, then loop until it's reconciled and verified — don't stop at "the code ran." This is what the whole `CONTRACT → … → FREEZE` loop is.
- **Think before coding.** Don't assume the metric or the method. Surface tradeoffs, state your assumptions, and name confusion instead of quietly guessing and building on the guess.

The simplicity-first and surgical-edit halves of that lineage live in **`analysis-craft`**.

## Running on Codex / other agents

These skills are plain `SKILL.md` files (`name` + `description` frontmatter) — the
same format Claude Code and **Codex** both use — so they load and trigger natively
on either: off the `description`, or by explicit `$<skill-name>` on Codex. What
differs by platform is the *always-on* and *backstop* layer, which on Claude Code
is hooks and on Codex is `AGENTS.md`:

- **Always-on discipline:** Claude Code injects it via a SessionStart hook; on
  Codex the same block is `AGENTS.md` at the repo root (symlinked to
  `hooks/session-context.md`), read automatically.
- **Triggering:** Claude Code adds a keyword router + skill-chain as backstops; on
  Codex, description-matching + each skill's own `## When to Use` / `## The Process`
  do the routing — no hooks needed.
- **Tool names:** when a skill says `Task` (dispatch a subagent), `TodoWrite`, or
  `Skill`, translate to your platform via
  [`references/codex-tools.md`](references/codex-tools.md). The robustness fan-out
  uses `spawn_agent` on Codex (or degrades to inline if multi-agent is off).
- **Resumability:** maintain the living `analysis-plan.md` and flush it before
  compacting — Claude Code automates the re-read with a hook; on Codex you do it.

## Instruction priority

These skills override default behavior, but **user instructions always win**. If the user (or a project's CLAUDE.md) says to skip a step, follow the user — they're in control. The skills tell you *how* to do rigorous analysis when rigor is wanted. One caveat: a user can *waive* a step, but you may never *silently* skip a confirmation gate — if you bypass framing, a PAP/model-card sign-off, or a checkpoint, say so explicitly so the waiver is the user's choice, not your omission.

## The bottom line

You are not slowing the analysis down. You are refusing to be confidently wrong — which is the only failure mode in data work that actually costs anything.
