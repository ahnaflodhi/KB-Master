---
name: nvk/llm-wiki — parallel multi-agent wiki with thesis-driven investigation
type: reference
researched: 2026-04-12
primary_sources:
  - https://github.com/nvk/llm-wiki
  - https://llm-wiki.net/
---

# nvk/llm-wiki — Parallel Multi-Agent Research + Thesis-Driven Investigation

Published 2026 (MIT license). Claude Code plugin or portable AGENTS.md file. 30+ subcommands. Zero external dependencies — runs on Claude's built-in file/web tools.

## Multi-agent research with diverse angles

Standard (5 agents): academic, technical, applied, news, contrarian
Deep (8 agents): adds historical, adjacent fields, data/stats
Retardmax (10 agents): broadest net, skips planning

Each agent searches independently. Findings synthesized into cross-referenced wiki articles with confidence scoring. Parallelism is **logical** (multi-round, multi-angle) not OS concurrency — Claude sequences calls and batches results.

## Thesis-driven investigation (anti-confirmation-bias)

`/wiki:thesis` takes a testable claim and decomposes into variables, predictions, falsification criteria.

Agent splitting by perspective:
- Separate cohorts for supporting evidence, opposing evidence, mechanistic explanations, meta-reviews, adjacent fields
- **In multi-round mode, Round 2 automatically focuses harder on the WEAKER side of the evidence**
- Thesis as bloat filter: sources unrelated to claim variables skipped
- Structured output: evidence tables, verdict (supported / contradicted / mixed / insufficient), no narrative hand-waving

## Concurrency handling

- **Session registry** for crash recovery across multi-round research
- **Distributed ingestion**: raw sources dropped in `inbox/` processed asynchronously
- **Progress scoring (0-100)** with smart termination when diminishing returns appear
- **Time budgets**: `--min-time 1h|2h|4h` runs iterative rounds, each drilling into gaps from previous round
- **Project isolation**: each topic wiki maintains isolated indexes preventing cross-topic noise

## Wiki architecture

One topic = one sub-wiki: `~/wiki/topics/<name>/`
Hub at `~/wiki/` is metadata-only (registry, logs).

Structure:
- `raw/` — immutable sources
- `wiki/` — compiled articles (concepts / topics / references)
- `output/projects/` — grouped artifacts with `_project.md` manifests
- `inbox/` — drop zone for async ingestion

Navigation: indexes-first — Claude reads `_index.md` before exploring directories.

## Key novel patterns for our blueprint

1. **Thesis-driven investigation with anti-confirmation-bias round allocation** — Round 2 focuses on the weaker side. This is the adversarial-verification counterpart to our TruthSayer but applied at research-design level, not just claim evaluation.

2. **Progress scoring (0-100) with smart termination** — we don't have any research saturation metric. This enables "stop when enough" instead of fixed iteration counts.

3. **Multi-wiki synthesis via `--with <wiki>`** — load context from a different wiki during a query. We discuss isolated iterations but not cross-wiki context injection.

4. **Lifecycle metadata as frontmatter states** — active/archived/retracted managed as frontmatter fields, NOT file moves. Avoids git churn and path-break issues.

5. **Source retraction with blast-radius preview** — before removing a source, shows which wiki pages would be affected. Our blueprint does not describe source retraction.

6. **Question decomposition → subquestions → per-agent tasks → playbook synthesis** — a concrete pipeline for turning a query into parallel research tasks.

7. **Fuzzy intent router** — natural language input routes to the right command (URL → ingest, question → query, "research X" → research, "where was I" → resume). Our blueprint does not describe fuzzy routing for command dispatch.
