---
name: RAG vs Wiki hybrid patterns — 2026 consensus
type: reference
researched: 2026-04-12
primary_sources:
  - https://www.mindstudio.ai/blog/llm-wiki-vs-rag-markdown-knowledge-base-comparison
  - https://atlan.com/know/llm-wiki-vs-rag-knowledge-base/
  - https://www.iqsource.ai/en/blog/karpathy-llm-wiki-knowledge-compounds-or-rots/
---

# RAG vs Wiki — 2026 Consensus

## Token thresholds (concrete numbers)

| Metric | Wiki wins | Transition zone | RAG wins |
|---|---|---|---|
| Knowledge base size | < 50K-100K tokens | 100K-500K tokens | > 500K tokens |
| Article count | < 100-200 articles | 200-500 | > 500 |
| Source documents | < 100 | 100-500 | > 500 |

At ~100 articles / ~400K tokens (Karpathy's own scale): index.md + context window sufficient. No vector DB needed.

## Infrastructure comparison

| Aspect | Wiki | RAG |
|---|---|---|
| Infra | Zero — markdown files | Vector DB + embedding pipeline + retrieval layer |
| Setup time | Hours | Days to weeks |
| Freshness | Manual + LLM health checks | Pipeline-triggered re-indexing; near-real-time |
| Multi-user | Race conditions, write conflicts | Access control depends on retrieval layer |
| Token cost | Up to 95% reduction vs naive loading (NOT vs optimized RAG) |  2K-5K tokens retrieved context per query |

## The hybrid wins

"A Combined approach (Wiki for context + RAG for verification) never lost a single round, even in tasks specifically designed to favor RAG." — MindStudio analysis

Pattern: **wiki in system prompt for stable curated knowledge + RAG for dynamic/large/user-specific content**.

## What breaks at scale (wiki failure modes)

1. **Error compounding**: bad wiki article becomes a prior that poisons future generations — "unlike hallucinations that reset per prompt"
2. **Context overflow**: index.md exceeds context window beyond ~200 articles
3. **No access control**: zero role-based permissions for multi-user
4. **Stale content**: requires periodic LLM health checks (not automatic)
5. **Race conditions**: multiple agents/users writing simultaneously

## What breaks at scale (RAG failure modes)

1. **Chunking boundary errors**: semantic context cut at wrong point — SILENT failure
2. **Embedding drift**: vocabulary mismatch → relevant chunks missed
3. **No accumulation**: knowledge re-derived every query, never compounds
4. **Audit gap**: neither approach inherently solves enterprise audit requirements

## For our blueprint

Already covered: wiki vs RAG comparison, scale threshold guidance, three-tier memory model

New insights to add:
- **Explicit hybrid recommendation**: wiki for stable compiled knowledge, vector search for sources/ retrieval, with clear crossover guidance
- **Error compounding as the wiki-specific risk** — more dangerous than RAG hallucination because errors persist and propagate
- **The "never lost" finding**: hybrid > either pure approach
- **Concrete token thresholds**: < 50K pure wiki, > 500K pure RAG, hybrid in between
