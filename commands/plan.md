---
description: Plan an iteration — produces iterations/current/spec.md
argument-hint: <topic or feedback file>
---

# /plan — Planner

Composes `/_delegate` with `role=planner`. Role contract: `20-roles/planner.md`. Bundle loaded at session start: `bundles/planner.yaml`. Output: `iterations/current/spec.md` per `60-schemas/spec.md`.

## Preconditions

- `PROGRESS.md.pipeline_state` MUST be `idle` (fresh iteration), OR a re-plan is active — signalled by `audit_cycle_current` ≥ 1 (re-plan after TruthSayer REVISE; max 2), `pre_check_cycle_current` ≥ 1 (re-plan after Pre-Check ambiguity; round 2 → ESCALATE), or `spec_flaw_count` ≥ 1 (re-plan after Evaluator SPEC-FLAW; ESCALATE at 2). Re-plan context lives in those counters, not a distinct `pipeline_state` value (`60-schemas/progress.md`).
- `PROJECT.md` MUST exist with `project_type` and `primary_objective`.
- If re-plan: `iterations/current/audit-report.md` (from TruthSayer) OR `iterations/current/spec-feedback.md` (from Evaluator) MUST exist as the input feedback.

## Dispatch

```
/_delegate
  role: planner
  inputs:
    - PROJECT.md
    - PROGRESS.md
    - LESSONS.md
    - wiki/index.md
    - iterations/current/audit-report.md   # if re-plan after REVISE
    - iterations/current/spec-feedback.md  # if re-plan after SPEC-FLAW
  expected_schema: spec
  iter_id: <current iter from PROGRESS.md>
```

The orchestrator (per `_delegate.md` Step 10 CONSUME) writes the validated spec.md to `iterations/current/spec.md`.

## Post-conditions

- `iterations/current/spec.md` exists with required sections per `60-schemas/spec.md`.
- `pipeline_state` advances to `planned`.
- If re-plan: `audit_cycle_current` was incremented at the prior STATE step; `/plan` itself does not increment.

## Critical sequencing (v2.5 fix)

The Planner does NOT write `contract.md` here. Contract is written in a SEPARATE `/plan` invocation only after `pipeline_state: pre-check-complete`. Writing contract.md in the same invocation as spec.md silently rebinds acceptance criteria — the v2.5 fix forbids this.

## Next command

After this returns `final_verdict: accepted` → run `/audit`.

---
