---
name: qmd — hybrid search engine internals
type: reference
researched: 2026-04-11
primary_sources:
  - https://github.com/tobi/qmd
  - https://github.com/tobi/qmd/blob/main/README.md
  - https://deepwiki.com/tobi/qmd/3.2-search-modes-explained
  - https://github.com/ehc-io/qmd
---

# qmd — Hybrid Search Engine Internals

## What it is
Local-first hybrid search engine for markdown knowledge bases. Tracks SOTA retrieval while running entirely offline via node-llama-cpp with GGUF models. Available as CLI, library, and MCP server (both tobi/qmd and fork ehc-io/qmd).

## Three search modes

| Mode | Description | When to use |
|---|---|---|
| `lex` | BM25 via SQLite FTS5 with weighted columns (title / body / path) | Fast keyword search, no LLM loaded |
| `vec` | Vector similarity with embedding model | Semantic search |
| `hybrid` (default) | BM25 + vec + optional HyDE, fused via RRF, then reranked | Highest quality |

Unified `search()` method auto-expands queries via LLM when given a simple string.

## Chunking parameters
- **Chunk size**: 900 tokens
- **Overlap**: 135 tokens (15% of chunk size)
- **Break-point search window**: 200 tokens
- **Break-point scoring**:
  - Headings: 70-100 points
  - Code blocks: 80 points
  - Blank lines: 20 points

## Embedding models (defaults)
- **Default**: `embeddinggemma-300M-Q8_0` — 768 dimensions, ~300MB
- **Alternative**: `Qwen3-Embedding-0.6B-Q8_0` — 1024 dimensions, ~640MB
- Query prefix: `search_query:` (task-specific formatting)

## Reranker
- **Model**: `qwen3-reranker:0.6b` (cross-encoder)
- Applied to top-30 candidates from fused list

## RRF + position-aware blending (load-bearing numbers)
- RRF k = 60, with top-rank bonuses
- Position-aware blend between RRF score and reranker score:
  - Ranks 1-3: 75% RRF / 25% reranker
  - Ranks 4-10: 60% RRF / 40% reranker
  - Ranks 11+: 40% RRF / 60% reranker

## Query expansion
- **Model**: `Qwen3-1.7B`
- Original query expanded to multiple variants, each searched by FTS and vector
- **Strong Signal Bypass**: if BM25 returns score ≥ 0.85 with gap ≥ 0.15 to next result, skip LLM expansion and reranking stages entirely

## Index layer
- SQLite with FTS5 for BM25
- Separate vector table for embeddings
- Hierarchical metadata returned alongside matching documents ("context system")
- Glob-based collection configuration
- Regex or AST-aware chunking for code

## MCP integration
Exposes tools via MCP for Claude Code / Claude Desktop. HTTP transport supports shared long-lived server instances (avoids repeated model loads per query).

## Observations for our blueprint

The strong-signal bypass (≥0.85 BM25 with ≥0.15 gap → skip LLM stages) is a concrete, cheap-path optimization we could adopt as a general principle: **any retrieval pipeline should short-circuit when a single signal is unambiguously strong**.

The position-aware RRF/reranker blending is a concrete schedule we don't currently specify when discussing retrieval in our blueprint.

The 900-token chunk / 135 overlap / heading-break preference is a sensible chunk-template default that our Section on sources ingestion does not pin down.
