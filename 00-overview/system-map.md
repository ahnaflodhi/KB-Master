---
id: 00-overview/system-map
title: System Component Map
purpose: knowledge-spec
audience: [orchestrator, planner, truthsayer, pre_check, executor, evaluator, kb_linter, wiki_ingest, wiki_query, meta_review, apply_meta]
status: stable
version: 2.9
last_reviewed: 2026-05-04
extracted_from:
  source: synthesis
  sections: ["§3 Architecture Overview", "§4 Directory Structure", "§25 External Agent Delegation Protocol (three-layer architecture)"]
  line_range_hint: "synthesis from §3 ASCII diagram + §4 directory tree + §25 roles/agents/adapters layering"
depends_on:
  - 00-overview/invariants.md
related:
  - 00-overview/philosophy.md
  - 00-overview/design-principles.md
  - 10-pipeline/state-machine.md
  - 10-pipeline/file-contracts.md
max_lines: 120
directives:
  must_count: 0
  should_count: 0
  may_count: 0
---

## System Component Map

This file is the high-altitude view: where the moving parts live, how the layers stack, and which artifacts cross which boundaries. For runtime detail follow the `related:` links — this file does not duplicate them.

### Three layers

| Layer | What lives here | Loaded by | Source of truth |
|---|---|---|---|
| **Layer 1** — Monolith | `SYSTEM-BLUEPRINT.md` (canonical reference, ~2,500 lines), `SYSTEM-BLUEPRINT-v{N}.md` (immutable snapshots) | Adopters who pin the v2.x path; backwards compatibility | This file is the canonical reference; never the runtime ingest entrypoint after Phase 4 |
| **Layer 2** — Decomposed wiki | `00-overview/`, `10-pipeline/`, `20-roles/`, `30-knowledge/`, `40-runtime/`, `50-adapters/`, `60-schemas/`, `80-status/` (each file ~50–180 lines) | Phase-2+ adopters via bundle assembly | Each file is the canonical reference for its slice; the monolith is regenerated FROM these via `tools/build-blueprint.sh` |
| **Layer 3** — Bundles | `bundles/<role>.yaml` (~3.5k tokens steady-state, ~7k worst-case) | Orchestrator at session start, per role dispatch | `tools/build-bundle.sh` derives membership from Layer-2 frontmatter (`audience`, `also_needed_by`, `purpose`) |

The **adoption direction** is one-way: a project loads bundles → bundles enumerate Layer-2 files → Layer-2 files were extracted from Layer-1. An adopter never reads the monolith at runtime once Phase 4 lands; the orchestrator-core bundle replaces "read SYSTEM-BLUEPRINT.md" entirely.

### Three-layer agent architecture (§25)

```
┌─────────────────────────────────────────────────────────────────┐
│  ROLES (blueprint)                                              │
│  Planner | TruthSayer | Pre-Check | Executor | Evaluator |      │
│  KB Linter | Wiki Ingester | Wiki Querier | Meta-Review | …     │
│  Stable. The blueprint never names a specific agent.            │
└──────────────────────────┬──────────────────────────────────────┘
                           │ assigned via agents.config.yaml
┌──────────────────────────▼──────────────────────────────────────┐
│  AGENTS (concrete instances)                                    │
│  claude-main (orchestrator, singleton, NON-DELEGABLE per Inv 9) │
│  claude-worker-{planner|research|commercial|kblint|…}           │
│  codex-{audit|eval|implement} (via codex-task-bridge)           │
│  [future: devstral-*, mistral-*, cursor-*, mcp-*]               │
└──────────────────────────┬──────────────────────────────────────┘
                           │ invoked via
┌──────────────────────────▼──────────────────────────────────────┐
│  ADAPTERS (protocol drivers)                                    │
│  claude-orchestrator | claude-native | codex-bridge |           │
│  [future: openai-compat-http | cursor-cli | mcp-agent]          │
│  Each adapter MUST report enforces_pre_action_facts (Inv 10).   │
└─────────────────────────────────────────────────────────────────┘
```

### Per-product directory shape (§4)

A product directory under `products/<product>/` contains:

- **Pipeline state**: `PROJECT.md`, `PROGRESS.md`, `LESSONS.md`, `iterate.sh`, `quality-criteria.json`
- **Domain knowledge**: `wiki/` (index, log, entities/competitors|apis|markets|tools|buyers, concepts/, synthesis/contradictions|feasibility|cross-cluster, claims/unverified|verified)
- **Build process meta-learning**: `knowledge/` (INDEX, findings/knowledge.md max 30 obs, methodology/hypotheses.md max 15, methodology/rules.md max 20 with temporal metadata, gaps/knowledge.md)
- **Immutable raw input**: `sources/research/iter-NNN/` (one dir per iteration; index.md + per-fetch files; never modified after initial save per Invariant 8)
- **Decisions**: `decisions/YYYY-MM-DD-{topic}.md`
- **Schemas**: `schema/` (entity types, extraction prompts)
- **Meta**: `meta/` (meta-review outputs)
- **Outputs**: `outputs/` (compiled deliverables — separate from wiki)
- **Iteration state**: `iterations/current/` (active 6-file chain) + `iterations/archive/iter-NNN/` (snapshots)

### The 6-file inter-agent chain (§8)

```
iterations/current/
├── spec.md              ← Planner writes; TruthSayer/Evaluator(pre-check) read
├── audit-report.md      ← TruthSayer writes; Executor/Evaluator read
├── acceptance-checklist.md ← Evaluator writes (pre-check); Executor reads
├── contract.md          ← Planner writes (after pre-check-complete); Executor reads
├── execution-log.md     ← Executor writes; Evaluator/KB-Linter read
└── eval-report.md       ← Evaluator writes; KB-Linter/Archive read
```

Optional companions: `spec-feedback.md` (Evaluator → Planner on SPEC-FLAW route); `escalation.md` (any agent → Human-in-loop on cycle exhaustion). Per-schema detail in `60-schemas/`.

### Where each component is documented

| Component | Authoritative file |
|---|---|
| Invariants 1–10 | `00-overview/invariants.md` |
| Philosophy & failure modes | `00-overview/philosophy.md` |
| Design principles | `00-overview/design-principles.md` |
| Iteration state machine | `10-pipeline/state-machine.md` |
| Iteration lifecycle (narrative) | `10-pipeline/iteration-lifecycle.md` |
| Inter-agent file contracts | `10-pipeline/file-contracts.md` |
| Per-file schemas | `60-schemas/*.md` |
| Quality gates & reward-hacking | `10-pipeline/quality-gates.md` |
| Escalation rules | `10-pipeline/escalation-rules.md` |
| Capability maturity | `80-status/shipped-vs-planned.md` |

Phase-3+ planned: `20-roles/` (per-role contracts), `30-knowledge/` (KB architecture detail), `40-runtime/` (delegation protocol, ledger semantics), `50-adapters/` (per-adapter spec), `70-adoption/` (per-scenario adoption guides). Status of each in `80-status/shipped-vs-planned.md`.

---
