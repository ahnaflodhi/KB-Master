---
id: 20-roles/meta-review
title: Meta-Review — Role Contract
purpose: role-contract
audience:
  - meta_review
also_needed_by:
  - orchestrator
  - apply_meta
  - kb_linter
status: stable
version: 2.10
last_reviewed: 2026-05-04
extracted_from:
  source: SYSTEM-BLUEPRINT-v2.10.md
  sections: ["§6 Meta-Review", "§21 Meta-Review cadence", "§22 Harness Assumption Decay Protocol", "§24 MCP memory deprecation checklist item 11"]
  line_range_hint: "synthesis: §6 protocol + §21 min(25 iters, 6 months) cadence + §22 RETAIN/DOWNGRADE/ARCHIVE per scaffold + §24 memory cleanup checklist"
depends_on:
  - 00-overview/invariants.md
  - 00-overview/design-principles.md
  - 10-pipeline/iteration-lifecycle.md
related:
  - 20-roles/orchestrator.md
  - 20-roles/apply-meta.md
  - 20-roles/kb-linter.md
max_lines: 150
directives:
  must_count: 5
  should_count: 4
  may_count: 1
---

## Meta-Review — Role Contract

### Mandate

The Meta-Review runs the harness audit on the cadence `min(25 iterations, 6 months)` per §22. For each protective scaffold the architecture mandates (cycle limits, reward-hacking checks, schema-validation rigor, gate enforcement, fact-presentation gates, host-access denials, etc.), the Meta-Review reads the scaffold's `compensates_for` + `evidence_threshold` frontmatter and decides one of three outcomes:

- **RETAIN** — the scaffold still catches its documented failure mode at expected frequency.
- **DOWNGRADE** — the scaffold has caught its target less often than `evidence_threshold` over the audit window; it goes from mandatory to advisory (warning, not error).
- **ARCHIVE** — the scaffold has caught zero relevant failures; it is removed and its specification recorded in the meta-audit so future reviewers can re-add it if the failure mode resurfaces.

This is the structural countermeasure to harness drowning (§22): a system that cannot retire its own scaffolds eventually drowns in them.

### Inputs

- `pipeline/verification-ledger.jsonl` — trailing window (last `min(25 iterations, 6 months)` of dispatch + consume rows)
- `iterations/archive/iter-NNN/iter-summary.md` for each iteration in the window
- `agents.config.yaml` — current scaffold configuration
- `00-overview/invariants.md` + `10-pipeline/quality-gates.md` — current scaffold inventory
- `meta/audit-YYYY-MM-DD.md` — prior meta-review (for delta detection)

### Outputs

| File | Schema | Purpose |
|---|---|---|
| `meta/audit-YYYY-MM-DD.md` | (project-defined) — sections: Scaffold inventory · Per-scaffold verdict (RETAIN / DOWNGRADE / ARCHIVE) · Evidence cited from ledger · MCP memory cleanup checklist · Next audit date | the audit report |

The Meta-Review itself does NOT mutate `agents.config.yaml`, slash commands, or scaffold frontmatter — that is the Apply-Meta role's job. Meta-Review produces decisions; Apply-Meta enacts them.

### Adapter requirements

- adapter MAY have `enforces_pre_action_facts: false` (Meta-Review is read-only — it produces a report, not a state mutation; the orchestrator's CONSUME step writes the audit file).
- Default adapter: `claude-native` (subagent or sdk).
- Sandbox: `read-only`.
- `host_access` (v2.10): not required.
- Tier per §17: **frontier** (judgment on whether scaffolds still earn their cost is high-leverage; mid-tier under-prunes).

### Tools required

`Read`, `Grep`, `Glob`. NOT `Bash`, `Edit`, `Write`.

### Cadence + scope

- Every `min(25 iterations, 6 months)` per §22.
- May also fire on demand via `/meta-review` (e.g. after a major adapter or invariant change).
- Per audit: ALL scaffolds with `compensates_for` frontmatter, plus invariants, plus quality gates, plus host-access denials (v2.10).

### Decision procedure (per scaffold)

| Evidence count over audit window | Verdict |
|---|---|
| ≥ `evidence_threshold` catches | RETAIN |
| 1 ≤ catches < threshold | DOWNGRADE — flag in audit; set `status: advisory` proposal |
| 0 catches AND no documented near-miss | ARCHIVE — record specification; propose removal |

A scaffold whose `compensates_for` failure mode has itself been retired by a model improvement (per §22) is automatically ARCHIVE-eligible regardless of catch count.

### What the Meta-Review MUST NOT do

- MUST NOT modify `agents.config.yaml`, `commands/*.md`, or scaffold frontmatter — Apply-Meta does that.
- MUST NOT skip a scaffold from the audit because "it's obviously still needed" — every scaffold gets evaluated against evidence.
- MUST NOT promote a one-iteration anomaly into a DOWNGRADE — the cadence exists to filter noise.
- MUST NOT compress the audit window to make a particular scaffold look more or less effective.
- MUST NOT publish the audit verdict before Apply-Meta has enacted (or rejected) it — verdicts in `meta/` are proposals until acted upon.

### Cross-references

- §22 Harness Assumption Decay Protocol — the source of the audit framework.
- Sibling role: `20-roles/apply-meta.md` (the actor that enacts verdicts).
- Cadence: §21.

---
