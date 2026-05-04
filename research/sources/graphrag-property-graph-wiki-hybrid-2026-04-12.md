---
name: Knowledge graph + wiki hybrid patterns (GraphRAG, LlamaIndex, Zep)
type: reference
researched: 2026-04-12
primary_sources:
  - https://github.com/microsoft/graphrag
  - https://arxiv.org/abs/2507.03226
  - https://www.llamaindex.ai/blog/introducing-the-property-graph-index-a-powerful-new-way-to-build-knowledge-graphs-with-llms
  - https://arxiv.org/abs/2501.13956
---

# Knowledge Graph + Wiki Hybrid Patterns

## What a property graph adds that pure markdown cannot

1. **Typed relationships**: "uses", "depends on", "contradicts", "supersedes" — pure markdown backlinks are untyped
2. **Graph traversal queries**: "what downstream pages are affected if source X is retracted?" — requires relationship walking, not text search
3. **Community detection**: Leiden clustering on entity graph reveals topic clusters automatically — replaces manual wiki directory organization
4. **Temporal edges**: each relationship has validity windows (when it became true, when superseded) — markdown links are atemporal
5. **Multi-hop reasoning**: graph traversal for questions requiring 2+ relationship hops — index.md can't help
6. **Contradiction detection via structure**: two entities with contradictory typed relationships are structurally detectable — in markdown, this requires full-text NLI

## Microsoft GraphRAG

- Extracts entities + relationships from text into property graph
- Leiden hierarchical community clustering
- Community summaries as retrieval units
- Works with Neo4j, Azure Cosmos DB for production storage
- Hybrid retrieval: vector similarity + graph traversal fused via RRF

## Towards Practical GraphRAG (arXiv 2507.03226)

Key finding: **SpaCy dependency parsing achieves 94% of LLM-based extraction quality** (61.87% vs 65.83% semantic alignment).
- Dramatically cheaper: classical NLP vs LLM API calls
- Pipeline: passive voice normalization → phrasal merging → coreference resolution → dependency triple extraction
- Hybrid retrieval: separate embeddings for entities, chunks, relations → RRF fusion (k=60) → top-k chunks + top-2k relations
- Evaluated on enterprise code migration datasets
- Limitation: "may miss context-dependent or implicit relations"

## LlamaIndex PropertyGraphIndex

- Nodes with labels + properties
- Multiple retrieval modes: keyword/synonym, vector similarity, Cypher query, Cypher template
- Can combine retrieval modes concurrently
- Production integration: Neo4j, Redis caching, Elasticsearch hybrid, Prometheus monitoring
- Graph versioning for safe deployment + rollback
- Security: TextToCypherRetriever requires read-only roles / sandboxed env

## Zep/Graphiti (arXiv 2501.13956)

Already in our blueprint. Additional details from paper:
- **Temporal contradiction resolution**: overlapping contradictions invalidated by setting t_invalid = t_valid of invalidating edge. New info always wins.
- Graph schema: Episode nodes, Entity nodes, Community nodes. Edges: Episode→Entity, Entity→Entity (semantic), Community→Entity. Each edge has 4 timestamps: t_valid, t_invalid (event), t'_created, t'_expired (transactional)
- Production performance: 90% latency reduction (2.58s vs 28.9s with gpt-4o), 1.6K average tokens vs 115K full context
- Known weakness: 17.7% performance DECREASE on single-session-assistant questions

## Synthesis for our blueprint

Our v2.6 mentions Zep/Graphiti for temporal facts but does not:
1. **Recommend when to adopt a property graph layer** — we could pin this: "when wiki exceeds ~200 pages and you need typed relationships or multi-hop queries"
2. **Specify relationship types** — rohitg00's list (uses / depends-on / contradicts / caused / fixed / supersedes) is a concrete starting set
3. **Describe the cost-effective extraction path** — SpaCy dependency parsing at 94% of LLM quality is a practical budget option for relationship extraction
4. **Distinguish what graphs add vs what markdown can handle** — the 6-point list above is the concrete answer
