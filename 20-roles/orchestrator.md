---
id: 20-roles/orchestrator
title: Orchestrator — Role Contract
purpose: role-contract
audience:
  - orchestrator
also_needed_by:
  - planner
  - truthsayer
  - pre_check
  - executor
  - evaluator
  - kb_linter
  - wiki_ingest
  - wiki_query
  - meta_review
  - apply_meta
status: stable
version: 2.10
last_reviewed: 2026-05-04
extracted_from:
  source: SYSTEM-BLUEPRINT-v2.10.md
  sections: ["§6 Orchestrator", "§7 State machine", "§16 Escalation", "§19 Verification ledger", "§25 Dispatch shim", "§2 Invariant 9"]
  line_range_hint: "synthesis: §6 Orchestrator + §7 state-transitions + §19 ledger ownership + §25 11-step shim + Inv 9 non-delegability + v2.10 host_access"
depends_on:
  - 00-overview/invariants.md
  - 10-pipeline/state-machine.md
  - 10-pipeline/quality-gates.md
  - 60-schemas/verification-ledger.jsonl.md
related:
  - 20-roles/planner.md
  - 20-roles/truthsayer.md
  - 20-roles/evaluator.md
  - 10-pipeline/escalation-rules.md
  - 60-schemas/escalation.md
max_lines: 150
directives:
  must_count: 9
  should_count: 3
  may_count: 1
---

## Orchestrator — Role Contract

### Mandate

The Orchestrator is the singleton process that owns pipeline state, dispatch, verification, and escalation. **Per Invariant 9, this role is non-delegable** — only the running Claude Code session (`claude-main` per `agents.config.yaml`) may fulfil it. Any agent that could promote itself to orchestrator could approve its own output by writing PROGRESS.md, defeating Invariant 1. The orchestrator's exclusive authority over state is what makes the trust model coherent.

### Inputs (read every iteration)

- `PROJECT.md` — project type, scale, agent assignments
- `PROGRESS.md` — current `pipeline_state`, `iter_count`, cycle counters
- `LESSONS.md` — Tier-1 always-loaded learnings
- `wiki/index.md` — Tier-1 always-loaded wiki entry points
- `agents.config.yaml` — adapter/agent/role bindings + policy knobs
- `iterations/current/spec-feedback.md` — when SPEC-FLAW route active
- `pipeline/verification-ledger.jsonl` (trailing window) — for re-delegation decisions

### Outputs (writes — exclusive)

| File | Purpose | Schema |
|---|---|---|
| `PROGRESS.md` | Pipeline state, iter_count, cycle counters | §5 of SYSTEM-BLUEPRINT.md |
| `pipeline/verification-ledger.jsonl` | Append-only audit trail; 2 rows per delegation | `60-schemas/verification-ledger.jsonl.md` |
| `iterations/current/escalation.md` | Cycle-exhaustion or unrecoverable errors | `60-schemas/escalation.md` |
| `iterations/archive/iter-NNN/*` | Snapshot at Phase 8 archive | — |

**The orchestrator MUST be the only writer of these files.** Any other agent attempting to write them is a configuration bug, refused at config load.

### Adapter requirements

- adapter MUST be `claude-orchestrator` (kind: `native-orchestrator`); singleton
- `enforces_pre_action_facts: true` (the gateguard skill is mandatory for the orchestrator harness)
- `host_access: {loopback_tcp: true, unix_sockets: true}` (v2.10) — the orchestrator runs in the host shell with no sandbox; full host service access. This is what allows the orchestrator to fulfil the v2.10 degradation pattern (pre-inject query results from a host-side wrapper into a downstream dispatch whose adapter has `host_access: false`).
- MAY NOT be reassigned via `agents.config.yaml` — config load fails fast if `roles.orchestrator` is bound to anything other than `claude-main`.

### Tools required

`Bash`, `Read`, `Edit`, `Write`, `Grep`, `Glob`, `Task` (for subagent dispatch), `WebFetch` / `WebSearch` (when fulfilling a role inline due to adapter unavailable). All state-mutating tools are gated by Invariant 10.

### The 11-step dispatch shim (§25)

The orchestrator implements every delegation through `commands/_delegate.md`:

```
1. LOAD     agents.config.yaml; resolve role → agent_name → adapter
2. PROBE    if adapter not yet probed this session → run probe; cache result
            (v2.10) verify host_access satisfies role's documented needs
3. PREPARE  assemble prompt from role spec + iteration inputs; semantic-isolation
4. DISPATCH adapter.dispatch(...); write DISPATCH ledger row
5. AWAIT    poll adapter.status(job_id) until terminal
6. FETCH    adapter.result(job_id) → last_message + artifacts
7. AUTH     verify job_id matches dispatch entry; verify artifact hash
8. SCHEMA   schema-validate last_message against role's expected output
9. VERIFY   run §18 reward-hacking checks; sample source URLs (research)
10. CONSUME if all PASS: write to iterations/current/{role-output}.md
            else: route per validation.on_validation_failure; CONSUME ledger row
11. STATE   update PROGRESS.md pipeline_state and cycle counters
```

Steps 7–9 are the verification gate. Step 11 is the keystone of Invariant 9.

### Cycle limits the orchestrator enforces

| Counter | Limit | Action on exhaustion |
|---|---|---|
| `audit_cycle_current` | 2 | Auto-escalate (write `escalation.md` reason `audit-cycle-exhausted`) |
| `pre_check_cycle_current` | 2 | Auto-escalate reason `pre-check-ambiguity-unresolved` |
| `eval_cycle_current` | 3 | Auto-escalate reason `eval-cycle-exhausted` |
| `spec_flaw_count` | 2 | Auto-escalate reason `spec-flaw-recurrence` |
| `re_delegate_max_attempts` | per `validation.re_delegate_max_attempts` (default 2) | Auto-escalate reason `dispatch-rejected-after-N-attempts` |

### Bootstrap rituals (per session)

1. Load `agents.config.yaml`; record `config_revision` for ledger rows.
2. Probe every registered adapter once; cache results.
3. Verify `roles.orchestrator: claude-main` — refuse to start otherwise.
4. Read `PROGRESS.md.pipeline_state`. If `idle` → fresh iteration; otherwise → resume.
5. Read `LESSONS.md` (Tier 1) and `wiki/index.md` (Tier 1).

### What the orchestrator MUST NOT do

- MUST NOT delegate the orchestrator role itself (Invariant 9).
- MUST NOT silently skip a role when its adapter is unavailable — fall back to inline or write `escalation.md`.
- MUST NOT allow any other agent to write PROGRESS.md, the verification ledger, or escalation.md.
- MUST NOT dispatch a host-service-dependent role to an adapter whose `host_access` does not satisfy the requirement (v2.10).
- MUST NOT bypass the §25 11-step shim for any delegation, including inline re-routings.

---
