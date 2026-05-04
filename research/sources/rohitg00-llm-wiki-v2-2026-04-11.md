---
name: LLM Wiki v2 — rohitg00 agentmemory extensions
type: reference
researched: 2026-04-11
primary_sources:
  - https://gist.github.com/rohitg00/2067ab416f7bbe447c1977edaaa681e2
---

# LLM Wiki v2 — Extensions Beyond Karpathy's Original (rohitg00)

Published as a follow-up gist titled "LLM Wiki v2 — extending Karpathy's LLM Wiki pattern with lessons from building agentmemory." Author is running a production agent-memory system, not just a personal wiki.

## Extensions identified

### 1. Memory lifecycle management
- **Confidence scoring per fact**: how many sources support it, how recently it was confirmed, what contradicts it. Confidence decays over time but is reinforced on re-access.
- **Supersession**: new information explicitly replaces old claims instead of coexisting. Version control for knowledge.
- **Forgetting (Ebbinghaus decay)**: facts fade if unused, reset when accessed/confirmed.
- **Consolidation tiers** (borrowed from human-memory models):
  - Working memory — recent observations
  - Episodic memory — compressed sessions
  - Semantic memory — cross-session facts
  - Procedural memory — workflows/patterns

### 2. Knowledge graph structure (not pure markdown)
- **Entity extraction**: people, projects, libraries, concepts, decisions with typed attributes
- **Typed relationships**: "uses", "depends on", "contradicts", "caused", "fixed", "supersedes"
- **Graph traversal** enables structural queries like tracing downstream impacts of a change — pure markdown backlinks cannot do this

### 3. Search architecture at scale
- **Hybrid search**: BM25 + vector + graph traversal, fused via RRF
- **Index file limitation**: "single `index.md` becomes unwieldy beyond approximately 100-200 pages"
- Direct threshold: the v2 author pins the crossover at ~100-200 pages

### 4. Event-driven automation (hooks)
- On new source → auto-ingest, entity extraction, graph updates
- On session end → compress observations into insights
- On query → assess whether answer merits wiki filing
- On schedule → periodic linting and retention decay

### 5. Quality control
- **Scoring everything**: all LLM-generated content receives quality evaluation before acceptance
- **Self-healing**: automated lint repairs orphaned pages, updates stale claims, fixes broken references
- **Contradiction resolution**: system proposes resolution based on source recency, authority, supporting observations

### 6. Multi-agent / collaboration
- **Mesh sync**: merge parallel observations into shared wikis using timestamp-based conflict resolution
- **Scope management**: distinguish personal (private) from team (shared) knowledge
- **Work coordination**: lightweight tracking prevents duplicate efforts across agents

### 7. Privacy & governance
- **Sensitive data filtering**: automatic stripping of credentials, API keys, tokens on ingest
- **Audit trails**: timestamped logging of all operations (ingest, edit, delete, query)

### 8. Crystallization pattern
Transform completed work chains (research threads, debugging sessions) into structured wiki digests that extract lessons as standalone facts strengthening the knowledge base.

### 9. Output format flexibility
Beyond markdown: comparison tables, timelines, dependency graphs, slide decks, JSON/CSV exports.

## Production failure modes at scale

1. **Flat indexing breaks**: single-catalog approach becomes LLM-readable bottleneck beyond ~100-200 pages
2. **Knowledge rot**: without lifecycle management, older claims sit unvalidated alongside newer ones
3. **Manual maintenance kills adoption**: bookkeeping overhead causes wikis to be abandoned
4. **Quality drift**: unvetted LLM content accumulates, eroding trust
5. **Lost connections**: purely textual pages miss structural relationships discoverable through graphs

## Key principle

"The schema document is the most important file in the system" — it encodes domain-specific ingest rules, update policies, quality standards, and contradiction handling.

## Recommended adoption path

Modular, not all-or-nothing:
minimal viable wiki → add lifecycle → add structure → add automation → add scale → add collaboration

## Relation to KB-Orchestrator-Core blueprint

Already covered by our v2.6:
- Confidence tiers (SINGLE-SOURCE / CROSS-VERIFIED / CONFIRMED) — ours is source-count, rohitg00 adds time decay
- Supersession via claim lifecycle unverified/ → verified/ → rules.md
- Contradiction files with severity tiers
- Temporal fact management (Zep)
- Trust model for privacy / sensitive sources

Not yet covered:
- **Ebbinghaus-style confidence decay over time** — we only supersede, we do not decay
- **Typed relationships** (uses / depends-on / contradicts / caused / fixed / supersedes) — we have free-form markdown links only
- **Consolidation tiers** (working/episodic/semantic/procedural) — not in our memory model
- **Crystallization pattern** — transforming completed work chains into wiki digests (our log.md is append-only but we don't crystallize)
- **Mesh sync with timestamp-based conflict resolution** — we do not address multi-agent merge yet
- **Hook-based automation** — we describe agents but not event triggers
- **Strong ~100-200 page threshold** — we say "moderate scale" without a number
