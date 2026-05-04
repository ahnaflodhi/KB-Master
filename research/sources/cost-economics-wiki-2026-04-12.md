---
name: Cost economics of LLM wiki compilation and maintenance
type: reference
researched: 2026-04-12
primary_sources:
  - https://www.silicondata.com/blog/llm-cost-per-token
  - https://pricepertoken.com/
  - https://blog.starmorph.com/blog/karpathy-llm-wiki-knowledge-base-guide
---

# Cost Economics of LLM Wiki at Scale (April 2026)

## Token pricing (April 2026)

| Model | Input/1M | Output/1M | Notes |
|---|---|---|---|
| Claude Sonnet 4 | $3.00 | $15.00 | Primary wiki compilation model |
| GPT-4o | $2.50 | $10.00 | Alternative |
| GPT-4o Mini | $0.15 | $0.60 | Lint / bulk operations |
| DeepSeek V3.2 | $0.14 | $0.28 | Cheapest high-quality |
| Gemini 3.1 Flash-Lite | $0.10 | $0.40 | Cheapest proprietary |

Batch API discount: ~50% off standard pricing (OpenAI confirmed).

## Per-article ingest cost estimate

Assumptions per article ingest:
- Read source: ~5K-20K tokens input
- Read existing wiki pages (10-15 pages): ~30K-60K tokens input
- Generate/update pages (10-15 pages): ~3K-5K tokens output per page = ~30K-75K output total
- Update index.md + log.md: ~1K output

### Conservative estimate per article (Claude Sonnet 4)

| Operation | Input tokens | Output tokens | Cost |
|---|---|---|---|
| Source read | 15K | - | $0.045 |
| Wiki read (10 pages) | 40K | - | $0.12 |
| Wiki write (10 pages) | - | 40K | $0.60 |
| Index/log | - | 1K | $0.015 |
| **Total per article** | **55K** | **41K** | **~$0.78** |

### At scale

| Scale | Claude Sonnet 4 | GPT-4o Mini | DeepSeek V3.2 |
|---|---|---|---|
| 100 articles | ~$78 | ~$3.50 | ~$2.40 |
| 500 articles | ~$390 | ~$17.50 | ~$12 |

## Lint cost estimate

Full lint pass (read all pages + pairwise comparison of flagged claims):
- Read 200 pages: ~400K tokens input
- NLI/contradiction analysis: ~100K tokens output
- **Per full lint**: ~$1.20 (Sonnet) / ~$0.07 (Mini) / ~$0.05 (DeepSeek)

With WikiCollide-style sampling (check 10% random sample):
- **Per sampled lint**: ~$0.12 (Sonnet) / ~$0.007 (Mini)

## Query cost

- Read index + relevant pages: ~10K-50K input tokens
- Generate answer: ~500-2K output tokens
- **Per query**: ~$0.03-0.15 (Sonnet) / ~$0.002-0.008 (Mini)

## Embedding cost (qmd / vector index)

- text-embedding-3-small: $0.02 per 1M tokens
- embeddinggemma-300M (local, qmd): $0 (GPU compute only)
- Initial embedding of 200-page wiki (~400K tokens): ~$0.008 (API) or free (local)

Embedding costs are negligible compared to compilation costs.

## Key economics takeaway

1. **Compilation (output tokens) is the dominant cost** — output tokens are 3-5x more expensive than input
2. **Lint is cheap** — mostly input tokens (reading), limited output
3. **Queries are cheap** — small output relative to compilation
4. **Model tiering is critical**: use Sonnet for compilation quality, Mini/DeepSeek for lint and bulk operations
5. **Batch API halves compilation cost**: ingest jobs can be batched
6. **No published production cost data exists** — these are estimates from token pricing
