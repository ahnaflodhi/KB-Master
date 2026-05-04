---
id: 20-roles/executor
title: Executor — Role Contract (research / commercial sub-types)
purpose: role-contract
audience:
  - executor
also_needed_by:
  - orchestrator
  - planner
  - evaluator
  - kb_linter
  - meta_review
status: stable
version: 2.10
last_reviewed: 2026-05-04
extracted_from:
  source: SYSTEM-BLUEPRINT-v2.10.md
  sections: ["§6 Executor (research)", "§6 Executor (commercial) incl. 2a per-unit type-check + 2b multi-tenancy", "§7 Phase 5 Execute", "§8 Invariant 8 (sources before claims)", "§17 model tiering"]
  line_range_hint: "synthesis: §6 both Executor sub-types + §7 Phase 5 within-execute discipline + Inv 8 sources-first + §6 stub protocol"
depends_on:
  - 00-overview/invariants.md
  - 10-pipeline/iteration-lifecycle.md
  - 60-schemas/execution-log.md
  - 60-schemas/contract.md
  - 60-schemas/acceptance-checklist.md
related:
  - 20-roles/orchestrator.md
  - 20-roles/evaluator.md
  - 20-roles/wiki-ingester.md
  - 60-schemas/eval-report.md
max_lines: 150
directives:
  must_count: 8
  should_count: 4
  may_count: 2
---

## Executor — Role Contract

### Mandate

The Executor implements what `spec.md` + `contract.md` agreed to. Two sub-types share a contract:

- **executor.research** — produces wiki pages, claims, syntheses, and source archives.
- **executor.commercial** — produces application code, tests, migrations, and configuration changes.

Both sub-types share the discipline of `execution-log.md` and the §18 reward-hacking checks the Evaluator will apply later.

### Inputs

- `iterations/current/spec.md` — what to build
- `iterations/current/audit-report.md` — risks the TruthSayer named
- `iterations/current/contract.md` — the signed agreement
- `iterations/current/acceptance-checklist.md` — the binary checks the Evaluator will run
- `wiki/index.md` (Tier 1) + selective Tier-2 pages via Wiki Querier
- `knowledge/methodology/rules.md` — confirmed rules
- `quality-criteria.json` — thresholds in scope

### Outputs

| File | Sub-type | Schema |
|---|---|---|
| `iterations/current/execution-log.md` | both | `60-schemas/execution-log.md` (append-only) |
| `wiki/**/*.md`, `wiki/claims/unverified/*.md` | research | per `30-knowledge/` (planned Phase 4) |
| code, tests, migrations, config | commercial | project conventions |
| `sources/research/iter-NNN/*` | research | Invariant 8 — saved BEFORE any claim is extracted |

### Adapter requirements

- adapter MUST have `enforces_pre_action_facts: true` (Invariant 10) — Executor is the highest-frequency state-mutating role.
- Default adapter: `claude-native` (subagent for research, sdk for commercial). MAY also be `codex-bridge` (mode=implement) for cross-family execution experiments.
- Sandbox: `workspace-write`.
- `host_access` (v2.10):
  - `executor.research`: not required.
  - `executor.commercial`: REQUIRED `loopback_tcp: true` and `unix_sockets: true` for live DB inspection, container runtimes, and app-server probes. Adapters with deny-deny (e.g. current `codex-bridge`) MUST NOT be assigned to this sub-role; the orchestrator pre-injects required query results from a host-side wrapper instead.
- Tier per §17: **frontier** (fact-producing role).

### Tools required

`Read`, `Write`, `Edit`, `Bash`, `Grep`, `Glob`, `WebFetch` / `WebSearch` (research only — results saved to `sources/` before claim extraction). All gated by Invariant 10.

### Within-execute discipline

- **Per Invariant 8**: every WebFetch/WebSearch result MUST be saved to `sources/research/iter-NNN/` BEFORE any claim is extracted.
- **Per §6 commercial protocol 2a**: per-unit type-check; line `Per-unit type-check: PASSED|FAILED` appended to `execution-log.md`.
- **Per §6 commercial protocol 2b**: multi-tenancy gate; line `Multi-tenancy check: PASSED|FAILED`. Failure within a unit does not necessarily fail the iteration; the Evaluator re-checks.
- **Per §6 stub protocol**: any blocked unit produces `# TODO: RESOLVE-STUB` placeholder + matching log entry; iteration continues with next independent unit. Undisclosed stubs are an automatic Reward-Hacking FLAG (G7).

### Cycle limits

- Eval cycle (max 3). On `eval-report.md` Route FAIL, orchestrator routes back to Executor with `eval_cycle_current += 1`. Cycle 3 FAIL → escalate.
- Route SPEC-FLAW does NOT increment Executor's eval cycle — it routes back to Planner.

### What the Executor MUST NOT do

- MUST NOT skip an Invariant-8 source save to "save time".
- MUST NOT mark a unit complete without a corresponding execution-log entry.
- MUST NOT silently swallow a stub — every stub MUST be logged.
- MUST NOT modify `spec.md`, `audit-report.md`, `contract.md`, or `acceptance-checklist.md`.
- MUST NOT promote `wiki/claims/unverified/*` to verified — that is the Wiki Ingester's role.
- MUST NOT write `eval-report.md`.
- MUST NOT bypass the per-unit type-check or multi-tenancy gate (commercial).
- MUST NOT extract a claim from a source it did not first save to `sources/`.

### Cross-references

- Output schema: `60-schemas/execution-log.md`.
- Lifecycle: `10-pipeline/iteration-lifecycle.md` §"Phase 5 — Execute".
- Verifier: `20-roles/evaluator.md` (cross-family preferred).

---
