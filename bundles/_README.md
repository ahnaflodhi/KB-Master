# bundles/ — Layer-3 manifest format

This file is intentionally **not** a bundle manifest itself (filename starts with `_`, skipped by `tools/build-bundle.sh`). It is the canonical reference for what every `<role>.yaml` manifest in this directory must look like and how the orchestrator consumes it.

Source of truth at runtime: this file. Source of design intent: `~/.claude/plans/crispy-sniffing-conway.md` §"Bundle manifest format" + §"`_delegate.md` Step 3 (PREPARE) rewire — the keystone".

## What a bundle is

A **bundle** is an explicit, hand-curated list of Layer-2 files that one agent loads into context when fulfilling one role.

Bundles are the framework's **current recommended implementation** of `INVARIANT 11` (minimum-viable context per role; no canonical monolith for runtime work — see `00-overview/invariants.md`). INV 11 binds the *outcome*: every dispatched role MUST load minimum-viable context and MUST NOT load `SYSTEM-BLUEPRINT.md` for runtime work, with the load recorded in the DISPATCH ledger's `context_sources` field. Bundles are today's mechanism for satisfying that outcome — they are not the only legal mechanism.

They exist because:

- Loading the 2,464-line monolith for every dispatch costs ~70k tokens and triggers lost-in-the-middle attention degradation (per blueprint §20).
- A planner does not need the bridge adapter spec; an evaluator does not need the wiki ingester contract.
- Without a recommended manifest per role, every agent ends up loading more than it needs (re-monolithification by accretion).

Adopters MAY use bundles verbatim (the framework's default), curate their own manifests, or substitute a better mechanism (semantic context routing, dynamic composition, RAG-style retrieval) — provided INV 11 holds. The framework does not bake in a specific selection mechanism; it binds the principle.

Bundles are **committed but auto-regenerable.** `tools/build-bundle.sh <role>` derives the membership from frontmatter (`audience`, `also_needed_by`, `purpose`); `tools/build-bundle.sh --check` validates bundle documentation integrity (the manifest is internally consistent — every cited path exists, every audience field matches). This is bundle hygiene, NOT INV 11 enforcement — INV 11 is enforced by the orchestrator at `commands/_delegate.md` Step 10 CONSUME via the DISPATCH ledger row's `context_sources` field.

## Schema

```yaml
# bundles/truthsayer.yaml — one example
bundle: truthsayer                 # required — role name (matches roles: key in agents.config.yaml)
version: 1                         # required — manifest schema version (bump on breaking schema change)
loads:                             # required — files loaded for every dispatch of this role (declared order is concat order)
  - 00-overview/invariants.md
  - 10-pipeline/state-machine.md
  - 10-pipeline/file-contracts.md
  - 20-roles/truthsayer.md
  - 60-schemas/audit-report.md
optional:                          # optional — loaded if present, skipped if absent
  - 80-status/shipped-vs-planned.md
adapter_specific:                  # optional — loaded IFF the active agent uses this adapter
  codex-bridge:
    - 50-adapters/codex-bridge.md
  claude-native:
    - 50-adapters/claude-native.md
estimated_tokens: ~3800            # informational — populated by tools/build-bundle.sh from wc + fixed ratio
loadable_by_protocol: 1            # required — minimum bridge protocol required by any file in adapter_specific
```

## How `_delegate.md` Step 3 (PREPARE) consumes a bundle

When an agent (e.g. `claude-worker-planner` or `codex-audit`) is dispatched to fulfil a role, the orchestrator runs:

1. Look up the role's agent in `agents.config.yaml` → resolve `loads_bundle: <role>` field.
2. Read `bundles/<role>.yaml`. Validate `bundle:`, `version:`, `loads:` are present (this minimal check is what `tools/build-bundle.sh --check` enforces today).
3. For each path in `loads:` → read file content (raw). Required — missing file is a hard failure.
4. For `adapter_specific[<active_adapter>]` (e.g. `adapter_specific.codex-bridge`) → read those files too. Adapter selected from the agent's `adapter:` field in `agents.config.yaml`.
5. For each path in `optional:` → read if present, skip silently if absent.
6. Concatenate file contents in the order they were declared. This becomes the agent's CONTEXT — passed verbatim into the prompt envelope.
7. Compute `prompt_hash = sha256(CONTEXT + role_instruction_body + inputs_summary)`. Recorded in `pipeline/verification-ledger.jsonl`.

**The slash command's instruction body MUST reference bundle entries by id, NEVER include monolith text.** A slash command that pastes a section of `SYSTEM-BLUEPRINT.md` directly into its prompt defeats the bundle architecture.

**If the bundle manifest is missing OR any required `loads:` file is missing → the orchestrator escalates with reason `bundle-missing`. It does NOT silently fall back to loading the monolith — that would be exactly the regression the v3.0 restructure is preventing.**

## The 13 bundles to ship

Per the approved plan §"The 13 bundles to ship". Manifest files land in Phase 5; this list is the registry:

| Manifest | Role | Approx. tokens | Notes |
|---|---|---|---|
| `orchestrator-core.yaml` | (loaded by claude-main at session start) | ~6,500 | Replaces "read SYSTEM-BLUEPRINT.md" |
| `planner.yaml` | planner | ~2,800 | |
| `truthsayer.yaml` | truthsayer | ~3,800 | Conditional codex-bridge doc |
| `pre-check.yaml` | pre_check | ~2,400 | Mirror of `commands/pre-check.md` |
| `executor-research.yaml` | executor.research | ~5,400 | |
| `executor-commercial.yaml` | executor.commercial | ~4,200 | |
| `evaluator.yaml` | evaluator | ~4,800 | |
| `kb-linter.yaml` | kb_linter | ~5,000 | Largest non-executor bundle |
| `wiki-ingest.yaml` | wiki_ingest | ~4,600 | |
| `wiki-query.yaml` | wiki_query | ~3,400 | |
| `meta-review.yaml` | meta_review | ~3,000 | |
| `apply-meta.yaml` | apply_meta | ~3,200 | Orchestrator-only by §25 policy |
| `agent-onboarding.yaml` | (cross-cutting; new adapter implementer) | ~7,000 | Largest bundle by design |

**Worst-case bundle**: ~7k tokens vs. monolith's ~70k = **10× reduction**. Steady-state per-role: ~3.5k tokens = **20× reduction**.

## Drift detection

`tools/build-bundle.sh --check` enforces referential integrity (Phase 6a): every path in `loads:`/`optional:`/`adapter_specific:` exists, and every non-universal `loads:` file declares the consuming role in its frontmatter `audience` or `also_needed_by`. CI runs this on every push to `main` and every pull request via `.github/workflows/ci.yml`. Byte-equivalent deterministic regeneration ("does the committed manifest match what the frontmatter-derivation rule would produce today?") is a future enhancement — `tools/build-bundle.sh <role>` emits a CANDIDATE manifest to stdout for human comparison until then. When drift is detected:

1. Re-run `tools/build-bundle.sh <role>` to regenerate the manifest.
2. Diff the regenerated file against the committed one.
3. Either commit the regeneration (frontmatter changed legitimately) OR fix the frontmatter (bundle membership shifted unintentionally).

## What NOT to put in a bundle manifest

- File paths that don't exist — the manifest is a contract; missing file is a hard escalation.
- Comments in `loads:` (use `optional:` if a file is conditionally needed).
- Hard-coded prompts or instruction text (those go in role-bearing slash commands).
- Per-iteration state (use `iterations/current/*.md` and `pipeline/verification-ledger.jsonl`).
