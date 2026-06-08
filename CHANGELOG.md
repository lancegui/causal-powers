# Changelog

All notable changes to Causal Powers. Versions follow the plugin manifest.

## 0.7.0 — Robustness is an argument, not an inventory
- `executing-analysis-plans` no longer fans out an exhaustive menu of robustness
  checks. It names the main identifying threat, proposes the ~3 checks that would
  break the result if it's fragile (each with a rationale), gets approval, and
  runs only the approved set.
- Reinforced across `causal-identification`, `pre-analysis-plan`,
  `analysis-checkpoints`, and the always-on hook card.

## 0.6.0 — Always-on layer + reusable agents (ECC-inspired)
- Added a **SessionStart hook** (`hooks/`) injecting a compact always-on
  discipline block, so must-always rules don't depend on a skill triggering.
- Added **agents/**: `robustness-runner` (fan-out worker) and `analysis-reviewer`
  (independent adversarial review).
- Folded **lessons-capture** into `result-verification` + seeded `docs/LESSONS.md`.

## 0.5.0 — Economic judgment + consolidation
- Wove senior-economist judgment into `question-framing` (form a prior on sign,
  magnitude, mechanism), `result-verification` (interpretable units, economic vs
  statistical significance, plausibility, mechanism, benchmark), and
  `causal-identification` ("what's your experiment?" + bad-controls).
- Trimmed repetition; reduced-form micro focus.

## 0.4.0 — Plan execution
- Added `executing-analysis-plans`: drive an approved plan, validate the
  dependent spine in order, fan independent work out to parallel subagents.

## 0.3.0 — Human-in-the-loop checkpoints
- Added `analysis-checkpoints`: loop toward the agreed goal, never change the
  design/sample/spec/estimand behind the user's back.
- Hardened `wrong-number-debugging` (data-bug fix vs analytical-design change)
  and `causal-identification`; `question-framing`/`pre-analysis-plan` persist an
  artifact and hard-stop for approval before execution.

## 0.2.0 — Karpathy craft principles
- Added `analysis-craft` (simplicity-first code + surgical edits) and wove
  goal-driven-execution + think-before-coding into the gateway.

## 0.1.0 — Initial family
- Gateway + 7 skills: `question-framing`, `pre-analysis-plan`, `data-contracts`,
  `wrong-number-debugging`, `result-verification`, `causal-identification`,
  `analysis-review`. Three-language (R/Julia/Python). Supersedes the earlier
  single `validation-driven-analysis` skill.
