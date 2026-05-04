---
id: 50-adapters/claude-orchestrator
title: claude-orchestrator — Adapter Contract
purpose: adapter-contract
audience:
  - orchestrator
also_needed_by:
  - apply_meta
  - meta_review
status: stable
version: 2.10
last_reviewed: 2026-05-04
extracted_from:
  source: SYSTEM-BLUEPRINT-v2.10.md
  sections: ["§2 Invariant 9", "§25 Adapter contract", "§25 Dispatch shim Step 11", "§24 Claude Code harness integration"]
  line_range_hint: "synthesis: Inv 9 non-delegability + §25 5-op interface + §24 startup ritual + v2.9 gateguard + v2.10 host_access"
depends_on:
  - 00-overview/invariants.md
  - 50-adapters/capability-matrix.md
related:
  - 20-roles/orchestrator.md
  - 40-runtime/dispatch-shim.md
max_lines: 150
directives:
  must_count: 6
  should_count: 2
  may_count: 1
---

## claude-orchestrator — Adapter Contract

### Identity

| Field | Value |
|---|---|
| `kind` | `native-orchestrator` |
| Singleton? | yes (Invariant 9 — non-delegable) |
| `binary_path` | n/a — the running Claude Code session |
| `capability_check` | implicit — if Claude Code is running, this adapter is available |

The `claude-orchestrator` adapter is unique: it represents the orchestrator's own context. It is never spawned, never invoked as an executor, and never assigned to any role except `roles.orchestrator: claude-main`. Config load fails fast if any other binding is attempted.

### Probe response

```yaml
available: true
protocol: n/a            # no wire protocol — same process
capabilities:
  - "session-state"     # owns PROGRESS.md, ledger, escalations
  - "host-shell"        # full bash access
enforces_pre_action_facts: true       # gateguard skill enforces Invariant 10
host_access:
  loopback_tcp: true                  # runs in host shell, no sandbox
  unix_sockets: true
pre_action_fact_mechanism: gateguard-skill
```

### Dispatch contract

Inline (synchronous) execution within the orchestrator's own context. Used for:

- Apply-Meta runs (`20-roles/apply-meta.md`) — orchestrator-inline because mutating `agents.config.yaml` mid-session is itself an Invariant-9 boundary case.
- Inline fallback when a delegated adapter is unavailable (per §25 graceful degradation): the orchestrator fulfils the role itself rather than silently skipping.
- v2.10 host-side wrapper invocations: when a downstream adapter has `host_access: false` and a role requires it, the orchestrator executes the host call (e.g. `psql`) and pre-injects the result as read-only evidence into the dispatch.

Dispatch arguments:

| Field | Behaviour |
|---|---|
| `role` | The role being fulfilled inline |
| `prompt` | Used as the orchestrator's own working prompt for that role |
| `sandbox` | Always host shell — orchestrator cannot sandbox itself |
| `model` | n/a — runs in the existing Claude Code session model |
| `inputs[]` | Read directly via Read/Grep/Glob tools |
| `expected_schema` | Validated by the orchestrator's own SCHEMA step |

### Result contract

Output is the orchestrator's user-visible response stream. The CONSUME step writes to `iterations/current/<role-output>.md` directly via the Edit/Write tools.

### Sandbox semantics

None. The orchestrator runs in the host shell with no filesystem or network restrictions. This is what makes it the keystone for Invariant 9 (it can write PROGRESS.md, the ledger, and escalation.md — files no delegated adapter is permitted to touch).

### Failure modes

- **gateguard skill not loaded**: harness-level failure. The orchestrator MUST refuse to start any state-mutating action. Adopters using a non-Claude-Code harness must implement an equivalent PreToolUse hook.
- **PROGRESS.md missing or unparseable**: `pipeline_state` defaults to `idle`; orchestrator emits a warning and starts a fresh iteration.
- **`agents.config.yaml` schema_version unknown**: refuse to load (forward-incompat).
- **Inline role fulfillment exceeds context budget**: orchestrator MUST escalate (`escalation.md` reason `inline-context-exhausted`); MUST NOT silently truncate.

### Pre-action fact enforcement (Invariant 10)

`enforces_pre_action_facts: true`, mechanism `gateguard-skill`. Every state-mutating tool call (Bash, Edit, Write, MultiEdit, NotebookEdit, Task, WebFetch outside `sources/`, mcp:write) MUST be preceded by a user-visible 4-fact block. The gateguard skill is harness-level: it blocks the tool call until the orchestrator emits the block.

Adopters on non-Claude-Code harnesses (Claude Agent SDK, custom CLI) MUST register an equivalent PreToolUse callback. The PROPAGATION clause in Invariant 10 makes this inheritance mandatory at config load.

### Host-local service access (v2.10)

`host_access: {loopback_tcp: true, unix_sockets: true}`. The orchestrator runs in the host shell with no sandbox, so it has full host service access by default. This capability is what enables the v2.10 degradation pattern: when a downstream adapter has `host_access: false` and a role needs `psql` / Redis / Docker / app-server probes, the orchestrator runs the host call itself and pre-injects the output as read-only evidence into the next dispatch.

### What this adapter MUST NOT do

- MUST NOT be invoked as an executor for any role except `orchestrator` and `apply_meta`.
- MUST NOT be reassigned via `agents.config.yaml roles:` to anything other than `claude-main`.
- MUST NOT delegate the orchestrator role to any other adapter (Invariant 9).
- MUST NOT bypass the §25 11-step shim for inline fulfilment — even when the orchestrator is the executor, the dispatch shim still runs (PROBE through STATE) so the audit trail is uniform.
- MUST NOT skip the gateguard skill (Invariant 10) by claiming "the orchestrator already knows the request" — the fact block is the audit-trail artifact, not a self-reminder.
- MUST NOT silently fall back to inline when a delegated adapter fails without recording an `inline-fallback` row in `pipeline/verification-ledger.jsonl`.

### Cross-references

- Role mandate: `20-roles/orchestrator.md`
- 11-step dispatch shim: `40-runtime/dispatch-shim.md`
- §22 harness-decay protocol: `40-runtime/harness-decay.md`

---
