---
id: 60-schemas/contract
title: contract.md schema
purpose: schema
audience: [planner, truthsayer, pre_check, executor, evaluator]
status: stable
version: 2.9
last_reviewed: 2026-05-04
extracted_from:
  source: SYSTEM-BLUEPRINT-v2.9.md
  sections: ["§8 Six-File Inter-Agent Communication Chain — contract.md format"]
  line_range_hint: "search for ### contract.md format"
depends_on:
  - 10-pipeline/file-contracts.md
  - 00-overview/invariants.md
related:
  - 60-schemas/spec.md
  - 60-schemas/acceptance-checklist.md
max_lines: 60
directives:
  must_count: 0
  should_count: 0
  may_count: 0
---
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
