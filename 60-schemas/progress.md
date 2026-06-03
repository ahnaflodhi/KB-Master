---
id: 60-schemas/progress
title: PROGRESS.md schema
purpose: schema
audience: [orchestrator]
status: stable
version: 3.0
last_reviewed: 2026-06-03
extracted_from:
  source: SYSTEM-BLUEPRINT-v2.10.md
  sections: ["§5 PROGRESS.md / pipeline state"]
  line_range_hint: "formalized at v3.0 from 10-pipeline/state-machine.md + iteration-lifecycle.md (no standalone §5 extraction existed)"
depends_on:
  - 10-pipeline/state-machine.md
  - 10-pipeline/iteration-lifecycle.md
  - 00-overview/invariants.md
related:
  - 60-schemas/escalation.md
  - 60-schemas/iter-summary.md
max_lines: 80
directives:
  must_count: 2
  should_count: 0
  may_count: 0
---
### PROGRESS.md

The single source of pipeline state for the current iteration. **Orchestrator-written
only** (INVARIANT 9). Read at bootstrap to decide fresh-start vs resume. One per
project root.

```markdown
# PROGRESS

pipeline_state:          {idle | planned | audited | pre-check-complete | contracted | executed}
iter_count:              {integer — completed iterations; ++ at archive}
tokens_used_this_iter:   {integer — reset to 0 at archive}
spec_flaw_count:         {integer — SPEC-FLAW route increments; >= 2 → ESCALATE}
audit_cycle_current:     {integer — Audit phase; cycle 2 REVISE → ESCALATE}
pre_check_cycle_current: {integer — Pre-Check phase; round 2 ambiguities → ESCALATE}
eval_cycle_current:      {integer — Evaluate phase; FAIL routes back to Executor; max 3}
```

#### Field notes

- `pipeline_state` — the resumable state. The canonical enum and ALL transitions are
  owned by `10-pipeline/state-machine.md`; this schema lists the persisted values, not
  the transition logic. Bootstrap (`10-pipeline/iteration-lifecycle.md` step 3) reads
  it: `idle` → fresh iteration; any other value → resume from that state.
- `iter_count` MUST advance only on a new iteration, and only at the archive step
  (which sets `pipeline_state: idle` and resets `tokens_used_this_iter`) — never
  mid-iteration.
- `spec_flaw_count` and the three `*_cycle_current` counters are the loop-closure
  guards; each MUST trigger ESCALATE at its declared bound (see
  `10-pipeline/state-machine.md` and `60-schemas/escalation.md`).
