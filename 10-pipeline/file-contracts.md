---
id: 10-pipeline/file-contracts
title: Six-File Inter-Agent Communication Chain
purpose: schema
audience: [orchestrator, planner, truthsayer, pre_check, executor, evaluator, kb_linter]
status: stable
version: 2.8
last_reviewed: 2026-05-04
extracted_from:
  source: SYSTEM-BLUEPRINT-v2.8.md
  sections: ["§8 Six-File Inter-Agent Communication Chain"]
  line_range_hint: "search for ## 8. heading"
depends_on:
  - 00-overview/invariants.md
  - 10-pipeline/state-machine.md
related:
  - 60-schemas/spec.md
  - 60-schemas/audit-report.md
  - 60-schemas/acceptance-checklist.md
  - 60-schemas/contract.md
  - 60-schemas/eval-report.md
max_lines: 180
directives:
  must_count: 0
  should_count: 0
  may_count: 0
---
## 8. Six-File Inter-Agent Communication Chain

```
iterations/current/
├── spec.md                ← Planner writes. TruthSayer reads. Evaluator reads (pre-check).
├── audit-report.md        ← TruthSayer writes. Executor reads. Evaluator reads.
├── acceptance-checklist.md ← Evaluator writes at pre-check. Executor reads before starting.
├── contract.md            ← Planner writes (initial draft) after TruthSayer APPROVED. Executor reads before starting.
├── execution-log.md       ← Executor writes. Evaluator reads. KB Linter reads.
└── eval-report.md         ← Evaluator writes. KB Linter reads. Archive reads.

Optional:
├── spec-feedback.md       ← Written by Evaluator on SPEC-FLAW route. Planner reads.
└── escalation.md          ← Written by any agent on escalation trigger.
```

### spec.md format

```markdown
---
## Iteration: {name}
## Objective: {what this achieves toward primary_objective}
## Hypothesis: {falsifiable claim being tested}        ← research projects
## User Story: {who / what / why}                     ← commercial projects (replaces Hypothesis)
## Acceptance Criteria: {independently testable list} ← commercial projects (replaces Hypothesis)
## Deliverable: {concrete, testable output}
## Sources to Consult: {specific URLs or file paths — not "search for X"}
## Success Conditions: {independently verifiable — Evaluator can check each}
## Constraints: {must-follow, forbidden approaches, scope limits}
## Dependencies: {what must exist before this can start}
## Decomposition: {ordered units, each independently executable}
## Open Questions: {ambiguities for TruthSayer}
---
```

**Field selection by project_type**:
- Research: use `Hypothesis` (falsifiable claim). A spec without a falsifiable hypothesis is malformed for research.
- Commercial: replace `Hypothesis` with `User Story` + `Acceptance Criteria`. A commercial spec without a `Hypothesis` field is **not malformed** — schema validation must not flag its absence. The `Objective` field covers the intent; `User Story` + `Acceptance Criteria` cover the contract.

### audit-report.md format

```markdown
---
## Revision Cycle: {N} of 2
## Verdict: APPROVED | REVISE | ESCALATE
## Critical Issues: {must fix — blocking. Specific: "X cited from blog not official page"}
## Warnings: {should address — not blocking}
## Missing: {gaps in success conditions, unverified assumptions}
## Overconfidence Flags: {claims stated as fact that are unverified assumptions}
---
```

### contract.md format

```markdown
## Sprint {N} Contract — {name}

### Agreed Deliverables
1. {specific file path or feature}

### [Domain-specific acceptance standards]
{taxonomy, thresholds, or acceptance criteria agreed before execution}

### Agreed by: TruthSayer (Revision Cycle {N}, APPROVED)
### Pre-Check by: Evaluator (acceptance-checklist.md written, no ambiguities)
```

### eval-report.md format

```markdown
---
## Cycle: {N} of 3
## Route: PASS | FAIL | SPEC-FLAW | ESCALATE
## Overall: PASS | CONDITIONAL PASS | FAIL | ESCALATE
## Tools Used: {list of tools invoked — static-only evaluation is CONDITIONAL at best}
## Scores: {criterion_id: score/threshold PASS/FAIL}
## Issues Found: {description, severity, location}
## Reward Hacking Check: CLEAN | FLAGGED ({description})
## Uncited Claims: {list}
## Feedback for Executor: {specific and actionable — reference acceptance-checklist.md items}
## Route Decision: {PASS→KB-Lint | FAIL→Executor | SPEC-FLAW→Planner | ESCALATE}
---
```

---

