# Conductor integration — causal-conductor on OpenCode

This reference covers the causal-conductor spine plugin for OpenCode. It is
**not** optional reading once the plugin is installed: every requirement below
binds in exactly the same way as `SKILL.md`'s core rules — nothing here is
weakened, advisory, or "nice to have" just because it lives in a reference
file. `SKILL.md` is the generic schema and discipline every user needs for
durable analysis state, including single-session users with no conductor
installed; this file is the additional contract that applies specifically
when causal-conductor is present, and it is fully binding for that audience.

## Plausibility threats require `owner_node`

Under plain schema v2 (`SKILL.md`), a `plausibility_threats[]` item needs only
`threat` and `check`. Under causal-conductor, every item must also carry
`owner_node`:

```yaml
plausibility_threats:             # REQUIRED, non-empty (a waiver is still an entry)
  - threat: mortality denominator mixes county populations across vintages
    check: recompute rates with fixed-vintage denominators, compare
    owner_node: sdid-main          # topology node that runs/verifies this check
```

`owner_node` names the topology node that will run or verify the check. A
threat check without an owner is not an advisory for later — it is a missing
piece of the phase contract that must be fixed before approval.

Correspondingly, in **Draft, Review, Approve** step 1, each plausibility
threat's `check` must name `owner_node` *before* approval, so an oracle
finding like "this check should run before completion" becomes a phase-draft
fix, not a mid-execution reapproval.

In **Red Flags**, add: a `plausibility_threats[]` item with no `owner_node`,
or an owner that is not a declared topology node, means the check has no
execution home.

## Approval binding — the conductor's own state

`SKILL.md` establishes that approval is never stored in the phase file itself
and that approval truth lives in the user's explicit sign-off in chat. When
the causal-conductor spine plugin is installed (OpenCode), approval truth
*additionally* lives in the plugin's own state:

```
{ phaseId, sha256(contract), approvedAt }
```

— never in anything the model can edit. Correspondingly, in **Draft, Review,
Approve** step 3: on approval, do not write anything into the phase file to
record that fact — approval lives in the user's words *and, if present, the
conductor plugin's bound record.*

## Draft, Review, Approve — the conductor's review role

Step 2 of `SKILL.md`'s Draft, Review, Approve reads generically ("route to
independent review"). Under causal-conductor the review role has a name:
route the phase YAML to **oracle** review when the design is high-risk.

## Drift = the approved phase contract changing (semantic, not byte-for-byte)

`SKILL.md` states the plain-user version of drift: don't quietly edit an
approved phase contract; changing scope, topology, or acceptance checks after
approval needs a new draft and re-approval, while edits to `index.yaml`,
`decisions.yaml`, other phase files, or run/handoff records are not drift.

Under causal-conductor this rule is enforced against a **semantic** contract,
not the file's raw bytes: the conductor plugin ignores pure phase bookkeeping
(`updated`, `status`, `next_action`) but binds the semantic contract — id,
goal/scope/out-of-scope, acceptance checks, plausibility threats, topology,
and any unknown non-bookkeeping fields. A change to any of those, even one
that leaves the file's other bytes untouched, is drift and requires
re-approval; a change confined to bookkeeping fields is not drift even though
it does touch the file.

## Oracle Isolation

Oracle may read `index.yaml` for navigation and the verification packet for
paths, commands, claims, and expected invariants. Oracle must verify claims
from source files, outputs, and commands, not from fixer/explorer prose.

## Handoffs — lane naming

`SKILL.md`'s handoff example uses a generic `agent:` value
(`robustness-runner`) so it reads correctly with no conductor installed.
Under causal-conductor, the `agent:` field is filled with the conductor's own
lane name — `fixer`, `explorer`, or `oracle` — rather than the generic
Causal Powers subagent name. The full lane-name mapping (which Causal Powers
role corresponds to which OpenCode/causal-conductor lane, and what each
lane does) lives in
`skills/using-causal-powers/references/opencode-tools.md`; this file does not
duplicate that table, only notes that handoff records follow it.

## Deleted-from-v1 field: `delegated_agents`

`SKILL.md` explains the deletion of `delegated_agents` from v1 phase records
in dispatch terms: which subagent runs a node is a per-task decision made at
execution time, not standing phase state. Under causal-conductor the fuller
reason is that assigning agents to phases would be role theater — the lane
architecture (fixer/explorer/oracle) is standing config owned by the
conductor plugin and the standing prompt, not something a phase record needs
to restate.
