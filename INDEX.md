# INDEX.md — Layer-3 Entrypoint

**Adopters: load this file FIRST. Do NOT load `SYSTEM-BLUEPRINT.md` directly.**

This is the v3.0 runtime entry point. It replaces "read the 2,531-line SYSTEM-BLUEPRINT.md" with "load the relevant role bundle". The monolith remains in place as a *compiled view* (regenerated from Layer-2 sources via `tools/build-blueprint.sh`) for backwards compatibility, but new ingestion targets this file.

## Quick start (what to load when)

| You are... | Load this |
|---|---|
| The orchestrator (claude-main) at session start | `bundles/orchestrator-core.yaml` |
| About to dispatch a role-bearing slash command | `bundles/<role>.yaml` for that role |
| Implementing a new adapter (Mistral, Cursor, MCP, etc.) | `bundles/agent-onboarding.yaml` |
| Auditing the harness (`/meta-review`) | `bundles/meta-review.yaml` |
| Curious about everything | this file + `00-overview/system-map.md` |

## The architecture in 30 seconds

A role-stable, agent-configurable orchestration architecture for self-learning knowledge bases. Three layers:

1. **Roles** (blueprint, stable): planner, truthsayer, pre-check, executor (research/commercial), evaluator, kb-linter, wiki-ingester, wiki-querier, meta-review, apply-meta, orchestrator. Defined in `20-roles/<role>.md`.
2. **Agents** (concrete instances, configurable): `claude-main`, `claude-worker-*`, `codex-*`, future `devstral-*`, `mistral-*`, `cursor-*`, etc. Bound to roles via `agents.config.yaml`.
3. **Adapters** (protocol drivers): `claude-orchestrator`, `claude-native` (subagent + sdk), `codex-bridge` (canonical implementation: sibling project `claude-codex-orchestration` — wiring guide: `adoption-guides/codex-bridge-adapter.md`), future `openai-compat-http`, `cursor-cli`, `mcp-agent`. Defined in `50-adapters/<adapter>.md`.

Every delegation flows through the §25 11-step dispatch shim (`commands/_delegate.md` — also documented in `40-runtime/dispatch-shim.md`). The verification ledger (`pipeline/verification-ledger.jsonl`) is the audit trail.

## The 10 invariants (cannot be relaxed)

See `00-overview/invariants.md`. Inv 9 (orchestrator non-delegable) and Inv 10 (pre-action fact presentation) are the load-time enforcement points — `agents.config.yaml` validates compliance at session start.

## The 13 bundles

| Bundle | Role | Token target |
|---|---|---|
| [orchestrator-core](bundles/orchestrator-core.yaml) | claude-main session start | ~6,500 |
| [planner](bundles/planner.yaml) | planner | ~2,800 |
| [truthsayer](bundles/truthsayer.yaml) | truthsayer | ~3,800 |
| [pre-check](bundles/pre-check.yaml) | pre_check | ~2,400 |
| [executor-research](bundles/executor-research.yaml) | executor.research | ~5,400 |
| [executor-commercial](bundles/executor-commercial.yaml) | executor.commercial | ~4,200 |
| [evaluator](bundles/evaluator.yaml) | evaluator | ~4,800 |
| [kb-linter](bundles/kb-linter.yaml) | kb_linter | ~5,000 |
| [wiki-ingest](bundles/wiki-ingest.yaml) | wiki_ingest | ~4,600 |
| [wiki-query](bundles/wiki-query.yaml) | wiki_query | ~3,400 |
| [meta-review](bundles/meta-review.yaml) | meta_review | ~3,000 |
| [apply-meta](bundles/apply-meta.yaml) | apply_meta | ~3,200 |
| [agent-onboarding](bundles/agent-onboarding.yaml) | new-adapter implementer | ~7,000 |

Worst-case bundle is ~7k tokens vs. the monolith's ~70k (10× reduction). Steady-state per-role is ~3.5k tokens (20× reduction). See `30-knowledge/three-tier-memory.md` for why.

## The 11 slash commands

All compose `commands/_delegate.md` (orchestrator-only, never user-invokable):

| Command | Role | Output |
|---|---|---|
| `/plan` | planner | `iterations/current/spec.md` (and `contract.md` after pre-check-complete) |
| `/audit` | truthsayer | `iterations/current/audit-report.md` |
| `/pre-check` | pre_check | `iterations/current/acceptance-checklist.md` |
| `/execute` | executor.research / executor.commercial | wiki pages or code + `execution-log.md` |
| `/evaluate` | evaluator | `iterations/current/eval-report.md` |
| `/kb-lint` | kb_linter | `iterations/current/iter-summary.md` + LESSONS.md append |
| `/wiki-ingest` | wiki_ingest | wiki pages + archive-on-ingest record |
| `/wiki-query` | wiki_query | in-context page bundle (no file write) |
| `/escalate` | orchestrator-inline | `iterations/current/escalation.md` |
| `/meta-review` | meta_review | `meta/audit-YYYY-MM-DD.md` |
| `/apply-meta` | apply_meta (orchestrator-inline) | edits to `agents.config.yaml`, `commands/_archived/`, frontmatter |

## Layer-2 directory map

| Directory | Purpose | Per-file cap |
|---|---|---|
| `00-overview/` | Invariants, philosophy, glossary, design principles, system map | 120 |
| `10-pipeline/` | State machine, file contracts, iteration lifecycle, quality gates, escalation rules | 180 |
| `20-roles/` | One per-role contract per blueprint role (11 roles) | 150 |
| `30-knowledge/` | Wiki + KB architecture, temporal-fact protocol, three-tier memory, failure modes | 200 |
| `40-runtime/` | Dispatch shim, verification ledger, bootstrap, harness decay, Claude Code integration | 180 |
| `50-adapters/` | Per-adapter contracts + capability matrix | 150 |
| `60-schemas/` | One per inter-agent file schema (10 schemas + ledger row schema) | 100 |
| `80-status/` | Shipped-vs-planned capability maturity | 100 |

## Tools

```
tools/verify-frontmatter.sh --strict   # frontmatter compliance + line-cap enforcement
tools/verify-cross-refs.sh             # depends_on / related cross-reference validity
tools/build-blueprint.sh --dry-run     # list canonical concat order; --force to regenerate monolith
tools/build-bundle.sh --check          # bundle drift detection (Phase 6 will gate CI on this)
tools/build-bundle.sh <role>           # generate bundles/<role>.yaml from frontmatter (Phase 6+)
```

## Adoption checklist

To adopt this architecture in your own project:

1. Copy `agents.config.yaml` and edit `agents:` + `roles:` for your environment.
2. Copy the `bundles/` directory verbatim (or run `tools/build-bundle.sh` for each role).
3. Wire your harness's PreToolUse equivalent to enforce Inv 10 (Claude Code: install gateguard skill).
4. Initialize `pipeline/verification-ledger.jsonl` as an empty file.
5. Initialize `PROGRESS.md` with `pipeline_state: idle`.
6. First iteration: run `/plan` → `/audit` → `/pre-check` → `/plan` (contract) → `/execute` → `/evaluate` → `/kb-lint`.

## What this INDEX is NOT

- It is not the canonical reference. The canonical reference is the union of `00-overview/` through `80-status/` (or `SYSTEM-BLUEPRINT.md` regenerated from them).
- It is not a tutorial. For that, see the role contracts in `20-roles/` and the lifecycle narrative in `10-pipeline/iteration-lifecycle.md`.
- It is not a manifest. Bundles are the manifest layer; this file points to them.

---
