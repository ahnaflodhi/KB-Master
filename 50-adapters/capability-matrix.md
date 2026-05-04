---
id: 50-adapters/capability-matrix
title: Adapter Capability Matrix
purpose: adapter-contract
audience:
  - orchestrator
also_needed_by:
  - planner
  - executor
  - evaluator
  - meta_review
  - apply_meta
status: stable
version: 2.10
last_reviewed: 2026-05-04
extracted_from:
  source: SYSTEM-BLUEPRINT-v2.10.md
  sections: ["§25 Adapter contract", "§25 Bridge adapter — Codex specifics", "§25 Sandbox flags do not imply host-local service access (v2.10)"]
  line_range_hint: "synthesis: §25 5-operation interface + per-adapter probe rows + v2.10 host_access denials"
depends_on:
  - 00-overview/invariants.md
related:
  - 50-adapters/claude-orchestrator.md
  - 50-adapters/claude-native.md
  - 50-adapters/codex-bridge.md
  - 40-runtime/dispatch-shim.md
max_lines: 150
directives:
  must_count: 3
  should_count: 2
  may_count: 1
---

## Adapter Capability Matrix

This is the at-a-glance grid the orchestrator consults at §25 Step 2 PROBE and Step 4 DISPATCH. Per-adapter files (`claude-orchestrator.md`, `claude-native.md`, `codex-bridge.md`) hold the rationale behind each cell. `agents.config.yaml` is the runtime source of truth — this matrix is descriptive and may lag a config edit by one commit.

### Identity + invocation

| Adapter | `kind` | Sub-modes | `binary_path` / protocol | Probe command |
|---|---|---|---|---|
| `claude-orchestrator` | `native-orchestrator` | (none — singleton) | the running Claude Code session | n/a — assumed available |
| `claude-native` | `claude-native` | `subagent`, `sdk` | Task tool (subagent) or `@anthropic-ai/claude-agent-sdk` on PATH (sdk) | capability check via SDK presence |
| `codex-bridge` | `cli-bridge` | `design`, `implement`, (planned: `review`, `raw`) | `../claude-codex-orchestration/codex_scaffold/bin/codex-task-bridge` | `version` first, then `capabilities --json` if protocol ≥ 2 |

### Probe response (§25 + v2.9 + v2.10)

| Adapter | `available` | `protocol` | `enforces_pre_action_facts` | `host_access.loopback_tcp` | `host_access.unix_sockets` |
|---|---|---|---|---|---|
| `claude-orchestrator` | true | n/a | true (gateguard skill) | true | true |
| `claude-native` (subagent) | true | n/a | true (inherited from parent harness) | true | true |
| `claude-native` (sdk) | iff SDK present | n/a | true (REQUIRES per-process pre-tool guard registration) | true | true |
| `codex-bridge` (MVP) | true (probed inline) | 1 | `orchestrator-side` (orchestrator emits fact block per dispatch) | **false** | **false** |
| `codex-bridge` (≥ 2) | true | 2+ | per `capabilities --json` | per `capabilities --json` | per `capabilities --json` |

Default-deny: missing/partial `host_access` subfields are treated as `false` per `policy.assume_host_access_false_unless_probed: true`.

### Dispatch contract (§25 Step 4)

Every adapter accepts `(role, prompt, sandbox, model, inputs[], expected_schema)` and returns a unique `job_id` (string). Sandbox precedence per BRIDGE_REQUIREMENTS: explicit `--sandbox` > `--full-auto` > mode default.

| Adapter | Sync / async | Sandbox values accepted | Default sandbox if omitted |
|---|---|---|---|
| `claude-orchestrator` | inline (synchronous) | host shell only | host shell |
| `claude-native` (subagent) | sync | inherits parent | parent's |
| `claude-native` (sdk) | async (job) | per SDK config | `read-only` |
| `codex-bridge` | sync (`run`) or async (`start`) | `read-only`, `workspace-write`, `workspace-write --full-auto`, `danger-full-access` | mode default (`design` → read-only, `implement` → workspace-write + full-auto) |

### Result + cancel

| Adapter | `last_message` location | Cancel supported |
|---|---|---|
| `claude-orchestrator` | inline (Claude Code response stream) | n/a |
| `claude-native` (subagent) | Task tool return value | best-effort (subagent halt) |
| `claude-native` (sdk) | SDK response object | best-effort per SDK |
| `codex-bridge` | `<job_dir>/last_message.txt` | yes (kill PID per `<job_dir>/pid`) |

### Role assignment denials (v2.10)

The orchestrator MUST refuse to bind a role to an adapter that does not satisfy its capability needs:

| Role | Required capability | Denied adapters today |
|---|---|---|
| `orchestrator` | singleton, host shell, `enforces_pre_action_facts: true`, `host_access: true/true` | everything except `claude-orchestrator` (Inv 9) |
| `executor.commercial` | `host_access: {loopback_tcp: true, unix_sockets: true}` for live DB / app-server probes | `codex-bridge` (false/false until bridge protocol exposes the field) |
| `evaluator` (commercial project) | `host_access: true/true` to re-run live test suites (Inv 7) | `codex-bridge` (false/false until bridge protocol exposes the field) |
| `kb_linter` (citation-health Rule #9 against host docs) | `host_access.loopback_tcp: true` if docs are local-served | adapters lacking the capability |
| any state-mutating role | `enforces_pre_action_facts: true` (or `orchestrator-side`) | adapters reporting `false` |

Read-only roles (planner, truthsayer, pre-check, evaluator-research, wiki_query, meta_review) have no host_access requirement and can be bound to any adapter that reports `available: true`.

### What the matrix does NOT decide

- Which adapter is *preferred* for a role — that is `agents.config.yaml` `roles:` (the bindings).
- Which model the adapter should pass to the runtime — that is per-agent (`agents.<agent>.model`).
- Whether cross-family adversarial pairing is satisfied — that is `policy.warn_if_eval_and_executor_same_model_family` (warning, not enforcement).

The matrix decides only: *can this adapter legally fulfil this role given its probed capabilities?* Yes/no.

---
