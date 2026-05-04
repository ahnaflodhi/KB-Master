---
name: Deep Research Findings — LLM Wiki/KB Implementations (April 2026)
type: reference
researched: 2026-04-11
primary_sources:
  - arxiv.org/abs/2509.23233 (WikiCollide)
  - github.com/amazon-science/RefChecker
  - vllm.ai/blog/halugate (HaluGate)
  - github.com/aviraldua93/wiki-recall
  - purplehorizons.io (tick-md)
  - claude.com/blog/multi-agent-coordination-patterns
  - github.com/microsoft/graphrag
  - arxiv.org/abs/2507.03226 (Practical GraphRAG)
  - arxiv.org/abs/2501.13956 (Zep/Graphiti)
  - gist.github.com/rohitg00/2067ab416f7bbe447c1977edaaa681e2
  - github.com/ArchiveBox/ArchiveBox
  - onlinelibrary.wiley.com/doi/full/10.1002/leap.1560 (citation rot)
  - mdpi.com/2079-9292/15/1/56 (AuditableLLM)
  - mindstudio.ai/blog/llm-wiki-vs-rag-markdown-knowledge-base-comparison
  - iqsource.ai/en/blog/karpathy-llm-wiki-knowledge-compounds-or-rots/
supporting_sources:
  - rohitg00-llm-wiki-v2-2026-04-11.md
  - qmd-search-internals-2026-04-11.md
  - nvk-llm-wiki-2026-04-12.md
  - wikicollide-contradiction-detection-2026-04-12.md
  - halugate-hallucination-detection-2026-04-12.md
  - multi-agent-concurrency-patterns-2026-04-12.md
  - wiki-recall-5layer-2026-04-12.md
  - provenance-citation-rot-2026-04-12.md
  - codewiki-raza-2026-04-12.md
  - atomicmemory-llmwiki-2026-04-12.md
  - rag-vs-wiki-hybrid-2026-04-12.md
  - cost-economics-wiki-2026-04-12.md
  - graphrag-property-graph-wiki-hybrid-2026-04-12.md
  - synthesis-quality-hallucination-2026-04-12.md
---

# Deep Research Findings — LLM Wiki/KB Implementations (April 2026)

Comprehensive follow-up to karpathy-llm-wiki-deep-research.md (2026-04-06). Research conducted across GitHub implementations, academic papers, and production case studies to identify improvements for SYSTEM-BLUEPRINT.md v2.6 → v2.7.

---

## Research Question 1: Embedding/Vector Retrieval for Wiki Pages

### Findings
- wiki-recall (github.com/aviraldua93/wiki-recall) measured: wiki-only 60% recall, search-only 45%, hybrid 93%. The hybrid approach never lost.
- Index.md crossover point validated at ~200 pages by multiple implementations.
- qmd (tobi/qmd) internals: BM25 + vector + LLM reranker. MCP server mode available.
- MindStudio analysis: "wiki in system prompt + RAG for dynamic content — combined approach never lost a single round."

### Blueprint Status
- PARTIALLY COVERED: Section 20 three-tier model exists but threshold guidance uses "moderate scale" (vague).
- NOT COVERED: concrete numeric thresholds for when to add vector search over wiki/ (as opposed to sources/).

### Recommendation: **EXTEND** Section 20
Replace "moderate scale" with concrete thresholds:
- < 200 wiki pages: index.md sufficient (current architecture)
- 200-500 pages: hybrid (index.md + BM25/vector retrieval). wiki-recall architecture: 93% recall.
- > 500 pages: full BM25 + vector + reranker (qmd MCP). wiki/index.md becomes secondary.

---

## Research Question 2: Recent Implementations

### Findings
- **rohitg00's LLM Wiki v2** (gist): adds typed relationships, mesh sync, scope management (personal/team), knowledge lifecycle maturity model, context-aware synthesis. Most comprehensive evolution of the pattern.
- **wiki-recall** (aviraldua93): 5-layer memory model, 550-token wake-up, 93% hybrid recall, 2,291 tests, handles 1,000 entities.
- **nvk-llm-wiki** (Nicola Viganò): Obsidian-native, strict 3-layer Karpathy, YAML frontmatter, works with Claude Code CLI.
- **awesome-llm-knowledge-bases** (SingggggYee): curated ecosystem list with new entries for qmd, compilation tools, RAG bridges.

### Blueprint Status
- Five-layer memory model NOT in blueprint (we have 3 tiers).
- Typed relationships NOT in blueprint.
- Knowledge lifecycle maturity model NOT in blueprint.

### Recommendation: **ADD** typed relationships to wiki frontmatter; **EXTEND** three-tier model with wiki-recall refinements (L0/L1 split, session layer).

---

## Research Question 3: Production Deployment Lessons

### Findings
- Error compounding is the wiki-unique risk: "LLM writes page with subtle mistake, queries cite it, answer filed back, now two pages reinforce same error." (IQ Source blog)
- Context overflow at ~200 articles confirmed by multiple independent sources.
- Multi-user race conditions documented as a real failure mode (tick-md v1.2.0 post-mortem).
- Token economics: 95% reduction vs naive loading; 550-token wake-up demonstrated.

### Blueprint Status
- Error compounding NOT named or mitigated in blueprint.
- Context overflow addressed via three-tier model but not explicitly quantified.

### Recommendation: **ADD** error compounding as a named risk in Section 18 or new section; add detection pattern (flag wiki-citing-wiki chains without source backing).

---

## Research Question 4: Synthesis Quality / Hallucination

### Findings
Five wiki-specific failure modes documented:
1. **Error compounding** — wiki errors persist and self-reinforce (see Q3)
2. **Claim drift** — paraphrase loses precision over compilation rounds; detectable via embedding drift (cosine similarity drop > 0.15)
3. **False consolidation** — distinct entities merged into one page; detectable via incompatible attribute sets
4. **Citation rot** — cited URL content changes or disappears; detectable via periodic re-fetch
5. **Confidence inflation** — LLM states things more confidently than sources warrant; detectable via hedging-language comparison

Detection tools:
- **RefChecker** (Amazon, EMNLP 2024): knowledge triplet extraction → per-triplet hallucination check. 18-27 point improvement over sentence-level checkers.
- **HaluGate** (vLLM): per-token granularity, 76-162ms overhead, suitable for batch wiki verification.
- **WikiCollide** (arXiv 2509.23233): 3.3% of Wikipedia facts internally inconsistent; NLI pipeline at O(N * k).

### Blueprint Status
- TruthSayer adversarial verification covers general quality.
- **NOT COVERED**: claim drift, false consolidation, confidence inflation, citation rot as named risks.
- **NOT COVERED**: knowledge triplet granularity for verification.
- **NOT COVERED**: O(N * k) contradiction scan algorithm.

### Recommendation: **ADD** five wiki-specific failure modes as named risks; **EXTEND** KB Linter with RefChecker-style triplet verification; **REPLACE** O(N^2) contradiction scan guidance with O(N * k) NLI pipeline.

---

## Research Question 5: Multi-Agent Concurrency

### Findings
- **tick-md**: file-level locking with claim-execute-release. Production-tested. MCP server integration.
- **Anthropic's five patterns**: Generator-Verifier, Orchestrator-Subagent, Agent Teams, Message Bus, Shared State. For wiki editing: "Shared State with locking, versioning, partitioning."
- **CRDTs don't work for Markdown**: Peritext (Ink & Switch) found plain-text CRDTs break formatting under concurrent edits.
- **rohitg00 mesh sync**: timestamp-based conflict resolution, manual override for genuine conflicts.

### Blueprint Status
- NOT COVERED: no concurrency protocol for wiki/. Blueprint assumes sequential iterations but doesn't enforce it.

### Recommendation: **ADD** page-level optimistic locking protocol. Claim-before-write pattern. Version hash in wiki page frontmatter.

---

## Research Question 6: Knowledge Graph + Wiki Hybrid

### Findings
What a property graph adds that pure markdown cannot:
1. Typed relationships (uses / depends-on / contradicts / supersedes)
2. Graph traversal queries ("what downstream pages are affected if source X retracted?")
3. Community detection via Leiden clustering (replaces manual wiki directory organization)
4. Temporal edges with validity windows
5. Multi-hop reasoning (2+ relationship hops)
6. Structural contradiction detection

**SpaCy dependency parsing achieves 94% of LLM extraction quality** (arXiv 2507.03226) — dramatically cheaper for relationship extraction.

GraphRAG (Microsoft): Leiden clustering + community summaries + hybrid retrieval (vector + graph via RRF).

### Blueprint Status
- Zep/Graphiti temporal model CITED but not deeply specified.
- Typed relationships NOT in blueprint.
- Graph traversal NOT described.
- Budget extraction path (SpaCy) NOT mentioned.

### Recommendation: **ADD** typed relationships to wiki frontmatter schema (uses / depends-on / contradicts / supersedes / caused / fixed). **ADD** activation criteria for property graph layer: ">200 pages AND multi-hop queries needed." **ADD** SpaCy as budget extraction option.

---

## Research Question 7: Lint Patterns That Scale

### Findings
- WikiCollide NLI pipeline: embed all claims as triplets → retrieve top-k most-similar pairs → NLI classify only those. O(N * k) where k = retrieval depth (typically 5-10).
- CLAIRE (best WikiCollide detector): ReAct agent with `clarify` + `explain` tools, 75.1% AUROC.
- Domain variation: 17.7% inconsistency rate in narrative/history articles vs ~2% in technical domains.
- 3.3% baseline inconsistency rate — expect this in any large wiki.

### Blueprint Status
- Lint operations described but no scaling algorithm.
- O(N^2) assumption implicit.

### Recommendation: **EXTEND** KB Linter specification with:
1. O(N * k) NLI pipeline as default contradiction scan algorithm
2. Domain-dependent scanning frequency (narrative pages scanned more often)
3. 3.3% baseline inconsistency expectation
4. 75% AUROC ceiling for automated detection — manual review remains necessary

---

## Research Question 8: Provenance/Audit Chains

### Findings
- **Citation rot** is a documented problem with no industry-wide solution.
- **Wikipedia's policy**: always archive web sources at time of citation. Record both original + archive URL.
- **ArchiveBox** (self-hosted): saves in redundant formats (HTML, singlefile, screenshot, PDF, WARC).
- **AuditableLLM** (MDPI 2026): hash-chain update logs. 3.4ms/step overhead, 5.7% slowdown, sub-second audit. EU AI Act + GDPR aligned.

### Blueprint Status
- Source delta tracking via manifest.json with SHA-256 hashes — COVERED.
- Citation rot — NOT COVERED.
- Archive-on-ingest — NOT COVERED.
- Hash-chain audit logs — NOT COVERED.
- Dual URL (original + archive) — NOT COVERED.

### Recommendation: **ADD** archive-on-ingest protocol. **ADD** `archive_url` + `archived_date` to source frontmatter. **ADD** citation health check as a lint operation. **CONSIDER** hash-chain audit log for compliance-grade deployments.

---

## Research Question 9: RAG vs Wiki Hybrid (2026 Consensus)

### Findings
Concrete token thresholds validated:
| KB Size | Best approach |
|---|---|
| < 50K-100K tokens | Pure wiki |
| 100K-500K tokens | Hybrid (wiki + vector retrieval) |
| > 500K tokens | RAG-dominant with wiki for stable facts |

"A combined approach (wiki for context + RAG for verification) never lost a single round, even in tasks specifically designed to favor RAG." — MindStudio analysis

### Blueprint Status
- PARTIALLY COVERED: Section 10 RAG vs wiki comparison exists.
- NOT COVERED: concrete token thresholds.
- NOT COVERED: explicit hybrid recommendation.

### Recommendation: **EXTEND** Section 10 with token threshold table. **ADD** explicit hybrid architecture recommendation.

---

## Research Question 10: Cost Economics

### Findings
- Embedding costs at wiki scale (~200 pages): effectively $0 on Cloudflare Workers AI free tier
- LLM lint pass: ~$0.10-0.50 per full wiki scan with Haiku-class models
- Source re-fetch (citation health): bandwidth-limited, not cost-limited
- qmd (local BM25+vector): $0 (runs locally)
- SpaCy relationship extraction: $0 (runs locally, 94% of LLM quality)
- Hash-chain audit: 3.4ms/step overhead, negligible cost

### Blueprint Status
- NOT COVERED: cost guidance for optional components.

### Recommendation: **ADD** cost notes to optional component recommendations (helps teams decide activation).

---

## Top 10 Recommendations for v2.7 (Ranked by Impact)

| Rank | Recommendation | Section | Action | Source |
|---|---|---|---|---|
| 1 | Name "error compounding" as the wiki-unique risk + add mitigation | New subsection in S18 | ADD | IQ Source, MindStudio |
| 2 | O(N * k) NLI pipeline for contradiction detection (replace O(N^2)) | S15 / KB Linter | EXTEND | WikiCollide arXiv 2509.23233 |
| 3 | Typed relationships in wiki frontmatter schema | S11 wiki page schema | ADD | rohitg00 v2, GraphRAG, arXiv 2507.03226 |
| 4 | Concrete scale thresholds (<200 / 200-500 / >500 pages) | S10, S20 | EXTEND | wiki-recall, MindStudio, multiple |
| 5 | Five wiki-specific failure modes (drift, consolidation, rot, inflation, compounding) | New subsection | ADD | RefChecker, HaluGate, WikiCollide |
| 6 | Archive-on-ingest + dual URL provenance | S14, source frontmatter | ADD | Wikipedia policy, ArchiveBox, AuditableLLM |
| 7 | Page-level optimistic locking for multi-agent writes | S8 or new | ADD | tick-md, Anthropic coordination blog |
| 8 | Refine three-tier → five-layer memory model | S20 | EXTEND | wiki-recall (93% recall) |
| 9 | SpaCy budget path for relationship extraction (94% of LLM quality) | S10 or S24 | ADD | arXiv 2507.03226 |
| 10 | Hash-chain audit log for compliance deployments | S14 | ADD (conditional) | AuditableLLM MDPI 2026 |
