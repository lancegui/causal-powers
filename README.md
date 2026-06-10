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
| `data-contracts` | Invariants, join-cardinality checks, totals reconciliation, frozen baselines — the **checker** | `test-driven-development` |
| `data-preparation` | Owns the data ingest & cleaning **phase** (the heaviest one): ingest→clean→join→dedup→recode→reconcile as a phased, checkboxed plan with a decisions log; the **doer** that *calls* `data-contracts` per step and routes consequential cleaning choices to `analysis-checkpoints` | `writing-plans` (for the cleaning phase) |
| `analysis-craft` | Minimum analysis that answers the question; surgical edits to notebooks/pipelines | Karpathy: simplicity + surgical |
| `analysis-checkpoints` | Stop and ask before changing design/sample/spec/estimand; loop toward the agreed goal, never redefine it | superpowers review gates |
| `executing-analysis-plans` | Drive an approved plan: sequential spine validated in order, independent specs/designs fanned out to parallel subagents | `executing-plans` / `subagent-driven-development` |
| `wrong-number-debugging` | Bisect the pipeline to the step where the number went bad | `systematic-debugging` |
| `result-verification` | Reconcile, reproduce from clean state, attack with robustness, before reporting | `verification-before-completion` |
| `causal-identification` | State & test identification assumptions; mandatory robustness for DiD/IV/RDD/etc. — the reduced-form workflow | (none — domain core) |
| `structural-estimation` | Estimate model primitives for counterfactuals the data can't contain: write the model card and get approval, prove recovery by Monte Carlo, derive analytical gradients group-by-group, re-solve equilibrium one scenario per mechanism — the structural workflow | (none — domain core) |
| `analysis-review` | Review an analysis for silent-failure classes; verify review feedback | `requesting`/`receiving-code-review` |
| `project-organization` | Paper-centric research-repo structure (pipeline stages × subject subfolders, `data/{raw,intermediate,output}`), standardized naming, gitignore the scratch; enforced throughout and tidied before git | (none — research-specific) |

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
experiment?", watching for bad controls (`causal-identification`); and, when the
question lives outside the data, go structural deliberately — justify it over
reduced form, name what identifies each primitive, prove the estimator recovers
truth before trusting it, and re-solve equilibrium for every counterfactual
(`structural-estimation`). The target is a senior microeconomist's instincts —
reduced-form *and* structural — not a careful RA's checklist.

## Why a separate family

In software the dangerous bug throws. In analysis it stays quiet: a join fans out
and revenue triples; one `NA` poisons a mean; units are off by 100×; a timezone
shifts every event into the wrong day; train/test overlap makes a metric a fantasy;
an identification assumption fails and confounding masquerades as an effect. None
raise an error. These skills assert everything *around* the answer that must hold
regardless of the answer — and, for causal work, force the identification
assumptions to be stated and tested before estimating. Structural work has its own
silent failure: a misspecified model fits in-sample and lies confidently
out-of-sample, or a non-identified parameter still gets a number from the
optimizer — so `structural-estimation` fixes the model and its identification in
an approved spec, and proves the estimator recovers known parameters before any
counterfactual is trusted.

## Beyond skills: always-on layer + agents

Skills are *triggered* — but triggering is fallible, and some discipline must hold
*every* time. So (inspired by [ECC](https://github.com/affaan-m/ecc)'s layered
model and superpowers' own hook) the plugin ships a **hook layer** that keeps the
discipline present, makes the chain *fire* reliably, and makes long work resumable:

- **A SessionStart always-on block** (`hooks/session-start`) — the creed, the
  never-change-the-goal-behind-the-user's-back rule, the
  write-it-down-before-you-build rule (plan / spec / model card), the
  frame→approve→execute→verify spine, and a silent-failure + economist red-lines
  card — so the discipline is present by default, not contingent on a skill
  triggering.
- **Trigger + chain-enforcement hooks** that turn the family from a *map* into a
  *flow that propels*. Every skill ends with an imperative `When to Use` decision
  graph + `The Process` that invokes the next skill; the hooks back that up — a
  `UserPromptSubmit` keyword router (`hooks/prompt-router`, a high-precision
  backstop) that re-surfaces the right skill on each prompt, and a `PostToolUse`
  skill-chain (`hooks/skill-chain`) that, the moment a skill is invoked, names its
  next obligation in the spine (framing → written plan → approval gate; execution →
  *ask* inline-vs-subagent fan-out, bounded ~3 checks; verify → review).
- **A resumability hook** (`hooks/plan-resume`, `SessionStart` + `PreCompact`):
  reads the living, phased **`analysis-plan.md`** and resumes you at the next open
  phase/step, so a long cleaning or estimation effort survives `/clear` and
  auto-compaction instead of restarting — disk-as-RAM, after
  [planning-with-files](https://github.com/othmanadi/planning-with-files).
- **Reusable subagents** (`agents/`): `robustness-runner` (executes one
  pre-specified spec against the validated data, asserts contracts, returns a
  structured result — the fan-out worker for `executing-analysis-plans`) and
  `analysis-reviewer` (independent adversarial review for the silent-failure
  classes).
- **Lessons-capture** (`docs/LESSONS.md`): a manual, no-machinery `/evolve` —
  record the silent failure that bit each project and fold general ones back into
  the skills.

## Requirements

- [Claude Code](https://docs.claude.com/en/docs/claude-code) with plugin support —
  or **[Codex](https://developers.openai.com/codex/skills)** / any agent that reads
  `SKILL.md` skills + `AGENTS.md` (see [On Codex](#on-codex-and-other-agents) below).
- The hooks (the always-on block, the trigger router / skill-chain, and the
  `analysis-plan.md` resumability hook) need **Claude Code v2.1+**, which auto-loads
  `hooks/hooks.json` from installed plugins. Everything else (skills, agents) works
  on any plugin-capable version.
- The skills are language-agnostic guidance for **R, Julia, and Python** — no
  packages are installed; you use the idioms native to your stack.

## Install

From inside Claude Code:

```text
/plugin marketplace add lancegui/causal-powers
/plugin install causal-powers@causal-powers
```

Then **restart Claude Code** so the hooks load. That's it — for any data,
analysis, or econometrics work the skills now trigger automatically, the always-on
discipline card is injected at the start of each session, and the chain propels
itself from framing through verification.

### Update / uninstall

```text
/plugin update causal-powers@causal-powers
/plugin uninstall causal-powers@causal-powers
```

### From source (local development)

```bash
git clone https://github.com/lancegui/causal-powers
# then, inside Claude Code:
#   /plugin marketplace add /absolute/path/to/causal-powers
#   /plugin install causal-powers@causal-powers
```

## On Codex (and other agents)

The skills are plain `SKILL.md` files with `name` + `description` frontmatter —
**the same format Codex uses** — so they load and trigger natively (off the
`description`, or by explicit `$<skill-name>`). Codex compatibility ships in the
repo: a Codex manifest (`.codex-plugin/plugin.json`), an `AGENTS.md` that carries
the always-on discipline (Codex has no SessionStart hook), and a tool-mapping
reference ([`skills/using-causal-powers/references/codex-tools.md`](skills/using-causal-powers/references/codex-tools.md)).

Install the skills into a directory Codex scans (per the
[Codex skills docs](https://developers.openai.com/codex/skills) — a project
`.agents/skills/` or your user `~/.agents/skills/`), then restart Codex:

```bash
git clone https://github.com/lancegui/causal-powers
# user scope (all projects):
mkdir -p ~/.agents/skills && ln -s "$PWD/causal-powers/skills"/* ~/.agents/skills/
# or project scope: copy/symlink the skills into <your-repo>/.agents/skills/
# and copy AGENTS.md to your repo root so the always-on discipline loads.
```

Or use Codex's built-in installer (`$skill-installer`) / the `/plugins` directory
if you prefer in-app install — see the
[Codex plugins docs](https://developers.openai.com/codex/plugins). Either way,
**copy `AGENTS.md` to your project root** (or merge it into an existing one) so the
discipline is always on, since the Claude Code hooks don't run on Codex.

**What changes on Codex:** the `hooks/` (always-on injection, trigger router,
skill-chain, `analysis-plan.md` resumability) are Claude-Code-only. On Codex the
discipline lives in `AGENTS.md`, skills trigger off their descriptions natively,
the subagent fan-out uses `spawn_agent` (or degrades to inline — enable
`[features] multi_agent = true` in `~/.codex/config.toml`), and you maintain the
living `analysis-plan.md` yourself (flush it before compacting). Full mapping in
[`codex-tools.md`](skills/using-causal-powers/references/codex-tools.md).

## How it's organized

```
causal-powers/
├── skills/        # the 14 disciplines (gateway + 13); plain SKILL.md — also Codex-native
├── agents/        # robustness-runner, analysis-reviewer
├── hooks/         # Claude Code: always-on block + trigger router + skill-chain + plan resumability
├── evals/trigger/ # per-skill trigger tests (the router's precision/recall regression set)
├── docs/          # design specs + LESSONS.md
├── AGENTS.md      # always-on discipline for Codex / other agents (symlink → hooks/session-context.md)
├── .codex-plugin/   # Codex plugin manifest
└── .claude-plugin/  # Claude Code plugin + marketplace manifests
```

## Design notes

The full design history lives in [`docs/specs/`](docs/specs/) — each version's
rationale, from the initial family through economic judgment, the always-on hook,
the "robustness is an argument" fix, the chain-enforcement layer (imperative
handoffs + trigger router + skill-chain), and the phased, resumable execution plan
with `data-preparation`.

## Contributing & feedback

Issues and PRs welcome. This is opinionated by design — it encodes one senior
microeconomist's instincts, reduced-form and structural — so if you disagree with
a default, open an issue and make the case.

## Credits

Built on ideas from [superpowers](https://github.com/obra/superpowers),
[Andrej Karpathy's notes](https://github.com/multica-ai/andrej-karpathy-skills),
and [ECC](https://github.com/affaan-m/ecc).

## License

[MIT](LICENSE) © Lance Gui
