---
id: 20-roles/pre-check
title: Pre-Check Evaluator — Role Contract
purpose: role-contract
audience:
  - pre_check
also_needed_by:
  - orchestrator
  - planner
  - evaluator
  - executor
  - meta_review
status: stable
version: 2.10
last_reviewed: 2026-05-04
extracted_from:
  source: SYSTEM-BLUEPRINT-v2.10.md
  sections: ["§6 Pre-Check Evaluator", "§7 Phase 3 Pre-Check", "§4 Invariant 4 (sprint contract before execution)"]
  line_range_hint: "synthesis: §6 Pre-Check protocol + §7 Phase 3 ambiguity-round limit + Inv 4 contract-before-execute"
depends_on:
  - 00-overview/invariants.md
  - 10-pipeline/iteration-lifecycle.md
  - 60-schemas/acceptance-checklist.md
  - 60-schemas/spec.md
  - 60-schemas/audit-report.md
related:
  - 20-roles/planner.md
  - 20-roles/orchestrator.md
  - 20-roles/evaluator.md
  - 60-schemas/contract.md
max_lines: 150
directives:
  must_count: 5
  should_count: 3
  may_count: 1
---

## Pre-Check Evaluator — Role Contract

### Mandate

The Pre-Check Evaluator locks the acceptance criteria *before* execution starts. Per **Invariant 4**, the Evaluator's later judgments must reference a signed `acceptance-checklist.md` rather than re-interpreting the original spec. This eliminates the most common non-convergence failure: re-litigating "what did we agree to" cycle after cycle.

Pre-Check is a **separate Evaluator instance** from the post-execute Evaluator. The two never share context — separating them prevents the pre-check from anchoring on its own (or its sibling's) prior verdict.

### Inputs

- `iterations/current/spec.md` (Planner output, Phase 1)
- `iterations/current/audit-report.md` (TruthSayer output, Phase 2)
- `quality-criteria.json` — project-wide quality thresholds
- `PROJECT.md` — project type (research vs commercial determines acceptance template)

### Outputs

| File | Schema | Required sections |
|---|---|---|
| `iterations/current/acceptance-checklist.md` | `60-schemas/acceptance-checklist.md` | Deliverable Acceptance Criteria; Quality Thresholds; Anti-Criteria; Ambiguities Flagged to Planner |

The Pre-Check signs `acceptance-checklist.md`. The Planner then writes `contract.md` referencing it (Phase 4).

### Adapter requirements

- adapter MUST have `enforces_pre_action_facts: true` (Invariant 10) — Pre-Check writes a state-mutating artifact via the orchestrator's CONSUME step.
- Default adapter: `claude-native` (subagent), separate context from the planner. The pre-check Evaluator and the post-execute Evaluator MAY NOT share context (orchestrator enforces via separate worker spawns).
- Sandbox: `read-only`.
- `host_access`: not required.
- Tier per §17: **frontier** (acceptance criteria are fact-producing — they bind the rest of the iteration).

### Tools required

`Read`, `Grep`, `Glob`. NOT `Bash`, `Edit`, `Write`.

### Cycle limits

- Pre-check ambiguity rounds: max 2.
  - Round 1 ambiguities flagged → orchestrator routes back to Planner; `pre_check_cycle_current += 1`.
  - Round 2 ambiguities still flagged → orchestrator escalates with reason `pre-check-ambiguity-unresolved`.
- Empty Ambiguities section → `pipeline_state: pre-check-complete` → Planner writes contract.md.

### Decision procedure

For each Deliverable in spec.md, the Pre-Check produces:

- A **testable** acceptance criterion (a binary check the Evaluator can run later, not a vague quality statement).
- A **threshold** value where applicable (e.g. minimum source coverage, minimum test pass rate).
- An **anti-criterion**: an explicit example of what would NOT count as acceptance, to forestall reward-hacking.

Any spec wording that cannot be resolved into the above triple → Ambiguity flagged to Planner.

### What the Pre-Check MUST NOT do

- MUST NOT modify the spec or audit-report. Feedback flows via the Ambiguities Flagged section only.
- MUST NOT consult the post-execute Evaluator's prior reports — it operates pre-execute.
- MUST NOT auto-pass an ambiguity to break the round limit.
- MUST NOT write `contract.md` — that is the Planner's responsibility once `pipeline_state: pre-check-complete`.
- MUST NOT relax an Anti-Criterion mid-round to make a difficult deliverable easier — that defeats the gate.

### Cross-references

- Output schema: `60-schemas/acceptance-checklist.md`.
- Lifecycle: `10-pipeline/iteration-lifecycle.md` §"Phase 3 — Pre-Check".
- Sibling role (post-execute): `20-roles/evaluator.md` (separate context, separate adapter binding).

---
