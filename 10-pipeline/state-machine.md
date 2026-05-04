---
id: 10-pipeline/state-machine
title: Iteration Lifecycle — Pipeline as Directed Graph
purpose: runtime-spec
audience: [orchestrator, planner, truthsayer, pre_check, executor, evaluator, kb_linter, meta_review]
status: stable
version: 2.8
last_reviewed: 2026-05-04
extracted_from:
  source: SYSTEM-BLUEPRINT-v2.8.md
  sections: ["§7 Iteration Lifecycle"]
  line_range_hint: "search for ## 7. heading"
depends_on:
  - 00-overview/invariants.md
related:
  - 10-pipeline/file-contracts.md
  - 10-pipeline/escalation-rules.md
  - 60-schemas/escalation.md
max_lines: 180
directives:
  must_count: 0
  should_count: 0
  may_count: 0
---

## 7. Iteration Lifecycle — Pipeline as Directed Graph

```
[IDLE] → iterate.sh 'goal'
   │
   ▼
[PLANNING]
   Planner writes spec.md
   │
   ▼
[AUDITING] ←──────────────────────────────────┐
   TruthSayer writes audit-report.md           │
   APPROVED → continue                         │
   REVISE   → back to Planner (cycle 2 max)    │
   ESCALATE → stop, await human               │
   │                                           │
   ▼                                           │
[PRE-CHECKING]                                 │
   Evaluator writes acceptance-checklist.md    │
   Ambiguities → Planner resolves (max 2 rounds, tracked as pre_check_cycle_current)│
   pre_check_cycle_current >= 2 with ambiguities → ESCALATE (spec-too-vague)      │
   No ambiguities → PRE-CHECK COMPLETE         │
   │                                           │
   ▼                                           │
[PRE-CHECK COMPLETE]                           │
   Set pipeline_state: pre-check-complete      │
   Planner writes contract.md (spec now stable — ambiguities resolved)             │
   │                                           │
   ▼                                           │
[CONTRACTED]                                   │
   Executor reads contract.md + acceptance-checklist.md (no unresolved items)     │
   │                                           │
   ▼                                           │
[EXECUTING]                                    │
   Executor produces output unit by unit       │
   Logs to execution-log.md + pipeline.log.jsonl│
   │                                           │
   ▼                                           │
[EVALUATING] ←────────────────────────────────┐
   Evaluator scores with tool use              │
   PASS     → continue                        │
   FAIL     → back to Executor (cycle 3 max) ─┘
   SPEC-FLAW → increments spec_flaw_count in PROGRESS.md
             → if spec_flaw_count < 2: writes spec-feedback.md, routes to [PLANNING], resets audit cycle
             → if spec_flaw_count >= 2: routes to ESCALATE (unbounded loop closed)
   ESCALATE → stop, await human
   │
   ▼
[KB-LINTING]
   KB Linter runs 8-rule checklist
   Temporal metadata updated on all promoted rules
   Provenance chain verified
   Eviction policy run if caps exceeded
   iter-summary.md written, LESSONS.md appended
   pipeline.log.jsonl flushed
   │
   ▼
[ARCHIVING]
   cp iterations/current/*.md iterations/archive/iter-NNN/
   PROGRESS.md: iter_count++, pipeline_state: idle, tokens_used_this_iter reset
   │
   ▼
[IDLE]
   Every 5 iterations → /meta-review prompt
```

### Escalation Triggers (auto-stop the pipeline)

An agent writes `escalation.md` and prints `ESCALATION NEEDED` when:
- TruthSayer rejects same spec element twice with no new information
- Evaluator fails same criterion for 3 cycles with no score improvement
- Evaluator routes SPEC-FLAW twice (spec is structurally unplannable)
- Executor cannot find a primary source for a critical claim
- Any agent detects a conflict between two confirmed rules it cannot auto-resolve
- `escalations_last_5 >= 3` — **this HALTS the pipeline entirely** (not just triggers meta-review). Pipeline stays halted until human-approved meta-review is applied via `/apply-meta`. Subsequent iterations cannot begin.
- Token budget exhausted before pipeline completion (see Section 17)
- pre_check_cycle_current >= 2 with unresolved ambiguities (spec-too-vague)

**Note on error cascade risk**: Sequential pipelines exhibit documented error amplification (Google DeepMind, arXiv:2603.04474). The TruthSayer (audit gate) and Pre-Check Evaluator (acceptance gate) function as cascade breakers — they prevent upstream errors from propagating undetected into the execution and KB-write phases. These two gates are the primary defense against the 17x error amplification observed in unguarded sequential agent pipelines.

---

