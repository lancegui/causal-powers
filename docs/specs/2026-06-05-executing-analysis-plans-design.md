# Causal Powers — Execution Orchestration

**Date:** 2026-06-05
**Status:** Approved for implementation

## Problem (from real use)

After an analysis plan is written, nothing in the family takes over to **execute**
it. The superpowers flow is brainstorm → writing-plans → executing-plans /
subagent-driven-development; Causal Powers had the planning end
(`pre-analysis-plan`) but no execution-orchestration analog. Consequences:
- Execution drifts (no skill drives the plan step by step).
- Independent work (robustness specs, competing designs, subsample cuts, placebo
  tests) is never fanned out to subagents — superpowers'
  `subagent-driven-development` is software-flavored and under-triggers on
  econometrics plans, so it doesn't pick up the slack.

## Decision

Add one self-contained skill, **`executing-analysis-plans`**, the analytics
analog of executing-plans + subagent-driven-development. It hands off cleanly
from the approved plan and integrates the existing guardrails.

## The skill: `executing-analysis-plans`

- **Prerequisite:** an *approved* brief/PAP. No approval → return to
  `question-framing` / `pre-analysis-plan`.
- **Sequential spine** (dependent, in order): build/clean/join dataset → validate
  (`data-contracts`) → construct treatment/outcome/covariates → validate →
  estimate the pre-committed primary spec.
- **Parallel fan-out** (independent, dispatch one subagent each, concurrent):
  robustness specs, placebo/falsification tests, alternative designs, subsample/
  heterogeneity cuts, secondary outcomes, sensitivity analyses. All read the same
  validated dataset + pre-specified recipe.
- **What each subagent must carry:** the exact pre-specified task (execute, don't
  choose); the data contracts to assert; a structured result to return; and the
  checkpoint rule — if it hits a design/sample/spec/estimand decision it
  **reports back and stops**, it does not resolve it.
- **Between steps:** validate (`data-contracts`), then checkpoint
  (`analysis-checkpoints`); wrong numbers → `wrong-number-debugging`.
- **Synthesis:** assemble the robustness table, reconcile across specs, flag
  contract failures, hand to `result-verification`.
- Uses superpowers' `dispatching-parallel-agents` / `subagent-driven-development`
  for the *mechanics*; provides the analytics *when/what to parallelize*.

## Wiring
- `question-framing` and `pre-analysis-plan` hand off to
  `executing-analysis-plans` once approved.
- Gateway: add to family table, flow diagram (with the approval gate), and the
  routing description.

## Housekeeping
- Bump to **0.4.0**; update README; reinstall.

## Roster after this change (gateway + 10 skills)
`question-framing`, `pre-analysis-plan`, `data-contracts`, `analysis-craft`,
`analysis-checkpoints`, `executing-analysis-plans` (new), `wrong-number-debugging`,
`result-verification`, `causal-identification`, `analysis-review`.
