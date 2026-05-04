---
name: wiki-recall — 5-layer memory architecture with 550-token wake-up
type: reference
researched: 2026-04-12
primary_sources:
  - https://github.com/aviraldua93/wiki-recall
---

# wiki-recall — Compiled Knowledge Meets Layered Recall

Combines Karpathy wiki with MemPalace memory layers. 5-layer architecture, ~550 tokens to wake up. 2,291 tests.

## 5-Layer Memory Architecture

| Layer | Name | Contents | Size | Loading |
|---|---|---|---|---|
| L0 | Brain | Identity + active work | ~300 tokens | Always loaded |
| L1 | Decisions | Settled architectural choices | ~250 tokens | Always loaded |
| L2 | Wiki | Compiled knowledge with citations | Variable | On-demand |
| L3 | Sessions | Full session history search | Large | Fallback |
| L4 | Raw | Unprocessed session data | Largest | Never direct |

**Wake-up cost**: L0 + L1 = ~550 tokens (identity + active blockers + key decisions).

## Routing logic
- Architecture questions → L2 compiled wiki
- Historical queries → L3 session search
- Identity questions → L0 brain layer

## Performance (load-bearing numbers)

| Approach | Recall | Tokens/Query |
|---|---|---|
| Wiki-only | ~60% | Low |
| Search-only | ~45% | High |
| **Hybrid (wiki-recall)** | **~93%** | **Low** |

**Token savings**: 98.4% reduction vs loading everything (550 vs 13,000+ tokens).
**Scale**: handles up to 1,000 entities without degradation.

## Test coverage
- TypeScript: 1,727 tests (100% pass)
- Python: 564 tests (100% pass)
- Stress-tested: SQL injection, concurrent CRUD, corrupt YAML, unicode edge cases

## Relation to our blueprint

Our blueprint (Section 19) describes a three-tier memory model:
1. always-loaded (CLAUDE.md, hot cache)
2. load-on-demand (wiki pages)
3. search-only (deep archive)

wiki-recall adds two refinements:
1. **Splits "always-loaded" into L0 (identity/active) and L1 (decisions)** — letting the system load with ~550 tokens vs our unquantified "small" tier
2. **Explicit session history layer (L3)** between wiki and raw — we archive iterations but don't have a searchable session-history layer

The **93% recall at low token cost** vs 60% wiki-only and 45% search-only strongly validates the hybrid approach and suggests our blueprint should specify that wiki-only retrieval is insufficient at scale.

Key threshold: **~1,000 entities** — beyond this, unknown if the architecture holds. Our 200-line index.md cap maps to roughly this entity count.
