# Causal Powers — Robustness is an argument, not an inventory

**Date:** 2026-06-05
**Status:** Approved for implementation

## Problem (from real use)

`executing-analysis-plans` runs an unsupervised "godly amount" of robustness
checks — a free buffet. The skill frames the parallel fan-out as "run every
robustness spec, every placebo, every subsample, every secondary outcome," and
the subagent machinery makes exhaustiveness cheap, so it sprawls. A senior
economist reads a 30-column robustness table as a *tell* of weak identification,
not as credibility.

## Principle

**Robustness is an argument, not an inventory.** Run the ~3 checks that would
actually break the result if it's fragile — the ones that probe the main threat
to identification — propose them with reasons, get approval, then run. Parallelism
serves the chosen shortlist; it is not a license for exhaustiveness.

## Decision

Soft default of ~3 + **mandatory propose-and-approve gate** before running
anything beyond the primary spec. Judgment, not a rigid quota (a design may
occasionally warrant a 4th — say so). Choosing the set is a consequential
decision → `analysis-checkpoints`.

## Changes

- **`executing-analysis-plans`** (primary): add a "Robustness is an argument"
  section — name the main threat, choose the ~3 checks that could break the
  result, propose the shortlist with one-line rationales, get approval, run only
  the approved set, more only on request. Reframe the parallel fan-out to serve
  the *approved shortlist*, not "each/every." Update red flags + rationalizations.
- **`causal-identification`**: lead the robustness section with "an argument, not
  an inventory"; target the specific identifying threat; skip decorative checks.
- **`pre-analysis-plan`**: the committed robustness suite is small and targeted,
  not a catalogue ("a pre-registered buffet is still a buffet").
- **`analysis-checkpoints`**: running a large battery is itself a checkpoint —
  propose the shortlist, get sign-off.
- **`hooks/session-context.md`**: one always-on red-line so it's present by
  default.

## Housekeeping
Bump to **0.7.0**; reinstall. No new files; edits only.
