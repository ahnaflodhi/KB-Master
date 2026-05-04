---
name: HaluGate — token-level hallucination detection pipeline
type: reference
researched: 2026-04-12
primary_sources:
  - https://vllm.ai/blog/halugate
  - https://huggingface.co/llm-semantic-router/halugate-sentinel
---

# HaluGate — Token-Level Hallucination Detection (vLLM, Dec 2025)

Three-stage conditional pipeline for catching unsupported claims before they reach users. Native Rust inference via Candle. Integrated into vLLM Semantic Router v0.1 "Iris."

## Pipeline

### Stage 1: HaluGate Sentinel (prompt classification)
- ModernBERT + LoRA binary classifier
- Decides if query requires fact-checking at all
- Skips creative, coding, opinion queries
- **72.2% efficiency gain**: ~35% of production queries are non-factual
- Accuracy: 96.4%, Latency: ~12ms
- Confidence threshold: 0.6 for FACT_CHECK_NEEDED

### Stage 2a: Token-Level Detection
- ModernBERT token classifier
- Input: `[CLS] context [SEP] question [SEP] answer [SEP]`
- Output: binary labels (0=Supported, 1=Hallucinated) per answer token only
- F1 on hallucinated class: 59% (known to over-flag — NLI stage filters)
- Latency: 45ms P50
- Token confidence threshold: 0.8 (configurable)
- Consecutive hallucinated tokens merged into spans

### Stage 2b: NLI Explanation
- ModernBERT NLI fine-tuned, 3-way classification
- Categories:
  - **CONTRADICTION** (severity 4): direct factual error
  - **NEUTRAL** (severity 2): unverifiable claim
  - **ENTAILMENT** (severity 0): false positive, filtered out
- NLI confidence threshold: 0.9
- Latency: 18ms P50

### Total overhead: 76-162ms

## Integration
Propagates via HTTP headers:
- `x-vsr-hallucination-detected: true`
- `x-vsr-hallucination-spans: [token list]`
- `x-vsr-nli-contradictions: [count]`
- `x-vsr-max-severity: [0-4]`

Actions configurable per deployment: `header` / `body` / `block` / `none`

## Relevance to our blueprint

### For wiki compilation quality
HaluGate's three-stage pattern maps directly to wiki page quality control:
1. **Sentinel equivalent**: not all wiki pages need claim verification (e.g., pure summaries vs factual claims)
2. **Token-level detection**: identify WHICH claims in a wiki page lack source support
3. **NLI explanation**: classify each flagged claim as CONTRADICTION / NEUTRAL / ENTAILMENT

### Concrete adoption patterns
- Our Evaluator agent could run a HaluGate-style pipeline on each compiled wiki page
- The severity scale (0-4) maps to our existing contradiction severity tiers
- The 0.8 token confidence + 0.9 NLI confidence thresholds are tuning starting points
- The ~76-162ms overhead per page is negligible at wiki compilation scale (not real-time)

### What our blueprint is missing
- **Per-claim granularity in verification** — we verify at page level, not claim level
- **Severity classification on individual claims** (CONTRADICTION / NEUTRAL / ENTAILMENT) — our contradiction file is page-to-page, not claim-to-claim
- **Conditional checking** (skip non-factual content) — we don't distinguish factual from non-factual wiki content in our lint pipeline
