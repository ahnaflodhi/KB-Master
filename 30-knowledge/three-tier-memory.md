---
id: 30-knowledge/three-tier-memory
title: Three-Tier Memory Model
purpose: knowledge-spec
audience:
  - wiki_query
  - orchestrator
also_needed_by:
  - planner
  - executor
  - kb_linter
  - meta_review
status: stable
version: 2.10
last_reviewed: 2026-05-04
extracted_from:
  source: SYSTEM-BLUEPRINT-v2.10.md
  sections: ["§20 Three-Tier Memory Model", "§17 Token Budget Management"]
  line_range_hint: "synthesis: §20 Tier 1/2/3 + lost-in-the-middle effect + wiki-recall data + bundle integration"
depends_on:
  - 00-overview/invariants.md
  - 30-knowledge/wiki-architecture.md
related:
  - 20-roles/wiki-querier.md
  - 40-runtime/claude-code-integration.md
  - 00-overview/design-principles.md
max_lines: 200
directives:
  must_count: 5
  should_count: 4
  may_count: 1
---

## Three-Tier Memory Model

A wiki that scales past ~200 pages cannot be bulk-loaded into every agent's context. Per §20 / wiki-recall data: bulk-loading a 200-page wiki costs ~70k tokens, triggers the **lost-in-the-middle attention effect** (per the literature: facts that land mid-load have measurably lower retrieval quality), and produces ~70% retrieval recall. The three-tier model achieves ~93% recall at ~98.4% token reduction.

This is not optional advice — it is the structural reason the architecture decomposes into bundles (Phase 5) and per-cluster index files (`wiki-architecture.md`).

### The three tiers

| Tier | What loads | When loaded | Cap |
|---|---|---|---|
| **Tier 1** — always-loaded | `wiki/index.md`, `LESSONS.md`, `knowledge/INDEX.md`, project root `CLAUDE.md`, current iteration's role-CLAUDE.md | every session start | each file ≤ 200 lines |
| **Tier 2** — selective | per-entity wiki pages, per-role bundle files, role-relevant `60-schemas/*.md` | when the query / role explicitly references them | per-bundle ≤ 7k tokens worst-case (steady-state ~3.5k) |
| **Tier 3** — search-fallback | full `wiki/` grep, `iterations/archive/iter-NNN/` archive search | only when Tier 1 + Tier 2 do not satisfy the query | unbounded but expensive — counts as a degradation event in the ledger |

Tier escalation is **one-way per query**. The Wiki Querier MUST NOT silently re-issue the same query at a higher tier without explicit caller request — that would defeat the cost discipline.

### The lost-in-the-middle problem

The literature (and §20 internal data) shows that LLMs retrieve facts from the *beginning* and *end* of a long context with high quality, but recall drops measurably for facts in the middle. This effect compounds with context length: at 200 pages of wiki, mid-load facts hit ~70% recall regardless of model quality.

The three-tier model side-steps this by never loading the middle:

```
WITHOUT three-tier (naive bulk-load):
  [wiki/index][page1][page2]...[page198][page199][page200]
  ↑ high recall  ↑ low recall middle    ↑ high recall

WITH three-tier:
  Tier 1: [wiki/index] (200 lines)            ← always-loaded; high recall
  Tier 2: [page-N from cluster X] (selective)  ← loaded because query referenced it
  Tier 3: [search the rest]                    ← fallback, expensive, rare
```

### Token budget per role (§17)

Per `00-overview/design-principles.md` design-principle 5 (selective retrieval), the bundle assembly (Phase 5) materialises Tier 2 per role:

| Role | Bundle steady-state | Worst-case |
|---|---|---|
| `planner` | ~3.5k tokens | ~7k tokens |
| `truthsayer` | ~3.5k tokens | ~7k tokens |
| `executor.research` | ~5k tokens | ~10k tokens (may include selective-Tier-2 wiki pages) |
| `executor.commercial` | ~5k tokens | ~10k tokens |
| `evaluator` | ~4k tokens | ~8k tokens |
| `kb_linter` | ~3k tokens | ~6k tokens |
| `wiki_ingest` | ~5k tokens | ~10k tokens |
| `wiki_query` | ~3k tokens | ~5k tokens (the role itself is the Tier-2 loader; its own bundle is small) |
| `meta_review` | ~4k tokens | ~8k tokens |
| `apply_meta` | ~3k tokens | ~5k tokens |
| `orchestrator` | ~7k tokens | ~12k tokens (largest because it loads the dispatch shim + all 50-adapters/) |

These are targets, not hard caps. The hard caps are per-file (per the per-directory `max_lines`) — the bundle totals follow from those per-file caps if Phase-5 bundle assembly stays disciplined.

### Tier-1 cap enforcement (`wiki/index.md` ≤ 200 lines)

When `wiki/index.md` would exceed 200 lines, the Wiki Ingester MUST offload to per-cluster index files (`wiki/entities/competitors/index.md`, etc.) and the root index becomes a one-line-per-cluster pointer document. This is what keeps Tier-1 bounded as the wiki grows.

KB Linter Rule (related): observation-velocity check — if `wiki/index.md` line growth exceeds `max_new_observations_per_iter`, flag for human review. Sustained growth without compaction is a signal that the cluster taxonomy needs refactoring.

### Querier discipline

Per `20-roles/wiki-querier.md`, the Querier returns structured page bundles, not raw page dumps. Every bundle reports `tier_distribution` (e.g. `{tier1: 1, tier2: 3, tier3: 0}`) so the caller observes its own retrieval-cost profile. A bundle with `tier3 > 0` is an observability signal — the Tier-1+2 model didn't satisfy the query.

### Cross-iteration caching

Tier-1 content is loaded fresh every session — there is no persistence beyond the file system. This is intentional: the only canonical source is the file. Caching Tier-1 content in the harness (e.g. via MCP memory) is **anti-pattern** because it obscures the file as the source of truth.

The exception is adapter probe results — those are cached for the session per `40-runtime/bootstrap-and-degradation.md` (re-probe on `agents.config.yaml` mtime change).

### What the model MUST NOT do

- MUST NOT bulk-load `wiki/` even when asked — Wiki Querier refuses, returns Tier-1 + a note that the query was overbroad.
- MUST NOT exceed the `wiki/index.md` ≤ 200-line cap; offload to per-cluster index instead.
- MUST NOT cache Tier-1 content in the harness; reload from the file every session.
- MUST NOT silently escalate a query to Tier 3 — escalation is observable in `tier_distribution`.
- MUST NOT load multiple per-cluster indices simultaneously when the query targets one cluster (selective-load means selective).

### Cross-references

- Producer of bundles (Phase 5): `tools/build-bundle.sh`
- Reader role: `20-roles/wiki-querier.md`
- Wiki structure that supports tiering: `30-knowledge/wiki-architecture.md`
- Design principle this enforces: `00-overview/design-principles.md` "Selective retrieval over bulk loading"

---
