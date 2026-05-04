# 20-roles/ — Per-role contracts

This directory holds one Markdown file per blueprint role (§6) describing that role's mandate, inputs, outputs, tool requirements, adapter requirements, cycle limits, and routing. Roles are stable — the blueprint never names a specific agent. `agents.config.yaml` binds each role to a concrete agent via an adapter.

For the directory's frontmatter conventions, see `00-overview/_README.md`. Per-directory cap for `20-roles/*` is 150 lines per file.

## Index of role contracts

| File | Role | Mandate (one-liner) | Producer of |
|---|---|---|---|
| [orchestrator.md](orchestrator.md) | Orchestrator | Singleton; non-delegable per Inv 9. Owns pipeline state + ledger + escalations. | PROGRESS.md, `pipeline/verification-ledger.jsonl`, `iterations/current/escalation.md` |
| [planner.md](planner.md) | Planner | Produces spec.md (and contract.md after pre-check-complete). | `spec.md`, `contract.md` |
| [truthsayer.md](truthsayer.md) | TruthSayer | Adversarial audit of spec.md per Inv 2. | `audit-report.md` |
| [pre-check.md](pre-check.md) | Pre-Check Evaluator | Locks acceptance criteria before execute starts. | `acceptance-checklist.md` |
| [executor.md](executor.md) | Executor (research / commercial) | Implements per spec+contract. | wiki pages or code + `execution-log.md` |
| [evaluator.md](evaluator.md) | Evaluator (post-execute) | Tool-using verification per Inv 7; runs §18 reward-hacking checks. | `eval-report.md` |
| [kb-linter.md](kb-linter.md) | KB Linter | 10 lint rules; promotes findings → hypotheses → rules. | `iter-summary.md`, LESSONS.md appends |
| [wiki-ingester.md](wiki-ingester.md) | Wiki Ingester | Two-layer ingestion (raw → wiki) per Inv 8 + §14 archive-on-ingest. | `wiki/**/*.md`, source-archive entries |
| [wiki-querier.md](wiki-querier.md) | Wiki Querier | Selective retrieval per §20 three-tier model. | Tier-1 + selective Tier-2 page bundles |
| [meta-review.md](meta-review.md) | Meta-Review | Harness audit on min(25 iters, 6 months) cadence per §22. | `meta/audit-YYYY-MM-DD.md` |
| [apply-meta.md](apply-meta.md) | Apply-Meta | Applies meta-review verdicts to live config + commands. | edits to `agents.config.yaml`, `commands/*.md`, frontmatter |

## Role → adapter → sandbox → host_access matrix

This is the steady-state assignment matrix that `agents.config.yaml` encodes. Edits to the matrix are config edits, not blueprint edits.

| Role | Adapter (default) | Sandbox | host_access required | enforces_pre_action_facts | Cross-family target |
|---|---|---|---|---|---|
| orchestrator | `claude-orchestrator` | host shell (no sandbox) | yes (loopback + sockets) | true | n/a — singleton |
| planner | `claude-native` (subagent) | read-only | no | true | Claude family |
| truthsayer | `codex-bridge` (mode=design) | read-only | no | orchestrator-side | Codex (cross-family vs. Claude planner) |
| pre_check | `claude-native` (subagent) | read-only | no | true | Claude family (separate context from evaluator) |
| executor.research | `claude-native` (subagent or sdk) | workspace-write | no | true | Claude family |
| executor.commercial | `claude-native` (sdk) | workspace-write | yes (loopback + sockets) | true | Claude family — codex-bridge currently denied (host_access false) |
| evaluator | `codex-bridge` (mode=design until protocol ≥ 2 ships review) | read-only | research: no; commercial: yes | orchestrator-side | Codex (cross-family vs. Claude executor) |
| kb_linter | `claude-native` (subagent, mid-tier model) | workspace-write | conditionally yes (citation health checks) | true | Claude family |
| wiki_ingest | `claude-native` (subagent or sdk) | workspace-write | no | true | Claude family |
| wiki_query | `claude-native` (subagent) | read-only | no | true | Claude family |
| meta_review | `claude-native` (subagent or sdk) | read-only | no | true | Claude family |
| apply_meta | `claude-orchestrator` (orchestrator-inline) | host shell | yes | true | n/a — orchestrator-only |

An adapter whose `host_access: {loopback_tcp: false, unix_sockets: false}` cannot be assigned to a role flagged as host-service-dependent (see `policy.host_local_service_dependent_roles` in `agents.config.yaml`). Empty cells in the matrix are documented denials, not gaps.

## Audience field convention for 20-roles/* files

Every role-contract file's `audience:` frontmatter MUST include the role itself. `also_needed_by:` lists the roles whose dispatch depends on knowing this role's contract. The orchestrator is in `also_needed_by:` for every role file (it dispatches all of them); meta_review is in `also_needed_by:` for every role file (it audits all of them).

## What NOT to put in role contracts

- Implementation detail of any specific agent (that lives in `50-adapters/<adapter>.md`, planned for Phase 4).
- Schema of any output file (that lives in `60-schemas/<output>.md`).
- State-machine transitions (those live in `10-pipeline/state-machine.md`).
- Quality-gate definitions (those live in `10-pipeline/quality-gates.md`).
- Escalation taxonomy (lives in `10-pipeline/escalation-rules.md`).

A role contract describes WHAT the role does and produces, the inputs and outputs, the cycle limits and routing, and the adapter requirements (host_access, enforces_pre_action_facts, cross-family preference). It does NOT prescribe HOW any specific agent fulfils it — that's the adapter's concern.

---
