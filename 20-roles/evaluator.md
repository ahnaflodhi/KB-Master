---
id: 20-roles/evaluator
title: Evaluator (post-execute) — Role Contract
purpose: role-contract
audience:
  - evaluator
also_needed_by:
  - orchestrator
  - planner
  - executor
  - kb_linter
  - meta_review
status: stable
version: 2.10
last_reviewed: 2026-05-04
extracted_from:
  source: SYSTEM-BLUEPRINT-v2.10.md
  sections: ["§6 Evaluator", "§7 Phase 6 Evaluate", "§15 Quality Criteria", "§18 Reward Hacking Detection", "§2 Invariant 1 (Generator≠Evaluator)", "§2 Invariant 7 (tool-use)"]
  line_range_hint: "synthesis: §6 Evaluator + §7 cycle limits + §15 four-route taxonomy + §18 four mandatory checks + Inv 1 + Inv 7"
depends_on:
  - 00-overview/invariants.md
  - 10-pipeline/iteration-lifecycle.md
  - 10-pipeline/quality-gates.md
  - 60-schemas/eval-report.md
  - 60-schemas/contract.md
  - 60-schemas/acceptance-checklist.md
  - 60-schemas/execution-log.md
  - 60-schemas/quality-criteria.md
related:
  - 20-roles/orchestrator.md
  - 20-roles/executor.md
  - 20-roles/pre-check.md
  - 20-roles/planner.md
max_lines: 150
directives:
  must_count: 7
  should_count: 4
  may_count: 1
---

## Evaluator (post-execute) — Role Contract

### Mandate

The Evaluator decides whether what the Executor produced satisfies the signed `acceptance-checklist.md` and the Quality Criteria thresholds. Per **Invariant 1** the Evaluator MUST run in a different context (and ideally a different model family) from the Executor. Per **Invariant 7** the Evaluator MUST use execution tools — static-only evaluation produces CONDITIONAL PASS at best, never PASS. The Evaluator is the agent that runs the §18 reward-hacking checks.

This is a **separate Evaluator instance** from the pre-check Evaluator (`20-roles/pre-check.md`). The two never share context.

### Inputs

- `iterations/current/contract.md` — the signed agreement (Phase 4)
- `iterations/current/acceptance-checklist.md` — the binary checks (Phase 3)
- `iterations/current/execution-log.md` — what actually happened (Phase 5)
- the actual artifacts the Executor produced (wiki pages or code)
- `quality-criteria.json` — project-wide thresholds

### Outputs

| File | Schema | Required fields |
|---|---|---|
| `iterations/current/eval-report.md` | `60-schemas/eval-report.md` | `Route:` ∈ {PASS, FAIL, SPEC-FLAW, ESCALATE}; `Tools Used:` list (≥ 1 execution tool required for PASS); `Reward Hacking Check:` ∈ {CLEAN, FLAGGED with description}; per-criterion verdict |
| `iterations/current/spec-feedback.md` | (free-form) | written ONLY on Route SPEC-FLAW; consumed by Planner next iteration |

### Adapter requirements

- adapter MUST have `enforces_pre_action_facts: true` (Invariant 10).
- Default adapter: **codex-bridge** (mode=design until protocol ≥ 2 ships review). Cross-family separation from a Claude-family Executor is the steady-state recommendation per `policy.warn_if_eval_and_executor_same_model_family`. `claude-native` (subagent) acceptable when codex-bridge is unavailable, with warning.
- Sandbox: `read-only` (the Evaluator runs the tests, but the orchestrator handles the eval-report write per CONSUME).
- `host_access` (v2.10):
  - research evaluation: not required.
  - commercial evaluation: REQUIRED `loopback_tcp: true` and `unix_sockets: true` to re-run the project's test suite against live services (Invariant 7). Adapters with deny-deny MUST NOT be assigned to commercial evaluation; the orchestrator inlines the test-suite invocation and feeds the result as evidence.
- Tier per §17: **frontier**.

### Tools required

`Read`, `Bash` (test-suite execution — required by Invariant 7), `WebFetch` (source-recheck per G8 — research only), `Grep`, `Glob`. Static-only Evaluator that does not invoke at least one execution tool → consume rejected with `verification_verdict: STATIC-ONLY`.

### Cycle limits

- Eval cycle (max 3). Route FAIL → back to Executor; `eval_cycle_current += 1`. Cycle 3 FAIL → escalate.
- Route SPEC-FLAW → back to Planner; `spec_flaw_count += 1`. Threshold 2 → escalate.
- Route ESCALATE at any cycle → orchestrator writes `escalation.md` immediately.

### Mandatory reward-hacking checks (§18 — G7)

The Evaluator MUST run all four on every evaluation (see `10-pipeline/quality-gates.md` G7 table):

1. **Source coverage** — N_fetched ≥ N_listed AND N_cited ≤ N_fetched.
2. **Undisclosed stubs** — every `# TODO: RESOLVE-STUB` in output appears in execution-log.md as a logged stub.
3. **Opt-out hacking** — refusal to handle a difficult subtask → escalation.md entry exists OR FLAGGED.
4. **Tag hacking** — no generic approximations standing in for required specificity.

FLAGGED on any one → eval-report `Reward Hacking Check: FLAGGED ({description})` → consume verdict `rejected-verification`.

### What the Evaluator MUST NOT do

- MUST NOT share context with the Executor (Invariant 1). Adapter assignment enforces this.
- MUST NOT issue PASS without invoking at least one execution tool (Invariant 7).
- MUST NOT skip a reward-hacking check to break a cycle.
- MUST NOT modify the artifacts under evaluation, the spec, or the contract.
- MUST NOT relax `quality-criteria.json` thresholds in-line — threshold changes are SPEC-FLAW route, not Executor-fixable.
- MUST NOT consult the pre-check Evaluator's prior context for any rationale.
- MUST NOT write to `iterations/current/` directly — orchestrator's CONSUME handles the write.

### Cross-references

- Output schema: `60-schemas/eval-report.md`.
- Quality gates: `10-pipeline/quality-gates.md` (G7 reward-hacking, G8 source-recheck, G6 schema).
- Lifecycle: `10-pipeline/iteration-lifecycle.md` §"Phase 6 — Evaluate".
- Sibling role (pre-execute): `20-roles/pre-check.md`.

---
