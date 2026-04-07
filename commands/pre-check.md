# /pre-check — The Pre-Check Evaluator

◆ Pre-Check Evaluator — spec-time contract negotiation. Runs AFTER /audit APPROVED, BEFORE /execute.

Read PROJECT.md → load project_type, primary_objective.
Read iterations/current/spec.md → understand what will be built/researched.
Read iterations/current/audit-report.md → understand what TruthSayer approved and what warnings remain.
Read quality-criteria.json → identify which criteria apply to this project_type.

Your job is to convert the approved spec into a signed, concrete acceptance checklist that:
1. Is unambiguous enough that a third party could verify each criterion independently
2. Prevents the Evaluator (post-execution) from re-interpreting the spec
3. Flags any ambiguities that must be resolved BEFORE the Executor begins

## Acceptance Checklist Format

Write to iterations/current/acceptance-checklist.md:

---
## Acceptance Checklist — {Sprint name from spec.md}
## Pre-Check Date: {today's date}
## Spec Version: {Revision Cycle N from audit-report.md}

### Deliverable Acceptance Criteria
For each item in spec.md Decomposition list:
- [ ] {specific, independently testable criterion}
  [HOW I WILL VERIFY: {specific tool or check — not "I will look at it"}]
  [ANTI-SHORTCUT: {what a non-genuine solution would look like for this criterion}]

### Quality Thresholds (from quality-criteria.json)
- [ ] {criterion-id} ≥ {threshold}/10
  [HOW: {specific check method}]

### Anti-Criteria (automatic FAIL conditions)
- Any acceptance criterion satisfied by undisclosed stub or placeholder
- Any factual claim present in output without inline citation (research)
- Any OWASP top-10 issue present (commercial)
- [Add project-specific anti-criteria based on this spec's risk areas]

### Ambiguities Requiring Resolution Before Execution
(List any parts of the spec that are unclear enough to cause Executor/Evaluator disagreement)
- {ambiguity 1}
  [If none: "None — spec is unambiguous."]
---

## After Writing Checklist

If ambiguities are listed:
- Do NOT proceed to contract or execution
- Print: "PRE-CHECK: Ambiguities found — Planner must resolve before Executor begins"
- The Planner reads this file and revises spec.md to address ambiguities (does not count as audit cycle)
- Then /pre-check is re-run against the revised spec

If no ambiguities:
- Set pipeline_state to 'pre-checked' in PROGRESS.md
- Print: "PRE-CHECK COMPLETE — acceptance-checklist.md written. Run /execute after contract.md agreed."
