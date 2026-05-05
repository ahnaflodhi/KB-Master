---
description: Executor implements per the signed contract — produces wiki pages or code + execution-log.md
argument-hint: (no arguments — reads contract.md and acceptance-checklist.md)
---

# /execute — Executor (research / commercial)

Composes `/_delegate` with `role=executor.research` OR `role=executor.commercial` (resolved from `PROJECT.md.project_type`). Role contract: `20-roles/executor.md`. Bundles: `bundles/executor-research.yaml` or `bundles/executor-commercial.yaml`. Output: `iterations/current/execution-log.md` per `60-schemas/execution-log.md` + sub-type-specific artifacts.

## Preconditions

- `PROGRESS.md.pipeline_state` MUST be `contracted` (post-Planner contract write) OR `eval-fail-cycle-N` (re-execute after Evaluator FAIL, cycle ≤ 3).
- `iterations/current/{spec.md, audit-report.md, contract.md, acceptance-checklist.md}` MUST all exist.
- `eval_cycle_current` MUST be < `policy.eval_cycle_max` (default 3).

## Dispatch

```
/_delegate
  role: executor.<research|commercial>     # resolved from PROJECT.md
  inputs:
    - iterations/current/spec.md
    - iterations/current/audit-report.md
    - iterations/current/contract.md
    - iterations/current/acceptance-checklist.md
    - wiki/index.md
    - knowledge/methodology/rules.md
    - quality-criteria.json
  expected_schema: execution-log
  iter_id: <current>
```

Default adapter: `claude-native` (subagent for research, sdk for commercial). Sandbox: `workspace-write`.

## v2.10 host_access

`executor.commercial` requires `host_access: {loopback_tcp: true, unix_sockets: true}` (live DB inspection, container runtimes, app-server probes). The orchestrator's PROBE step (per `_delegate.md` Step 2) refuses dispatch to adapters with deny-deny — currently denies `codex-bridge` for this sub-role. Per `policy.on_host_access_missing_for_required_role`: `escalate` (default), `reroute` (try fallback adapter), or `inline` (orchestrator pre-injects host-side wrapper output).

## Within-execute discipline (auto-enforced by harness)

- **Inv 8**: every WebFetch/WebSearch result saved to `sources/research/iter-NNN/` BEFORE any claim is extracted.
- **Per-unit type-check (commercial 2a)**: `Per-unit type-check: PASSED|FAILED` line per unit in execution-log.md.
- **Multi-tenancy check (commercial 2b)**: `Multi-tenancy check: PASSED|FAILED` per unit.
- **Stub protocol**: blocked units → `# TODO: RESOLVE-STUB` placeholder + matching log entry. Undisclosed stubs are an automatic Reward-Hacking FLAG (G7).

## Routing

Output → `/evaluate`. The Evaluator is the gate; this command does not self-verify.

## Next command

After this returns `final_verdict: accepted` → run `/evaluate`.

---
