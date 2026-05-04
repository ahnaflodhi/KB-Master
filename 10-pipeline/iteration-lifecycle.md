---
id: 10-pipeline/iteration-lifecycle
title: Iteration Lifecycle (Narrative)
purpose: knowledge-spec
audience: [orchestrator, planner, truthsayer, pre_check, executor, evaluator, kb_linter, meta_review]
status: stable
version: 2.9
last_reviewed: 2026-05-04
extracted_from:
  source: synthesis
  sections: ["§7 Iteration Lifecycle (state machine)", "§22 Harness Assumption Decay Protocol", "§16 Escalation Protocol", "§24 Claude Code Harness Integration (startup ritual)"]
  line_range_hint: "synthesis: §7 narrative companion to state-machine.md, plus §22 decay overlay + §16 escalation triggers + §24 startup ritual"
depends_on:
  - 00-overview/invariants.md
  - 10-pipeline/state-machine.md
  - 10-pipeline/file-contracts.md
related:
  - 10-pipeline/escalation-rules.md
  - 10-pipeline/quality-gates.md
  - 60-schemas/spec.md
  - 60-schemas/contract.md
  - 60-schemas/eval-report.md
max_lines: 180
directives:
  must_count: 0
  should_count: 0
  may_count: 0
---

## Iteration Lifecycle — Narrative

This file is the **narrative companion** to `10-pipeline/state-machine.md`. State-machine.md gives the diagram and the canonical state enum; this file walks an iteration end-to-end, explains why each transition exists, and notes where harness-decay and Invariant 10 (pre-action fact presentation) fire. For escalation triggers in detail, see `10-pipeline/escalation-rules.md`.

### Startup ritual (per iteration)

Before any state-mutating action this iteration, the orchestrator (`claude-main`) does:

1. Loads `agents.config.yaml` (config_revision recorded in every ledger row).
2. Probes every adapter once per session — caches results. An adapter reporting `enforces_pre_action_facts: false` cannot be assigned to state-mutating roles (Invariant 10).
3. Reads PROGRESS.md to determine `pipeline_state`. If `pipeline_state: idle` → fresh iteration. Otherwise → resume from declared state.
4. Reads LESSONS.md (Tier 1) and `wiki/index.md` (Tier 1). Selective Tier-2 loading happens at role dispatch, not here.
5. Increments `iter_count` IFF this is a new iteration.

### Phase 1 — Plan

**Role**: Planner. **Adapter**: per `agents.config.yaml` `roles.planner`. **Sandbox**: read-only (Planner only writes spec.md, no other state).

**Inputs read**: PROJECT.md, PROGRESS.md, LESSONS.md, `wiki/index.md`, `spec-feedback.md` if present (SPEC-FLAW route from prior eval).
**Output**: `iterations/current/spec.md` per `60-schemas/spec.md`.

**Pre-action fact (Invariant 10)**: emitted by orchestrator before dispatch. The Planner adapter's own writes are gated by its harness if claude-native, or orchestrator-side for codex-bridge.

**Transition out**: `pipeline_state: planned` → invoke TruthSayer.

### Phase 2 — Audit (max 2 cycles)

**Role**: TruthSayer. **Sandbox**: read-only. **Mandate**: Invariant 2 — "find what is wrong, weak, or missing; not here to praise."

**Inputs read**: spec.md, `knowledge/*/rules.md`, `decisions/`.
**Output**: `iterations/current/audit-report.md` per `60-schemas/audit-report.md` with Verdict ∈ {APPROVED, REVISE, ESCALATE}.

**Transition rules**:
- Verdict APPROVED → `pipeline_state: audited` → Phase 3.
- Verdict REVISE → orchestrator routes back to Planner; cycle counter `audit_cycle_current` += 1.
- Cycle 2 returns REVISE → automatic ESCALATION (Phase 16).
- Verdict ESCALATE at any cycle → write escalation.md immediately; pipeline halts.

### Phase 3 — Pre-Check (max 2 ambiguity rounds)

**Role**: Pre-Check Evaluator (separate Evaluator instance from the post-execute Evaluator).
**Inputs**: spec.md, audit-report.md.
**Output**: `iterations/current/acceptance-checklist.md` per `60-schemas/acceptance-checklist.md`. Records Deliverable Acceptance Criteria, Quality Thresholds, Anti-Criteria, and Ambiguities Flagged to Planner.

**Transition rules**:
- No ambiguities → `pipeline_state: pre-check-complete` → Phase 4.
- Ambiguities flagged → orchestrator routes back to Planner; `pre_check_cycle_current` += 1.
- Round 2 returns ambiguities → automatic ESCALATION.

### Phase 4 — Contract

**Role**: Planner (writes contract.md; Pre-Check signed off the acceptance criteria).
**Critical sequencing fix v2.5**: contract.md is written ONLY after `pipeline_state: pre-check-complete` — not after TruthSayer APPROVED alone.

**Output**: `iterations/current/contract.md` per `60-schemas/contract.md`. Records Agreed Deliverables + domain-specific acceptance standards.

**Transition out**: `pipeline_state: contracted` → Phase 5.

### Phase 5 — Execute

**Role**: Executor (research or commercial subtype).
**Inputs**: spec.md, audit-report.md, contract.md, acceptance-checklist.md, `wiki/index.md`.
**Output**: wiki pages or code + `iterations/current/execution-log.md` per `60-schemas/execution-log.md`.

**Within-execute discipline**:
- Per Invariant 8: every WebFetch/WebSearch result saved to `sources/research/iter-NNN/` BEFORE any claim is extracted.
- Per §6 commercial protocol: per-unit type-check (2a) + multi-tenancy gate (2b) logged in execution-log.md.
- Per §6 stub protocol: any blocked unit produces `# TODO: RESOLVE-STUB` placeholder; iteration continues with next independent unit.
- Per Invariant 10: every Bash/Edit/Write within the executor adapter's sandbox triggers the pre-action fact gate.

**Transition out**: `pipeline_state: executed` → Phase 6.

### Phase 6 — Evaluate (max 3 cycles)

**Role**: Evaluator. **Cross-family preferred** (executor=Claude → evaluator=Codex, or vice versa) per `policy.cross_family_evaluator_preferred`.

**Inputs**: contract.md, acceptance-checklist.md, execution-log.md, `quality-criteria.json`.
**Output**: `iterations/current/eval-report.md` per `60-schemas/eval-report.md`.

**Mandatory**: Invariant 7 — Evaluator MUST use execution tools (run tests, fetch URLs). Static-only evaluation produces CONDITIONAL PASS at best, not PASS. The four reward-hacking checks (§18) are mandatory.

**Routing**:
- Route PASS → Phase 7 (KB-Lint).
- Route FAIL → back to Executor; `eval_cycle_current` += 1; max 3 cycles.
- Route SPEC-FLAW (the spec itself was malformed) → back to Planner; `spec_flaw_count` += 1.
- Route ESCALATE | cycle 3 FAIL | spec_flaw_count ≥ 2 → escalation.

### Phase 7 — KB-Lint

**Role**: KB Linter. **Tier**: mid-tier model per §17 (mechanical maintenance).
**Inputs**: all `knowledge/*.md`, all `wiki/**/*.md`, eval-report.md.
**Outputs**: `iter-summary.md` (15-line cap per `60-schemas/iter-summary.md`); appends to LESSONS.md; runs the 10 lint rules (orphan detection, contradiction scan, citation rot check, etc.).

### Phase 8 — Archive

**Role**: orchestrator. Snapshots `iterations/current/` → `iterations/archive/iter-NNN/`. Resets `iterations/current/`. Bumps `iter_count`. Writes git commit per §23 adoption guide ("iter-NNN: {goal}"). Sets `pipeline_state: idle`.

### Where harness decay overlays the lifecycle (§22)

Every `min(25 iterations, 6 months)` the orchestrator (or human via `/meta-review` → `/apply-meta`) runs the harness audit. For each scaffold (cycle limits, reward-hacking checks, schema-validation rigor, gate enforcement), evidence is read from `compensates_for` + `evidence_threshold` frontmatter; outcome is RETAIN | DOWNGRADE | ARCHIVE. The lifecycle's shape does not change at audit time — the rigor of individual phases does.

### Cross-iteration accumulation

- LESSONS.md grows: 1 entry per iteration (KB Linter writes during Phase 7).
- knowledge/findings → hypotheses → rules: caps (30/15/20) enforce density. KB Linter promotes when confirmation thresholds met.
- wiki/index.md grows but capped at 200 lines (§20); excess content moves to per-cluster index files.
- pipeline/verification-ledger.jsonl grows: 2 rows per delegation (dispatch + consume). Never rotated automatically — meta-review reads the trailing window.

### Where Invariant 10 fires within an iteration

Every state-mutating action by any agent. Concretely:
- Planner writing spec.md → 1 fact gate.
- TruthSayer writing audit-report.md → 1 fact gate.
- Executor's N tool invocations during Phase 5 → N fact gates (this is the highest-frequency phase for the gate).
- Orchestrator's writes to PROGRESS.md, ledger, escalation.md → fact-gated even though orchestrator-side.

The gate's job is per-action alignment between request and action. The lifecycle's job is per-iteration progress. Both run simultaneously; neither replaces the other.

---
