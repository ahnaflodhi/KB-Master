---

id: 60-schemas/acceptance-checklist
title: acceptance-checklist.md schema
purpose: schema
audience: [pre_check, evaluator, executor, planner, truthsayer]
status: stable
version: 2.9
last_reviewed: 2026-05-04
extracted_from:
  source: SYSTEM-BLUEPRINT-v2.9.md
  sections: ["§6 Agent Roles — Pre-Check Evaluator"]
  line_range_hint: "search for ### Pre-Check Evaluator"
depends_on:
  - 60-schemas/spec.md
  - 60-schemas/audit-report.md
  - 60-schemas/contract.md
  - 00-overview/invariants.md
related:
  - 60-schemas/eval-report.md
  - 60-schemas/quality-criteria.md
max_lines: 100
directives:
  must_count: 0
  should_count: 0
  may_count: 0
---
### Pre-Check Evaluator (`/pre-check`) ← NEW IN V2.0

**Mandate**: Review the Planner's spec and sign off on concrete acceptance criteria BEFORE the Executor begins. This is the Evaluator acting at spec time, not execution time.

**Critical role**: Prevents non-convergence. If the Evaluator and Executor work from different implicit understandings of the spec, evaluation cycles can iterate indefinitely without convergence.

**Reads**: `iterations/current/spec.md`, `iterations/current/audit-report.md`

**Produces**: `iterations/current/acceptance-checklist.md`

```markdown
## Acceptance Checklist — Sprint {N}
## Pre-Check Date: {YYYY-MM-DD}
## Checklist Version: {matches spec revision cycle}

### Deliverable Acceptance Criteria
- [ ] {specific, independently testable criterion 1}
- [ ] {specific, independently testable criterion 2}
  [HOW I WILL VERIFY: {specific tool or check — not "I will look at it"}]

### Quality Thresholds
- [ ] source-groundedness ≥ 9/10 (for research)
- [ ] functionality ≥ 9/10 (for commercial)
[...from quality-criteria.json]

### Anti-Criteria (what would cause automatic FAIL)
- [ ] Criterion is met by shortcut rather than genuine solution
- [ ] Any acceptance criterion satisfied by placeholder/stub without disclosure
- [ ] [project-specific anti-criteria]

### Ambiguities Flagged to Planner (must be resolved before execution)
- {ambiguity 1 — if present, Executor must not begin until resolved}
```

If ambiguities are flagged, Planner revises spec to resolve them — does NOT count as an audit cycle. Executor cannot begin until `acceptance-checklist.md` exists with no unresolved ambiguities.

**Ambiguity resolution cycle limit**: Maximum 2 pre-check ambiguity rounds before auto-escalation. The `pre_check_cycle_current` field in PROGRESS.md tracks this. If pre_check_cycle_current >= 2 and ambiguities remain, write `escalation.md` with reason: `spec-too-vague` and stop. This prevents an unbounded Planner↔PreCheck loop that consumes tokens without triggering any audit cycle counter.

---

