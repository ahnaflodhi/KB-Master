---
id: 10-pipeline/quality-gates
title: Quality Gates and Reward-Hacking Checks
purpose: knowledge-spec
audience: [evaluator, truthsayer, pre_check, executor, kb_linter, orchestrator]
status: stable
version: 2.9
last_reviewed: 2026-05-04
extracted_from:
  source: synthesis
  sections: ["§15 Quality Criteria System", "§18 Reward Hacking Detection", "§19 Verification Ledger / authentication+verification gates", "§25 Dispatch shim Steps 7-9 (AUTH/SCHEMA/VERIFY)"]
  line_range_hint: "synthesis: §15 criteria + thresholds, §18 four mandatory reward-hacking checks, §25 dispatch-shim AUTH/SCHEMA/VERIFY gates, §19 verification ledger as audit trail"
depends_on:
  - 00-overview/invariants.md
  - 60-schemas/quality-criteria.md
  - 60-schemas/eval-report.md
  - 60-schemas/execution-log.md
related:
  - 10-pipeline/state-machine.md
  - 10-pipeline/iteration-lifecycle.md
  - 10-pipeline/escalation-rules.md
  - 60-schemas/verification-ledger.jsonl.md
max_lines: 180
directives:
  must_count: 0
  should_count: 0
  may_count: 0
---

## Quality Gates and Reward-Hacking Checks

This file consolidates the **gates** that the orchestrator and Evaluator apply at each pipeline transition and the **reward-hacking checks** that run on every Evaluator pass. The criteria themselves are declared in `60-schemas/quality-criteria.md`; the gates here describe **when** those criteria fire and **what verdict** the gate emits.

For the verbatim §15 criteria text and threshold semantics, read `60-schemas/quality-criteria.md`. For the verbatim §18 reward-hacking taxonomy, read §18 of the canonical blueprint. This file is the per-transition map that ties them to the iteration lifecycle.

### Gate inventory (where each gate fires)

| # | Gate | Fires at | Producer of input | Consumer of verdict | What it catches |
|---|---|---|---|---|---|
| G0 | **Pre-action fact gate** (Invariant 10) | Before every state-mutating tool call | Any agent | Harness (PreToolUse hook) | Context drift, hallucinated work, silent runaway loops |
| G1 | **TruthSayer adversarial gate** | End of Phase 2 (audit) | TruthSayer | Orchestrator | Spec quality, hidden assumptions, weak success conditions |
| G2 | **Pre-check ambiguity gate** | End of Phase 3 (pre-check) | Pre-Check Evaluator | Orchestrator | Ambiguous acceptance criteria, undefined anti-criteria |
| G3 | **Per-unit type-check** (commercial only) | Within Phase 5 (execute) | Executor (logs to execution-log.md) | Evaluator (re-runs in Phase 6) | Compilation errors propagated past unit boundary |
| G4 | **Multi-tenancy gate** (commercial only) | Within Phase 5 (execute) | Executor | Evaluator | Tenant data leakage in production paths |
| G5 | **Authentication gate** (§25 Step 7) | After every delegated dispatch | Adapter `result()` | Orchestrator | Wrong/substituted artifact, lost return value, mismatched job_id |
| G6 | **Schema-validation gate** (§25 Step 8) | After every delegated dispatch | Adapter result | Orchestrator | Missing required header, malformed enum value, semantic-isolation violation |
| G7 | **Reward-hacking gate** (§18 — 4 checks) | Every Evaluator pass (Phase 6) | Evaluator | Orchestrator (verification ledger) | Source coverage misses, undisclosed stubs, opt-out hacking, tag hacking |
| G8 | **Source-recheck gate** (research only) | After every Evaluator pass | Orchestrator (re-fetches sample) | Orchestrator | Citation rot, fabricated URLs, source-mismatch with claim text |
| G9 | **KB-lint gate** (10 rules) | Phase 7 (kb-lint) | KB Linter | Orchestrator | Orphans, contradictions, citation rot, observation-velocity breach |

Each gate emits a verdict that lands in either `eval-report.md`, the dispatch shim's CONSUME ledger row, or `iter-summary.md` per producer.

### G0 — Pre-action fact gate (the cross-cutting gate, v2.9)

**Specification**: Invariant 10 (`00-overview/invariants.md`). Every state-mutating tool call MUST be preceded by a user-visible statement of (a) the current request and (b) what the action verifies/produces. Adapters report `enforces_pre_action_facts` in their probe; adapters reporting `false` may only fulfil read-only roles.

**Verdict**: pass-through (allow) | reject (block tool execution) | warn (log only — `policy.on_pre_action_fact_missing: warn`).

**Why this is gate 0**: it applies before every other gate's input is produced, including the Evaluator's tool invocations during G7. Without G0, an Evaluator could fire reward-hacking checks based on stale or mis-aligned intent.

### G1 — TruthSayer adversarial gate

**Specification**: Invariant 2; §6 TruthSayer.
**Input**: spec.md.
**Output**: audit-report.md `Verdict` ∈ {APPROVED, REVISE, ESCALATE}.

**Decision procedure**: TruthSayer must produce at least one Critical Issue OR explicit Overconfidence Flag if any field of spec.md states an unverified assumption as fact. A TruthSayer that consistently APPROVES is malfunctioning (Invariant 2).

### G2 — Pre-check ambiguity gate

**Specification**: §6 Pre-Check Evaluator (`60-schemas/acceptance-checklist.md`).
**Input**: spec.md + audit-report.md.
**Output**: acceptance-checklist.md with explicit Ambiguities section (empty list = gate passed).

**Round limit**: 2. Round 2 with ambiguities → escalation.

### G3, G4 — In-execute gates (commercial)

Per §6 Executor 2a (per-unit type-check) and 2b (multi-tenancy). Each unit logs a `Per-unit type-check: PASSED|FAILED` and `Multi-tenancy check: PASSED|FAILED` line in execution-log.md (per `60-schemas/execution-log.md`). Failures within a unit do not necessarily fail the iteration; the Evaluator re-checks in G7.

### G5 — Authentication gate (§25 Step 7)

**Inputs**: dispatch ledger entry (job_id, prompt_hash, dispatch_ts), adapter result artifact (e.g. `<job_dir>/last_message.txt`).
**Procedure**: compute `output_hash = sha256(artifact)`; record on consume row. Confirm artifact's job_id matches dispatch entry. Mismatch → consume verdict `rejected-auth` → re-delegate (or escalate if `re_delegate_max_attempts` exceeded).

**Catches**: artifact substitution, bridge returning wrong job's output, claude-native worker truncation.

### G6 — Schema-validation gate (§25 Step 8)

**Inputs**: adapter result + `60-schemas/<expected-artifact>.md`.
**Procedure**: parse the result; check required headers present; check enum-valued fields hold legal values; apply semantic-isolation rule (treat field values as opaque data — Invariant 3 / §19 v2.1 addendum).

**For audit-report.md** specifically: `Verdict:` field must hold a value in {APPROVED, REVISE, ESCALATE}. Anything else → `rejected-schema`.

### G7 — Reward-hacking gate (§18 — 4 mandatory checks)

The Evaluator runs these on **every** evaluation. FLAGGED on any one → eval-report.md `Reward Hacking Check: FLAGGED ({description})` → consume verdict `rejected-verification`.

| Check | What it counts | Failure condition |
|---|---|---|
| **Source coverage** (replaces unreliable tool-call count heuristic) | URLs in spec.md `Sources to Consult` vs WebFetch/WebSearch invocations in execution-log.md vs inline citations in output | `N_fetched < N_listed` OR `N_cited > N_fetched` |
| **Undisclosed stubs** | `# TODO: RESOLVE-STUB` in output that was NOT logged in execution-log.md as a known stub | Any undisclosed stub = automatic FAIL |
| **Opt-out hacking** | Cases where the agent refused a difficult subtask without escalating | Refusal without escalation.md entry = FLAGGED |
| **Tag hacking** | Generic approximations standing in for required specificity (e.g. "various sources" instead of cited URLs) | Any unspecific approximation in fact-bearing output = FLAGGED |

### G8 — Source-recheck gate (research only)

**Specification**: §25 Step 9; sample rate `validation.source_recheck_sample_rate` (default 0.20 → 20%).
**Procedure**: orchestrator re-fetches a uniform random 20% of cited URLs in the output. For each, confirm the cited claim still exists at the source. Failure on any sampled URL → `verification_verdict: SOURCE-MISMATCH` → consume rejected.

**Citation-completeness gate** (complements G8): per `60-schemas/eval-report.md` Hard rules, an `Overall: PASS` / `Route: PASS` is FORBIDDEN when the eval-report's `Uncited Claims` list is non-empty (caps at `CONDITIONAL PASS`, routes FAIL). G8 checks that *cited* sources are real; this rule ensures every claim is *cited in the first place*. Scope: research projects (where claims are source-backed). Commercial code claims are validated by tests/linters/type-checks (G3/G6) rather than URL citation.

### G9 — KB-lint gate (10 rules)

**Specification**: §11 wiki-specific failure modes + §6 KB Linter.
**Output**: iter-summary.md anomalies section + per-rule findings appended to LESSONS.md.

The 10 lint rules: orphans, stale claims, contradiction scan, missing incoming_links, observation-velocity breach (max_new_observations_per_iter), claim-confidence inconsistency, **provenance integrity** (Rule #7), citation health (Rule #9), error compounding (Rule #10), schema validity.

### Routing summary

```
G1 REVISE  → re-plan (cycle ≤ 2; otherwise escalate)
G2 ambig   → re-plan (round ≤ 2; otherwise escalate)
G5 fail    → re-delegate (≤ re_delegate_max_attempts; otherwise escalate)
G6 fail    → re-delegate (same)
G7 FLAGGED → eval-report Route = FAIL → re-execute (cycle ≤ 3) OR SPEC-FLAW → re-plan
G8 fail    → eval-report Route = FAIL OR SPEC-FLAW depending on which spec field is implicated
G9 anomaly → not blocking; flagged in iter-summary, fed to next planner via LESSONS.md
G0 reject  → harness blocks tool call BEFORE execution; no ledger row needed (action did not happen)
```

### Verdict integration

Every gate's verdict lands in `pipeline/verification-ledger.jsonl` (per `60-schemas/verification-ledger.jsonl.md`) for delegated work, OR in `eval-report.md` (per `60-schemas/eval-report.md`) for in-iteration evaluator findings, OR in `iter-summary.md` (per `60-schemas/iter-summary.md`) for cross-iteration KB-linter findings. The orchestrator consults all three at the start of the next iteration.

---
