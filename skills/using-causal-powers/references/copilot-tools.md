# GitHub Copilot tool mapping

The Causal Powers skills are written with Claude Code tool names. On **GitHub
Copilot CLI** the skills load natively — Copilot auto-discovers skills from
installed plugins, reads their `name`/`description` frontmatter, and exposes them
through its built-in `skill` tool. When a skill names a Claude Code tool, use the
Copilot equivalent:

| Skill references | Copilot CLI equivalent |
|---|---|
| `Skill` tool (invoke a skill) | Skills load natively — follow the instructions, or invoke via the `skill` tool |
| `Read` / `Write` / `Edit` (files) | Copilot's file read / create / edit tools |
| `Bash` (run commands) | Copilot's shell / terminal tool |
| `Grep` / `Glob` (search) | Copilot's search tools |
| `Task` tool (dispatch a subagent) | See [Subagent fan-out](#subagent-fan-out-degrades-to-inline) |
| `TodoWrite` (task tracking) | Copilot's plan/todo surface, or maintain `analysis-plan.md` by hand |

## Always-on discipline lives in `AGENTS.md`

Copilot CLI reads the repo-root **`AGENTS.md`** (a symlink to
`hooks/session-context.md`) and `.github/copilot-instructions.md`. Keep the managed
Causal Powers block in whichever your setup loads, so the discipline is always on
when you work in the tree. The plugin's `hooks/` (SessionStart injection, trigger
backstops, Stop-gate) are **Claude-Code-only** and do **not** run here — the
`AGENTS.md` block carries the discipline, and each skill's own `## When to Use`
graph carries the handoffs.

## Re-apply, don't reload (skills don't dedup on Copilot)

Same caveat as OpenCode: Causal Powers **re-fires per analytical request** (a new
spec, a new cut, a re-run all re-trigger the relevant skill — this is deliberate),
but Copilot has **no harness bookkeeping of what's already in context**. The
`skill` tool re-injects a skill's **full body** every time you call it, so the
failure mode is reloading the same skill a dozen-plus times in one session — token
churn, not rigor.

The rule:

- **Body still in context?** Don't call the `skill` tool — **narrate** the
  re-application ("re-applying `causal-identification` (still loaded)") and proceed.
- **Body scrolled out** (long session, post-compact, can't see it)? *Then* reload
  it via the `skill` tool.
- One batch loaded at the top of a turn is fine; re-loading that batch on **every**
  turn is the anti-pattern.

This is the Copilot-specific enforcement of the *re-apply-don't-reload* line in the
always-on discipline block (`AGENTS.md`).

## Subagent fan-out degrades to inline

`executing-analysis-plans` fans **independent** work (the chosen ~3 robustness
specs, alternative designs, subsample cuts, placebo tests) out to parallel
subagents on Claude Code. If your Copilot setup exposes no subagent/task tool, the
fan-out **degrades to inline** — run the chosen specs one at a time in the current
session, still bounded to ~3, each validated with the `data-contracts` checks. This
is the *inline* arm of the execution-mode choice `executing-analysis-plans` already
presents; the `robustness-runner` / `analysis-reviewer` recipes still apply, you
just run them yourself rather than dispatching them.

## Maintain `analysis-plan.md` yourself

With no resumability hook, keep the living `analysis-plan.md` current and **flush it
before you compact or end a session**, so a fresh Copilot session resumes from the
file (disk-as-RAM).
