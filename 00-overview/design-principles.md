---
id: 00-overview/design-principles
title: Design Principles
purpose: knowledge-spec
audience: [orchestrator, planner, truthsayer, pre_check, executor, evaluator, kb_linter, wiki_ingest, wiki_query, meta_review, apply_meta]
status: stable
version: 2.9
last_reviewed: 2026-05-04
extracted_from:
  source: synthesis
  sections: ["§3 Architecture Overview", "§10 Knowledge Base Architecture (Two-Layer Karpathy + Process Learning Extension)", "§22 Harness Assumption Decay Protocol", "§24 Claude Code Harness Integration"]
  line_range_hint: "synthesis: §3 (file-based memory + adversarial wiring), §10 (raw/+wiki/+knowledge/ separation), §22 (decay decision outcomes), §24 (folder-specific CLAUDE.md hierarchy)"
depends_on:
  - 00-overview/invariants.md
  - 00-overview/philosophy.md
related:
  - 00-overview/system-map.md
  - 10-pipeline/iteration-lifecycle.md
  - 10-pipeline/quality-gates.md
max_lines: 120
directives:
  must_count: 0
  should_count: 0
  may_count: 0
---

## Design Principles

These are the recurring decision patterns the architecture encodes. They are **derived from** the philosophy (`00-overview/philosophy.md`) and **enforced by** the invariants (`00-overview/invariants.md`). When the architecture appears to over-constrain a use case, the answer is almost always to honour the principle and find a different shape — not to relax the principle.

### 1. File-based memory before conversational memory

All inter-agent state lives in files under `iterations/current/` (active) and `iterations/archive/iter-NNN/` (history). Conversation context is volatile; files survive `/clear`, agent restarts, model swaps, and human review.

**When the principle applies**: any time two agents need to share state. Even if both agents are Claude workers in the same orchestrator session, the state goes to a file — not to a parent prompt.

**Trade-off**: file I/O is slower than passing context. The pipeline accepts the latency because the alternative is context amnesia (failure mode #3) and audit-trail loss.

### 2. Adversarial wiring over collaborative wiring

The TruthSayer's mandate is "find what is wrong, weak, or missing — not here to praise" (Invariant 2). The Evaluator runs on a different model family from the Executor whenever possible. The pre-check Evaluator signs the contract before execution starts.

**Why**: collaborative agents converge on consensus quickly but converge on the wrong answer just as quickly. Adversarial agents disagree more, surface more issues, and produce slower-to-write but durable outputs.

**When the principle applies**: at every role boundary in §6. If two adjacent roles share an instinct to agree, the wiring is wrong.

### 3. Temporal facts over current-state facts

Rules in `knowledge/methodology/rules.md` carry `valid_from`, `invalidated_at`, and provenance. A new contradicting observation **never** overwrites an old rule — it creates a new rule and stamps the old one `invalidated_at = now()`.

**Why**: a current-state KB cannot answer "what did we believe last sprint, and what changed?" Without that, contradiction-resolution and meta-review cannot work.

**When the principle applies**: anywhere a fact has a producer, a confidence level, or a source. The protocol is documented in §13 and enforced by the KB Linter.

### 4. Karpathy two-layer + process-learning extension

- **Layer 1 — `sources/`**: immutable raw input. Never modified after initial save (Invariant 8).
- **Layer 2 — `wiki/`**: domain knowledge synthesised from sources. Karpathy original.
- **Process-learning extension — `knowledge/`**: meta-learning about how this project gets built. Distinct from the wiki because it is process truth, not domain truth.

The extension is the project's, not Karpathy's — §10 is renamed accordingly.

### 5. Selective retrieval over bulk loading

Per §20 / wiki-recall data: bulk-loading a >200-page wiki into every agent's context costs ~70k tokens, triggers the lost-in-the-middle attention effect, and degrades retrieval quality for facts that land in the middle of the load. The Three-Tier Memory Model (Tier 1 always-loaded ≤200 lines, Tier 2 selective, Tier 3 search-fallback only) achieves ~93% recall at ~98.4% token reduction.

**When the principle applies**: every dispatch. Bundle assembly (Layer 3) is the architectural manifestation — each role gets exactly the files it needs, never the monolith.

### 6. Mechanical maintenance gets cheaper models, fact-producing work gets frontier

Per §17 model tiering: ingest, planning, audit, pre-check, evaluation, execution → frontier. KB linting, simple wiki updates, batch re-ingest of already-processed sources → mid-tier. The asymmetry is real: a $0.20 saving on a lint pass is dwarfed by a $3 rework cost when a mid-tier model misses a contradiction during ingest.

### 7. Harness components decay

Per §22: every protective scaffold this blueprint mandates is a model-version snapshot. As models improve, some scaffolds (verbose schema validation, explicit reward-hacking checks, format compliance prompts) become redundant. The harness audit cadence (`min(25 iterations, 6 months)`) is when each component is reviewed against `compensates_for` and `evidence_threshold` frontmatter — outcomes are RETAIN, DOWNGRADE (mandatory → advisory), or ARCHIVE (remove + record specification).

**Why this is a design principle, not a roadmap item**: a system that cannot retire its own scaffolds eventually drowns in them. The decay protocol is the structural countermeasure.

### 8. Orchestrator authority is the keystone

Per Invariant 9: the orchestrator role is non-delegable. `claude-main` exclusively writes PROGRESS.md, the verification ledger, escalations, and pipeline state. Why this is a principle rather than a convention: any agent that could promote itself to orchestrator mid-pipeline could approve its own output by writing PROGRESS.md, defeating Invariant 1. The orchestrator's authority over state is what makes the trust model coherent.

### 9. Pre-action fact presentation is propagated by inheritance

Per Invariant 10 (v2.9): every state-mutating tool call must be preceded by a user-visible statement of the current request and what the action verifies/produces. Adapters that cannot enforce this gate are restricted to read-only roles. The PROPAGATION clause means any project loading `agents.config.yaml` inherits the gate — adopting projects do not need to re-derive it.

### What is NOT a design principle here

- "More verification = better" — see philosophy.md.
- "Configurability over convention" — every knob in `agents.config.yaml` has a documented failure mode it addresses; configurability without that grounding is overhead.
- "Backwards compatibility forever" — `SYSTEM-BLUEPRINT-v{N}.md` snapshots preserve old contracts for adopters who pinned them, but the canonical reference moves forward. v2.x → v3.0 is a deliberate architectural break (monolith → bundles).

---
