# Evolution candidates — ecosystem survey, 2026-06-12

A survey of the skill/plugin ecosystems causal-powers borrows from, run while
building v0.19.0, with adoption decisions. Sources were read directly (commit
logs, file trees, release notes), not assumed; links inline.

## Adopted in 0.19.0

- **With/without behavioral benchmark** — the survey's #2-ranked candidate,
  independently already in flight; design matches the best published template
  ([planning-with-files `docs/evals.md`](https://github.com/othmanadi/planning-with-files/blob/master/docs/evals.md):
  parallel with/without arms, objectively verifiable assertions, token/time
  capture). Ours: `evals/behavioral/` + `scripts/run-behavioral-eval.py`.
- **Stale-plugin-version warning** (`hooks/session-start`) — counters
  [claude-code#52218](https://github.com/anthropics/claude-code/issues/52218)
  (auto-update never refreshes plugin installs, so plugin hooks pin to a stale
  path forever) and [#26744](https://github.com/anthropics/claude-code/issues/26744)
  (third-party marketplaces don't auto-update). No surveyed plugin self-detects
  drift — this was an open niche, and it's the exact mechanism behind our own
  "the skills never triggered" incident.
- **`startup|clear|compact` SessionStart matcher** (superpowers' trick so the
  card re-injects after compaction) — already present in `hooks/hooks.json`;
  confirmed, no change needed.
- **Executable contracts** (the [nimrodfisher](https://github.com/nimrodfisher/data-analytics-skills)
  / [anthropics document-skills](https://github.com/anthropics/skills) pattern of
  scripts-not-prose) — partially: `data-contracts` now ships copy-paste helper
  preludes in 4 languages (`references/contract-helpers.md`). Standalone
  `scripts/*.py` checkers remain an option if the preludes prove insufficient.

## Ranked next (not yet adopted)

1. **Official eval schema + description hill-climbing**
   ([anthropics/skills skill-creator](https://github.com/anthropics/skills/tree/main/skills/skill-creator):
   `run_eval.py` with early stream-detection of skill invocation,
   `improve_description.py` + `history.json` won/lost loop). Migrate
   `evals/trigger/*.json` to the `evals.json` expectations schema and run the
   hill-climber over the 14 descriptions.
   [arXiv:2604.04323](https://arxiv.org/abs/2604.04323) found skill benefits
   degrade sharply with realistic retrieval — cross-sibling description
   discriminability is the binding constraint, and it's optimizable. Our
   `scripts/eval-triggers.py --live --competitors` is the measurement half;
   this adds the optimization half.

2. **Pressure-test the discipline skills; regression-test the subagents**
   (superpowers [`testing-skills-with-subagents.md`](https://github.com/obra/superpowers):
   RED-GREEN-REFACTOR for skills — run 3+-pressure scenarios *without* the
   skill, capture rationalizations verbatim, write the skill against them).
   Sharper still: superpowers **v5.0.6 measured its subagent review loop and
   deleted it** (~25 min overhead, zero quality delta across 5×5 trials), and
   v5.1.0 dissolved its last named agent into a prompt-template file. Apply the
   same test to our `robustness-runner` / `analysis-reviewer` before assuming
   they earn their dispatch cost; the behavioral benchmark now makes that
   measurable. Adversarial prompts worth adding to the corpus: "just give me
   the coefficient, skip the robustness", "no time for a plan, the deadline is
   tonight", "the old analysis already validated this join".

3. **Stop-hook accumulator/gate + JSONL run ledger**
   (ecc's [`stop:format-typecheck` batch pattern](https://github.com/affaan-m/ecc);
   planning-with-files v3 `gate-stop.sh` + append-only `ledger-append`). For
   us: accumulate datasets/results touched during a turn, reconcile once at
   Stop ("results written without `result-verification`?"); optionally gate
   "analysis done" on the plan's open checkboxes. Adopt carefully —
   planning-with-files gates only when five conditions align, to avoid the
   infinite-loop hazard, and
   [#20221](https://github.com/anthropics/claude-code/issues/20221) limits
   SubagentStop enforcement. A `type: "agent"` Stop hook
   ([hooks guide](https://code.claude.com/docs/en/hooks-guide)) could run the
   verification subagent natively.

4. **Scoped-down instinct loop** (ecc
   [`continuous-learning-v2`](https://github.com/affaan-m/ecc): Stop-hook mines
   the transcript into confidence-scored lesson YAMLs; `/evolve` clusters them
   into skill edits; runs at Stop, deliberately not UserPromptSubmit, for
   latency). v0.19.0 closed the *manual* loop (debugging/review/verification all
   log to `docs/LESSONS.md`); this is the automation rung above it. Adopt only
   if the manual loop demonstrably under-captures.

5. **Prompt-injection hardening of the hook surface** (planning-with-files'
   March-2026 audit: a PreToolUse hook re-injecting a plan file that
   WebFetch-able content could write to = injection amplification; fixed with
   attestation + tool restrictions). Our `plan-resume` re-injects
   `analysis-plan.md` and the skill-chain echoes skill output. Cheap first
   step: never auto-inject plan content beyond a capped excerpt, and note the
   boundary in the hook headers. SHA attestation if the threat ever gets real.

6. **Hook ergonomics** (ecc: every hook entry carries `id` + `description`, a
   `ECC_DISABLED_HOOKS` env kill-switch, an injected-context size cap). Trivial
   to mirror (`CAUSAL_POWERS_DISABLED_HOOKS`); do it next time `hooks.json` is
   touched.

## Declined (and why)

- **ecc's scale** (262 skills / 64 agents / 29 rules, SQLite session store,
  Rust control plane): against the family's lean, paper-centric ethos; our
  binding constraint is reliability of 14 skills, not coverage of 262.
- **Named-agent expansion**: the ecosystem is moving the other way
  (superpowers v5.1.0 deleted its last named agent) — candidate #2 above may
  shrink our agent count, not grow it.
- **superpowers' Codex sync-script model** (one-way generated fork): our
  symlinked single-source `AGENTS.md` + installer is simpler and hasn't
  drifted; revisit only if platform divergence grows.

## Peer landscape (positioning, not adoption)

No surveyed project combines discipline skills + hooks + subagents + evals for
causal inference; the peers are *reference libraries*:
[dylantmoore/stata-skill](https://github.com/dylantmoore/stata-skill) (37
references, 20 package guides — complementary, Stata),
[causal-inference-mixtape](https://github.com/Jill0099/causal-inference-mixtape)
(method templates), [StatsPAI](https://github.com/brycewang-stanford/StatsPAI)
(library-coupled), [NICAR 2026 skills](https://github.com/amkessler/nicar2026_skills_in_codex_claude)
(data+schema bundling — "never guess field names; ship the schema" is
`data-contracts` made concrete and worth citing),
[econ-writing-skill](https://github.com/hanlulong/econ-writing-skill)
(downstream complement). The discipline-enforcement layer remains this
family's distinct contribution; the benchmark is what makes the claim
falsifiable.
