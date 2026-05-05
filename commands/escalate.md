---
description: Write iterations/current/escalation.md to halt the pipeline (orchestrator-inline)
argument-hint: <reason-code> [<free-text context>]
---

# /escalate — Escalation (orchestrator-inline)

Writes `iterations/current/escalation.md` per `60-schemas/escalation.md` and stops the pipeline. Per **Invariant 9**, only the orchestrator (`claude-main`) writes escalation.md. This command is dispatched to `claude-orchestrator` adapter inline, never delegated.

## When to use

- **User-initiated**: when the user wants to halt mid-iteration with a documented reason.
- **Orchestrator-internal**: automatic — triggered when:
  - `audit_cycle_current >= policy.audit_cycle_max` (default 2) AND TruthSayer returned REVISE
  - `pre_check_cycle_current >= policy.pre_check_ambiguity_round_max` (default 2) AND ambiguities still flagged
  - `eval_cycle_current >= policy.eval_cycle_max` (default 3) AND Evaluator returned FAIL
  - `spec_flaw_count >= policy.spec_flaw_count_escalation_threshold` (default 2)
  - Adapter probe failure with no fallback path
  - v2.10 host_access required + adapter denies + `policy.on_host_access_missing_for_required_role: escalate`

## Dispatch (no delegation — inline)

```
/_delegate
  role: orchestrator                 # orchestrator-inline; refused if dispatched elsewhere (Inv 9)
  inputs:
    - PROGRESS.md
    - iterations/current/<relevant-files>
  expected_schema: escalation
  iter_id: <current>
```

Adapter: `claude-orchestrator` (host shell, full host_access, gateguard). The `/_delegate` shim's Step-1 LOAD will refuse any other adapter binding for this role (Invariant 9 — orchestrator non-delegable).

## Output schema (`60-schemas/escalation.md`)

Required fields:
- `Reason:` enum — one of `audit-cycle-exhausted`, `pre-check-ambiguity-unresolved`, `eval-cycle-exhausted`, `spec-flaw-recurrence`, `dispatch-rejected-after-N-attempts`, `agent-unavailable`, `host-access-required-but-not-advertised`, `inline-context-exhausted`, `user-initiated`, `audit-escalate-immediate`, `bundle-missing`, `config-schema-unsupported`, `role-unassigned`, `adapter-missing`, `delegation-validation-failed`
- `Context:` free-form description of what triggered the escalation
- `Recommended-Resolution:` free-form proposed next steps for the human
- `Triggered-By:` agent-id (typically `claude-main` for orchestrator-internal; user for user-initiated)
- `iter_id:`, `pipeline_state_at_escalation:`, `cycle_counters_at_escalation:`

## Post-conditions

- `iterations/current/escalation.md` exists.
- `PROGRESS.md.pipeline_state` set to `escalated`.
- The pipeline halts. Next user action is human review + manual intervention OR `/apply-meta` if the resolution involves harness changes.
- A single audit row appended to `pipeline/verification-ledger.jsonl` recording the escalation event.

## What this command MUST NOT do

- MUST NOT be invoked under any non-orchestrator role.
- MUST NOT auto-resume the pipeline — escalation requires human decision.
- MUST NOT delete `iterations/current/escalation.md` once written; resolution either creates a new iteration or fixes the underlying cause and re-runs from the appropriate phase.

---
