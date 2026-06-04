# Causal Powers

**Superpowers for data analytics, causal inference, and econometrics.**

A Claude Code skill family that ports the *discipline* of the
[superpowers](https://github.com/obra/superpowers) software skills to the failure
modes that are specific to data work — where the dangerous bug is **silent** (the
code runs clean and hands you a confident, wrong answer) rather than loud (a stack
trace). Three-language throughout: **R, Julia, Python**.

> A number you computed but never validated is a guess wearing a lab coat.

## The skills

| Skill | What it does | Software analog |
|---|---|---|
| `using-causal-powers` | Gateway: the creed, the map, and routing to the right skill | `using-superpowers` |
| `question-framing` | Pin the estimand/metric, population, unit, and the decision — before code | `brainstorming` |
| `pre-analysis-plan` | Lock hypotheses, primary spec, and robustness suite before seeing outcomes | spec-driven dev / `writing-plans` |
| `data-contracts` | Invariants, join-cardinality checks, totals reconciliation, frozen baselines | `test-driven-development` |
| `wrong-number-debugging` | Bisect the pipeline to the step where the number went bad | `systematic-debugging` |
| `result-verification` | Reconcile, reproduce from clean state, attack with robustness, before reporting | `verification-before-completion` |
| `causal-identification` | State & test identification assumptions; mandatory robustness for DiD/IV/RDD/etc. | (none — domain core) |
| `analysis-review` | Review an analysis for silent-failure classes; verify review feedback | `requesting`/`receiving-code-review` |

## Why a separate family

In software the dangerous bug throws. In analysis it stays quiet: a join fans out
and revenue triples; one `NA` poisons a mean; units are off by 100×; a timezone
shifts every event into the wrong day; train/test overlap makes a metric a fantasy;
an identification assumption fails and confounding masquerades as an effect. None
raise an error. These skills assert everything *around* the answer that must hold
regardless of the answer — and, for causal work, force the identification
assumptions to be stated and tested before estimating.

## Install (local)

```bash
claude plugin marketplace add ~/Developer/causal-powers
claude plugin install causal-powers@causal-powers-dev
```

## Design

See [`docs/specs/2026-06-04-causal-powers-design.md`](docs/specs/2026-06-04-causal-powers-design.md).

## License

MIT
