---
id: 00-overview/glossary
title: Glossary — Terms to Defining Files
purpose: knowledge-spec
audience: [orchestrator, planner, truthsayer, pre_check, executor, evaluator, kb_linter, wiki_ingest, wiki_query, meta_review, apply_meta]
status: stable
version: 2.8
last_reviewed: 2026-05-04
extracted_from:
  source: synthesis
  sections: ["§1–§25 of SYSTEM-BLUEPRINT-v2.8.md (term-to-section pointer index)"]
related:
  - 00-overview/invariants.md
  - 10-pipeline/state-machine.md
  - 10-pipeline/file-contracts.md
max_lines: 120
directives:
  must_count: 0
  should_count: 0
  may_count: 0
---

# Glossary — what term is defined where

This is not a dictionary. It is a pointer index — for every recurring term in the blueprint, the canonical defining file. Read the term's definition there, not here.

If a term you need is missing, the term is either: (a) not yet extracted to a Layer-2 file (still in the v2.8 monolith), (b) defined in a future-Phase file (`(planned)` annotation), or (c) genuinely undefined and worth raising at meta-review.

## Architecture & roles

| Term | Defined in |
|---|---|
| **Invariant** (1–9) | `00-overview/invariants.md` |
| **Generator ≠ Evaluator** | `00-overview/invariants.md` (INVARIANT 1) |
| **Orchestrator** (role, non-delegable) | `00-overview/invariants.md` (INVARIANT 9); `20-roles/orchestrator.md` (planned, Phase 3) |
| **Planner / TruthSayer / Pre-Check / Executor / Evaluator / KB Linter / Wiki Ingester / Wiki Querier / Meta-Reviewer / Apply-Meta** | `20-roles/<role>.md` (planned, Phase 3) |
| **claude-main** | `agents.config.yaml` `agents.claude-main`; `00-overview/invariants.md` (INVARIANT 9) |
| **claude-worker-\*** (subagent / SDK executor) | `agents.config.yaml` `agents.claude-worker-*`; `50-adapters/claude-native.md` (planned, Phase 4) |
| **codex-\*** (codex-audit / codex-eval / codex-implement) | `agents.config.yaml` `agents.codex-*`; `50-adapters/codex-bridge.md` (planned, Phase 4) |
| **Adapter** (claude-orchestrator / claude-native / codex-bridge / openai-compat-http / cursor-cli / mcp-agent) | `agents.config.yaml` `adapters:`; `50-adapters/adapter-contract.md` (planned, Phase 4) |
| **Bundle** | `bundles/_README.md`; `40-runtime/delegation-protocol.md` (planned, Phase 4) |

## Pipeline & state

| Term | Defined in |
|---|---|
| **Pipeline state machine** (planning → auditing → pre-checking → pre-check-complete → contracted → executing → evaluating → kb-linting → escalated) | `10-pipeline/state-machine.md` |
| **`pipeline_state`** field | `10-pipeline/state-machine.md`; `60-schemas/iter-summary.md` (planned, Phase 2 batch 2) |
| **SPEC-FLAW route** | `10-pipeline/state-machine.md` |
| **Cycle limits** (audit ≤ 2; eval ≤ 3; pre-check ambiguity ≤ 2; spec_flaw_count ≤ 2) | `10-pipeline/state-machine.md`; `agents.config.yaml` `policy:` |
| **Six-File Inter-Agent Communication Chain** | `10-pipeline/file-contracts.md` |
| **`spec.md` / `audit-report.md` / `acceptance-checklist.md` / `contract.md` / `execution-log.md` / `eval-report.md`** formats | `10-pipeline/file-contracts.md` (overview); `60-schemas/<file>.md` (per-file schema, planned Phase 2 batch 2) |
| **Escalation** | `10-pipeline/file-contracts.md`; `10-pipeline/escalation-rules.md` (planned, Phase 2 batch 2); `60-schemas/escalation.md` (planned) |

## Trust & verification

| Term | Defined in |
|---|---|
| **Trust levels** (high / medium / low / untrusted) | `40-runtime/agent-trust-and-injection-defense.md` (planned, Phase 4) |
| **Semantic isolation** (treat field values as opaque data) | `00-overview/invariants.md` (INVARIANT 3); `40-runtime/agent-trust-and-injection-defense.md` (planned) |
| **Authentication ≠ Verification** distinction | `40-runtime/verification-ledger.md` (planned, Phase 4) |
| **Verification ledger** | `pipeline/verification-ledger.jsonl` (live); `40-runtime/verification-ledger.md` (planned) |
| **§25 verification gate** (AUTH + SCHEMA + SEMANTIC) | `commands/_delegate.md` (Steps 7-9); `40-runtime/delegation-protocol.md` (planned) |
| **Reward hacking** (4 mandatory checks) | `40-runtime/reward-hacking-checks.md` (planned, Phase 4) |

## Knowledge layer

| Term | Defined in |
|---|---|
| **Three-Layer Karpathy Pattern** (raw sources → wiki → schema) | `30-knowledge/kb-architecture.md` (planned, Phase 4) |
| **Wiki / wiki entity page / wiki/index.md** | `30-knowledge/wiki-spec.md` (planned, Phase 4) |
| **OBS → HYP → RULE promotion** | `30-knowledge/self-learning-spec.md` (planned, Phase 4) |
| **Bi-temporal model** (4 timestamps) | `30-knowledge/temporal-facts.md` (planned, Phase 4) |
| **Provenance chain** (RULE → HYP → OBS → file → URL) | `30-knowledge/provenance.md` (planned, Phase 4) |
| **Three-tier retrieval** (Tier 1 always-loaded / Tier 2 on-demand / Tier 3 search-only) | `30-knowledge/retrieval-tiers.md` (planned, Phase 4) |
| **Wiki failure modes** (error compounding, claim drift, false consolidation, citation rot, confidence inflation) | `30-knowledge/failure-modes.md` (planned, Phase 4) |
| **Confidence levels** (SINGLE-SOURCE / CROSS-VERIFIED / CONFIRMED) | `30-knowledge/wiki-spec.md` (planned, Phase 4) |

## Operations

| Term | Defined in |
|---|---|
| **Token budget** / **budget pressure mode** / **model tiering** | `40-runtime/token-budget-enforcement.md` (planned, Phase 4); `70-adoption/cost-optimization-guide.md` (planned, Phase 5) |
| **Quality criteria** (per project_type) | `60-schemas/quality-criteria.md` (planned, Phase 2 batch 2); `70-adoption/quality-thresholds-guide.md` (planned, Phase 5) |
| **Meta-review** (cadence + checklist) | `20-roles/meta-reviewer.md` (planned, Phase 3) |
| **Harness audit / harness assumption decay** | `80-status/shipped-vs-planned.md` (status); `40-runtime/claude-harness.md` (planned, Phase 4) |

## Bridge & adapters

| Term | Defined in |
|---|---|
| **Bridge** / **codex-task-bridge** | `50-adapters/codex-bridge.md` (planned, Phase 4); `../claude-codex-orchestration/BRIDGE_REQUIREMENTS.md` (external authoritative source) |
| **Bridge protocol** (1=MVP / 2+=planned) | `agents.config.yaml` `adapters.codex-bridge.cached_protocol_probe`; `80-status/shipped-vs-planned.md` |
| **Bridge mode** (`design` / `implement` / `review`) | `50-adapters/codex-bridge.md` (planned); BRIDGE_REQUIREMENTS.md |
| **Sandbox precedence** (explicit > full-auto > mode default) | `50-adapters/codex-bridge.md` (planned); BRIDGE_REQUIREMENTS.md |
| **Job artifact** (last_message.txt / meta.env / events.jsonl) | `50-adapters/codex-bridge.md` (planned); BRIDGE_REQUIREMENTS.md |
