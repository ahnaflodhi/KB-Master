---
id: 50-adapters/claude-native
title: claude-native — Adapter Contract
purpose: adapter-contract
audience:
  - orchestrator
also_needed_by:
  - planner
  - pre_check
  - executor
  - kb_linter
  - wiki_ingest
  - wiki_query
  - meta_review
status: stable
version: 2.10
last_reviewed: 2026-05-04
extracted_from:
  source: SYSTEM-BLUEPRINT-v2.10.md
  sections: ["§24 Claude Code harness integration", "§25 Adapter contract", "§25 Adversarial diversity"]
  line_range_hint: "synthesis: §24 subagent + SDK + §25 5-op interface + cross-family pairing notes + v2.9 gateguard inheritance + v2.10 host_access true/true"
depends_on:
  - 00-overview/invariants.md
  - 50-adapters/capability-matrix.md
related:
  - 50-adapters/claude-orchestrator.md
  - 40-runtime/dispatch-shim.md
  - 40-runtime/claude-code-integration.md
max_lines: 150
directives:
  must_count: 6
  should_count: 3
  may_count: 1
---

## claude-native — Adapter Contract

### Identity

| Field | Value |
|---|---|
| `kind` | `claude-native` |
| `sub_modes` | `subagent`, `sdk` |
| `default_sub_mode` | `subagent` |
| `capability_check` | "Task tool available OR `@anthropic-ai/claude-agent-sdk` on PATH" |

The adapter has two sub-modes that share the contract but differ in process boundary:

- **subagent**: in-process via Claude Code's `Task` tool with a `subagent_type`. Different conversation context (satisfies Inv 1 Generator≠Evaluator at context level) but same harness, same tools, same gateguard inheritance.
- **sdk**: separate process via `@anthropic-ai/claude-agent-sdk`. Different process, different harness instance — useful when stronger isolation is required, but the host project MUST register an explicit pre-tool guard equivalent to gateguard.

### Probe response

```yaml
available: true                 # iff Task tool available (subagent) OR SDK on PATH (sdk)
protocol: n/a
capabilities:
  - "context-isolation"        # always — different conversation
  - "process-isolation"        # sdk sub-mode only
enforces_pre_action_facts: true
host_access:
  loopback_tcp: true            # workers run on the host
  unix_sockets: true
pre_action_fact_mechanism: gateguard-skill   # subagent: inherited from parent harness; sdk: per-process registration REQUIRED
```

### Dispatch contract

| Sub-mode | Invocation | Sync / async |
|---|---|---|
| `subagent` | `Task(subagent_type=<role-mapped>, prompt=...)` | sync (blocks until subagent returns) |
| `sdk` | `claude-agent-sdk run --prompt-file=<path> --output=<job_dir>` | async (job model — `dispatch` returns immediately with `job_id`) |

Argument mapping (both sub-modes):

| Field | Behaviour |
|---|---|
| `role` | Mapped to a Claude Code subagent_type or SDK config preset |
| `prompt` | Assembled per §25 Step 3 PREPARE; semantic-isolation rule applied to copied field values |
| `sandbox` | Default `read-only` for read-only roles; `workspace-write` for executor / kb_linter / wiki_ingest |
| `model` | Per `agents.<agent>.model` in `agents.config.yaml`; defaults Sonnet 4.6 for mid-tier roles, Opus 4.7 for frontier |
| `inputs[]` | File paths the subagent should read |
| `expected_schema` | The `60-schemas/<role-output>.md` file the orchestrator's SCHEMA step will validate against |

### Result contract

| Sub-mode | `last_message` location | Artifacts |
|---|---|---|
| `subagent` | Return value of the `Task` tool call | None separate — subagent writes to filesystem if its sandbox permits, orchestrator reads after |
| `sdk` | `<job_dir>/last_message.txt` | `<job_dir>/stdout.log`, `<job_dir>/stderr.log`, `<job_dir>/exit_code`, optional `<job_dir>/events.jsonl` |

### Sandbox semantics

- `read-only`: Read/Grep/Glob/WebFetch (research carve-out for sources/), no Edit/Write/Bash mutating operations
- `workspace-write`: above + Edit/Write/Bash within the project tree
- `host shell` (subagent only, when parent is orchestrator-mode): full host access — typically not used for delegated workers

The sandbox is enforced by Claude Code's permission mode (subagent inherits from parent harness; sdk respects per-config setting). Per §25 it MUST always be passed explicitly at dispatch time — relying on the default is an adapter-misuse bug.

### Failure modes

- **Task tool unavailable** (subagent sub-mode): adapter probe returns `available: false`; orchestrator falls back to sdk sub-mode if available, else inline.
- **SDK process exits non-zero** (sdk sub-mode): consume verdict `rejected-auth`; re-delegate up to `validation.re_delegate_max_attempts` then escalate.
- **Worker exceeds context budget**: SDK truncates; orchestrator's SCHEMA step detects missing required fields and rejects.
- **Worker writes outside its sandbox**: harness-level error; consume rejected with `verification_verdict: SANDBOX-VIOLATION` (the violation itself was already prevented; the rejection is to surface the bug).

### Pre-action fact enforcement (Invariant 10)

- **subagent**: gateguard inherited from parent harness. No per-worker setup needed.
- **sdk**: REQUIRES explicit registration of a PreToolUse callback equivalent to gateguard. Adopters using sdk sub-mode MUST configure this in their SDK initialization or the adapter MUST report `enforces_pre_action_facts: false` (which restricts it to read-only roles).

### Host-local service access (v2.10)

`host_access: {loopback_tcp: true, unix_sockets: true}`. Workers (both sub-modes) run on the orchestrator's host so they have the same network and socket access by default. This makes claude-native the steady-state choice for `executor.commercial` and any commercial Evaluator role that needs live test-suite execution against host services.

### What this adapter MUST NOT do

- MUST NOT be assigned to `roles.orchestrator` (claude-orchestrator only).
- MUST NOT report `enforces_pre_action_facts: true` from the sdk sub-mode without the per-process pre-tool guard actually registered (false advertisement is a config bug).
- MUST NOT silently inherit a parent's permission mode that exceeds the dispatched sandbox value.
- MUST NOT cache subagent return values across dispatches — every dispatch is a fresh context.
- MUST NOT re-use a `job_id` across dispatches (sdk sub-mode); the orchestrator's AUTH step will reject collisions.
- MUST NOT swallow worker stderr — even on success, stderr SHOULD be written to the consume ledger row's `notes:` field for observability.

### Cross-references

- Adapter probe matrix: `50-adapters/capability-matrix.md`
- Bridge alternative for cross-family adversarial pairing: `50-adapters/codex-bridge.md`
- Claude Code harness specifics: `40-runtime/claude-code-integration.md`

---
