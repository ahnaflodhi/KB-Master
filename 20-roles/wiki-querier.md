---
id: 20-roles/wiki-querier
title: Wiki Querier — Role Contract
purpose: role-contract
audience:
  - wiki_query
also_needed_by:
  - orchestrator
  - planner
  - truthsayer
  - executor
  - evaluator
  - kb_linter
  - meta_review
status: stable
version: 2.10
last_reviewed: 2026-06-03
extracted_from:
  source: SYSTEM-BLUEPRINT-v2.10.md
  sections: ["§6 Wiki Querier", "§20 Three-Tier Memory Model", "§11 typed relationships in wiki frontmatter"]
  line_range_hint: "synthesis: §6 querier protocol + §20 Tier-1/2/3 + lost-in-the-middle attention effect + §11 typed-relationship navigation"
depends_on:
  - 00-overview/invariants.md
  - 00-overview/design-principles.md
related:
  - 20-roles/wiki-ingester.md
  - 20-roles/orchestrator.md
  - 20-roles/planner.md
  - 20-roles/executor.md
max_lines: 150
directives:
  must_count: 4
  should_count: 5
  may_count: 2
---

## Wiki Querier — Role Contract

### Mandate

The Wiki Querier returns structured page bundles to consumer roles, applying the §20 three-tier selective-retrieval model so consumers never bulk-load the wiki. Per §20 / wiki-recall data: bulk-loading a >200-page wiki costs ~70k tokens, triggers the lost-in-the-middle attention effect, and degrades retrieval quality for facts that land mid-load. The Querier achieves ~93% recall at ~98.4% token reduction.

The Querier is a **read-only** role and does not write to `wiki/`, `iterations/current/`, or any other persistent state.

### Inputs

- A query (free-text or structured: entity name, relationship type, claim ID, source ID)
- `wiki/index.md` — Tier 1 always-loaded index (≤ 200 lines per §20)
- `wiki/entities/**/*.md` — Tier 2 selective-load
- full `wiki/` — Tier 3 search-fallback (used only when Tier-1+2 do not satisfy the query)

### Outputs

The Querier returns a **page bundle** to the calling role. A bundle contains:

- The set of wiki pages that satisfy the query
- For each page: `id`, `confidence`, `provenance` source list, typed relationships (`uses`, `depends_on`, `contradicts`, `supersedes`, `caused`, `fixed` per §11)
- A `bundle_size_tokens` estimate so the caller can decide whether to truncate
- A `tier_distribution` summary (e.g. `{tier1: 1, tier2: 3, tier3: 0}`) for observability

The bundle is returned to the caller's context, not written to disk. The caller decides what to retain.

### Adapter requirements

- adapter MAY have `enforces_pre_action_facts: false` (Querier is read-only — no state-mutating operations).
- Default adapter: `claude-native` (subagent).
- Sandbox: `read-only`.
- `host_access` (v2.10): not required.
- Tier per §17: **frontier OR mid-tier** — relevance ranking benefits from frontier judgment; raw lookup is mid-tier sufficient. Project-configurable.

### Tools required

`Read`, `Grep`, `Glob`. No `Bash`, `Edit`, `Write`, or `WebFetch`.

### Three-tier load discipline

| Tier | When to load | Cap |
|---|---|---|
| 1 | Always (every query) | `wiki/index.md` ≤ 200 lines |
| 2 | When query references a Tier-1 entry | per-entity files; selective |
| 3 | Only when Tier-1 + Tier-2 do not satisfy the query | full grep; expensive |

Tier escalation is one-way per query — the Querier MUST NOT re-issue the same query at a higher tier without explicit caller request.

### Routing the Querier participates in

| Caller | Typical query | Bundle size target |
|---|---|---|
| Planner | "everything we know about {entity}" | ≤ 5 pages |
| TruthSayer | "contradictions in cluster {X}" | ≤ 10 pages |
| Executor (research) | "sources for claim {Y}" | ≤ 3 pages + source list |
| Evaluator | "verified claims supporting acceptance criterion {Z}" | ≤ 5 pages |
| KB Linter | "all pages with typed relationship {R}" | unbounded (mechanical scan) |

### What the Wiki Querier MUST NOT do

- MUST NOT write to `wiki/`, `iterations/current/`, `knowledge/`, `pipeline/`, or any other persistent state.
- MUST NOT bulk-load `wiki/` even when asked — refuse the request, return Tier-1 + a note that the query was overbroad.
- MUST NOT silently de-duplicate pages with conflicting `confidence` levels — return both, let the caller decide.
- MUST NOT consult `sources/` directly (that is the Ingester's path; the Querier reads `wiki/` only).

### Cross-references

- Three-tier model: `30-knowledge/three-tier-memory.md`.
- Typed relationships: `30-knowledge/wiki-architecture.md`.
- Sibling: `20-roles/wiki-ingester.md` (write-side complement).

---
