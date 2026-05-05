---
description: TruthSayer audits the current spec — produces iterations/current/audit-report.md
argument-hint: (no arguments — reads iterations/current/spec.md)
---

# /audit — TruthSayer

Composes `/_delegate` with `role=truthsayer`. Role contract: `20-roles/truthsayer.md`. Bundle: `bundles/truthsayer.yaml`. Output: `iterations/current/audit-report.md` per `60-schemas/audit-report.md`.

Per **Invariant 2**, the TruthSayer's mandate is to find what is wrong, weak, or missing — not to praise. A run that returns APPROVED with zero Critical Issues and zero Overconfidence Flags on a spec containing unverified assumptions is malfunctioning.

## Preconditions

- `PROGRESS.md.pipeline_state` MUST be `planned` (post-Planner) OR `audit-revise-cycle-1` (re-audit after Planner re-plan).
- `iterations/current/spec.md` MUST exist (Planner output).
- `audit_cycle_current` MUST be < `policy.audit_cycle_max` (default 2).

## Dispatch

```
/_delegate
  role: truthsayer
  inputs:
    - iterations/current/spec.md
    - knowledge/methodology/rules.md
    - knowledge/methodology/hypotheses.md
    - knowledge/gaps/knowledge.md
    - decisions/
    - wiki/synthesis/contradictions/
  expected_schema: audit-report
  iter_id: <current>
```

Default adapter: `codex-bridge` mode=design (cross-family adversarial separation from a Claude-family Planner). Sandbox: `read-only`.

## Routing

Verdict from `audit-report.md`:
- **APPROVED** → orchestrator advances `pipeline_state: audited` → run `/pre-check`.
- **REVISE** → orchestrator routes back to `/plan` with audit-report.md as feedback; `audit_cycle_current += 1`. Cycle 2 REVISE → orchestrator escalates.
- **ESCALATE** → orchestrator writes `escalation.md` reason `audit-escalate-immediate`; pipeline halts.

## Next command

After APPROVED → `/pre-check`.

---
