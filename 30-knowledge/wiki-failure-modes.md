---
id: 30-knowledge/wiki-failure-modes
title: Wiki-Specific Failure Modes (§11)
purpose: knowledge-spec
audience:
  - kb_linter
  - wiki_ingest
also_needed_by:
  - orchestrator
  - truthsayer
  - meta_review
  - planner
status: stable
version: 2.10
last_reviewed: 2026-05-04
extracted_from:
  source: SYSTEM-BLUEPRINT-v2.10.md
  sections: ["§11 Wiki-Specific Failure Modes", "§6 KB Linter Rules #1 / #9 / #10"]
  line_range_hint: "synthesis: §11 five failure modes (error compounding / claim drift / false consolidation / citation rot / confidence inflation) + their KB-Linter detection rules"
depends_on:
  - 00-overview/invariants.md
  - 00-overview/philosophy.md
  - 30-knowledge/wiki-architecture.md
  - 30-knowledge/temporal-facts.md
related:
  - 20-roles/kb-linter.md
  - 20-roles/wiki-ingester.md
  - 10-pipeline/quality-gates.md
max_lines: 200
directives:
  must_count: 5
  should_count: 4
  may_count: 1
---

## Wiki-Specific Failure Modes

The seven general failure modes (`00-overview/philosophy.md`) — hallucination laundering, sycophancy collapse, context amnesia, spec drift, gap blindness, fact corruption, reward hacking — are countered by Invariants 1-7. The five failure modes documented here are **wiki-specific**: they emerge when a wiki accumulates over many iterations even though every individual ingest pass appears correct. Each has a documented KB Linter detection pattern (Rules #1 / #9 / #10).

### The five modes

| # | Failure mode | What it looks like | Detection rule | Why it matters |
|---|---|---|---|---|
| 1 | **Error compounding** | Iteration 1 records claim C with low confidence. Iteration 2 cites C as evidence for D. Iteration 3 cites D as evidence for E. By iter 5, E is a "rule" in `knowledge/methodology/rules.md` resting on C's original low-confidence foundation. | KB Linter Rule #10: trace the provenance chain backward — if any link in a rule's chain has `confidence: SINGLE-SOURCE` or is invalidated, flag the descendant rule | Without this check, a single early hallucination ramifies through the rule layer over months |
| 2 | **Claim drift** | A wiki claim's text gets edited iteration over iteration ("API supports OAuth" → "API supports OAuth and SAML" → "API supports all major SSO methods") with each edit individually defensible but the cumulative drift unsupported by the original source | KB Linter Rule #9 (citation health): re-fetch the source URL on the trailing-window cadence; verify the cited claim's text still appears at the source verbatim | Drift is invisible at any single iteration; only longitudinal comparison catches it |
| 3 | **False consolidation** | Two distinct entities (e.g. two competitors with similar names, two APIs with the same endpoint shape) get merged into one wiki page, losing the per-entity nuance | KB Linter Rule #1 (contradiction scan, O(N·k) NLI): when a page's claims include statements that would be true of one entity but false of another, surface as a `wiki/synthesis/contradictions/` entry | Consolidation collapses signal; downstream users get confidently-stated false unification |
| 4 | **Citation rot** | A cited URL still resolves but the original quoted text no longer appears (page edited upstream); or the URL 404s; or the URL redirects to a cookie wall / login page | KB Linter Rule #9 (citation health, sample rate per `validation.source_recheck_sample_rate`): re-fetch sampled URLs each lint pass; flag rot | Citations that look healthy structurally but rot semantically are the most dangerous because Tier-1 readers trust them |
| 5 | **Confidence inflation** | Iteration 1 marks a claim SINGLE-SOURCE. Iteration 3 cites the same claim from a derivative source ("X says ... per source-Y" where source-Y itself was based on source-X). The Linter naively counts 2 sources and promotes to CROSS-VERIFIED | KB Linter independence check: when promoting from SINGLE-SOURCE to CROSS-VERIFIED, verify that the second source's provenance chain does NOT trace back to the first source | Confidence inflation defeats the entire confidence-ladder discipline |

### Why these are *wiki-specific*

The general failure modes (`00-overview/philosophy.md`) emerge from agent dynamics within an iteration. The wiki-specific modes emerge from **artifact accumulation across iterations**. They are invisible at any single decision point; they need longitudinal lint passes to surface. This is why the KB Linter (`20-roles/kb-linter.md`) reads the trailing window of `iter-summary.md` files, not just the current iteration's eval-report.

### Per-failure detection cadence

| Failure mode | Cadence | Source of evidence |
|---|---|---|
| Error compounding (#1) | every Phase-7 KB-Lint pass | `knowledge/methodology/rules.md` provenance chains |
| Claim drift (#2) | per `validation.source_recheck_sample_rate` (default 20%) per pass | re-fetched sample of `wiki/claims/verified/*.md` cited URLs |
| False consolidation (#3) | every pass | `wiki/synthesis/contradictions/` net-new entries; NLI scan output |
| Citation rot (#4) | per source-recheck sample rate | URL fetch results vs. cited text |
| Confidence inflation (#5) | only when the Linter is about to promote | provenance chain of candidate-promotion claim |

### Typed relationships and their role here (§11)

The typed-relationship frontmatter on wiki pages (`uses`, `depends_on`, `contradicts`, `supersedes`, `caused`, `fixed`) is what makes the O(N·k) contradiction scan tractable. Without typed relationships, contradiction-scan is O(N²) NLI over every pair of claims. With typed relationships:

- `contradicts:` makes the contradiction explicit; the Linter only NLI-scans claim pairs where one is in another's `contradicts:` list (k = average contradicts list size)
- `supersedes:` lets the Linter skip pairs where one is documented to replace the other (no contradiction; intentional supersession per Inv 6)
- `depends_on:` lets the error-compounding scan walk the dependency graph

### Detection vs. resolution

The KB Linter detects; it does not resolve. Detection produces:

- A new entry in `wiki/synthesis/contradictions/` for the TruthSayer to consult during the next iteration's audit
- A KB-Lint anomaly row in `iter-summary.md` for the orchestrator
- An optional `escalation.md` if the failure mode crosses a severity threshold (e.g. >3 rules with chains containing invalidated links)

Resolution requires Planner + TruthSayer judgment in a subsequent iteration. The Linter MUST NOT silently fix any of these failure modes — that would defeat the audit trail.

### What the failure-mode framework MUST NOT do

- MUST NOT auto-resolve any of the 5 modes — every detected case becomes an audit artifact, not a silent fix.
- MUST NOT skip Rule #9 (citation health) on a per-pass basis (the sample rate is the cost-control mechanism, not the skip mechanism).
- MUST NOT count derivative-source confirmations as independent (failure mode #5).
- MUST NOT consolidate entities without surfacing the consolidation as a `wiki/synthesis/cross-cluster/` entry for review.
- MUST NOT treat a `confidence: CONFIRMED` claim as immune from re-check — citation rot strikes confirmed claims too.

### Cross-references

- Detection mechanism: `20-roles/kb-linter.md`
- Quality-gate cross-walk: `10-pipeline/quality-gates.md` G9
- Wiki structure these failure modes act on: `30-knowledge/wiki-architecture.md`
- Temporal-fact protocol that the supersedes-tracking depends on: `30-knowledge/temporal-facts.md`
- Broader failure modes: `00-overview/philosophy.md`

---
