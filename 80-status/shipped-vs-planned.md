---
id: 80-status/shipped-vs-planned
title: Shipped vs Planned — Capability Maturity
purpose: status
audience: [orchestrator, planner, evaluator, human]
also_needed_by: [meta_review]
status: active
version: 2.8.1
last_reviewed: 2026-05-04
extracted_from:
  source: SYSTEM-BLUEPRINT-v2.8.md
  sections: ["§25", "§24", "§19 v2.8 addendum", "§2 Invariant 9"]
  line_range: [2195, 2371]
related:
  - 50-adapters/codex-bridge.md
  - 50-adapters/capability-matrix.md
  - ../claude-codex-orchestration/BRIDGE_REQUIREMENTS.md
  - .claude/plans/crispy-sniffing-conway.md
max_lines: 100
---

# Shipped vs Planned

A single answer to the question: **what is currently working, what is specified but not yet wired, and what is gated behind a runtime probe?**

This file exists because the audit (`auditor-central/KB-Orchestrator/audit.md` finding #5) flagged that timeless invariants, current shipped behavior, planned bridge capability, and future adapter strategy were all mixed inside one continuous document. Agents could not tell what to gate behind probes. This file is the separation.

Source of truth at runtime: `agents.config.yaml` for adapters/agents/roles; `codex-task-bridge capabilities --json` for bridge surface; this file for everything else.

## Blueprint architecture

| Capability | Status | Source | Notes |
|---|---|---|---|
| §1–24 (philosophy, invariants 1–8, roles, KB architecture, wiki spec, harness integration, etc.) | **shipped** (v2.0–v2.7) | SYSTEM-BLUEPRINT.md | All baseline architecture. Stable. |
| §25 External Agent Delegation Protocol | **shipped** (v2.8) | SYSTEM-BLUEPRINT.md §25 | Service-agnostic three-layer (roles/agents/adapters). Spec complete. |
| Invariant 9 — orchestrator role non-delegable | **shipped** (v2.8) | SYSTEM-BLUEPRINT.md §2 | |
| §19 v2.8 addendum — delegated-output trust + verification ledger | **shipped** (v2.8) | SYSTEM-BLUEPRINT.md §19 | |
| Invariant 10 — pre-action fact presentation | **shipped** (v2.9) | SYSTEM-BLUEPRINT.md §2 + §25 adapter `enforces_pre_action_facts` field | Harness-enforced via PreToolUse hook (Claude Code: gateguard skill). Adapters reporting false restricted to read-only roles. |
| §25 host_access adapter capability | **shipped** (v2.10) | SYSTEM-BLUEPRINT.md §25 + agents.config.yaml policy block | Source-attributed to Codex's BRIDGE_REQUIREMENTS:165-192 Stage-4 lesson. Default-deny: missing/partial host_access subfields treated as false. |

## Repository assets

| Asset | Status | Path | Notes |
|---|---|---|---|
| `agents.config.yaml` | **shipped** (v2.10) | project root | Registry: adapters, agents, roles, validation, policy. `schema_version: 1`, `config_revision: 3`. v2.9 added Invariant-10 policy block; v2.10 added host_access policy block + per-adapter advertisements. |
| `commands/_delegate.md` | **shipped** (v2.10, Step-2 host_access wired in Phase 5) | commands/ | Eleven-step dispatch sequence with v2.9 enforces_pre_action_facts check + v2.10 host_access compatibility check at Step 2 PROBE. Step 3 PREPARE references bundles. |
| `commands/pre-check.md` | **shipped** (v1.0+, drift-fixed v2.8.1) | commands/ | The original role-bearing slash command. |
| 10 role-bearing slash commands (`plan`, `audit`, `execute`, `evaluate`, `kb-lint`, `wiki-ingest`, `wiki-query`, `escalate`, `meta-review`, `apply-meta`) | **shipped** (v3.0 Phase 5) | commands/ | Each composes `_delegate.md` with role + inputs + expected_schema; routing per the role's contract in `20-roles/`. |
| Layer-2 role contracts (`20-roles/*.md`, 11 files) | **shipped** (v3.0 Phase 3) | 20-roles/ | One file per blueprint role: orchestrator, planner, truthsayer, pre-check, executor, evaluator, kb-linter, wiki-ingester, wiki-querier, meta-review, apply-meta. Each ≤150 lines. |
| `templates/schemas/<schema>.md` (referenced by `_delegate.md` step 8) | **shipped** (v3.0 Phase 2 — relocated to `60-schemas/`) | 60-schemas/ | 10 schema files + `_README.md`. Schema validation is now actionable. |
| Layer-2 numbered directories (`00-overview/` … `80-status/`) | **shipped** (v3.0 Phases 0–4) | project root | 00/10/20/30/40/50/60/80 populated (52 files total). 70/adoption-guides/ still planned (Phase 5+). |
| Knowledge architecture (`30-knowledge/*.md`, 6 files) | **shipped** (v3.0 Phase 4) | 30-knowledge/ | wiki-architecture, knowledge-base, temporal-facts, three-tier-memory, wiki-failure-modes + _README. |
| Runtime semantics (`40-runtime/*.md`, 6 files) | **shipped** (v3.0 Phase 4) | 40-runtime/ | dispatch-shim, verification-ledger, bootstrap-and-degradation, harness-decay, claude-code-integration + _README. |
| Adapter contracts (`50-adapters/*.md`, 5 files) | **shipped** (v3.0 Phase 4) | 50-adapters/ | claude-orchestrator, claude-native, codex-bridge, capability-matrix + _README. Future adapters (openai-compat-http, cursor-cli, mcp-agent) remain commented templates in agents.config.yaml. |
| Bundle manifests (`bundles/*.yaml`, 13 files) | **shipped** (v3.0 Phase 5) | bundles/ | All 13 manifests (orchestrator-core, planner, truthsayer, pre-check, executor-research, executor-commercial, evaluator, kb-linter, wiki-ingest, wiki-query, meta-review, apply-meta, agent-onboarding). Hand-written for v1; tools/build-bundle.sh generation logic deferred to Phase 6. tools/build-bundle.sh --check passes structural validation on all 13. |
| INDEX.md (Layer-3 entrypoint) | **shipped** (v3.0 Phase 5) | project root | The runtime ingest entry. Replaces "read SYSTEM-BLUEPRINT.md" with role-specific bundle loading. |
| `tools/` scripts (build-blueprint, verify-frontmatter, verify-cross-refs, build-bundle) | **shipped** (v3.0 Phase 1) | tools/ | All four operational; verify-* gates currently green for 32/32 frontmatter, 46/46 cross-refs. |
| `pipeline/verification-ledger.jsonl` | **active** (v3.0 Phases 2 + 3 + v2.10 propagation logged) | pipeline/ | Schema per §19 v2.8 addendum. 72 entries across Phase-2 extractions, Phase-3 syntheses, and v2.10 propagation. 35 accepted + 1 re-delegated (sandbox boundary, recovered). |

## Codex bridge capabilities (per BRIDGE_REQUIREMENTS.md)

Authoritative source: `codex-task-bridge capabilities --json` at runtime (when protocol ≥ 2). This table is descriptive and may lag.

| Bridge capability | Status | Notes |
|---|---|---|
| `run --mode design` (sync) | **shipped** (MVP) | Used by `codex-audit`, `codex-eval` agents under `agents.config.yaml`. |
| `run --mode implement` (sync) | **shipped** (MVP) | Used by `codex-implement` agent. |
| `start --mode design\|implement` (async) | **shipped** (MVP) | Available for parallelised extraction in v3.0 Phase 2+. |
| `status` / `tail` / `result` / `list` | **shipped** (MVP) | |
| `--model` passthrough | **shipped** (MVP) | |
| `version` + `capabilities --json` probes | **planned** | Until shipped, orchestrators must follow bootstrap fallback (treat as protocol 1). |
| `--mode review` (`codex exec review`) | **planned** | Preferred mode for `codex-eval` once available. Currently uses `--mode design` with prompt-level review framing. |
| `--sandbox` first-class | **planned** | Currently sandbox is mode-default per BRIDGE_REQUIREMENTS table. |
| `resume`, `raw`, `--profile`, `--config`, `--add-dir`, `--cd`, `--image`, `--ephemeral`, `--ignore-user-config`, `--ignore-rules`, `--enable`, `--disable` | **planned** | Per BRIDGE_REQUIREMENTS planned-surface table. |
| `--output-schema` + `output.json` artifact | **planned** | Until shipped, output validation runs client-side in `_delegate.md` step 8. |
| `--json-events` + `events.jsonl` artifact + `events` subcommand | **planned** | |

## v3.0 restructure phase status

Source of truth for the current v3.0 migration: `~/.claude/plans/crispy-sniffing-conway.md` + this file's row below.

| Phase | Status | Completed at |
|---|---|---|
| **0 — Stabilize** (README freshen, monolith banner, this STATUS skeleton, CHANGELOG v2.8.1) | **shipped** (v2.8.1) | 2026-05-04 |
| **1 — Tooling foundation** (`SYSTEM-BLUEPRINT-v2.8.md` archive, `tools/` skeletons, `00-overview/_README.md`, `bundles/_README.md`) | **shipped** (v2.8.1) | 2026-05-04 |
| **2 — Extract kernel** (00/10/60) | **shipped** (v2.9) | 2026-05-04. 23 Layer-2 files extracted via joint Codex/Claude pipeline (5 in 00-overview/, 5 in 10-pipeline/, 11 in 60-schemas/, 1 in 80-status/, plus the in-source `_README.md` files). Codex produced 9 verbatim extractions; Claude produced 8 inline syntheses (where source spans multiple sections). All §25 SEMANTIC gates green; tools/verify-frontmatter and verify-cross-refs both PASS. |
| **2.5 — v2.9 INVARIANT 10** (pre-action fact presentation propagated from local hook to structural blueprint property) | **shipped** (v2.9) | 2026-05-04. New Invariant 10 in §2; new §25 adapter `enforces_pre_action_facts` field; new policy knobs in `agents.config.yaml`; PROPAGATION clause: any project loading agents.config.yaml inherits the gate. |
| **2.6 — v2.10 host_access** (Codex BRIDGE_REQUIREMENTS Stage-4 lesson propagated) | **shipped** (v2.10) | 2026-05-04. New §25 adapter `host_access` probe field (REQUIRED, default-deny); new §25 "Sandbox flags do not imply host-local service access" subsection; `policy.assume_host_access_false_unless_probed: true`; per-adapter advertisements (claude-orchestrator/native true-true, codex-bridge false-false until bridge protocol exposes the field). |
| **3 — Extract role contracts** (20-) | **shipped** (v2.10) | 2026-05-04. 11 per-role contracts in `20-roles/` (orchestrator, planner, truthsayer, pre-check, executor, evaluator, kb-linter, wiki-ingester, wiki-querier, meta-review, apply-meta) + `_README.md` index with role→adapter→sandbox→host_access matrix. All ≤150 lines per the 20-roles/ cap. |
| **4 — Extract knowledge/runtime/adapters** (30/40/50) | **shipped** (v2.10) | 2026-05-04. 17 files across 3 directories: 30-knowledge/ (6: wiki-architecture, knowledge-base, temporal-facts, three-tier-memory, wiki-failure-modes + _README); 40-runtime/ (6: dispatch-shim, verification-ledger, bootstrap-and-degradation, harness-decay, claude-code-integration + _README); 50-adapters/ (5: claude-orchestrator, claude-native, codex-bridge, capability-matrix + _README). All under per-directory caps (200/180/150 respectively). 32 Phase-4 ledger entries, all PASS. Future adapters (openai-compat-http, cursor-cli, mcp-agent) remain commented templates in agents.config.yaml until their `capability_check` passes. |
| **5 — Adoption + status + bundles + commands wiring** | **shipped** (v3.0) | 2026-05-05. 25 new files + 1 `_delegate.md` Step-2 host_access wiring. 10 role-bearing slash commands (plan, audit, execute, evaluate, kb-lint, wiki-ingest, wiki-query, escalate, meta-review, apply-meta) compose the §25 11-step shim. 13 bundle manifests in bundles/ (orchestrator-core through agent-onboarding) — hand-written for v1; `tools/build-bundle.sh --check` passes structural validation on all 13. INDEX.md is the new Layer-3 runtime entrypoint; adopters load bundles per role rather than reading the monolith. tools/verify-frontmatter PASS 46/46; tools/verify-cross-refs PASS 74/74. |
| **6 — Demote monolith** (regenerate from Layer-2 + 5-day soak) | **planned** | — |

When a phase completes, update its row's status to `shipped` with the date.
