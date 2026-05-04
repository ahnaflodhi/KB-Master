---
name: atomicmemory/llm-wiki-compiler
type: reference
researched: 2026-04-12
primary_sources:
  - https://github.com/atomicmemory/llm-wiki-compiler
---

# atomicmemory/llm-wiki-compiler

A post-April-2026 fork of the llm-wiki-compiler concept, published by the atomicmemory org.

## Key features beyond Karpathy
- **Two-phase extraction pipeline**: concept extraction decoupled from page generation
- **Incremental compilation via SHA-256 hash-based change detection**
- **Compounding query mechanism**: `--save` flag writes query answers as wiki pages
- **Linting pass** for wiki quality assurance
- **Paragraph-level source attribution** via `^[filename.md]` markers

## Schema
- YAML frontmatter: title, summary, sources[], createdAt, updatedAt
- `[[wikilink]]` references (Obsidian-compatible)
- Per-paragraph source attribution

## Output directories
- `concepts/` — one .md per extracted concept
- `queries/` — saved Q&A answers
- `index.md` — auto-generated TOC

## Novel patterns
1. **Compounding knowledge**: queries saved with `--save` become indexed pages
2. **Order-independent compilation**: two-phase pipeline prevents dependency on source ingest order
3. **Honest truncation**: oversized sources get `truncated: true` metadata with original char count

## Lint
Checks broken links, orphaned pages, empty pages, general quality.

## Retrieval
- Current: index-based only
- Limitation acknowledged: "suitable for small, high-signal corpora (a few dozen sources)"
- Planned: semantic search + embeddings

## Constraints
- Node.js ≥ 18
- Anthropic API only (OpenAI/local on roadmap)

## Relation to our blueprint
- **Paragraph-level source attribution with `^[filename]` markers** — we have inline citations, but paragraph-anchor footnote style is a concrete format we don't specify
- **`truncated: true` metadata on oversized sources** — a concrete honesty mechanism for when ingestion hits limits. Our blueprint does not describe the "what happens when a source is too big" case
- **Two-phase extraction (concepts extracted before pages generated)** — ensures ingest order doesn't affect result. Our pipeline doesn't explicitly split concept discovery from page writing
