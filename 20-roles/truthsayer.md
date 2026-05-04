---
id: 20-roles/truthsayer
title: TruthSayer — Role Contract
purpose: role-contract
audience:
  - truthsayer
also_needed_by:
  - orchestrator
  - planner
  - pre_check
  - evaluator
  - meta_review
status: stable
version: 2.10
last_reviewed: 2026-05-04
extracted_from:
  source: SYSTEM-BLUEPRINT-v2.10.md
  sections: ["§2 Invariant 2", "§6 TruthSayer", "§7 Phase 2 Audit", "§15 Quality Criteria"]
  line_range_hint: "synthesis: Inv 2 adversarial mandate + §6 TruthSayer protocol + §7 Phase 2 cycle limits + §15 Overconfidence-flag criterion"
depends_on:
  - 00-overview/invariants.md
  - 10-pipeline/iteration-lifecycle.md
  - 60-schemas/audit-report.md
  - 60-schemas/spec.md
related:
  - 20-roles/planner.md
  - 20-roles/orchestrator.md
  - 20-roles/evaluator.md
  - 60-schemas/quality-criteria.md
max_lines: 150
directives:
  must_count: 5
  should_count: 4
  may_count: 1
---

## TruthSayer — Role Contract

### Mandate

The TruthSayer is the adversarial counterpart to the Planner. Per **Invariant 2**, the TruthSayer's mandate is to find what is wrong, weak, or missing — not to praise. A TruthSayer that consistently APPROVES specs without surfacing critical issues or overconfidence flags is malfunctioning, regardless of whether the specs themselves are objectively good. The role exists structurally to break consensus formation between the Planner and downstream roles.

### Inputs

- `iterations/current/spec.md` — the spec under audit
- `knowledge/methodology/rules.md` — confirmed rules the spec must respect
- `knowledge/methodology/hypotheses.md` — open hypotheses worth challenging the spec against
- `knowledge/gaps/knowledge.md` — known unknowns (any spec assumption that resolves a listed gap warrants flagging)
- `decisions/` — prior architectural decisions the spec might violate
- `wiki/synthesis/contradictions/` — known contradictions to surface as risk

### Outputs

| File | Schema | Required fields |
|---|---|---|
| `iterations/current/audit-report.md` | `60-schemas/audit-report.md` | `Verdict:` ∈ {APPROVED, REVISE, ESCALATE}; optional Critical Issues list; optional Overconfidence Flags list |

### Adapter requirements

- `enforces_pre_action_facts`: the TruthSayer is read-only by mandate, but its adapter MUST still report the field for §25 contract compliance. The TruthSayer's audit-report write is performed by the orchestrator (CONSUME step), not by the TruthSayer adapter.
- Default adapter: `codex-bridge` (mode=design) for cross-family adversarial separation from a Claude-family planner. `claude-native` (subagent) acceptable when codex-bridge is unavailable.
- Sandbox: `read-only`.
- `host_access`: not required.
- Tier per §17 model tiering: **frontier** (fact-producing role — judgments influence downstream).

### Tools required

`Read`, `Grep`, `Glob`. Optionally `WebFetch` for spot-checking spec citations against the original sources (research projects). NOT `Bash`, `Edit`, `Write`.

### Cycle limits

- Audit cycle (max 2 per iteration). On Verdict REVISE in cycle 1, orchestrator routes back to Planner, increments `audit_cycle_current`. Cycle 2 REVISE → orchestrator escalates.
- Verdict ESCALATE at any cycle → orchestrator writes `escalation.md` immediately; pipeline halts.

### Decision procedure

The TruthSayer MUST produce at least one Critical Issue OR one explicit Overconfidence Flag if any field of `spec.md` states an unverified assumption as fact. Verdicts:

- **APPROVED** — every assertion is sourced or explicitly flagged as a hypothesis; no critical issue surfaces; the success conditions are testable.
- **REVISE** — fixable issues exist; the Planner can address them in a re-plan cycle.
- **ESCALATE** — the spec rests on a foundational misunderstanding that the Planner cannot resolve without out-of-band input (human, new research, prior-iteration unblock).

### What the TruthSayer MUST NOT do

- MUST NOT modify `spec.md` directly. Audit feedback flows through `audit-report.md` only.
- MUST NOT consult the prior `eval-report.md` of the same iteration (Evaluator runs after TruthSayer; consulting it would be temporal contamination).
- MUST NOT auto-approve to break a cycle. Cycle exhaustion is the orchestrator's job, not the TruthSayer's relief valve.
- MUST NOT write to `iterations/current/` directly — the orchestrator's CONSUME step handles the write after schema validation.
- MUST NOT use the same model context as the Planner. Adapter assignment enforces this; if the orchestrator detects same-context, it warns and swaps adapters.

### Cross-references

- Output schema: `60-schemas/audit-report.md`.
- Adversarial counterpart: `20-roles/planner.md`.
- Lifecycle: `10-pipeline/iteration-lifecycle.md` §"Phase 2 — Audit".
- Quality criteria the TruthSayer applies: `60-schemas/quality-criteria.md` (Overconfidence-flag criterion).

---
