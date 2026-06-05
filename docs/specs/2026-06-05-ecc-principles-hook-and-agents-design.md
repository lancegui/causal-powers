# Causal Powers — ECC principles: always-on hook, subagents, lessons-capture

**Date:** 2026-06-05
**Status:** Approved for implementation
**Source studied:** github.com/affaan-m/ecc (harness-native operator system).

## What we learned from ECC (and what we ignored)

ECC separates work into five layers by *activation mechanism*: **rules**
(always-loaded), **hooks** (deterministic on tool events), **instincts**
(always-on learned heuristics), **skills** (triggered procedures), **agents**
(delegated scope). The key insight: **things that must happen every time do not
belong in triggered skills** — Causal Powers' reliability failures ("didn't stop
to ask", "didn't write the spec", "decided behind my back", "subagent step
didn't fire") are all *triggering* failures of a skills-only design.

Adopted (selectively): an always-on **SessionStart hook** and **reusable
subagents + lessons-capture**.
Ignored as bloat: 251-skill sprawl, 63 agents, cross-harness adapters,
confidence-scored auto-learning, dashboards, installers, security scanning, i18n.

## Changes

### 1. SessionStart hook — the always-on layer
Mirror superpowers' mechanism (it injects `using-superpowers` via a SessionStart
hook). Files:
- `hooks/hooks.json` — SessionStart hook (matcher `startup|clear|compact`)
  running `hooks/session-start`. No `hooks` field in plugin.json (Claude Code
  auto-loads `hooks/hooks.json`).
- `hooks/session-start` — bash script: read `hooks/session-context.md`, escape
  for JSON, emit `hookSpecificOutput.additionalContext` (Claude Code), with a
  generic `additionalContext` fallback. Executable.
- `hooks/session-context.md` — a **compact** always-on block (NOT the full
  gateway, to limit noise in non-analytics sessions): the creed; the
  non-negotiable "never change the goal behind the user's back → STOP
  (`analysis-checkpoints`)" rule; the workflow spine with the write-artifact +
  approval gate; a silent-failure red-lines card (join cardinality, clean-run ≠
  correct, leakage); an economist red-lines card (interpretable units + economic
  significance, named design + mechanism, bad controls, implausible magnitude);
  and a pointer to the skills.

Tradeoff (accepted): fires on every session, like superpowers. Kept tight.

### 2. Reusable subagents (`agents/`)
- `agents/robustness-runner.md` — executes ONE pre-specified spec/placebo/design
  against an already-validated dataset, asserts `data-contracts`, returns a
  structured result (estimate, SE, N, diagnostics, contract pass/fail). Does not
  choose the spec; if it hits a design/sample/spec/estimand decision it reports
  back and stops (`analysis-checkpoints`). The fan-out worker for
  `executing-analysis-plans`.
- `agents/analysis-reviewer.md` — adversarial reviewer for the silent-failure
  classes; returns concrete findings with severity, not a rubber stamp. Used by
  `analysis-review`.

Wire `executing-analysis-plans` to dispatch fan-out work to `robustness-runner`,
and `analysis-review` to use `analysis-reviewer` for independent review.

### 3. Lessons-capture (folded in, no new skill)
- `result-verification`: add an end-of-analysis beat — record the specific silent
  failure that bit this project to `docs/LESSONS.md`; if it generalizes, fold it
  into the relevant skill (the manual `/evolve`).
- `analysis-review`: brief mention to surface lessons during review.
- `docs/LESSONS.md` — template/convention file seeded.

### 4. Housekeeping
Bump to **0.6.0**; README note (hook + agents + lessons); reinstall; restart to
load the hook. Skill count unchanged (gateway + 10); adds `hooks/` and `agents/`.

## Out of scope
Deterministic enforcement hooks (PreToolUse/Stop guards), a standalone curated
instincts file, auto-learning machinery. (The compact red-lines card in the hook
covers the always-on knowledge need for now.)
