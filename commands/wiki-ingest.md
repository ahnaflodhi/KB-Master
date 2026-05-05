---
description: Promote sources/research/iter-NNN/* into wiki/ with provenance + hash-chain audit
argument-hint: <iter-NNN or sources path>
---

# /wiki-ingest — Wiki Ingester

Composes `/_delegate` with `role=wiki_ingest`. Role contract: `20-roles/wiki-ingester.md`. Bundle: `bundles/wiki-ingest.yaml`. Outputs: `wiki/entities/**/*.md`, `wiki/concepts/`, `wiki/synthesis/`, `wiki/claims/unverified/*.md`, `wiki/index.md` (≤200 lines per §20), `wiki/log.md` (append), archive-on-ingest record per §14.

Per **Invariant 8**, sources under `sources/` are immutable. The Ingester reads them, creates wiki entries, and stamps each with `provenance` pointing back. The Ingester does NOT modify sources.

## Preconditions

- `sources/research/iter-NNN/index.md` MUST exist for the target iteration.
- `sources/` MUST contain saved fetches (every WebFetch/WebSearch result already saved per Inv 8 by the Executor).

## Dispatch

```
/_delegate
  role: wiki_ingest
  inputs:
    - sources/research/iter-NNN/                  # immutable raw input
    - wiki/index.md                                # Tier-1 collision detection
    - wiki/synthesis/contradictions/               # known contradictions
    - knowledge/methodology/rules.md               # confirmed rules constraining acceptance
  expected_schema: (no single schema — wiki pages per 30-knowledge/wiki-architecture.md)
  iter_id: <current>
```

Default adapter: `claude-native` (subagent or sdk). Sandbox: `workspace-write`. Tier per §17: **frontier** (synthesis decisions affect every downstream consumer). NO `WebFetch`/`WebSearch` — fetching is the Executor's job per Inv 8.

## Promotion contract

Every new claim starts in `wiki/claims/unverified/` regardless of source confidence. The KB Linter promotes:
- `unverified/` → `verified/` (CROSS-VERIFIED) when ≥ 2 independent sources confirm
- CROSS-VERIFIED → CONFIRMED when ≥ 3 confirmations across iterations

The Ingester MUST NOT skip the unverified step.

## Archive-on-ingest (§14)

Every Ingester run produces a per-source record with `hash_chain: sha256(source_content) → sha256(wiki_page_content)`. This is the backstop that lets wiki content be re-derived from sources if the wiki is corrupted.

## Routing

`/wiki-ingest` typically runs as a sub-invocation of `/execute` (research) during Phase 5; the orchestrator dispatches it inline. May also run standalone via `claude /wiki-ingest <iter>`.

After completion: `wiki/log.md` appended; downstream `/kb-lint` reads the new entries on its next pass.

---
