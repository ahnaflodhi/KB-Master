---
id: 20-roles/wiki-ingester
title: Wiki Ingester — Role Contract
purpose: role-contract
audience:
  - wiki_ingest
also_needed_by:
  - orchestrator
  - executor
  - kb_linter
  - wiki_query
  - meta_review
status: stable
version: 2.10
last_reviewed: 2026-05-04
extracted_from:
  source: SYSTEM-BLUEPRINT-v2.10.md
  sections: ["§6 Wiki Ingester", "§10 Karpathy two-layer + process-learning extension", "§14 archive-on-ingest with hash-chain audit", "§8 Invariant 8 (sources immutable)", "§17 model tiering (frontier)"]
  line_range_hint: "synthesis: §6 ingester protocol + §10 layer separation + §14 archive-on-ingest + Inv 8 sources-first + §17 frontier"
depends_on:
  - 00-overview/invariants.md
  - 00-overview/philosophy.md
  - 10-pipeline/iteration-lifecycle.md
related:
  - 20-roles/orchestrator.md
  - 20-roles/wiki-querier.md
  - 20-roles/kb-linter.md
  - 20-roles/executor.md
max_lines: 150
directives:
  must_count: 7
  should_count: 3
  may_count: 1
---

## Wiki Ingester — Role Contract

### Mandate

The Wiki Ingester is the only role authorised to promote raw `sources/research/iter-NNN/*` content into the structured `wiki/`. Per **Invariant 8**, sources are immutable after first save — the Ingester reads them, creates corresponding wiki entries, and stamps each entry with `provenance` pointing back to the source archive. Per §10 the Ingester maintains the Karpathy two-layer separation: `sources/` is raw immutable input, `wiki/` is synthesised domain knowledge — they never collapse into one another.

Per §14, every ingest operation produces an archive-on-ingest record with a hash-chain audit option, so wiki content can be re-derived from sources if the wiki is corrupted or superseded.

### Inputs

- `sources/research/iter-NNN/index.md` + per-fetch files (Inv 8 immutable)
- existing `wiki/index.md` (Tier 1) + selective `wiki/entities/**/*.md` for collision detection
- `knowledge/methodology/rules.md` — confirmed rules that constrain claim acceptance
- `wiki/synthesis/contradictions/` — known contradictions (new ingest may resolve or extend)

### Outputs

| File / directory | Purpose | Schema notes |
|---|---|---|
| `wiki/entities/{competitors,apis,markets,tools,buyers}/*.md` | per-entity pages | frontmatter: `id`, `created_at` ISO-8601, `confidence` ∈ {SINGLE-SOURCE, CROSS-VERIFIED, CONFIRMED}, `provenance: [source-id]`, `incoming_links: int` |
| `wiki/concepts/*.md` | concept pages | same frontmatter |
| `wiki/synthesis/{contradictions,feasibility,cross-cluster}/*.md` | synthesis pages | adds `synthesised_from: [page-id]` |
| `wiki/claims/unverified/*.md` | new SINGLE-SOURCE claims | promoted by KB Linter once cross-verified |
| `wiki/claims/verified/*.md` | claims promoted to CROSS-VERIFIED or CONFIRMED | requires ≥ 2 independent sources for CROSS-VERIFIED, ≥ 3 confirmations for CONFIRMED |
| `wiki/index.md` | append entries | ≤ 200-line cap per §20; excess moves to per-cluster index |
| `wiki/log.md` (append) | one-line ingest record per iteration | none |
| archive-on-ingest record (per §14) | hash-chain audit row | optional but recommended |

### Adapter requirements

- adapter MUST have `enforces_pre_action_facts: true` (Invariant 10) — every wiki write is state-mutating.
- Default adapter: `claude-native` (subagent or sdk).
- Sandbox: `workspace-write`.
- `host_access` (v2.10): not required (operates on local source archives).
- Tier per §17: **frontier** (fact-producing — synthesis decisions affect every downstream consumer).

### Tools required

`Read`, `Write`, `Edit`, `Grep`, `Glob`. NO `WebFetch` / `WebSearch` — fetching is the Executor's job per Inv 8 (sources must already exist in `sources/` before ingest can read them).

### Cycle limits

The Ingester does not have its own cycle limits — it runs as a subordinate of `executor.research` (Phase 5) or as a dedicated `/wiki-ingest` invocation. Cycle accounting flows through the parent Executor.

### Promotion contract (claims)

| From | To | Condition |
|---|---|---|
| (new claim) | `wiki/claims/unverified/` | initial save, SINGLE-SOURCE |
| `unverified/` | `wiki/claims/verified/` (CROSS-VERIFIED) | ≥ 2 independent sources confirm |
| `verified/` (CROSS-VERIFIED) | `verified/` (CONFIRMED) | ≥ 3 confirmations across iterations |
| any | (mark `invalidated_at`) | contradicting evidence — Invariant 6; the Linter flags, the Ingester writes the new entry |

The Ingester MUST NOT skip the `unverified/` step for a new claim — every claim begins SINGLE-SOURCE regardless of how confident the source is.

### What the Wiki Ingester MUST NOT do

- MUST NOT modify `sources/` (Invariant 8 — sources are immutable).
- MUST NOT promote a claim past SINGLE-SOURCE without the required source count.
- MUST NOT silently overwrite a contradicted page; create a new entry and mark the old one `invalidated_at` per Inv 6.
- MUST NOT exceed the 200-line cap in `wiki/index.md` (offload to per-cluster index instead).
- MUST NOT write to `iterations/current/`, `knowledge/`, `pipeline/`, or `decisions/` — those belong to other roles.
- MUST NOT consume an unsigned source (every source under `sources/` MUST have a corresponding `index.md` entry recording its origin URL and fetch ts).
- MUST NOT use `WebFetch` directly — that bypasses the Inv-8 archive step.

### Cross-references

- Lifecycle: typically runs within `10-pipeline/iteration-lifecycle.md` §"Phase 5 — Execute" (`executor.research` sub-invocation).
- Sibling: `20-roles/wiki-querier.md` (read-side complement).
- Linter dependency: `20-roles/kb-linter.md` (promotes unverified → verified per its lint pass).

---
