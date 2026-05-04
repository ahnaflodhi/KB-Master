# 60-schemas/ — Per-file format reference

This directory holds one file per artifact that flows through the iteration pipeline. Each file is the **authoritative** schema for that artifact: required fields, semantics, validation rules. The 6-file inter-agent communication chain summary lives at `10-pipeline/file-contracts.md`; this directory is the per-file detail those summaries link to.

Like other `_README.md` files in this restructure, this one is intentionally **not** subject to `tools/verify-frontmatter.sh` — it documents the directory's contract rather than being a loadable artifact itself. See `00-overview/_README.md` for the frontmatter standard every schema file in this directory follows.

## Index

| File | Producer | Consumer(s) | Source section | Purpose |
|---|---|---|---|---|
| `spec.md` | Planner | TruthSayer, Pre-Check, Executor, Evaluator | §8 spec.md format | Iteration intent — Hypothesis (research) OR User Story + Acceptance Criteria (commercial), Sources, Success Conditions, Constraints, Decomposition |
| `audit-report.md` | TruthSayer | Planner, Executor, Evaluator | §8 audit-report.md format | Adversarial review of spec.md — Verdict (APPROVED/REVISE/ESCALATE), Critical Issues, Warnings, Missing, Overconfidence Flags |
| `acceptance-checklist.md` | Pre-Check Evaluator | Executor (read), Evaluator (re-read) | §6 Pre-Check Evaluator | Pre-execution acceptance criteria — Deliverable Acceptance Criteria, Quality Thresholds, Anti-Criteria, Ambiguities |
| `contract.md` | Planner | Executor | §8 contract.md format | Sprint contract written AFTER pre-check-complete — Agreed Deliverables + domain-specific acceptance standards |
| `eval-report.md` | Evaluator | KB Linter, Archive | §8 eval-report.md format | Evaluation verdict — Cycle, Route (PASS/FAIL/SPEC-FLAW/ESCALATE), Tools Used, Scores, Reward Hacking Check, Feedback for Executor |
| `escalation.md` | Any agent | Human-in-loop, orchestrator | §16 escalation.md Format | DEADLOCK ESCALATION block + Response Routing — emitted on cycle exhaustion, spec-flaw repeat, or budget exhaustion |
| `iter-summary.md` | KB Linter | Meta-Review, Archive | §6 KB Linter / §12 / §21 | 15-line cap. One-iteration recap — what was built, what was learned, what should be promoted to LESSONS.md or rules.md |
| `execution-log.md` | Executor | Evaluator, KB Linter | §6 Executor / §8 / §14 | Append-only record of executor tool invocations, fetched sources, multi-tenancy gates, stubs (`# TODO: RESOLVE-STUB`), per-unit type-check results |
| `quality-criteria.md` | (config — declared in PROJECT.md) | Evaluator | §15 Quality Criteria System | Declarative criteria + thresholds the Evaluator scores against — Standard Research, Standard Commercial, Threshold Semantics |
| `verification-ledger.jsonl` | Orchestrator (claude-main, exclusive — Invariant 9) | Meta-Review, debug | §19 Verification Ledger | Append-only audit trail. Two rows per delegation: dispatch (records prompt_hash, sandbox, model, config_revision, job_id, target_path) + consume (records output_hash, auth_verdict, schema_verdict, verification_verdict, reward_hacking_check, final_verdict) |

## Schema vs implementation

These files describe the **canonical shape** of each artifact. The actual files agents produce live in `iterations/current/<artifact>` and the orchestrator-managed `pipeline/verification-ledger.jsonl`. Schema validation in the §25 dispatch shim (Step 8) consults these files: a delegated agent's output is compared against the schema declared here before consume.

## How to add a new schema

1. Identify the section of `SYSTEM-BLUEPRINT.md` (or a derived Layer-2 file) that defines the new artifact.
2. Write the file with the standard frontmatter (see `00-overview/_README.md`).
3. Add an Index row above.
4. Add the role(s) that consume the new artifact to the relevant `bundles/<role>.yaml` (Phase 5).
5. Update `10-pipeline/file-contracts.md` to reference the new schema if the artifact participates in the 6-file chain.

## Cap

`max_lines: 100` per file in this directory (per `00-overview/_README.md` per-directory caps). A schema that needs more than 100 lines is a sign that the artifact has too many responsibilities — split it.
