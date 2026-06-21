# Causal Powers

**Superpowers for data analytics, causal inference, and econometrics.**

A Claude Code skill family that adapts the *discipline* of
[superpowers](https://github.com/obra/superpowers), whose name it borrows in
homage, to the failure modes specific to data work. In software the dangerous bug
is loud: a stack trace points near its cause. In empirical work it is **silent** —
the code runs clean and returns a confident, wrong answer. These skills make that
failure visible before it reaches a result.

> A number you computed but never validated is a guess wearing a lab coat.

## What makes it different

1. **Economic framing of mature, proven skills.** It adapts the disciplines proven in software engineering — contract-checked transforms, systematic debugging, specification before code, independent review — to the silent failures and judgment calls of empirical microeconomics.
2. **It grows into your data's domain.** Each iteration records what went wrong in a given project and surfaces it the next time the same step recurs, so the discipline grows more attuned to that dataset over time. The shared skills stay general; what accumulates is the project's own record of past mistakes.
3. **Built for day-to-day research, not one-shot answers.** Empirical projects run for weeks across many sessions. A living, phased `analysis-plan.md` keeps the state of the work on disk, so it survives `/clear`, automatic compaction, and interruption: a new session resumes where the last left off, with prior decisions and their rationale intact.

## Motivation

The most carefully designed agent skills today are built for **software engineering**, yet their organizing ideas are not specific to software:

- **Goal-driven execution** — state the success criterion, then loop until it is met; evidence before assertion ([superpowers](https://github.com/obra/superpowers); [Karpathy's notes](https://github.com/multica-ai/andrej-karpathy-skills)).
- **Human-in-the-loop gates** — surface a consequential decision for the user rather than settle it silently ([superpowers](https://github.com/obra/superpowers)).
- **Evolving** — skills that sharpen each time they run, recording what failed and folding it back in ([ECC](https://github.com/affaan-m/ecc)).
- **Planning** — a written plan that persists across sessions and resumes cleanly, treating the disk as working memory ([planning-with-files](https://github.com/othmanadi/planning-with-files)).

Each transfers naturally to **empirical microeconomics**, where the consequential failures are silent and the work divides into three pathways with distinct purposes: **reduced-form** analysis, which measures an effect present in the data; **structural** estimation, which recovers the primitives needed to simulate a counterfactual the data does not contain; and **predictive modeling**, which predicts, scores, ranks, or flags outcomes — with leakage-safe evaluation and a hard prediction-is-not-causation line.

Causal Powers therefore introduces no new methodology. It reorganizes these well-developed practices and refocuses them on microeconomic analysis, then adds the discipline the domain demands: identification before estimation, recovery before trust, and economic, not merely statistical, judgment.

## What you get

- **Catches the bugs that don't throw.** A join fans out and revenue triples; one `NA` poisons a mean; train/test overlap fakes a model metric; a control is post-treatment — every one a clean run. These skills make them loud **before** they reach a stakeholder.
- **A senior economist's instincts, not an RA's checklist.** Forms a prior on sign, magnitude, and mechanism before the data; reads every estimate in interpretable units and judges *economic*, not just statistical, significance; refuses a causal claim without a named design ("what's your experiment?").
- **Never changes the goal behind your back.** Dropping data, swapping a spec, "upgrading" the design mid-debug — each one stops and asks. You stay in control of the estimand, the sample, and the design; the agent loops autonomously *toward the agreed goal*, never past it.
- **Plans at two altitudes.** It pins the estimand before code (study altitude) *and* the small-step roadmap before a merge or a debug (task altitude) — the roadmap you approve first, not a dive.
- **Measured, not asserted.** Ships a trigger CI and a planted-silent-failure benchmark. Most skill libraries can't tell you whether they actually help; this one is instrumented (`scripts/eval-triggers.py`, `scripts/run-behavioral-eval.py`).

## The flow

![Causal Powers flow: any data, analysis, or figure request goes to question-framing, forks to reduced-form (causal-identification), structural (structural-estimation), or predictive (predictive-modeling), through a write-the-plan approval gate, then executing-analysis-plans, data-preparation and data-contracts, result-verification, and analysis-review to ship; analysis-craft, analysis-checkpoints, and wrong-number-debugging run alongside.](docs/flow.svg)

*The whole flow runs on an **always-on layer** (a discipline card injected every session + a trigger router) that re-fires the right skill on every request. `analysis-craft` (minimal, surgical code) and `analysis-checkpoints` (the human-in-the-loop guardrail) run alongside every step; `project-organization` keeps the repo legible and tidies before commit.*

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
| `predictive-modeling` | Predict, score, rank, or flag outcomes: gated Prediction Spec, leakage-safe evaluation, deployment-matched splits, and a hard prediction-is-not-causation line — the predictive workflow | (none — domain core) |
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
(`structural-estimation`); and, when the goal is to predict, score, rank, or
flag, route to the predictive workflow — gated spec, leakage-safe eval,
deployment-matched splits, and never claim causation from a predictive model
(`predictive-modeling`). The target is a senior microeconomist's instincts —
reduced-form, structural, *and* predictive — not a careful RA's checklist.

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
  Injected excerpts are length-capped and sanitized (the plan file is an
  injection surface).
- **A Stop-gate + run ledger** (`hooks/stop-gate`): at most once per session, in
  analysis projects only (opt-in via `analysis-plan.md`/`docs/LESSONS.md`), and
  never when already continuing from a block — if a results artifact was written
  but `result-verification` never fired, or debugging ran but no lesson was
  logged, the stop is blocked once with a precise reason (and an explicit out).
  Every stop also appends one line to `.causal-powers/ledger.jsonl` — an
  append-only audit trail that survives compaction. All hooks honor a
  `CAUSAL_POWERS_DISABLED_HOOKS` env kill-switch (comma-separated hook names).
- **Reusable subagents** (`agents/`): `robustness-runner` (executes one
  pre-specified spec against the validated data, asserts contracts, returns a
  structured result — the fan-out worker for `executing-analysis-plans`) and
  `analysis-reviewer` (independent adversarial review for the silent-failure
  classes).
- **Lessons-capture** (`docs/LESSONS.md`): a manual, no-machinery `/evolve` —
  `wrong-number-debugging`, `analysis-review`, and `result-verification` each end
  by logging the failure class that bit, and general lessons fold back into the
  skills.
- **Evals that measure both halves** (`evals/`, `scripts/`). *Does it fire?* —
  `scripts/eval-triggers.py` runs the trigger corpus through the real
  `prompt-router` against a committed regression baseline, with a `--live`
  description-matching mode that includes the *competing* superpowers
  descriptions. *Does it catch anything?* — `scripts/run-behavioral-eval.py`
  A/Bs `claude -p` with and without the always-on card on nine tasks with
  planted silent failures (fan-out join, leakage, bad control, pre-trend
  violation, non-identified parameter, …), isolated from locally installed
  plugins, LLM-graded against per-scenario catch criteria
  (`evals/behavioral/README.md`).

## Requirements

- [Claude Code](https://docs.claude.com/en/docs/claude-code) with plugin support —
  or **[Codex](https://developers.openai.com/codex/skills)** / **[OpenCode](https://opencode.ai)** /
  any agent that reads `SKILL.md` skills + `AGENTS.md` (see [On Codex](#on-codex-and-other-agents)
  and [On OpenCode](#on-opencode) below).
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

### Built-in installer (copy-paste)

One command installs the skills into a directory Codex scans (`~/.agents/skills`
for user scope, per the [Codex skills docs](https://developers.openai.com/codex/skills))
**and** installs the always-on discipline as a managed block in your
`~/.codex/AGENTS.md` — then restart Codex:

```bash
curl -fsSL https://raw.githubusercontent.com/lancegui/causal-powers/main/scripts/install-codex.sh | bash
```

Project scope instead (checked into one repo, for your team — installs to
`<repo>/.agents/skills` and the repo-root `AGENTS.md`):

```bash
curl -fsSL https://raw.githubusercontent.com/lancegui/causal-powers/main/scripts/install-codex.sh | bash -s -- --project .
```

The installer is **idempotent** — re-run any time to update (it pulls a cached
clone and re-copies), and `--uninstall` cleanly removes the skills and the managed
block, leaving the rest of your `AGENTS.md` untouched. From a local clone:
`./scripts/install-codex.sh` (add `--project DIR` or `--uninstall`). Requires
`bash`, `git`, `python3`. (Prefer in-app install? Codex's own `$skill-installer`
and `/plugins` directory also work — see the
[Codex plugins docs](https://developers.openai.com/codex/plugins) — but you'd then
add `AGENTS.md` to your project root yourself for the always-on discipline.)

**What changes on Codex:** the `hooks/` (always-on injection, trigger router,
skill-chain, `analysis-plan.md` resumability) are Claude-Code-only. On Codex the
discipline lives in `AGENTS.md`, skills trigger off their descriptions natively,
the subagent fan-out uses `spawn_agent` (or degrades to inline — enable
`[features] multi_agent = true` in `~/.codex/config.toml`), and you maintain the
living `analysis-plan.md` yourself (flush it before compacting). Full mapping in
[`codex-tools.md`](skills/using-causal-powers/references/codex-tools.md).

## On OpenCode

[OpenCode](https://opencode.ai) auto-discovers `SKILL.md` skills and reads
`AGENTS.md` natively, so Causal Powers works with **no new manifest** — it scans
`.agents/skills/`, `.claude/skills/`, and `.opencode/skills/` (plus their `~/`
globals), which is exactly where the installer below puts the skills, and it loads
the always-on discipline from the repo-root `AGENTS.md` or the global
`~/.config/opencode/AGENTS.md` ([OpenCode skills](https://opencode.ai/docs/skills/) ·
[rules](https://opencode.ai/docs/rules/)).

The same installer serves OpenCode — pass `--opencode` (the only difference from
Codex is the user-scope `AGENTS.md` path):

```bash
curl -fsSL https://raw.githubusercontent.com/lancegui/causal-powers/main/scripts/install-codex.sh | bash -s -- --opencode
```

Project scope is **agent-agnostic** — `--project .` installs skills to
`<repo>/.agents/skills` and the discipline to the repo-root `AGENTS.md`, both of
which OpenCode reads, so the plain `--project` command above works for OpenCode
too. Re-run to update; `--uninstall --opencode` cleanly removes it.

**What changes on OpenCode:** like Codex, the `hooks/` are Claude-Code-only — the
discipline lives in `AGENTS.md`, skills trigger off their descriptions natively
(exposed through OpenCode's `skill` tool), the subagent fan-out uses the `task`
tool (or degrades to inline), and you maintain the living `analysis-plan.md`
yourself. Full mapping in
[`opencode-tools.md`](skills/using-causal-powers/references/opencode-tools.md).

## How it's organized

```
causal-powers/
├── skills/        # the 14 disciplines (gateway + 13); plain SKILL.md — also Codex-native
├── agents/        # robustness-runner, analysis-reviewer
├── hooks/         # Claude Code: always-on block + trigger router + skill-chain + plan resumability
├── evals/         # trigger/ (router CI corpus + baseline) · behavioral/ (planted-silent-failure benchmark)
├── scripts/       # eval-triggers.py (trigger CI) · run-behavioral-eval.py (benchmark) · install-codex.sh
├── docs/          # LESSONS.md template + dated design & measurement notes
├── AGENTS.md      # always-on discipline for Codex / other agents (symlink → hooks/session-context.md)
├── .codex-plugin/   # Codex plugin manifest
└── .claude-plugin/  # Claude Code plugin + marketplace manifests
```

## Contributing & feedback

Issues and PRs welcome. This is opinionated by design — it encodes one senior
microeconomist's instincts, reduced-form and structural — so if you disagree with
a default, open an issue and make the case.

## Credits

Built on ideas from [superpowers](https://github.com/obra/superpowers),
[Andrej Karpathy's notes](https://github.com/multica-ai/andrej-karpathy-skills),
[ECC](https://github.com/affaan-m/ecc), and
[planning-with-files](https://github.com/othmanadi/planning-with-files).

## License

[MIT](LICENSE) © Lance Gui
