# Causal Powers — Human-in-the-Loop Checkpoints

**Date:** 2026-06-05
**Status:** Approved for implementation
**Extends:** the v0.1/v0.2 specs

## Problem (from real use)

The family's up-front skills work well (`question-framing`, `pre-analysis-plan`),
but **execution has no human-in-the-loop discipline**, so the agent runs to
completion making consequential analytical decisions silently — a direct
violation of the Think-Before-Coding / surface-tradeoffs principle, but during
execution where nothing enforces it.

Reported symptoms:
1. The planning step no longer **writes a spec/plan artifact** and does not
   **stop to ask** for approval before executing.
2. During execution/debugging the agent **changes the research design behind the
   user's back.** Canonical example: debugging surfaced uneven geographic
   incidence of a 2016 recording jump (Beverly's 2 mi ring +66% while its 0.5 mi
   ring stayed flat); the agent unilaterally **upgraded Design B from near-vs-far
   DiD to a triple-difference** (band×month FE). That is a change of
   identification strategy — a deviation from the pre-analysis plan — and should
   have stopped and asked.
3. `wrong-number-debugging` debugs and "fixes" too autonomously.

## Root cause

- No skill governs *which execution decisions belong to the user*.
- `wrong-number-debugging`'s `FIX AT THE SOURCE` step conflates two very
  different things: a **data-bug fix** (restores the intended computation) and an
  **analytical-design change** (changes what is being estimated). The first is
  fine to do; the second must be escalated.
- The PAP's "deviation disclosed is science" norm is stated but **not enforced**
  with a stop-and-approve gate, and `wrong-number-debugging` / `causal-
  identification` don't reference it.
- The Karpathy goal-driven-autonomy principle ("loop until verified") was read as
  license to *change the goal* mid-flight. It is not: you loop toward the agreed
  goal; you do not redefine it.

## Decisions

1. **New skill `analysis-checkpoints`** — the human-in-the-loop execution
   discipline (which decisions are the user's; how to stop and surface them).
2. **Harden the offenders** — `wrong-number-debugging` and `causal-
   identification` get explicit STOP gates that route design/spec/sample changes
   through `analysis-checkpoints`.
3. **Up-front skills persist an artifact + hard-stop for approval** —
   `question-framing` writes the brief to a file; `pre-analysis-plan` writes the
   PAP to a file; both stop and require user sign-off before execution begins.

## Changes

### New: `skills/analysis-checkpoints/SKILL.md`
- **Core principle:** during execution, some decisions are the user's, not yours.
  Loop toward the agreed goal autonomously; never redefine the goal silently.
- **Decisions that REQUIRE a checkpoint (stop and ask):** changing the estimand,
  research design, or identification strategy; any deviation from the PAP or the
  framed question; dropping/filtering/winsorizing/trimming data or changing the
  sample/exclusions; choosing between materially different specs/models with a
  real tradeoff; redefining a metric or changing units/grain; changing
  missing-data handling; anything that changes a number the user has already seen.
- **Decisions you may make autonomously (note, don't ask):** mechanical data-bug
  fixes that *restore* the intended computation (dedup a key that must be unique,
  correct a wrong join type, fix a unit error); cosmetic/code choices. Always
  report them.
- **The checkpoint format:** state the decision plainly; give ≥2 options with the
  tradeoff; give your recommendation + why; show the evidence that surfaced it;
  then WAIT — do not implement past the checkpoint until the user chooses.
- **Clarify goal-driven autonomy:** "loop until verified" = iterate toward fixed,
  agreed success criteria; it does not authorize changing the criteria, design,
  or sample. That distinction is the whole skill.
- House format: Red Flags, Common Rationalizations, relationship-to-siblings,
  bottom line.

### Edit: `skills/wrong-number-debugging/SKILL.md`
- Split the fix step into **data-bug fix** (proceed + report) vs.
  **analytical-design change** (STOP → `analysis-checkpoints`).
- Add the identification-threat case: when debugging surfaces a design threat,
  you *diagnose and explain* it; you do **not** unilaterally change the design.
  Use the Beverly triple-difference as the worked example.
- Add to Red Flags: changing the design/spec to make a number behave without
  surfacing it as the user's decision.

### Edit: `skills/causal-identification/SKILL.md`
- Add: choosing or changing the identification strategy is the user's decision.
  When a diagnostic fails (pre-trends violated, weak instrument, manipulation) or
  a threat is discovered, present the threat + candidate remedies as a checkpoint;
  don't silently upgrade the design.

### Edit: `skills/question-framing/SKILL.md`
- Persist the framing brief to a file in the project; present it and get
  confirmation before proceeding.

### Edit: `skills/pre-analysis-plan/SKILL.md`
- Write the PAP to a file; **hard-stop for explicit user approval before any
  estimation**; deviations during execution return to the user via
  `analysis-checkpoints`.

### Edit: `skills/using-causal-powers/SKILL.md` (gateway)
- Add `analysis-checkpoints` to the family table + flow.
- Add a prominent principle: you loop toward the agreed goal; you do not redefine
  the goal (design/sample/spec/estimand) behind the user's back — when execution
  wants to, STOP.

### Housekeeping
- Bump to **0.3.0**; update README; reinstall.

## Out of scope
- Reworking the skills the user said already work well beyond the minimal
  additions above (surgical changes).

## Roster after this change (gateway + 9 skills)
`question-framing`, `pre-analysis-plan`, `data-contracts`, `analysis-craft`,
`analysis-checkpoints` (new), `wrong-number-debugging`, `result-verification`,
`causal-identification`, `analysis-review`.
