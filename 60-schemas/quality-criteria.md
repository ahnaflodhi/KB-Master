---
id: 60-schemas/quality-criteria
title: Quality Criteria System
purpose: schema
audience: [planner, evaluator, executor, truthsayer, kb_linter, pre_check]
status: stable
version: 2.9
last_reviewed: 2026-05-04
extracted_from:
  source: SYSTEM-BLUEPRINT-v2.9.md
  sections: ["§15 Quality Criteria System"]
  line_range_hint: "search for ## 15. heading"
depends_on:
  - 60-schemas/eval-report.md
  - 60-schemas/acceptance-checklist.md
  - 00-overview/invariants.md
related:
  - 10-pipeline/quality-gates.md
max_lines: 100
directives:
  must_count: 0
  should_count: 0
  may_count: 0
---
## 15. Quality Criteria System

### Standard Research Criteria

```json
[
  {"id": "source-groundedness", "threshold": 9, "weight": "critical",
   "description": "Every factual claim traceable to specific source with inline citation"},
  {"id": "methodology", "threshold": 8, "weight": "critical",
   "description": "Approach reproducible — same steps, same wiki pages"},
  {"id": "contribution", "threshold": 7, "weight": "high",
   "description": "Adds verified signal beyond what was already asserted"},
  {"id": "validity", "threshold": 8, "weight": "critical",
   "description": "Estimates flagged as estimates. Single-source flagged as single-source."},
  {"id": "feasibility-verification", "threshold": 9, "weight": "critical",
   "description": "For each API/tool: ToS reviewed, pricing confirmed, rate limits documented"},
  {"id": "competitive-gap-accuracy", "threshold": 8, "weight": "high",
   "description": "Gap claims based on current verified product state, not assumptions"},
  {"id": "evaluator-tool-use", "threshold": 1, "weight": "critical",
   "description": "Evaluator must have fetched at least 2 cited URLs. Static-only = automatic CONDITIONAL."}
]
```

### Standard Commercial Criteria

```json
[
  {"id": "functionality", "threshold": 9, "weight": "critical",
   "description": "Contract acceptance criteria met as defined in acceptance-checklist.md"},
  {"id": "code-quality", "threshold": 8, "weight": "high",
   "description": "No speculative abstractions, no features beyond contract, tests present"},
  {"id": "security", "threshold": 9, "weight": "critical",
   "description": "No OWASP top-10 issues. Input validated at system boundaries."},
  {"id": "ux-and-scope-realism", "threshold": 7, "weight": "standard",
   "description": "MVP discipline maintained. No polish beyond what was contracted."},
  {"id": "evaluator-tool-use", "threshold": 1, "weight": "critical",
   "description": "Evaluator must have run tests. Static-only evaluation = automatic CONDITIONAL."},
  {"id": "reward-hacking-clean", "threshold": 1, "weight": "critical",
   "description": "Reward hacking check passed. Output solves problem, not just spec text."}
]
```

### Threshold Semantics

- `critical` weight: project cannot ship if criterion is below threshold
- `high` weight: FAIL triggers revision but pipeline can conditionally proceed
- `standard` weight: advisory — feeds into next iteration's spec as a warning
- Score of `1` for binary criteria (passed / not passed)

---

