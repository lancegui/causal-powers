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
| `analysis-craft` | Minimum analysis that answers the question; surgical edits to notebooks/pipelines | Karpathy: simplicity + surgical |
| `analysis-checkpoints` | Stop and ask before changing design/sample/spec/estimand; loop toward the agreed goal, never redefine it | superpowers review gates |
| `executing-analysis-plans` | Drive an approved plan: sequential spine validated in order, independent specs/designs fanned out to parallel subagents | `executing-plans` / `subagent-driven-development` |
| `wrong-number-debugging` | Bisect the pipeline to the step where the number went bad | `systematic-debugging` |
| `result-verification` | Reconcile, reproduce from clean state, attack with robustness, before reporting | `verification-before-completion` |
| `causal-identification` | State & test identification assumptions; mandatory robustness for DiD/IV/RDD/etc. | (none — domain core) |
| `analysis-review` | Review an analysis for silent-failure classes; verify review feedback | `requesting`/`receiving-code-review` |

Two cross-cutting **craft principles** — *goal-driven execution* (a data contract
is a success criterion; loop until verified) and *think before coding* (surface
tradeoffs, don't assume) — run through the gateway and every skill. The craft
principles are adapted from
[Andrej Karpathy's notes](https://github.com/multica-ai/andrej-karpathy-skills)
on how LLMs over-assume and overcomplicate, translated to data work.

The family also carries **economic judgment**, not just process hygiene: form a
prior on sign, magnitude, and mechanism before the data (`question-framing`);
read every estimate in interpretable units and judge economic — not just
statistical — significance, plausibility, and fit with the literature
(`result-verification`); and start every causal study from "what's your
experiment?", watching for bad controls (`causal-identification`). The target is
a senior reduced-form microeconomist's instincts, not a careful RA's checklist.

## Why a separate family

In software the dangerous bug throws. In analysis it stays quiet: a join fans out
and revenue triples; one `NA` poisons a mean; units are off by 100×; a timezone
shifts every event into the wrong day; train/test overlap makes a metric a fantasy;
an identification assumption fails and confounding masquerades as an effect. None
raise an error. These skills assert everything *around* the answer that must hold
regardless of the answer — and, for causal work, force the identification
assumptions to be stated and tested before estimating.

## Beyond skills: always-on layer + agents

Skills are *triggered*. Some discipline must hold *every* time, so (inspired by
[ECC](https://github.com/affaan-m/ecc)'s layered model and superpowers' own hook)
the plugin also ships:

- **A SessionStart hook** (`hooks/`) that injects a compact always-on block — the
  creed, the never-change-the-goal-behind-the-user's-back rule, the
  frame→approve→execute→verify spine, and a silent-failure + economist red-lines
  card — so the discipline is present by default, not contingent on a skill
  triggering.
- **Reusable subagents** (`agents/`): `robustness-runner` (executes one
  pre-specified spec against the validated data, asserts contracts, returns a
  structured result — the fan-out worker for `executing-analysis-plans`) and
  `analysis-reviewer` (independent adversarial review for the silent-failure
  classes).
- **Lessons-capture** (`docs/LESSONS.md`): a manual, no-machinery `/evolve` —
  record the silent failure that bit each project and fold general ones back into
  the skills.

## Install (local)

```bash
claude plugin marketplace add ~/Developer/causal-powers
claude plugin install causal-powers@causal-powers-dev
```

## Design

See [`docs/specs/2026-06-04-causal-powers-design.md`](docs/specs/2026-06-04-causal-powers-design.md).

## License

MIT
