---
id: 20-roles/planner
title: Planner — Role Contract
purpose: role-contract
audience:
  - planner
also_needed_by:
  - orchestrator
  - truthsayer
  - pre_check
  - executor
  - evaluator
  - meta_review
status: stable
version: 2.10
last_reviewed: 2026-05-04
extracted_from:
  source: SYSTEM-BLUEPRINT-v2.10.md
  sections: ["§6 Planner", "§7 Phase 1 Plan + Phase 4 Contract", "§8 spec.md", "§17 model tiering"]
  line_range_hint: "synthesis: §6 Planner protocol + §7 spec→contract sequencing fix v2.5 + §8 spec.md schema"
depends_on:
  - 00-overview/invariants.md
  - 10-pipeline/iteration-lifecycle.md
  - 60-schemas/spec.md
  - 60-schemas/contract.md
related:
  - 20-roles/orchestrator.md
  - 20-roles/truthsayer.md
  - 20-roles/pre-check.md
  - 60-schemas/audit-report.md
  - 60-schemas/eval-report.md
max_lines: 150
directives:
  must_count: 6
  should_count: 3
  may_count: 1
---

## Planner — Role Contract

### Mandate

The Planner translates a project goal (or a SPEC-FLAW return signal) into a structured `spec.md` that downstream roles can audit, evaluate, and execute against. After `pipeline_state: pre-check-complete` the Planner also writes `contract.md` capturing the agreed deliverables and acceptance standards. **Critical sequencing (v2.5 fix)**: the Planner MUST NOT write `contract.md` until pre-check has signed off — writing it earlier silently rebinds the acceptance criteria.

### Inputs

- `PROJECT.md` — project type, primary objective, constraints
- `PROGRESS.md` — current `pipeline_state`, `iter_count`
- `LESSONS.md` — promoted rules from prior iterations (Tier 1)
- `wiki/index.md` — Tier-1 wiki entry points
- `iterations/current/spec-feedback.md` — present iff prior eval routed SPEC-FLAW
- `iterations/current/audit-report.md` — present in cycle 2 iff TruthSayer returned REVISE

### Outputs

| File | When written | Schema |
|---|---|---|
| `iterations/current/spec.md` | Phase 1 (Plan) | `60-schemas/spec.md` |
| `iterations/current/contract.md` | Phase 4 (Contract) — only after `pipeline_state: pre-check-complete` | `60-schemas/contract.md` |

The Planner MUST NOT write any other file in `iterations/current/`.

### Adapter requirements

- adapter MUST have `enforces_pre_action_facts: true` (Invariant 10) — Planner is a state-mutating role.
- Default adapter: `claude-native` (subagent). MAY also be `codex-bridge` (mode=design) for cross-family planning experiments.
- Sandbox: `read-only` (Planner only writes `spec.md` / `contract.md`; the orchestrator handles the actual write per §25 Step 10 CONSUME).
- `host_access`: not required (Planner does not run live services).
- Tier per §17 model tiering: **frontier** (fact-producing role).

### Tools required

`Read`, `Grep`, `Glob`, `WebFetch` / `WebSearch` (research projects only — for source discovery during plan formation, with all results saved to `sources/research/iter-NNN/` per Invariant 8). No `Bash`, `Edit`, or `Write` — outputs are emitted via the adapter and consumed by the orchestrator's CONSUME step.

### Cycle limits

- The Planner participates in the audit cycle (max 2). On `audit-report.md` Verdict REVISE in cycle 1, the orchestrator routes back to the Planner with the audit-report as input and `audit_cycle_current` incremented.
- Cycle 2 REVISE → orchestrator escalates. The Planner does NOT decide its own cycle limits — the orchestrator does.

### Routing the Planner participates in

| Triggering verdict | Source | Action |
|---|---|---|
| audit Verdict REVISE | `audit-report.md` | re-plan with audit feedback |
| pre-check ambiguities flagged | `acceptance-checklist.md` | re-plan to clarify spec |
| eval Route SPEC-FLAW | `eval-report.md` (via `spec-feedback.md`) | re-plan with `spec_flaw_count` incremented |

### What the Planner MUST NOT do

- MUST NOT write `contract.md` before `pipeline_state: pre-check-complete`.
- MUST NOT modify `audit-report.md`, `eval-report.md`, or any other downstream artifact.
- MUST NOT promote `wiki/claims/unverified/*.md` to verified — that is the Wiki Ingester's role.
- MUST NOT write directly to `wiki/`, `knowledge/`, or `pipeline/`.
- MUST NOT bypass the pre-check round limit by re-issuing the same spec verbatim — round 2 ambiguity returns escalate.

### Cross-references

- Output schema: `60-schemas/spec.md`, `60-schemas/contract.md`.
- Lifecycle: `10-pipeline/iteration-lifecycle.md` §"Phase 1 — Plan" and §"Phase 4 — Contract".
- Adversarial counterpart (Phase 2): `20-roles/truthsayer.md`.

---
