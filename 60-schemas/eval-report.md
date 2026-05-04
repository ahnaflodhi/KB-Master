---
id: 60-schemas/eval-report
title: eval-report.md schema
purpose: schema
audience: [evaluator, planner, executor, kb_linter, orchestrator]
status: stable
version: 2.9
last_reviewed: 2026-05-04
extracted_from:
  source: SYSTEM-BLUEPRINT-v2.9.md
  sections: ["§8 Six-File Inter-Agent Communication Chain — eval-report.md format"]
  line_range_hint: "search for ### eval-report.md format"
depends_on:
  - 10-pipeline/file-contracts.md
  - 00-overview/invariants.md
related:
  - 60-schemas/contract.md
  - 60-schemas/acceptance-checklist.md
  - 60-schemas/quality-criteria.md
max_lines: 80
directives:
  must_count: 0
  should_count: 0
  may_count: 0
---
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

