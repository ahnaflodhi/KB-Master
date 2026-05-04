---
id: 40-runtime/bootstrap-and-degradation
title: Bootstrap and Graceful Degradation
purpose: runtime-spec
audience:
  - orchestrator
also_needed_by:
  - apply_meta
  - meta_review
  - executor
  - evaluator
status: stable
version: 2.10
last_reviewed: 2026-05-04
extracted_from:
  source: SYSTEM-BLUEPRINT-v2.10.md
  sections: ["§25 Bootstrap and graceful degradation", "§25 Sandbox flags do not imply host-local service access (v2.10)", "§24 Claude Code harness integration (startup ritual)"]
  line_range_hint: "synthesis: §25 bootstrap rituals + adapter probe failure handling + v2.10 host_access degradation pattern + §24 startup checklist"
depends_on:
  - 00-overview/invariants.md
  - 50-adapters/capability-matrix.md
  - 40-runtime/dispatch-shim.md
related:
  - 50-adapters/codex-bridge.md
  - 50-adapters/claude-orchestrator.md
  - 10-pipeline/escalation-rules.md
max_lines: 180
directives:
  must_count: 7
  should_count: 3
  may_count: 1
---

## Bootstrap and Graceful Degradation

The orchestrator's session-start bootstrap is what makes the architecture survive partial environments — adapters that are not installed, bridge protocols below required versions, host-access denials, missing `agents.config.yaml` knobs. This file documents the bootstrap sequence and the documented degradation paths.

Failures are **downgrades, not crashes**. Per §24 the orchestrator never silently skips a role: it falls back to the next available adapter, or fulfils the role inline, or escalates with an `escalation.md` entry stating exactly which capability was missing.

### Session-start bootstrap

```
1. LOAD agents.config.yaml
   - Verify schema_version is supported (refuse to load on forward-incompat)
   - Cache config_revision (recorded in every ledger row this session)

2. PROBE every registered adapter (§24-style cached probe)
   - Run probe with timeout per adapter's bootstrap_probe.timeout_seconds
   - Record probe response (capabilities, protocol, host_access, enforces_pre_action_facts)
   - Mark unavailable adapters; log warning to iterations/current/execution-log.md

3. VERIFY orchestrator binding
   - Refuse to start if roles.orchestrator != claude-main (Invariant 9)

4. VERIFY policy compliance
   - For every state-mutating role, check the bound adapter reports
     enforces_pre_action_facts: true|orchestrator-side (Invariant 10)
   - For every host-service-dependent role (per policy.host_local_service_dependent_roles),
     check the bound adapter advertises the required host_access subfield (v2.10)
   - Refuse to dispatch a violating role; suggest reassignment

5. READ runtime state
   - PROGRESS.md → pipeline_state, iter_count, cycle counters
   - LESSONS.md → Tier-1 always-loaded learnings
   - wiki/index.md → Tier-1 wiki entry points

6. CACHE probe results for the session
   - Re-probe trigger: explicit /reload-agents OR agents.config.yaml mtime change
```

Probe results are cached for the session. Re-probe is triggered by an explicit `/reload-agents` command or by `agents.config.yaml` mtime change.

### Adapter-probe failure paths

| Failure | Action |
|---|---|
| Adapter binary missing (e.g. `codex-task-bridge` not on PATH) | Mark adapter `available: false`. Any agent bound to it is unavailable. Roles assigned to those agents reroute to the next adapter for the same role family, or fall back to inline (claude-main fulfils the role itself). Append warning to `execution-log.md`. |
| Bridge protocol < required for sub-mode | Per BRIDGE_REQUIREMENTS bootstrap rules: try `raw -- <equivalent codex exec args>`. If also unavailable, fall back to inline. |
| Adapter probe timeout exceeded | Treat as unavailable; same as binary-missing. Increase `bootstrap_probe.timeout_seconds` if the adapter is slow but reachable. |
| Adapter probe responds but reports `enforces_pre_action_facts: false` AND role is state-mutating | Refuse to bind; warn that the adapter can only fulfil read-only roles. Reroute or escalate. |
| Adapter probe responds but `host_access` subfield required by role is `false` (v2.10) | Per `policy.on_host_access_missing_for_required_role`: `escalate` (default), `reroute` (try next adapter), or `inline` (orchestrator runs the host call itself, then re-dispatches with pre-injected results). |
| All adapters for a role family unavailable | Inline fallback per role's "fall back to orchestrator" clause. If even inline cannot fulfil it (e.g. capability gap), write `escalation.md` reason `agent-unavailable` and stop the pipeline. |

### v2.10 host-access degradation pattern

When a role requires host-local service access (per `policy.host_local_service_dependent_roles`) and the bound adapter has `host_access: {loopback_tcp: false, unix_sockets: false}`, the orchestrator has three documented options per `policy.on_host_access_missing_for_required_role`:

#### Option 1 — `escalate` (default, fail-loud)

Write `iterations/current/escalation.md` with reason `host-access-required-but-not-advertised` and stop the pipeline. Recommended when the role cannot meaningfully produce its output without live host access (e.g. an Evaluator running a test suite that hits a database).

#### Option 2 — `reroute` (try next adapter)

Iterate the role's adapter preference list (per `agents.config.yaml roles.<role>.fallback_adapters`) until one with the required `host_access` is found. If none, escalate.

#### Option 3 — `inline` (orchestrator host-side wrapper)

The orchestrator (`claude-orchestrator`, which has `host_access: true/true`) runs the host call itself outside the delegated job, captures the output, and re-dispatches the role with the captured output pre-injected as read-only evidence. Example: an Executor needs `psql` results to verify a migration; the orchestrator runs `psql -c '<query>' > /tmp/preinjected.txt`, then dispatches the Executor with `/tmp/preinjected.txt` in `inputs[]`.

```
[role=executor.commercial dispatched to codex-bridge (host_access: false/false)]
  └── orchestrator detects host_access mismatch
        └── option=inline:
              orchestrator runs `psql -c '<query>' > /tmp/preinjected.txt`
              orchestrator re-dispatches Executor with inputs:[/tmp/preinjected.txt]
              Codex job sees the file, completes its task, returns
        └── consume + ledger row record `host_access_degradation: orchestrator-inlined`
```

### What bootstrap does NOT do

- MUST NOT auto-install missing adapter binaries — adopters configure their own environment.
- MUST NOT silently re-bind a role to a different adapter without writing a warning to `execution-log.md`.
- MUST NOT proceed with `roles.orchestrator != claude-main` (Invariant 9).
- MUST NOT skip the `agents.config.yaml` policy-compliance check at step 4.
- MUST NOT cache probe results across sessions (probe runs once per session at start; re-probe only on explicit trigger).
- MUST NOT treat a bridge `version` non-zero exit as "bridge broken" — per BRIDGE_REQUIREMENTS, treat as protocol 1 and fall back accordingly.
- MUST NOT continue if step 4 detects a role bound to an adapter with `enforces_pre_action_facts: false` AND the role is state-mutating — refuse to start.

### Cross-references

- Per-adapter probe shapes: `50-adapters/capability-matrix.md`
- The 11-step shim this bootstrap precedes: `40-runtime/dispatch-shim.md`
- Escalation taxonomy: `10-pipeline/escalation-rules.md`
- v2.10 source-attributed: `../claude-codex-orchestration/BRIDGE_REQUIREMENTS.md` §"Local service / socket access"

---
