---
name: Synthesis quality and hallucination patterns in LLM-compiled wikis
type: reference
researched: 2026-04-12
primary_sources:
  - https://github.com/amazon-science/RefChecker
  - https://vllm.ai/blog/halugate
  - https://www.iqsource.ai/en/blog/karpathy-llm-wiki-knowledge-compounds-or-rots/
  - https://www.emergentmind.com/papers/2509.23233
---

# Synthesis Quality and Hallucination Patterns in LLM-Compiled Wikis

## Wiki-specific failure modes (distinct from general LLM hallucination)

### 1. Error compounding (the wiki-unique risk)
"The LLM writes a wiki page with a subtle mistake. Someone queries against that page. The mistake enters the answer. The answer gets filed back. Now two pages reinforce the same error."
— Unlike per-prompt hallucinations that reset, wiki errors persist and self-reinforce.

### 2. Claim drift (paraphrase loses precision)
When an LLM summarizes a source, paraphrasing introduces subtle shifts. Over multiple compilation rounds, the claim drifts further from the original. Detection: compare compiled claim embedding to source claim embedding; flag when cosine similarity drops below threshold.

### 3. False consolidation (merging distinct entities)
When two sources discuss similar-but-distinct concepts, the LLM may merge them into a single wiki page. Example: two different "Transformer" architectures treated as one. Detection: entity resolution with typed attributes; flag when a single wiki entity cites sources that describe incompatible attributes.

### 4. Citation rot (citation no longer supports claim)
Original source may be updated, deleted, or its content may have changed since the wiki page was compiled. Detection: periodic re-fetch and diff of source content against the claim it supports.

### 5. Confidence inflation
LLM-generated text tends to state things more confidently than sources warrant. "Medium confidence" in a source becomes "is" in the wiki. Detection: compare hedging language in source vs wiki; flag definitive claims derived from hedged sources.

## Detection tools

### RefChecker (Amazon, EMNLP 2024)
- Three-stage: claim extraction → hallucination checking → aggregation
- **Knowledge triplet format**: (subject, predicate, object) — same as knowledge graph structure
- Granularity: per-triplet, not per-sentence. Catches partial hallucinations within correct sentences.
- Outperforms sentence-level checkers by 18.2-27.2 points on benchmark
- Supports: GPT-4, Claude, open-source models via vllm, NLI-based checkers, AlignScore
- Fine-tuned Mistral 7B for claim extraction
- Three evaluation contexts: zero-context, noisy-context (RAG), accurate-context (single doc)
- **Directly applicable to wiki verification**: treat wiki page as "response", source documents as "references"

### HaluGate (vLLM, Dec 2025)
- Three-stage: sentinel (needs checking?) → token detection → NLI explanation
- Per-token granularity with CONTRADICTION/NEUTRAL/ENTAILMENT classification
- Total overhead: 76-162ms
- Token confidence threshold: 0.8; NLI confidence threshold: 0.9
- Practical for batch processing wiki pages (not real-time constrained)

### WikiCollide (arXiv 2509.23233)
- Baseline: 3.3% of English Wikipedia facts are internally inconsistent
- NLI pipeline approach: retrieve → NLI classify → triage
- O(N * k) complexity where k = retrieval depth, NOT O(N^2)
- Domain variation: 17.7% in history/narrative vs much lower in math/technical

## Recommended detection pipeline for wiki lint

1. **Extract claims as knowledge triplets** (RefChecker-style) from each wiki page
2. **For each triplet, retrieve source passage** that should support it
3. **NLI classify**: ENTAILMENT (supported) / NEUTRAL (unverifiable) / CONTRADICTION (error)
4. **Flag NEUTRAL + CONTRADICTION** for human review at meta-review cadence
5. **Track claim-to-source cosine similarity over time** — flag drift > 0.15
6. **For cross-page contradictions**: embed all triplets, retrieve top-k similar pairs, NLI classify pairs. This is O(N * k), not O(N^2).

## Relation to our blueprint

Already covered:
- Contradiction file format with severity tiers
- TruthSayer agent for adversarial verification
- Evaluator agent for quality scoring

Not yet covered:
- **Knowledge triplet granularity** for claim verification (we verify at page level)
- **Error compounding as the wiki-specific risk** — needs explicit callout and mitigation
- **Claim-to-source embedding drift monitoring** as a lint operation
- **Confidence inflation detection** (hedging-language comparison)
- **The O(N * k) contradiction scan** replacing O(N^2) pairwise comparison
