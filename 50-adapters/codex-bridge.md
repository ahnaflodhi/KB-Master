---
id: 50-adapters/codex-bridge
title: codex-bridge — Adapter Contract
purpose: adapter-contract
audience:
  - orchestrator
also_needed_by:
  - truthsayer
  - evaluator
  - meta_review
status: stable
version: 2.10
last_reviewed: 2026-05-10
extracted_from:
  source: SYSTEM-BLUEPRINT-v2.10.md
  sections: ["§25 Bridge adapter — Codex specifics", "§25 Sandbox flags do not imply host-local service access (v2.10)", "../claude-codex-orchestration/BRIDGE_REQUIREMENTS.md (authoritative external)"]
  line_range_hint: "synthesis: §25 bridge subsection + v2.10 host_access subsection + BRIDGE_REQUIREMENTS protocol-1 MVP surface"
depends_on:
  - 00-overview/invariants.md
  - 50-adapters/capability-matrix.md
related:
  - 50-adapters/claude-native.md
  - 40-runtime/dispatch-shim.md
  - 40-runtime/bootstrap-and-degradation.md
max_lines: 160
directives:
  must_count: 7
  should_count: 4
  may_count: 1
---

## codex-bridge — Adapter Contract

### Identity

| Field | Value |
|---|---|
| `kind` | `cli-bridge` |
| `binary_path` | `../claude-codex-orchestration/codex_scaffold/bin/codex-task-bridge` |
| `bootstrap_probe.version_command` | `["version"]` |
| `bootstrap_probe.capabilities_command` | `["capabilities", "--json"]` |
| `bootstrap_probe.timeout_seconds` | 2 |
| `fallback_protocol` | 1 (MVP — assumed when probe fails) |
| `artifact_dir_root` | `../claude-codex-orchestration/codex_scaffold/runtime/codex-jobs/` |

The codex-bridge adapter wraps the `codex-task-bridge` CLI. It is the first non-Claude adapter and the steady-state cross-family Evaluator + TruthSayer pairing for projects whose Executor is Claude.

**Ownership (Model C, 2026-05-10).** This file is the *adapter slot* — the contract every codex-bridge implementation must satisfy. The *canonical implementation* of the slot lives in the sibling project `claude-codex-orchestration` (binary at `binary_path` above). That project owns: the `codex-task-bridge` CLI, the protocol-versioning + capability-discovery contract (`BRIDGE_REQUIREMENTS.md` — authoritative external spec for the wire format), and the six Claude-Code slash commands (`/codex-design`, `/codex-implement`, `/codex-review`, `/codex-status`, `/codex-result`, `/codex-list`) that target the bridge. KB-Orchestrator-Core owns: the role abstraction, the §25 dispatch shim, the verification ledger, and INV 9 / INV 10. Adopters wiring Codex into a KB-Orchestrator-Core deployment SHOULD start at `adoption-guides/codex-bridge-adapter.md`.

### Probe response

Per BRIDGE_REQUIREMENTS bootstrap rule: probe `version` first; non-zero exit → treat as protocol 1. Protocol ≥ 2 → call `capabilities --json` for the supported surface. The orchestrator does NOT call non-MVP bridge subcommands (`--mode review`, `raw`, `--output-schema`, `--json-events`) unless the probe confirms them.

```yaml
# MVP (protocol 1) — current
available: true
protocol: 1
capabilities: ["start", "run", "status", "tail", "result", "list", "help"]
enforces_pre_action_facts: orchestrator-side    # bridge has no in-process callback
host_access:
  loopback_tcp: false                           # Stage-4 evidence — see below
  unix_sockets: false
pre_action_fact_mechanism: orchestrator-emitted-block
cached_protocol_probe:
  protocol: 1
  probed_at: 2026-05-04
  notes: "version subcommand not implemented; capabilities --json not yet shipped"
```

### Dispatch contract

| Sub-mode | Default sandbox | Used for |
|---|---|---|
| `--mode design` | `read-only` | `truthsayer`, `evaluator` (research projects) |
| `--mode implement` | `workspace-write` + `--full-auto` | `executor.research` cross-family experiments |
| `--mode review` | `read-only` (preferred for `evaluator`) | **planned** — protocol ≥ 2 only |
| `raw` | mode default | **planned** — protocol ≥ 2 only |

Sandbox precedence per BRIDGE_REQUIREMENTS: explicit `--sandbox <value>` > `--full-auto` > mode default. Slash commands SHOULD always pass `--sandbox` explicitly; relying on the mode default is a slash-command bug, not a bridge feature.

Argument mapping:

| Field | Behaviour |
|---|---|
| `role` | Mapped to a bridge sub-mode + sandbox per the matrix above |
| `prompt` | Written to a temp file, passed via `--prompt-file=<path>` |
| `sandbox` | Passed verbatim as `--sandbox <value>` |
| `model` | Passed via `--model <id>` (currently `gpt-5.4` default) |
| `inputs[]` | File paths in the prompt; bridge reads them via Codex's filesystem access |
| `expected_schema` | Validated client-side by `_delegate.md` Step 8 (no bridge `--output-schema` in MVP) |

### Result contract

Per BRIDGE_REQUIREMENTS job-artifact contract — files under `<job_dir>/`:

| File | Purpose |
|---|---|
| `prompt.txt` | The prompt as sent |
| `meta.env` | `protocol`, `bridge_subcommand`, `mode`, `model`, `started_at`, `finished_at`, `exit_code` (ISO-8601 timestamps) |
| `status` | `running` / `succeeded` / `failed` |
| `pid` | Backgrounded jobs only |
| `exit_code`, `finished_at` | When terminal |
| `stdout.log`, `stderr.log` | Captured streams |
| `last_message.txt` | Final agent message — **the orchestrator's CONSUME source** |
| `events.jsonl` | Iff `--json-events` set (planned, protocol ≥ 2) |
| `output.json` | Iff `--output-schema` set (planned, protocol ≥ 2) |

Artifact file names are part of the public contract; the bridge MUST NOT rename them within a protocol version. The orchestrator computes `output_hash = sha256(last_message.txt)` for the consume ledger row's AUTH gate.

### Sandbox semantics

Per BRIDGE_REQUIREMENTS: `read-only`, `workspace-write`, `workspace-write --full-auto`, `danger-full-access` are the four values Codex itself accepts. The bridge does NOT refuse a sandbox value Codex accepts. Sandbox controls filesystem and approval-mode behaviour ONLY — see host_access section below.

### Failure modes

- **Bridge binary not on PATH** → probe fails → adapter `available: false` → orchestrator routes role inline (or escalates if no inline fallback).
- **Bridge protocol < required for sub-mode** (e.g. role wants `--mode review` but probe says protocol 1) → degrade per BRIDGE bootstrap rules: try `raw -- <equivalent codex exec args>`; if also unavailable, fall back to inline.
- **`<job_dir>/exit_code != 0`** → consume verdict `rejected-auth`; re-delegate up to `validation.re_delegate_max_attempts`.
- **`last_message.txt` missing or empty** → consume verdict `rejected-auth`; re-delegate.
- **Sandbox boundary error** (e.g. bridge invoked from one CWD, target path outside that scope): observed in v3.0 Phase 2 once; recovered by re-invoking with absolute paths from KB-Orchestrator-Core CWD.

### Pre-action fact enforcement (Invariant 10)

`enforces_pre_action_facts: orchestrator-side`. The bridge has no in-process pre-tool callback. The orchestrator (claude-main) emits the §25-mandated 4-fact block as user-visible text immediately before each `codex-task-bridge run|start` invocation. This is the v2.9 PROPAGATION mechanism for adapters that cannot self-enforce.

The orchestrator-emitted-block enforcement is **permanent for this adapter slot**. Per `../claude-codex-orchestration/BRIDGE_REQUIREMENTS.md` § Non-goals, the bridge by design does NOT impose orchestration policy — no future protocol-2 in-process callback is planned. Adopters MUST treat orchestrator-side enforcement as the steady-state mechanism, not a temporary stopgap.

### Host-local service access (v2.10)

`host_access: {loopback_tcp: false, unix_sockets: false}`. **Stage-4 evidence**: a `--mode implement` Codex job launched specifically to run `psql` reported the database cluster as unavailable, despite holding `workspace-write` and `--full-auto`. The bridge correctly applied the sandbox; the failure was orchestrator-side mis-modeling. Until bridge protocol exposes `capabilities --json` with explicit `host_access`, deny-deny is the conservative default.

**Degradation pattern**: when a role needs host-local services, the orchestrator (`claude-orchestrator`, which has full host access) runs the host call itself and pre-injects the result into the dispatch as read-only evidence. This is documented in `40-runtime/bootstrap-and-degradation.md`.

### What this adapter MUST NOT do

- MUST NOT be assigned to `roles.orchestrator`.
- MUST NOT be assigned to `executor.commercial` or `evaluator` (commercial project) until `host_access` is true/true.
- MUST NOT call non-MVP bridge subcommands (`--mode review`, `raw`, `--output-schema`, `--json-events`) when the probe says protocol 1.
- MUST NOT pass `--sandbox` values the bridge has not advertised in `capabilities`.
- MUST NOT silently rename or omit artifact files under `<job_dir>/`.
- MUST NOT swallow Codex's stderr — record to consume ledger row's `notes:` field.
- MUST NOT bypass the orchestrator-emitted fact block before each dispatch (Invariant 10).

### Cross-references

- Authoritative bridge contract (sibling project, canonical implementation): `../claude-codex-orchestration/BRIDGE_REQUIREMENTS.md`
- Adopter wiring guide: `adoption-guides/codex-bridge-adapter.md`
- Capability matrix: `50-adapters/capability-matrix.md`
- v2.10 host-access degradation: `40-runtime/bootstrap-and-degradation.md`

---
