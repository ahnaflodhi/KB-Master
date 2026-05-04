---
name: CodeWiki — Muhammad Raza's codebase-specific LLM wiki
type: reference
researched: 2026-04-12
primary_sources:
  - https://muhammadraza.me/2026/building-codewiki-compiling-codebases-into-living-wikis/
---

# CodeWiki — Compiling Codebases Into Living Wikis (Muhammad Raza, 2026)

## Motivation
AI coding agents "start from zero" each session, spending ~10 minutes exploring architecture before productive work begins. CodeWiki compiles repos into markdown wikis agents maintain across sessions.

## Architecture
- `_index.md` — master index
- `_architecture.md` — system overview
- `modules/` — one article per code module
- `concepts/` — cross-cutting concerns
- `decisions/` — design rationale
- `learnings/` — discoveries from working on the code
- `queries/` — past Q&A filed back into the wiki

## CLI (`cw`, Rust-based, ~400 lines)
Commands: `cw init`, `cw status`, `cw index`, plus Claude Code skill installation.
**Key property**: the CLI makes NO LLM calls — the agent provides all intelligence. CLI only handles git operations and metadata tracking.

## Staleness management
- YAML frontmatter includes `source_files:` mapping
- CLI tracks last-compilation commit hash
- `cw status` diffs changed files and cross-references article source dependencies
- Quote: *"The agent sees this and knows exactly what to re-read and update. No guessing, no full recompile."*

This is concrete incremental-recompile architecture: manifest-equivalent, commit-hash-anchored.

## Retrieval at scale
- Small wikis: well-organized index is enough
- Larger wikis: integrates with **qmd** (hybrid BM25 + vector + rerank) via MCP
- Agent queries wiki through qmd during sessions

## Key differentiation from Karpathy
- Automated staleness detection via git diffs (not just manifest hashes)
- Structured namespacing: modules / concepts / decisions / learnings
- Integration with Obsidian for graph browsing
- CLI scaffolding (initialization + status but no intelligence)
- Framed against RAG as "preserving semantic relationships that chunked embeddings lose"

## What the article DOES NOT provide
- Cost / token numbers
- Scale thresholds (no page count limits)
- Failure modes
- Lint specifics

## Relation to our blueprint
Already covered:
- Source delta tracking via manifest
- Structured sub-directories in wiki/

Not yet covered:
- **Separate `decisions/` and `learnings/` directories** — we roll these into knowledge/ OBS/HYP/RULE, but CodeWiki's simpler "decisions vs learnings" split may be a cleaner user-facing cut
- **CLI-with-no-LLM-calls pattern** — all intelligence in the agent; CLI only does bookkeeping. This is a clean separation of concerns our blueprint does not explicitly recommend
- **Git-commit-hash-anchored staleness** (not just file sha256) — for any project with a git source
