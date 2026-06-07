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
version: 3.0
last_reviewed: 2026-06-07
extracted_from:
  source: SYSTEM-BLUEPRINT-v2.10.md
  sections: ["§25 Bridge adapter — Codex specifics", "§25 Sandbox flags do not imply host-local service access (v2.10)", "../claude-codex-orchestration/BRIDGE_REQUIREMENTS.md (authoritative external; protocol-3 sub-agent + persistent-agent surface is the current authoritative-external slice)"]
  line_range_hint: "synthesis: §25 bridge subsection + v2.10 host_access subsection + BRIDGE_REQUIREMENTS protocol-3 surface (sub-agents + persistent agents)"
depends_on:
  - 00-overview/invariants.md
  - 50-adapters/capability-matrix.md
related:
  - 50-adapters/claude-native.md
  - 40-runtime/dispatch-shim.md
  - 40-runtime/bootstrap-and-degradation.md
max_lines: 210
directives:
  must_count: 9
  should_count: 3
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
| `agent_storage_root` | `../claude-codex-orchestration/codex_scaffold/runtime/codex-agents/` |

The codex-bridge adapter wraps the `codex-task-bridge` CLI. It is the first non-Claude adapter and the steady-state cross-family Evaluator + TruthSayer pairing for projects whose Executor is Claude.

**Ownership (Model C, 2026-05-10).** This file is the *adapter slot* — the contract every codex-bridge implementation must satisfy. The *canonical implementation* of the slot lives in the sibling project `claude-codex-orchestration` (binary at `binary_path` above). That project owns: the `codex-task-bridge` CLI, the protocol-versioning + capability-discovery contract (`BRIDGE_REQUIREMENTS.md` — authoritative external spec for the wire format), and the six Claude-Code slash commands (`/codex-design`, `/codex-implement`, `/codex-review`, `/codex-status`, `/codex-result`, `/codex-list`) that target the bridge. KB-Orchestrator-Core owns: the role abstraction, the §25 dispatch shim, the verification ledger, and INV 9 / INV 10. Adopters wiring Codex into a KB-Orchestrator-Core deployment SHOULD start at `adoption-guides/codex-bridge-adapter.md`.

### Probe response

Per BRIDGE_REQUIREMENTS bootstrap rule: probe `version` first; non-zero exit → treat as protocol 1. Protocol ≥ 2 → call `capabilities --json` for the supported surface. The orchestrator does NOT call non-shipped bridge surface (`--mode review`, `raw`, `resume`, `--json-events`, `--sandbox`/`--full-auto` first-class passthrough) unless the probe confirms them.

```yaml
# Protocol 3 — current (canonical bridge at ../claude-codex-orchestration/codex_scaffold/bin/codex-task-bridge)
available: true
protocol: 3
capabilities: ["run", "start", "subagent", "agent", "status", "tail", "result", "list", "version", "capabilities"]
subagent_actions: ["run"]
agent_actions: ["create", "run", "remember", "list", "show"]
agent_storage: runtime/codex-agents
passthroughs_advertised: ["--model", "--output-schema"]    # --sandbox still NOT advertised
modes_advertised: ["design", "implement"]
enforces_pre_action_facts: orchestrator-side    # bridge has no in-process callback
host_access:
  loopback_tcp: false                           # Stage-4 evidence — see below; UNCHANGED at protocol 3
  unix_sockets: false
pre_action_fact_mechanism: orchestrator-emitted-block
cached_protocol_probe:
  protocol: 3
  probed_at: 2026-06-07
  notes: "protocol 3 shipped 2026-06-07: subagent run + agent create/run/remember/list/show; per-agent state under runtime/codex-agents/<name>/; meta.env adds agent_name + subagent_kind. Still planned: --mode review, raw, resume, --json-events, --sandbox first-class, codex_exec_failure error-prefix slice."
```

### Dispatch contract

| Sub-mode | Default sandbox | Used for |
|---|---|---|
| `--mode design` | `read-only` | `truthsayer`, `evaluator` (research projects) |
| `--mode implement` | `workspace-write` + `--full-auto` | `executor.research` cross-family experiments |
| `--mode review` | `read-only` (preferred for `evaluator`) | **planned** — protocol ≥ 2 only |
| `raw` | mode default | **planned** — protocol ≥ 2 only |
| `subagent run` | mode default (design→read-only, implement→workspace-write+full-auto) | one-off cross-family sub-agent jobs (e.g. a scoped audit/research delegate) |
| `agent run` | mode default (as above) | persistent named profile invoked as a tracked job (durable system-prompt + memory + knowledge-roots) |

Sandbox is selected by `--mode` (design→`read-only`, implement→`workspace-write --full-auto`). The bridge does **not** accept a first-class `--sandbox` passthrough — it is not in advertised `passthroughs`, and `--sandbox` first-class remains **planned**. Until it ships, the `--mode` mapping is the only sandbox control; sub-agent and persistent-agent dispatches inherit the same mode→sandbox semantics.

Argument mapping:

| Field | Behaviour |
|---|---|
| `role` | Mapped to a bridge sub-mode + sandbox per the matrix above |
| `prompt` | Passed as positional args after `--` (e.g. `run --mode design -- "<prompt>"`), or via stdin. There is **no** `--prompt-file` flag. |
| `sandbox` | Selected by `--mode` (NOT passed as `--sandbox` — not an advertised passthrough). First-class `--sandbox` is planned; until then the mode mapping is the only control. |
| `model` | Passed via `--model <id>` (currently `gpt-5.4` default) |
| `inputs[]` | File paths in the prompt; bridge reads them via Codex's filesystem access |
| `expected_schema` | Schema validation is client/orchestrator-side (`_delegate.md` Step 8). Bridge `--output-schema FILE` passthrough shipped 2026-05-12 (protocol 2): when set, the bridge forwards the schema file to Codex and copies `last_message.txt` to `<job_dir>/output.json`. The bridge does NOT validate JSON or schema conformance — `output.json` presence means the directive was forwarded and a final message captured, not that the artifact is valid. Consumers must validate before use. |
| `agent_name` / `subagent_kind` | Recorded in `meta.env` and surfaced by `status` (empty for ordinary `run`/`start` jobs). `--kind` labels a sub-agent/profile (`development`, `audit`, `research`, `web-research`, `persona`, …); persistent-agent profile fields (`--system-prompt[-file]`, `--knowledge-root`, `--description`) are set at `agent create` time. |

### Result contract

Per BRIDGE_REQUIREMENTS job-artifact contract — files under `<job_dir>/`:

| File | Purpose |
|---|---|
| `prompt.txt` | The prompt as sent |
| `meta.env` | `protocol` (now stamps `3`), `bridge_subcommand`, `mode`, `model`, `started_at`, `finished_at`, `exit_code` (ISO-8601 timestamps), plus `agent_name` + `subagent_kind` (empty for ordinary `run`/`start` jobs) |
| `status` | `running` / `succeeded` / `failed` |
| `pid` | Backgrounded jobs only |
| `exit_code`, `finished_at` | When terminal |
| `stdout.log`, `stderr.log` | Captured streams |
| `last_message.txt` | Final agent message — **the orchestrator's CONSUME source** |
| `events.jsonl` | Iff `--json-events` set (planned, protocol ≥ 2) |
| `output.json` | Iff `--output-schema` set (shipped protocol 2, 2026-05-12); raw copy of `last_message.txt`, not bridge-validated for JSON or schema conformance |

Artifact file names are part of the public contract; the bridge MUST NOT rename them within a protocol version. The orchestrator computes `output_hash = sha256(last_message.txt)` for the consume ledger row's AUTH gate.

#### Persistent-agent state (protocol 3)

`agent create NAME` writes a persistent profile under `runtime/codex-agents/<name>/`:

| File | Purpose |
|---|---|
| `agent.env` | profile metadata (kind, mode, model, description) |
| `system_prompt.md` | the profile's injected system prompt |
| `memory.md` | project-local memory (`agent remember NAME -- "<text>"` appends) |
| `knowledge_roots.txt` | declared knowledge-root dirs |
| `sessions.jsonl` | one line per `agent run` invocation |
| `artifacts/` | per-run artifact outputs |

These six `agent_files` names are part of the public contract within protocol 3 — additive-only, never renamed. `agent run NAME` invokes the profile as a single tracked Codex job, injecting its system prompt + memory + knowledge roots into the directive.

### Sandbox semantics

Per BRIDGE_REQUIREMENTS: `read-only`, `workspace-write`, `workspace-write --full-auto`, `danger-full-access` are the four values Codex itself accepts. The bridge currently exposes only **two** of them, via the `--mode` mapping — `design` → `read-only` and `implement` → `workspace-write --full-auto`. The other values (`workspace-write` without full-auto, `danger-full-access`) are NOT reachable through the bridge until first-class `--sandbox` selection ships (planned). Sandbox controls filesystem and approval-mode behaviour ONLY — see host_access section below.

### Failure modes

- **Bridge binary not on PATH** → probe fails → adapter `available: false` → orchestrator routes role inline (or escalates if no inline fallback).
- **Bridge protocol < required for sub-mode** (e.g. role wants `--mode review` but probe says protocol 1, or a `subagent`/`agent` call against a protocol < 3 bridge) → degrade per BRIDGE bootstrap rules. Since `raw` is non-shipped (see § What this adapter MUST NOT do), do NOT route through `raw`: fall back to the contract-sanctioned degraded path — direct `codex exec` with the equivalent mode/args, recorded as `adapter_degraded` — or to orchestrator-inline if that too is unavailable.
- **`<job_dir>/exit_code != 0`** → consume verdict `rejected-auth`; re-delegate up to `validation.re_delegate_max_attempts`.
- **`last_message.txt` missing or empty** → consume verdict `rejected-auth`; re-delegate.
- **Sandbox boundary error** (e.g. bridge invoked from one CWD, target path outside that scope): observed in v3.0 Phase 2 once; recovered by re-invoking with absolute paths from KB-Orchestrator-Core CWD.

### Pre-action fact enforcement (Invariant 10)

`enforces_pre_action_facts: orchestrator-side`. The bridge has no in-process pre-tool callback. The orchestrator (claude-main) emits the §25-mandated 4-fact block as user-visible text immediately before each **Codex-invoking dispatch: `run`, `start`, `subagent run`, and `agent run`**. This is the v2.9 PROPAGATION mechanism for adapters that cannot self-enforce.

`agent create`, `agent remember`, `agent list`, `agent show`, `version`, `capabilities`, `status`, `tail`, `result`, `list` do **not** invoke `codex exec` and are therefore **not** INV-10 dispatch points. `create`/`remember` are local state mutations — record them in the execution log, not as a four-fact dispatch.

The orchestrator-emitted-block enforcement is **permanent for this adapter slot**. Per `../claude-codex-orchestration/BRIDGE_REQUIREMENTS.md` § Non-goals, the bridge by design does NOT impose orchestration policy — no future in-process callback is planned. Adopters MUST treat orchestrator-side enforcement as the steady-state mechanism, not a temporary stopgap.

### Host-local service access (v2.10)

`host_access: {loopback_tcp: false, unix_sockets: false}` — **unchanged at protocol 3** (the sub-agent/persistent-agent surface added no host capability; ephemeral and persistent agents inherit the same sandbox + host_access posture). **Stage-4 evidence**: a `--mode implement` Codex job launched specifically to run `psql` reported the database cluster as unavailable, despite holding `workspace-write` and `--full-auto`. The bridge correctly applied the sandbox; the failure was orchestrator-side mis-modeling. Until bridge protocol exposes `capabilities --json` with explicit `host_access`, deny-deny is the conservative default.

**Degradation pattern**: when a role needs host-local services, the orchestrator (`claude-orchestrator`, which has full host access) runs the host call itself and pre-injects the result into the dispatch as read-only evidence. This is documented in `40-runtime/bootstrap-and-degradation.md`.

### What this adapter MUST NOT do

- MUST NOT be assigned to `roles.orchestrator`.
- MUST NOT be assigned to `executor.commercial` or `evaluator` (commercial project) until `host_access` is true/true.
- MUST NOT call non-shipped bridge surface (`--mode review`, `raw`, `resume`, `--json-events`) regardless of protocol level, and MUST NOT call `subagent`/`agent` when the probe says protocol < 3.
- MUST NOT pass `--sandbox` values the bridge has not advertised in `capabilities`.
- MUST NOT treat a persistent agent as an autonomous/long-running process — each `agent run` is one tracked job, verified like any other.
- MUST NOT allow a delegated Codex job to create unmanaged bridge children; any executor-proposed fan-out MUST round-trip through the orchestrator (the bridge never accepts a call originating from inside a sandbox).
- MUST NOT silently rename or omit artifact files under `<job_dir>/`.
- MUST NOT swallow Codex's stderr — record to consume ledger row's `notes:` field.
- MUST NOT bypass the orchestrator-emitted fact block before each dispatch (Invariant 10).

### Cross-references

- Authoritative bridge contract (sibling project, canonical implementation): `../claude-codex-orchestration/BRIDGE_REQUIREMENTS.md`
- Adopter wiring guide: `adoption-guides/codex-bridge-adapter.md`
- Capability matrix: `50-adapters/capability-matrix.md`
- v2.10 host-access degradation: `40-runtime/bootstrap-and-degradation.md`

---
