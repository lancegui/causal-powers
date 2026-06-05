# Causal Powers — Karpathy-Principles Integration

**Date:** 2026-06-04
**Status:** Approved for implementation
**Extends:** `2026-06-04-causal-powers-design.md`

## Purpose

Integrate the four behavioral principles from the
[andrej-karpathy-skills](https://github.com/multica-ai/andrej-karpathy-skills)
`CLAUDE.md` into the Causal Powers family. Those principles are *coding-behavior*
guidance; this spec translates them into analytics terms and places each where it
belongs rather than bolting on the original CLAUDE.md wholesale.

## The four principles and where each lands

| Karpathy principle | Verbatim core | Analytics translation | Disposition |
|---|---|---|---|
| **Goal-Driven Execution** | "Define success criteria. Loop until verified." | A data contract *is* a success criterion; loop until reconciled & verified. | **Already the spine** — make explicit in the gateway. |
| **Think Before Coding** | "Don't assume. Don't hide confusion. Surface tradeoffs." | Don't assume the metric or the method; surface tradeoffs; name confusion. | **Weave** into gateway (stance) + `question-framing` (metric-level). |
| **Simplicity First** | "Minimum code that solves the problem. Nothing speculative." | Minimum analysis that answers the question; no speculative pipeline. | **New skill** `analysis-craft` (gap). |
| **Surgical Changes** | "Touch only what you must. Clean up only your own mess." | Edit notebooks/pipelines surgically; don't refactor working analysis. | **New skill** `analysis-craft` (gap). |

## Decisions

1. **Integration shape:** one new skill (`analysis-craft`) for the two genuine
   gaps, plus weaving the two cross-cutting principles into existing skills. No
   wholesale CLAUDE.md.
2. **Scope boundary:** `analysis-craft` owns **code craft** (code simplicity +
   surgical edits + minimum-analysis). **Modeling parsimony** (kitchen-sink
   controls, specification search) stays in `causal-identification` and
   `pre-analysis-plan`; `analysis-craft` only cross-references it.

## Changes

### New: `skills/analysis-craft/SKILL.md`
The engineering-craft counterpart to the rigor skills. Sections:
- **Overview** — rigor keeps you from being *wrong*; craft keeps the analysis
  *legible, reproducible, and cheap to change*. The two are different axes.
- **Simplicity First (code):** minimum analysis that answers the question; no
  speculative pipeline, no premature abstraction, no config flags for a one-off
  script, no framework where three verbs do. Test: "would a senior analyst call
  this overcomplicated?" Cross-reference modeling-parsimony to siblings.
- **Surgical Changes:** touch only what the task needs; don't refactor a
  colleague's working analysis; match their style; keep diffs reproducible and
  traceable; remove only the orphans *your* change created; flag (don't delete)
  pre-existing dead code.
- **Think Before Coding (approach level):** state assumptions about the data and
  the method; present competing analytical approaches instead of silently
  picking; name confusion rather than guessing.
- House format: Red Flags table, Common Rationalizations table,
  relationship-to-siblings, bottom line. Three-language where relevant.

### Edit: `skills/using-causal-powers/SKILL.md` (gateway)
- Add **Goal-Driven Execution** and **Think Before Coding** as the overarching
  stance (a short "The craft principles" section), with a one-line credit to the
  Karpathy lineage.
- Add `analysis-craft` to the family table and the typical-flow line.

### Edit: `skills/question-framing/SKILL.md`
- One beat: state assumptions explicitly and present competing interpretations of
  an ambiguous request rather than choosing silently — the metric-level form of
  Think Before Coding.

### Housekeeping
- Bump `plugin.json` + `marketplace.json` to **0.2.0**.
- Update `README.md` (add the `analysis-craft` row; note the Karpathy lineage).
- Reinstall the plugin locally so changes load.
- **Done already:** removed 10 stray `causal-identification-skill-<hash>.md`
  command stubs from `~/.claude/commands/` (namespace pollution from an earlier
  run).

## Out of scope
- Shipping the original Karpathy CLAUDE.md as an always-on guideline (the user
  chose scoped skills over global behavior).
- Re-deriving modeling parsimony as new content (cross-reference only).

## The roster after this change (gateway + 8 skills)
`using-causal-powers`, `question-framing`, `pre-analysis-plan`, `data-contracts`,
`analysis-craft` (new), `wrong-number-debugging`, `result-verification`,
`causal-identification`, `analysis-review`.
