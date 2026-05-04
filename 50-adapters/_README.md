# 50-adapters/ — Per-adapter contracts

This directory holds one Markdown file per adapter (the protocol-driver layer of §25's three-layer agent architecture). An adapter knows how to turn a generic delegation request — `(role, prompt, sandbox, model, inputs, expected_schema)` — into a concrete invocation of a specific agent runtime, and how to report back via the standard 5-operation interface (`probe`, `dispatch`, `status`, `result`, `cancel`).

For frontmatter conventions see `00-overview/_README.md`. Per-directory cap for `50-adapters/*` is 150 lines per file.

## Index of adapter contracts

| File | Adapter | Kind | Status |
|---|---|---|---|
| [capability-matrix.md](capability-matrix.md) | (cross-cutting) | reference | The single matrix the orchestrator consults at PROBE / DISPATCH time |
| [claude-orchestrator.md](claude-orchestrator.md) | `claude-orchestrator` | native-orchestrator | shipped — singleton, non-delegable per Inv 9 |
| [claude-native.md](claude-native.md) | `claude-native` | claude-native (subagent + sdk sub-modes) | shipped |
| [codex-bridge.md](codex-bridge.md) | `codex-bridge` | cli-bridge | shipped (MVP — protocol 1) |

Future adapters (templates commented in `agents.config.yaml`): `openai-compat-http` (Mistral, Devstral, Together, Groq, OpenRouter), `cursor-cli`, `mcp-agent`. Each gets its own file when its `capability_check` passes.

## Why per-adapter files

The blueprint role layer (`20-roles/`) describes WHAT each role does. The adapter layer here describes HOW a specific runtime fulfils delegation. The separation means:

- A new agent runtime (Devstral, Mistral, Cursor, etc.) can be added by writing one new adapter file + the corresponding `agents.config.yaml` block, without touching any role contract.
- An adopter swapping providers reads the relevant `50-adapters/<adapter>.md` file plus their own `agents.config.yaml` — they do NOT need to re-read the blueprint.
- `tools/build-bundle.sh` can include only the adapters a project actually uses, keeping bundles small.

## What every adapter contract MUST document

Every file under `50-adapters/` MUST contain these sections (in order):

1. **Identity** — `kind:`, `binary_path:` or `protocol:`, capability check
2. **Probe response shape** — what the adapter returns from `probe()` including v2.9 `enforces_pre_action_facts` and v2.10 `host_access`
3. **Dispatch contract** — argument mapping (`role → prompt`, `sandbox`, `model`, `inputs`, `expected_schema`) and return type
4. **Result contract** — artifact paths, `last_message` location, exit-code semantics
5. **Sandbox semantics** — what the adapter's sandbox flag enforces (filesystem? network? sockets?)
6. **Failure modes** — what kind of failures the adapter can produce and how the orchestrator should react (re-delegate, escalate, downgrade)
7. **Pre-action fact enforcement** — `true | false | orchestrator-side` and the mechanism (gateguard skill, in-process callback, orchestrator-emitted block, etc.)
8. **Host-local service access** (v2.10) — `host_access: {loopback_tcp: bool, unix_sockets: bool}` and the rationale
9. **What this adapter MUST NOT do** — the explicit denials (e.g. "MUST NOT decide policy", "MUST NOT swallow Codex's stderr")

## Capability matrix

See `capability-matrix.md` for the at-a-glance grid. The matrix is the source of truth the orchestrator consults at §25 Step 2 PROBE; per-adapter files are the source of truth for the rationale behind each cell.

## What NOT to put in adapter contracts

- Per-role mandate (lives in `20-roles/<role>.md`).
- Pipeline-state transitions (live in `10-pipeline/state-machine.md`).
- Inter-agent file schemas (live in `60-schemas/<file>.md`).
- Wiki / KB structure (lives in `30-knowledge/`).

An adapter contract describes the protocol driver. It does not describe the work the driver carries.

---
