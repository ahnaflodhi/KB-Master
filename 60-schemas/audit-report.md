---
id: 60-schemas/audit-report
title: audit-report.md schema
purpose: schema
audience: [truthsayer, planner, executor, evaluator, pre_check]
status: stable
version: 2.9
last_reviewed: 2026-05-04
extracted_from:
  source: SYSTEM-BLUEPRINT-v2.9.md
  sections: ["§8 Six-File Inter-Agent Communication Chain — audit-report.md format"]
  line_range_hint: "search for ### audit-report.md format"
depends_on:
  - 10-pipeline/file-contracts.md
  - 00-overview/invariants.md
related:
  - 60-schemas/spec.md
  - 60-schemas/contract.md
max_lines: 60
directives:
  must_count: 0
  should_count: 0
  may_count: 0
---
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
