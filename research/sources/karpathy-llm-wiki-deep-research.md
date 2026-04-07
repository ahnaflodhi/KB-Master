---
name: Karpathy LLM Wiki — Deep Research
type: reference
researched: 2026-04-06
primary_sources:
  - https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f
  - https://x.com/karpathy/status/2039805659525644595
  - https://x.com/karpathy/status/2040470801506541998
---

# Karpathy LLM Wiki / Knowledge Base — Comprehensive Research

## Timeline

- **Late March 2026**: @FreakinFrick (Tex) posts about YouTube/podcast transcript knowledge base using a similar pattern (possibly independent parallel development)
- **April 2-3, 2026**: Karpathy posts original "LLM Knowledge Bases" tweet (1.7M+ views)
- **April 4, 2026**: Posts follow-up + publishes gist (5,000+ stars, 1,251 forks)

---

## The Exact Three Layers

### Layer 1: `raw/`
- Immutable source documents — articles, papers, repos, datasets, images, meeting notes, web clips
- LLM reads but **never modifies**
- Obsidian Web Clipper for web → markdown conversion
- The source of truth. Ground truth for all wiki content.

### Layer 2: `wiki/`
- LLM-generated and LLM-maintained markdown files
- LLM owns this entirely — creates, updates, maintains cross-references
- Humans read; LLM writes
- **Two mandatory special files**:
  - `index.md` — content-oriented catalog; one-line entry per page organized by category; updated on every ingest; replaces vector search at moderate scale
  - `log.md` — append-only chronological record; parseable prefixes e.g. `## [2026-04-04] ingest | Article Title`
- Common sub-structure: `concepts/`, `entities/`, `sources/`, `comparisons/`
- Filed query answers go here too (the compounding mechanism)

### Layer 3: `CLAUDE.md` / `AGENTS.md` (THE THIRD LAYER — the schema file)
- A single configuration document — not a directory
- Called `CLAUDE.md` for Claude Code, `AGENTS.md` for OpenAI Codex
- Tells the LLM: how the wiki is structured, naming conventions, citation rules, frontmatter format, ingest workflow steps, Q&A behavior, linting conventions
- **Human-LLM co-evolved** over time as domain develops
- Karpathy: *"This is the key configuration file — it's what makes the LLM a disciplined wiki maintainer rather than a generic chatbot."*
- Building it well is itself a form of thinking about the domain

**Core rules the schema file contains**:
- Never modify `raw/`
- Full LLM ownership of `wiki/`
- Update `index.md` on every ingest
- Maintain `log.md` as append-only
- Prefer updating existing pages over creating new ones
- Add source links for important claims
- Mark uncertain points as open questions
- Propose changes to operational pages as diffs requiring human review

### Optional 4th element: `outputs/`
Some implementations (not in original gist) add `outputs/` for rendered artifacts: Marp slides, matplotlib charts, HTML, filed query answers. In Karpathy's canonical gist, outputs are filed back into `wiki/` itself.

---

## YAML Frontmatter (from gist and implementations)

```yaml
---
title: Page Title
type: concept | entity | source-summary | comparison
sources: [list of raw/ files referenced]
related: [list of wiki pages linked]
created: YYYY-MM-DD
updated: YYYY-MM-DD
confidence: high | medium | low
---
```

---

## The Three Core Operations

### 1. Ingest
1. Read source file from `raw/`
2. Discuss key takeaways with user
3. Create summary page in `wiki/sources/`
4. Update `wiki/index.md`
5. Update all relevant concept and entity pages (~10-15 pages per source)
6. Append to `wiki/log.md`

### 2. Query
1. Read `wiki/index.md` to locate relevant pages
2. Read identified pages
3. Synthesize answer with wiki-link citations
4. Offer to file valuable answers as new wiki pages
   → This is the compounding mechanism: every query adds up

### 3. Lint (periodic health check)
- Scan for contradictions between pages
- Identify orphan pages (no inbound links)
- Find concepts mentioned but lacking their own page
- Detect stale claims superseded by newer sources
- Impute missing information via web search
- Suggest new articles based on gaps
- Propose connections between existing pages

---

## Scale and Tools

**Scale**: Karpathy's own wiki ≈ 100 articles, ~400,000 words (~533,000 tokens)  
At this scale: index.md + LLM context window is sufficient. No vector DB needed.  
Beyond ~100 sources: consider hybrid wiki + qmd search.

**Tools mentioned**:
- **Obsidian** — primary IDE/viewer; Web Clipper for ingestion; Graph view; Dataview plugin
- **qmd** — local BM25 + vector + LLM re-ranking search for large wikis; available as CLI and MCP server
  - https://github.com/tobi/qmd
  - https://github.com/ehc-io/qmd
- **Marp** — markdown slide generation
- **Matplotlib** — chart generation from wiki content

**Key Karpathy quotes**:
- *"Obsidian is the IDE; the LLM is the programmer; the wiki is the codebase."*
- *"The LLM is rediscovering knowledge from scratch on every question. There's no accumulation."* (on RAG's limitation)
- *"You never (or rarely) write the wiki yourself — the LLM writes and maintains all of it."*
- *"The knowledge is compiled once and then kept current, not re-derived on every query."*
- *"Outputs from queries get filed back into the wiki, so every exploration adds up."*
- *"The wiki is a persistent, compounding artifact."*
- *"The tedious part of maintaining a knowledge base is not the reading or the thinking — it's the bookkeeping."*

**Future vision**: Use wiki to generate synthetic Q&A training data for fine-tuning — eventually embed knowledge in model weights rather than relying on context windows.

---

## Known Implementations

| Repo | Key Feature |
|---|---|
| https://github.com/toolboxmd/karpathy-wiki | hooks.json auto-trigger; SKILL.md schema; two skills: research + project-wiki |
| https://github.com/Astro-Han/karpathy-llm-wiki | Claude Code, Cursor, Codex CLI compatible; minimal and focused |
| https://github.com/ussumant/llm-wiki-compiler | 5-pass compilation; coverage indicators (High/Med/Low); 84% token reduction; 81x file compression |
| https://github.com/kfchou/wiki-skills | 5 skills: wiki-init, wiki-ingest, wiki-query, wiki-lint, wiki-update; SCHEMA.md; severity-tiered lint |
| https://github.com/rvk7895/llm-knowledge-bases | Obsidian-focused; adds outputs/; 3-depth query (Quick/Standard/Deep multi-agent); kb.yaml config |
| https://github.com/Ar9av/obsidian-wiki | Multi-agent (Claude, Cursor, Windsurf, Codex, Gemini, Copilot); .manifest.json delta tracking |
| https://github.com/GuiminChen/crate | Python CLI; compile/ask/lint/ingest commands; OpenAI-compatible providers |
| https://github.com/SingggggYee/awesome-llm-knowledge-bases | Curated ecosystem list: ingestion, compilation, linting, viewers, RAG, visualization, fine-tuning |

**Real-world example — Farzapedia**: Developer Farza compiled 2,500 diary/notes/iMessage entries into 400 interlinked personal Wikipedia articles. Karpathy highlighted this as the ideal manifestation.

**CodeWiki**: Applies pattern to codebases. Git-aware staleness tracking; `modules/`+`concepts/`+`decisions/`+`learnings/` structure.

---

## Conceptual Evolution Spectrum

| Level | Description |
|---|---|
| **1 — Pure Karpathy** | raw/ + wiki/ + schema file; three operations; no DB, no embeddings |
| **2 — Structured Extensions** | Coverage indicators; delta/manifest tracking; outputs/ directory; severity-tiered lint |
| **3 — Database-Backed** | SQLite (xoai/sage-wiki); ACID transactions; versioning; rollback |
| **4 — Multi-Agent** | Shared wiki with concurrency; role-based workflows; enterprise RBAC |
| **5 — Fine-tuning Endpoint** | Wiki → synthetic Q&A → model fine-tuning |

---

## What Communities Have Learned

**What Karpathy got right**:
1. Maintenance burden is the real KB bottleneck — LLMs solve it
2. Pre-compilation beats RAG at moderate scale (synthesis cost paid once)
3. index.md replaces vector DB at ~100 articles scale
4. Filing queries back compounds value (the key innovation)
5. Explicit inspectable memory has UX advantages over implicit AI memory

**Scaling failure modes**:
- Context saturation: degraded attention >200-300K tokens even with 1M windows → use selective loading
- Lint complexity: O(N²) contradiction scan → use randomized sampling
- Knowledge decay: LLM summaries can introduce subtle distortions → maintain provenance, keep raw/ as ground truth
- Stale articles: as sources change, wiki pages go stale → manifest-based delta tracking (CodeWiki: git diff staleness)
- Source provenance loss: unclear which claim came from which source → record source file hashes at compilation

**What implementations had to add beyond the gist**:
- Delta tracking / manifest systems (avoid re-processing unchanged sources)
- Coverage/confidence tags per section
- Separate outputs/ directory
- Multi-agent history ingestion
- Archive/rebuild with timestamped snapshots
- Severity tiers in lint reports

---

## RAG vs. Pre-Compiled Wiki

| | RAG | Karpathy Wiki |
|---|---|---|
| Synthesis timing | Query-time (repeated) | Ingest-time (once) |
| Relationships | Implicit (similarity) | Explicit (backlinks, named) |
| Accumulation | None (re-derived each time) | Yes (queries file back) |
| Infrastructure | Vector DB + embeddings | None (plain markdown) |
| Scale limit | Petabyte (with infra) | ~100-500 sources with just index.md |
| Inspectability | Low (embeddings opaque) | High (human-readable markdown) |
| Local ownership | Partial | Full |

**When RAG wins**: Real-time data, freshness-critical domains, petabyte corpora, multi-user RBAC, compliance-grade audit trails.

---

## How This Maps to Our Blueprint

Our `KB-Orchestrator-Core` blueprint implements an extended version:
- `sources/` = Karpathy's `raw/` (immutable ground truth) ✓
- `wiki/` = Karpathy's `wiki/` (LLM-compiled knowledge) ✓
- `CLAUDE.md` = Karpathy's schema file ✓ 
- `knowledge/` = **Blueprint extension** — process-learning layer (OBS→HYP→RULE) NOT in Karpathy's original
- Adversarial pipeline (Planner/TruthSayer/Evaluator) = **Blueprint extension** — not in Karpathy
- Temporal fact management = **Blueprint extension** (draws on Zep arXiv:2501.13956) — not in Karpathy
- `iterations/` = **Blueprint extension** — pipeline state management not in Karpathy

The "Three-Layer Karpathy Pattern" label in earlier blueprint versions was therefore inaccurate. v2.1 correctly names it "Two-Layer Karpathy Pattern + Process Learning Extension."

---

## HackerNews Discussions
- Main: https://news.ycombinator.com/item?id=47640875
- Show HN implementation: https://news.ycombinator.com/item?id=47656181

## Analysis
- VentureBeat: https://venturebeat.com/data/karpathy-shares-llm-knowledge-base-architecture-that-bypasses-rag-with-an
- Pebblous (ontology framing / "Cheap Ontology"): https://blog.pebblous.ai/report/karpathy-llm-wiki/en/
- Antigravity (complete guide): https://antigravity.codes/blog/karpathy-llm-wiki-idea-file
- Epsilla (enterprise limits): https://www.epsilla.com/blogs/karpathy-agentic-wiki-beyond-rag-enterprise-memory
- Extended Brain (synthesis critique): https://extendedbrain.substack.com/p/postscript-the-wiki-that-writes-itself
