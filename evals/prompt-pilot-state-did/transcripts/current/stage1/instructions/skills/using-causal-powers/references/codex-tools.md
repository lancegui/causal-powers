# Codex tool mapping

The Causal Powers skills are written with Claude Code tool names. On **Codex** the
skills load natively and trigger off their `description` (or explicit
`$<skill-name>`); when a skill names a Claude Code tool, use the Codex equivalent:

| Skill references | Codex equivalent |
|---|---|
| `Task` tool (dispatch a subagent) | `spawn_agent` — see [Subagent fan-out](#subagent-fan-out-needs-multi-agent) |
| Multiple `Task` calls in parallel (the robustness fan-out) | Multiple `spawn_agent` calls |
| `Task` returns its result | `wait_agent` |
| Subagent slot freed | `close_agent` |
| `Skill` tool (invoke a skill) | Skills load natively — just follow the instructions, or `$<skill-name>` to invoke explicitly |
| `TodoWrite` (task tracking) | `update_plan` |
| `Read` / `Write` / `Edit` (files) | your native file tools |
| `Bash` (run commands) | your native shell tools |

## Subagent fan-out needs multi-agent

`executing-analysis-plans` fans **independent** work (the chosen ~3 robustness
specs, alternative designs, subsample cuts) out to parallel subagents, and ships
two agents — `robustness-runner` (runs one pre-specified spec, asserts the data
contracts, returns a structured result) and `analysis-reviewer` (independent
silent-failure review). On Codex these are dispatched with `spawn_agent`. Enable
multi-agent in `~/.codex/config.toml`:

```toml
[features]
multi_agent = true
```

If multi-agent is unavailable, the fan-out **degrades to inline** — run the chosen
specs one at a time in the current session (still bounded to ~3, still each
validated with the data-contracts checks). This is exactly the *inline* arm of the
execution-mode choice `executing-analysis-plans` already presents; on Codex,
"inline vs subagent" is decided by whether `multi_agent` is on.

## What does NOT carry over from Claude Code (and what replaces it)

The plugin's `hooks/` are Claude-Code-only. On Codex:

- **Always-on discipline** (the SessionStart injection) → lives in **`AGENTS.md`**
  at the repo root, kept byte-identical to `hooks/session-context.md`, which
  Codex reads automatically.
- **Trigger router + skill-chain** (the UserPromptSubmit / PostToolUse backstops)
  → not needed: Codex selects skills from their `description` natively, and each
  skill's own `## When to Use` graph + `## The Process` carry the handoffs.
- **Claude Code's `plan-resume`/`stop-gate` hooks** (SessionStart/PreCompact/Stop)
  → no direct equivalent; the discipline is `docs/analysis/index.yaml` itself.
  Maintain `index.yaml` plus the named YAML records and flush them before
  compaction, so a fresh Codex session reads the index first instead of
  rereading a giant plan. If a root `analysis-plan.md` (v1) is still present,
  that is a migration signal only — extract it into `docs/analysis/` via
  `analysis-state-management` and archive or delete it; never resume from it
  directly.
