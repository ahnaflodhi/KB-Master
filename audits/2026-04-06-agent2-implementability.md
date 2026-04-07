# Implementability & Completeness Audit — Agent 2
**Date**: 2026-04-06 | **Verdict**: REVISE

## Critical Implementation Gaps

**Gap 1: 11 of 12 command files missing** — Only pre-check.md exists. CLAUDE.md lists all 11 others as if they exist. templates/ and adoption-guides/ directories are empty. Repository misrepresents its completeness state. Adopters told to copy files that aren't there.
Fix: Write 11 missing command files OR add explicit note that adopters must generate them from Section 6/9 descriptions.

**Gap 2: Token self-estimation is a fabricated capability** — Claude API has pre-send counting endpoint but NO post-execution readback. Agents cannot read their own running session total. "Rough estimate is acceptable" produces incompatible implementations. Two agents will produce entirely different estimates.
Fix: Harness (iterate.sh) tracks session token usage via API response `usage` objects and writes running total to PROGRESS.md externally.

**Gap 3: No global iteration cap — infinite SPEC-FLAW loop** — SPEC-FLAW explicitly resets audit cycle counter. A legal infinite loop: Evaluator → SPEC-FLAW → Planner → TruthSayer (2 fresh cycles) → Executor → Evaluator → SPEC-FLAW → repeat. Quick Reference says "SPEC-FLAW twice → ESCALATE" but this is absent from Evaluator role definition (Section 6). Inconsistency.
Fix: Add `spec_flaw_count` to PROGRESS.md (never reset). Define: spec_flaw_count >= 2 → ESCALATE regardless of cycle counters.

**Gap 4: contract.md has no specified author** — INVARIANT 4 requires agreed contract.md. The pipeline has [CONTRACTED] state but no command creates it. Executor "proposes" it but no agent is assigned responsibility.
Fix: Add to Planner role: "After TruthSayer APPROVED, Planner writes contract.md from the spec's Decomposition list."

**Gap 5: pre-check ambiguity loop has no exit condition** — "Does not count as audit cycle" and no limit stated. A vague project objective creates perpetual ambiguity. Consumes tokens without any escalation trigger.
Fix: Add `pre_check_cycle_current` to PROGRESS.md, max 2 ambiguity resolution rounds before auto-escalation as "spec-too-vague."

## Underspecified Components

**KB eviction quality score formula undefined** — Four terms listed (recency × citation_frequency × confidence_score × information_density) with no units. Two agents produce different eviction rankings.
Fix: Define each term: recency = 1/(1+iterations_since_last_validated); citation_frequency = count of incoming_links; confidence_score = SINGLE-SOURCE=1, CROSS-VERIFIED=2, CONFIRMED=3; information_density = count of inline citations in page.

**Tier 2 "load on demand" — no decision procedure** — "Agent retrieves based on current task" is entirely agent judgment. Two agents loading Tier 2 for same spec will load different subsets.
Fix: Add explicit retrieval trigger table per agent role.

**CROSS-VERIFIED vs CROSS-VERIFIED contradiction — no deferred path** — Algorithm escalates to human for 60%+ of mature KB contradictions. Pipeline permanently stalls.
Fix: Allow pipeline to continue with CONTESTED flag. Log to synthesis/contradictions/. Escalate immediately only if contradiction affects current iteration's contract.md.

**pipeline.log.jsonl — 3 examples not a schema** — Only wiki_write, rule_promoted, rule_invalidated events shown. All other event types undefined. Two Executors will log different names for same operations.
Fix: Add complete event type enumeration with required fields.

**incoming_links frontmatter — no update trigger** — Required field but no agent assigned to maintain it. Orphan detection and eviction formula both depend on it being accurate.
Fix: Add to KB Linter checklist: scan all written pages for outgoing links, verify linked pages have the linking page in incoming_links.

**Pre-check ambiguity exit condition missing** — No limit on ambiguity resolution loop.

## Operationally Vague Sections

- Harness decay: "What model limitation does this compensate for?" — historical data never recorded at component creation time. Add `compensates_for` and `evidence_threshold_for_removal` frontmatter to each command file.
- Independence test tie-breaker: When in doubt, apply organizational test (controlled by different organizations with independent editorial judgment). Log judgment in claim frontmatter.
- Harness audit cadence: iteration-based vs model-capability timing mismatch. Should be time-based OR iteration-based, whichever comes first.
- Reward hacking Check 1 speed threshold: "5+ tool calls" is uncalibrated. Replace with output-based checks.

## Confirmed Implementable
- spec.md format (all headers clear, unambiguous)
- audit-report.md format (verdict taxonomy crisp, cycle limit stated)
- eval-report.md format (route decisions fully enumerated)
- Rule/hypothesis/observation formats (temporal metadata fully specified)
- quality-criteria.json (both templates complete, weight semantics defined)
- Contradiction resolution steps 1 and 3 (temporal comparison and auto-resolution)
- escalation.md format (4 response options and routing fully specified)
- Size caps (numeric caps and overflow actions specific)
- commands/pre-check.md (well-specified, two independent implementations would be compatible)
- INVARIANT 7 (Evaluator tool use — binary criterion, concrete enough)

## Framework Comparison Gaps
- LangGraph: machine-readable typed state schema (not prose); mid-iteration checkpoint/resume on crash
- CrewAI: expected_output field per task degrades gracefully even without perfect Evaluator
- AutoGen: code-level termination predicates (not prose instructions)
- All frameworks: explicit retry policy for technical failures (network error, rate limit, partial output) — blueprint only handles semantic failures

## Priority Fixes
1. Write 11 missing command files (or add explicit "must generate" caveat)
2. Add spec_flaw_count + pre_check_cycle_current to PROGRESS.md
3. Add escalation caps for both loops
4. Specify Planner writes contract.md
5. Replace token self-estimation with harness-level tracking
6. Define KB eviction formula terms
7. Add deferred resolution for CROSS-VERIFIED contradictions
8. Add incoming_links to KB Linter checklist
9. Add compensates_for frontmatter to command files
10. Output-based reward hacking checks
11. Dual trigger for harness audits (iterations OR calendar time)
12. Full pipeline.log.jsonl event schema
13. Machine-readable inter-agent file schemas
14. Technical failure protocol (network errors, tool call exceptions)
