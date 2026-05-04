---
id: 60-schemas/iter-summary
title: iter-summary.md schema
purpose: schema
audience: [kb_linter, meta_review, orchestrator, planner]
status: stable
version: 2.9
last_reviewed: 2026-05-04
extracted_from:
  source: synthesis
  sections: ["§6 KB Linter (writes)", "§12 Self-Learning Knowledge Layer (promotion candidates)", "§21 Meta-Review Cadence (consumer)"]
  line_range_hint: "iter-summary.md has no single format block — synthesised from §6 'Writes: iterations/current/iter-summary.md (15-line cap)', §12 hypothesis/rule promotion criteria, §21 meta-review consumption pattern"
depends_on:
  - 00-overview/invariants.md
  - 60-schemas/eval-report.md
related:
  - 10-pipeline/iteration-lifecycle.md
  - 10-pipeline/file-contracts.md
max_lines: 100
directives:
  must_count: 0
  should_count: 0
  may_count: 0
---

## iter-summary.md — Synthesis schema

**Status**: synthesised from §6 (KB Linter writes), §12 (Self-Learning Knowledge Layer), and §21 (Meta-Review Cadence). The blueprint does not give `iter-summary.md` a dedicated format block; it is referenced by writer obligation, by content (promotion candidates), and by consumer pattern. This file consolidates those references into a single contract.

### Producer

**KB Linter** — at the end of every iteration (§6 KB Linter, line 722: `Writes: iterations/current/iter-summary.md (15-line cap), appends to LESSONS.md`).

### Consumers

- **Meta-Review** (§21) — reads `archive/*/iter-summary.md` across the trailing window (`min(5 iterations, 14 days)`) to identify cross-iteration patterns.
- **Archive** — snapshotted into `archive/iter-NNN/` at iteration completion (§4 Directory Structure).
- **Orchestrator** — consults the most recent iter-summary.md when assembling context for the next planner dispatch (read-only).
- **Planner** (next iteration) — reads to avoid re-deciding settled questions.

### Mandatory line cap

`15 lines`. Hard cap (per §6 KB Linter). A KB Linter that writes more than 15 lines is operating below spec — the cap forces synthesis, not stenography.

### Required fields (suggested — within 15-line budget)

```markdown
## iter-NNN ({YYYY-MM-DD})
- Goal:        {one-line restatement of spec.md Objective}
- Outcome:    {PASS | CONDITIONAL PASS | FAIL | ESCALATED}
- Built:      {2-3 lines on what landed}
- Learned:    {2-3 lines on what changed our understanding}
- Promotions:
  - HYP-{NNN}: {pattern statement}              ← if observation count crossed promotion threshold
  - RULE-{NNN}: {declarative truth}             ← if hypothesis confirmation count crossed promotion threshold
- Anomalies:  {flagged via §6 'observation velocity enforcement' if max_new_observations_per_iter exceeded}
- Next:       {one-line focus for the next iteration — fed to Planner}
```

### Field semantics

| Field | Meaning | Source |
|---|---|---|
| `Goal` | One-line restatement of `spec.md` Objective field | §8 spec.md |
| `Outcome` | Mirrors `eval-report.md` Overall verdict | §8 eval-report.md |
| `Built` | Concrete artifacts written this iteration (file paths under wiki/, code/, knowledge/) | §6 Executor execution-log.md → KB Linter aggregation |
| `Learned` | New observations promoted to LESSONS.md | §12 Observation Format |
| `Promotions` | Hypotheses or rules whose confirmation count crossed the §12 promotion threshold this iteration (2+ for entity pages, 3+ for rules.md) | §12 / Invariant 5 |
| `Anomalies` | Velocity-cap breaches, contradiction flags, source-coverage misses | §6 KB Linter / §11 Wiki-Specific Failure Modes |
| `Next` | One-line focus, fed to next Planner dispatch | §21 Meta-Review feedback loop |

### What MUST NOT appear in iter-summary.md

- Verbatim eval-report.md content (link to it; do not duplicate).
- New claims (those go to `wiki/claims/unverified/` per Invariant 5).
- New rules (those go to `knowledge/rules.md` with temporal metadata per Invariant 6).
- Multi-line prose explanations (15-line cap — synthesise, do not narrate).

### Validation

Schema validation in the §25 dispatch shim (Step 8) checks: `wc -l ≤ 15` AND the `Outcome:` field value is in the eval-report.md verdict enum. A KB Linter output failing either check is rejected and re-delegated.

---
