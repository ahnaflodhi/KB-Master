---
id: 00-overview/philosophy
title: Philosophy — The Failure Modes This System Solves
purpose: knowledge-spec
audience: [orchestrator, planner, truthsayer, pre_check, executor, evaluator, kb_linter, wiki_ingest, wiki_query, meta_review, apply_meta]
status: stable
version: 2.9
last_reviewed: 2026-05-04
extracted_from:
  source: synthesis
  sections: ["§1 Philosophy"]
  line_range_hint: "§1 lines 64-93 — verbatim core problem + two artifacts + key insights, expanded with cross-refs to invariants and downstream files"
depends_on:
  - 00-overview/invariants.md
related:
  - 00-overview/system-map.md
  - 00-overview/design-principles.md
  - 10-pipeline/iteration-lifecycle.md
max_lines: 120
directives:
  must_count: 0
  should_count: 0
  may_count: 0
---

## Why this system exists

Every project with an LLM-assisted workflow faces the same seven failure modes. Each is documented in production systems; each has a structural countermeasure encoded as one or more invariants. The pipeline, the file-based memory, the adversarial role wiring, and the temporal fact tracking are not "features" — they are direct responses to these failure modes.

### The seven failure modes

| # | Failure mode | What it looks like | Countermeasure | Invariant |
|---|---|---|---|---|
| 1 | **Hallucination laundering** | An unverified claim from one source gets cited by a downstream agent, then by another, until it is "confirmed" by repetition. | Claims start in `wiki/claims/unverified/`. Promotion to entity pages requires 2+ independent sources; promotion to `rules.md` requires 3+ confirmations. | INVARIANT 5 |
| 2 | **Sycophancy collapse** | The Evaluator agrees with the Executor because they share context (or model). Quality scores trend up while real quality stays flat. | The Evaluator runs in a separate context (and ideally a separate model family) from the Executor. The TruthSayer is explicitly adversarial. | INVARIANT 1, 2 |
| 3 | **Context amnesia** | An insight from iteration 3 is forgotten by iteration 8 because it never made it into a persistent file. | All inter-agent state lives in `iterations/current/`. LESSONS.md preserves cross-iteration learnings. KB Linter writes `iter-summary.md` on every iteration. | INVARIANT 3 |
| 4 | **Spec drift** | What gets built diverges from what was agreed because the spec changed silently between phases. | Sprint contract is written AFTER pre-check-complete and signed by the Evaluator. The Evaluator's later judgments must reference the signed acceptance-checklist.md, not re-interpret the spec. | INVARIANT 4 |
| 5 | **Gap blindness** | Unverified assumptions remain invisible until they break production. | Every assumption is logged to `knowledge/gaps/knowledge.md`. TruthSayer flags `Overconfidence Flags` in audit-report.md. | §6 TruthSayer / §15 |
| 6 | **Fact corruption** | An outdated fact silently overrides a correct one because facts have no temporal metadata. | Rules carry `valid_from`/`invalidated_at` timestamps. Contradicting evidence creates a new rule and marks the old one invalidated — never overwrites. | INVARIANT 6 |
| 7 | **Reward hacking** | The agent satisfies the Evaluator's surface checks (test passes, cited sources) without solving the real problem. | The Evaluator runs four mandatory reward-hacking checks (source coverage, undisclosed stubs, etc.) on every evaluation. Tool-use is required (no static-only PASS). | INVARIANT 7 / §18 |

### The two artifacts that compound

| Artifact | What it captures | Maintained during | Property |
|---|---|---|---|
| **Wiki** (`wiki/`) | What is known about the project's subject domain — entities, claims, contradictions, syntheses | Research, then maintained during build | Never degrades. Cross-references between entities are the primary value, not page depth. Every page has a source citation, confidence level (SINGLE-SOURCE → CROSS-VERIFIED → CONFIRMED), and `created_at`. |
| **Knowledge base** (`knowledge/`) | What the team has learned about how to build this project — observations → hypotheses → confirmed rules | Every iteration, via the KB Linter promotion pipeline | Size-capped to stay dense (30 obs / 15 hyp / 20 rules per §12). Every fact carries temporal metadata + provenance back to its raw source. Audit trail, not current-state snapshot. |

The wiki answers "what does the world look like." The knowledge base answers "what works in this project." Conflating them collapses both — the wiki bloats with process notes; the KB drifts toward domain trivia. Keep them separate.

### Three key insights (architectural, not advisory)

1. **Generator ≠ Evaluator** (INVARIANT 1). The agent that produces output cannot evaluate that output. This is structural, not instructional. One agent's ceiling is another agent's floor to challenge. A pipeline where one context plays both roles inevitably produces sycophancy collapse — even with good prompts.

2. **Sprint contract before execution** (INVARIANT 4). The Evaluator reviews the Planner's spec and signs off on acceptance criteria *before* the Executor begins. The Evaluator's later judgments must reference this signed checklist — not re-interpret the original spec. This eliminates the most common non-convergence failure: re-litigating "what did we agree to" cycle after cycle.

3. **Temporal facts, never silent overwrites** (INVARIANT 6). Old facts are marked `invalidated`, not deleted. The KB is an audit trail, not a current-state snapshot. If you cannot answer "when did we believe X, and what changed?", the audit trail is broken — and so is the rule-promotion pipeline that depends on it.

### What this philosophy is NOT

- It is not "more agents = better." Adding agents without role separation just multiplies the same failure modes.
- It is not "more prompts = better." The system replaces prompt engineering with structural separation; complex prompts inside the wrong structure still fail.
- It is not "more verification = better." Each verification gate has a documented failure mode it catches (§25 Gate 1 + Gate 2). Adding gates that don't catch a documented mode is overhead, not safety.

### Where this lands in the codebase

- The seven failure modes → 10 invariants (`00-overview/invariants.md`).
- The two artifacts → wiki + knowledge directories (`00-overview/system-map.md`).
- The three insights → six-file inter-agent chain + adversarial role wiring + temporal-fact protocol (`10-pipeline/file-contracts.md`, `60-schemas/*`).

---
