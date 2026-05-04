---
id: 30-knowledge/wiki-architecture
title: Wiki Architecture (Karpathy Two-Layer + Project Structure)
purpose: knowledge-spec
audience:
  - wiki_ingest
  - wiki_query
also_needed_by:
  - orchestrator
  - executor
  - kb_linter
  - planner
  - meta_review
status: stable
version: 2.10
last_reviewed: 2026-05-04
extracted_from:
  source: SYSTEM-BLUEPRINT-v2.10.md
  sections: ["§10 Knowledge Base Architecture (two-layer Karpathy + process learning extension)", "§4 Directory Structure", "§14 archive-on-ingest", "§11 typed relationships"]
  line_range_hint: "synthesis: §10 layer split + §4 per-cluster shape + §14 archive + §11 relationship typing"
depends_on:
  - 00-overview/invariants.md
  - 30-knowledge/temporal-facts.md
related:
  - 20-roles/wiki-ingester.md
  - 20-roles/wiki-querier.md
  - 30-knowledge/three-tier-memory.md
  - 30-knowledge/wiki-failure-modes.md
max_lines: 200
directives:
  must_count: 6
  should_count: 4
  may_count: 1
---

## Wiki Architecture

This file documents the structure and rules of the project's `wiki/` directory — the synthesised domain knowledge that compounds across iterations. The architecture follows Karpathy's two-layer separation strictly: `sources/` is immutable raw input (per Invariant 8), `wiki/` is the synthesised view, and they never collapse into each other.

### The two layers

| Layer | Path | Mutability | Producer |
|---|---|---|---|
| **Layer 1 — Raw input** | `sources/research/iter-NNN/` | immutable after first save (Inv 8) | Executor (research) via WebFetch/WebSearch — saves BEFORE any claim is extracted |
| **Layer 2 — Synthesised wiki** | `wiki/` | mutable via Wiki Ingester only | Wiki Ingester reads sources, creates wiki entries, stamps provenance |

The KB Linter then promotes claims through verification ladders (see `temporal-facts.md`). No agent — including the orchestrator — may modify Layer 1.

### Per-cluster wiki shape

```
wiki/
├── index.md              ← Tier-1 always-loaded (≤ 200 lines per §20)
├── log.md                ← append-only one-line per iteration
├── entities/             ← per-entity pages
│   ├── competitors/
│   ├── apis/
│   ├── markets/
│   ├── tools/
│   └── buyers/
├── concepts/             ← cross-entity concepts
├── synthesis/
│   ├── contradictions/   ← KB Linter writes; surfaced to TruthSayer
│   ├── feasibility/      ← Planner consults during plan formation
│   └── cross-cluster/    ← spans multiple entity clusters
└── claims/
    ├── unverified/       ← SINGLE-SOURCE; awaiting promotion
    └── verified/         ← CROSS-VERIFIED + CONFIRMED
```

The `entities/` taxonomy (competitors/apis/markets/tools/buyers) is project-conventional — research projects use it as documented; commercial projects MAY use a different sub-clustering as long as the principle (one entity = one page) holds.

### Wiki page frontmatter requirements

Every page under `wiki/` MUST carry:

```yaml
id: <stable-hook>                 # path without .md; survives directory moves
created_at: <ISO-8601 date>       # YYYY-MM-DD
confidence: SINGLE-SOURCE | CROSS-VERIFIED | CONFIRMED
provenance:                        # source-id list — every claim must be traceable
  - <source-id-1>
  - <source-id-2>
incoming_links: <int>             # number of other wiki pages that link to this one
```

Per §11, pages SHOULD also carry typed relationships when applicable:

```yaml
uses: [<page-id>...]              # this entity uses these
depends_on: [<page-id>...]        # this entity depends on these
contradicts: [<page-id>...]       # surfaces a contradiction
supersedes: [<page-id>...]        # this page replaces an older one (Inv 6)
caused: [<page-id>...]            # incident-style causation
fixed: [<page-id>...]             # resolution
```

Synthesis pages additionally carry `synthesised_from: [page-id]` listing the entity pages they aggregate.

### Confidence ladder

| Tier | Required evidence | Promotion authority |
|---|---|---|
| **SINGLE-SOURCE** | one source; default for new claims | Wiki Ingester writes initially |
| **CROSS-VERIFIED** | ≥ 2 independent sources confirm | KB Linter promotes |
| **CONFIRMED** | ≥ 3 confirmations across iterations | KB Linter promotes |

A claim MUST start in `wiki/claims/unverified/` regardless of how confident the source feels. Promotion is the KB Linter's job during Phase 7, not the Ingester's. This separation prevents the Ingester from inflating confidence at write-time.

### Archive-on-ingest (§14)

Every Wiki Ingester run MUST produce an archive-on-ingest record per source it consumes:

```yaml
ingest_id: <ULID>
source_id: <id>                   # cross-references sources/research/iter-NNN/
source_url: <original URL>
fetched_at: <ISO-8601>
hash_chain: sha256:<source_hash> → sha256:<wiki_page_hash>
ingester_agent: <agent_id>
ingest_iter: <iter-NNN>
```

The hash chain is what enables Wiki content to be re-derived from sources if the wiki is corrupted or superseded. This is the backstop for the entire two-layer architecture: sources remain immutable; the synthesis can be re-run.

### `wiki/index.md` cap

Per §20 the index MUST stay ≤ 200 lines. When it would exceed, the Ingester offloads to per-cluster index files (`wiki/entities/competitors/index.md`, etc.) and the root `wiki/index.md` becomes a one-line-per-cluster pointer document. This is what keeps Tier-1 always-loaded context bounded — see `three-tier-memory.md`.

### Per-cluster CLAUDE.md

Per §24 each `wiki/<cluster>/` MAY carry a `CLAUDE.md` (≤ 200 lines) describing cluster-specific conventions (e.g. "competitors pages always include a `pricing_tier:` field"). The Ingester reads the cluster's `CLAUDE.md` before writing into that cluster.

### What this architecture MUST NOT do

- MUST NOT modify any file under `sources/` (Invariant 8 — sources are immutable).
- MUST NOT promote a claim past SINGLE-SOURCE without the required source count (KB Linter responsibility, not Ingester).
- MUST NOT silently overwrite a contradicted page; create a new entry and mark the old one `invalidated_at` per Inv 6 / `temporal-facts.md`.
- MUST NOT exceed the 200-line cap in `wiki/index.md` (offload to per-cluster index instead).
- MUST NOT collapse `sources/` and `wiki/` into a single tree — the two layers are orthogonal.
- MUST NOT consume an unsigned source (every source under `sources/` MUST have a corresponding `index.md` entry recording its origin URL and fetch ts).

### Cross-references

- Producer role: `20-roles/wiki-ingester.md`
- Reader role: `20-roles/wiki-querier.md`
- Promotion thresholds: `30-knowledge/knowledge-base.md`
- Temporal-fact protocol (never-overwrite rule): `30-knowledge/temporal-facts.md`
- Three-tier memory model that bounds index size: `30-knowledge/three-tier-memory.md`
- Failure modes this architecture prevents: `30-knowledge/wiki-failure-modes.md`

---
