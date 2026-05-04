---
name: WikiCollide — contradiction detection at scale (arXiv 2509.23233)
type: reference
researched: 2026-04-12
primary_sources:
  - https://www.emergentmind.com/papers/2509.23233
  - https://arxiv.org/abs/2509.23233
---

# WikiCollide — Detecting Wikipedia Inconsistencies with LLMs

## Core finding

**At least 3.3% of atomic facts in English Wikipedia are inconsistent with other facts in the corpus** (99% CI: 1.6%–5.0%).

These inconsistencies propagate into downstream QA benchmarks: 7.3% of FEVEROUS examples and 4.0% of AmbigQA examples are affected.

## Dataset

- **Size**: 955 manually annotated atomic facts
- **Inconsistency rate in sample**: 34.7% labeled inconsistent (enriched sample, not random baseline)
- **Source**: Level 5 Vital Articles, extracted via GPT-4o, filtered for likely inconsistencies, human-verified
- **Contradiction taxonomy**: 7 types. Most prevalent:
  - Numerical discrepancies: 54.7%
  - Logical contradictions: 17.5%

## Three detection systems benchmarked

### CLAIRE (best performer)
- ReAct-based agent with tools: `clarify` (entity disambiguation) and `explain` (terminology)
- Outputs continuous inconsistency score [0,1]
- **75.1% AUROC** on test set (80.9% on validation)
- Ablation: both tools necessary for optimal performance
- Uses RankGPT for reranking retrieved evidence

### Retrieve-and-Verify
- Standard retrieval followed by LLM-based verification
- Details sparse in summary

### NLI Pipeline
- Retrieval → pairwise NLI classification → triage
- Modular: retriever → NLI classifier → triage system
- Benefits: faster iteration and clearer audits than agentic approach

## Sampling approach for prevalence estimation
Random sampling from Wikipedia + CLAIRE-assisted analysis to estimate prevalence. Heavily domain-dependent:
- History/narrative-heavy articles: up to **17.7%** inconsistency rate
- Technical domains (math): much more reliable

## Failure modes
- **Entity conflation**: two distinct entities merged
- **Context-dependent false positives**: rounding differences, translation variants, temporal mismatches
- **Inability to distinguish scholarly disagreement from factual contradiction**

## Relevance to our blueprint

Our Section 15 describes contradiction file format with severity tiers, and Section 22 covers harness assumption decay. WikiCollide provides:

1. **Concrete baseline rate**: expect ~3.3% of claims to be internally inconsistent. Our O(N^2) contradiction-scan assumption can be replaced with a sampling strategy: scan a random subset and extrapolate.

2. **Taxonomy of contradiction types** we could adopt: numerical discrepancy, logical contradiction, entity conflation, temporal mismatch, rounding/translation artifacts, scholarly disagreement.

3. **NLI pipeline as a scalable lint approach**: retrieve → NLI classify → triage. This is O(N * k) where k is retrieval depth, NOT O(N^2). Replace pairwise scan with embedding-based retrieval of claims most likely to conflict, then NLI classify only those pairs.

4. **Domain-dependent scanning frequency**: narrative-heavy wiki pages need more frequent scanning than technical/formal pages.

5. **The 0.85 AUROC ceiling** tells us automated detection will miss ~25% of contradictions — manual review at meta-review cadence remains necessary.
