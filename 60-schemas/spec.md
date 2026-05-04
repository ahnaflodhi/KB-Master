---
id: 60-schemas/spec
title: spec.md schema
purpose: schema
audience: [planner, truthsayer, pre_check, executor, evaluator]
status: stable
version: 2.9
last_reviewed: 2026-05-04
extracted_from:
  source: SYSTEM-BLUEPRINT-v2.9.md
  sections: ["§8 Six-File Inter-Agent Communication Chain — spec.md format"]
  line_range_hint: "search for ### spec.md format"
depends_on:
  - 10-pipeline/file-contracts.md
  - 00-overview/invariants.md
related:
  - 60-schemas/audit-report.md
  - 60-schemas/contract.md
max_lines: 80
directives:
  must_count: 0
  should_count: 0
  may_count: 0
---
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
