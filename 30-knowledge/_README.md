# 30-knowledge/ — Knowledge architecture

This directory documents the two artifacts that compound across iterations: the **wiki** (`wiki/`) which captures what is known about the project's subject domain, and the **knowledge base** (`knowledge/`) which captures what the team has learned about how to build this project. The Karpathy two-layer separation + the process-learning extension are the architectural backbone; the temporal-fact protocol and three-tier memory model are how the architecture stays usable at scale.

For frontmatter conventions see `00-overview/_README.md`. Per-directory cap for `30-knowledge/*` is 200 lines per file (knowledge content is denser than runtime spec).

## Index

| File | Purpose | Source |
|---|---|---|
| [wiki-architecture.md](wiki-architecture.md) | Karpathy two-layer (`sources/` + `wiki/`); per-cluster wiki structure; index/log/synthesis files | §10 + §4 |
| [knowledge-base.md](knowledge-base.md) | Process-learning extension (`knowledge/`); findings → hypotheses → rules with caps (30/15/20); confirmation thresholds | §10 + §12 |
| [temporal-facts.md](temporal-facts.md) | Temporal-fact protocol per Inv 6; `valid_from` / `invalidated_at`; never-overwrite rule; provenance chain | §13 |
| [three-tier-memory.md](three-tier-memory.md) | Selective retrieval per §20; Tier 1/2/3; ~93% recall at ~98.4% token reduction; lost-in-the-middle | §20 |
| [wiki-failure-modes.md](wiki-failure-modes.md) | Five wiki-specific failure modes (error compounding, claim drift, false consolidation, citation rot, confidence inflation) + KB-Linter detection patterns | §11 |

## What lives where

```
sources/research/iter-NNN/    immutable raw input (Invariant 8)
wiki/                          synthesised domain knowledge (Karpathy layer 2)
  index.md                       Tier-1 entry point (≤ 200 lines)
  log.md                         one-line ingest record per iteration
  entities/                      per-entity pages (competitors/apis/markets/tools/buyers)
  concepts/                      cross-entity concepts
  synthesis/                     contradictions, feasibility, cross-cluster
  claims/unverified/             SINGLE-SOURCE claims (KB Linter promotes)
  claims/verified/               CROSS-VERIFIED + CONFIRMED claims
knowledge/                     process-learning extension (this project's, not Karpathy's)
  INDEX.md                       Tier-1 entry point
  findings/knowledge.md          observations (cap 30)
  methodology/hypotheses.md      promoted from findings (cap 15)
  methodology/rules.md           promoted from hypotheses (cap 20; valid_from/invalidated_at)
  gaps/knowledge.md              known unknowns
```

## Why these five files

The blueprint role layer (`20-roles/`) describes WHO produces and consumes knowledge. The runtime layer (`40-runtime/`) describes HOW delegations move through the system. This directory describes WHAT the knowledge artifacts are and the rules that govern their evolution:

- An adopter setting up `wiki/` reads `wiki-architecture.md` for the directory shape and frontmatter requirements.
- An adopter wiring up the KB Linter reads `knowledge-base.md` for the promotion thresholds (30/15/20) and `temporal-facts.md` for the never-overwrite rule.
- An adopter scaling past 200 wiki pages reads `three-tier-memory.md` to avoid the lost-in-the-middle attention effect.
- An adopter debugging a "good claims overwritten by bad ones" incident reads `wiki-failure-modes.md` for the documented detection patterns.

## What NOT to put in 30-knowledge/

- Per-role mandate (lives in `20-roles/<role>.md`, especially `wiki-ingester.md`, `wiki-querier.md`, `kb-linter.md`).
- Per-adapter contract (lives in `50-adapters/<adapter>.md`).
- File schemas (live in `60-schemas/<file>.md`).
- Pipeline state-machine (lives in `10-pipeline/state-machine.md`).
- Token budget guidance (lives in `00-overview/design-principles.md`).

This directory describes the *artifacts* and the *rules that govern their evolution*, not the actors or the runtime mechanisms.

---
