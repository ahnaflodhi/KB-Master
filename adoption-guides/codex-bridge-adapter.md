# Adoption guide — codex-bridge adapter (Codex executor wiring)

**Use this when** you want to dispatch work to OpenAI Codex from inside a KB-Orchestrator-Core deployment — i.e., bind a Codex agent (`codex-audit`, `codex-eval`, optionally `codex-implement`) to a role and have the §25 dispatch shim route delegations through it.

**Prerequisite.** This guide assumes you have completed adoption per `external-orchestrator-directive.md` (or are running the framework in its native Claude Code home). The codex-bridge adapter slot is one of several adapters (`claude-orchestrator`, `claude-native`, `codex-bridge`, planned `openai-compat-http` / `cursor-cli` / `mcp-agent`); this guide covers only the codex-bridge slot.

## Section 1 — Where the implementation lives (Model C ownership)

KB-Orchestrator-Core defines the **adapter slot**: the contract every codex-bridge implementation must satisfy is in `50-adapters/codex-bridge.md` and the per-adapter capability surface is in `50-adapters/capability-matrix.md`. This is the framework's owned scope.

The **canonical implementation** of that slot lives in a separate, focused project:

> **`claude-codex-orchestration`** (`git@github.com:ahnaflodhi/claude-codex-orchestration.git`) — ships the `codex-task-bridge` CLI, six Claude Code slash commands (`/codex-design`, `/codex-implement`, `/codex-review`, `/codex-status`, `/codex-result`, `/codex-list`), and a normative protocol-versioning + capability-discovery contract. Authoritative spec: `BRIDGE_REQUIREMENTS.md` in that repo. Substitute this URL for the `<claude-codex-orchestration-url>` placeholders in Section 2.

Why two projects? The bridge contract is independently useful — someone may want a Claude↔Codex bridge without the 70-file framework attached. KB-Orchestrator-Core is the upstream framework that owns roles + dispatch + audit + INV 9/10; `claude-codex-orchestration` ships one slot's implementation.

The split is documented reciprocally on both sides:
- **Framework side (this repo):** `50-adapters/codex-bridge.md` § "Ownership (Model C, 2026-05-10)" + this guide.
- **Implementation side (sibling repo):** `claude-codex-orchestration/CLAUDE.md` § 0 "Upstream framework" (with an explicit owned-by-upstream / owned-by-this-repo split table, plus operating rules forbidding local redefinition of concepts KB-Orchestrator-Core owns) and `BRIDGE_REQUIREMENTS.md` § "Upstream framework" (which names itself as the authoritative-external contract for the slot defined here).

## Section 2 — Install the bridge

Three install paths, taken from the sibling repo's `CLAUDE.md` §5 ("Porting to another project") and adapted for a KB-Orchestrator-Core deployment:

### Path A — Copy `codex_scaffold/` into the project root (sibling §5 option 1)

The sibling repo's primary recommendation. Copy the bridge's self-contained scaffold directly into your KB-Orchestrator-Core deployment.

```bash
git clone <claude-codex-orchestration-url> /tmp/claude-codex-orchestration
cp -r /tmp/claude-codex-orchestration/codex_scaffold ./codex_scaffold
chmod +x ./codex_scaffold/bin/codex-task-bridge
./codex_scaffold/bin/codex-task-bridge version    # exits 0 with integer N (protocol ≥ 2) OR non-zero on MVP/protocol-1 — both are fine
```

Then update `agents.config.yaml.adapters.codex-bridge.binary_path` to `./codex_scaffold/bin/codex-task-bridge` and `artifact_dir_root` to `./codex_scaffold/runtime/codex-jobs`.

### Path B — Global install on `$PATH` (sibling §5 option 2)

Install once to `~/.codex/bin/codex-task-bridge` and reuse across multiple KB-Orchestrator-Core deployments.

```bash
git clone <claude-codex-orchestration-url> /tmp/claude-codex-orchestration
mkdir -p ~/.codex/bin
cp /tmp/claude-codex-orchestration/codex_scaffold/bin/codex-task-bridge ~/.codex/bin/
chmod +x ~/.codex/bin/codex-task-bridge
~/.codex/bin/codex-task-bridge version
```

Then set `agents.config.yaml.adapters.codex-bridge.binary_path` to the absolute path `~/.codex/bin/codex-task-bridge` (or `$HOME/.codex/bin/codex-task-bridge`). Set `artifact_dir_root` to a writable per-deployment path (e.g. `./codex_scaffold/runtime/codex-jobs`) — the binary location is global, but artifact dirs are per-project.

### Path C — `CODEX_BRIDGE` env var (sibling §5 option 3)

If you want to point at an arbitrary bridge binary at run-time without editing `agents.config.yaml`:

```bash
export CODEX_BRIDGE=/abs/path/to/codex-task-bridge
```

The framework's bridge resolver (per sibling repo's `CLAUDE.md` §2) checks `$CODEX_BRIDGE` first, then `./codex_scaffold/bin/codex-task-bridge`, then `~/.codex/bin/codex-task-bridge`, then `codex-task-bridge` on `$PATH`. This path is the right choice for CI environments and ephemeral containers; it is the wrong choice for a checked-in adopter deployment (the env var is invisible to anyone reading `agents.config.yaml`).

### Sibling-vendored variant (framework's stock default)

The framework's stock `agents.config.yaml.adapters.codex-bridge.binary_path` ships as `../claude-codex-orchestration/codex_scaffold/bin/codex-task-bridge`, assuming the sibling repo has been git-cloned alongside KB-Orchestrator-Core. This is a convenience default for development — adopters SHOULD pick one of Paths A/B/C above and update `binary_path` accordingly, rather than relying on the sibling-vendored path.

In all paths: the `codex` CLI itself must be installed and authenticated (`codex --version`, `codex login status`). The bridge is a wrapper around `codex exec` — without `codex`, the bridge has nothing to invoke.

## Section 3 — Wire the adapter in `agents.config.yaml`

The framework's stock `agents.config.yaml` already declares the codex-bridge adapter. Verify the relevant block (this is the **install-sensitive subset** — your file may also include `enforces_pre_action_facts: orchestrator-side` and `cached_protocol_probe:` blocks; leave those alone unless you have a reason to override):

```yaml
adapters:
  codex-bridge:
    kind: cli-bridge
    binary_path: ./codex_scaffold/bin/codex-task-bridge   # Adjust per Path A/B/C
    bootstrap_probe:
      version_command: ["version"]
      capabilities_command: ["capabilities", "--json"]
      timeout_seconds: 2
    fallback_protocol: 1                # if probe fails, treat as MVP-only
    artifact_dir_root: ./codex_scaffold/runtime/codex-jobs
    pre_action_fact_mechanism: orchestrator-emitted-block
    host_access:
      loopback_tcp: false               # default-deny until probe advertises otherwise
      unix_sockets: false
```

**Active vs. declared agent bindings.** The framework declares three Codex agents in `agents:`, but only two are active in the stock `roles:` map:

| Agent | Role binding (in `roles:`) | Status | Bridge sub-mode | Sandbox |
|---|---|---|---|---|
| `codex-audit` | `truthsayer: codex-audit` | **active** | `design` (review on protocol ≥ 2) | `read-only` |
| `codex-eval` | `evaluator: codex-eval` | **active** | `design` (review on protocol ≥ 2) | `read-only` |
| `codex-implement` | `executor.commercial: claude-worker-commercial` (commented "swap to codex-implement for cross-family") | **declared, not active** | `implement` | `workspace-write` |

To activate `codex-implement`, edit `roles.executor.commercial: codex-implement`. Be aware: `executor.commercial` is in `policy.host_local_service_dependent_roles`, so codex-implement cannot be dispatched until either (a) `host_access.loopback_tcp` and `host_access.unix_sockets` flip to `true` in the bridge's probe response, OR (b) you set `policy.on_host_access_missing_for_required_role: inline` so the orchestrator pre-injects host-side outputs as read-only evidence. Both options are documented in `40-runtime/bootstrap-and-degradation.md`.

Add new bindings the same way (declare the agent in `agents:`, point its `adapter:` at `codex-bridge`, declare its `loads_bundle:`). **Never invent a role** to fit a Codex agent's capabilities — the role abstraction is fixed in `20-roles/`.

**Persistent agents (protocol 3).** `agent create` + `agent run` can back a read-only role as a durable, memory-carrying profile (e.g. a domain-expert `truthsayer` whose `system_prompt.md` + `memory.md` accumulate context across iterations). This does **not** introduce a new role — bind the persistent agent to an existing role per `50-adapters/capability-matrix.md`; "never invent a role" still applies. A persistent agent is still a `read-only` (`--mode design`) tracked job and grants no new capability.

## Section 4 — INV 10 enforcement (orchestrator-emitted block)

The bridge has no in-process `PreToolUse` callback, and per `BRIDGE_REQUIREMENTS.md` § Non-goals the bridge **does not impose orchestration policy** — it executes the directive Claude sends and records artifacts; nothing more. This is by design, not a missing feature. The orchestrator-emitted-block enforcement model is therefore **permanent for this adapter slot**, not a temporary stopgap.

Concretely: the bridge probe MUST report `enforces_pre_action_facts: "orchestrator-side"`, and the orchestrator (claude-main) MUST emit the four-fact INV 10 block as user-visible text immediately before each **Codex-invoking dispatch — `run`, `start`, `subagent run`, and `agent run`** (protocol 3 added the latter two). `agent create` and `agent remember` are **local state ops** (they do not invoke `codex exec`) — record them in `iterations/current/execution-log.md`, not as a four-fact dispatch:

```
<pre-action-facts>
1. Request: <one-sentence restatement of the user/orchestrator directive>
2. Verifies/produces: <effect — file/artifact written, schema validated, etc.>
3. Impacted: [<paths the dispatch will read or write>]
4. Quote: "<verbatim quote of the directive being acted upon>"
</pre-action-facts>
```

This is the contract that lets the verification ledger (and the truthsayer/evaluator audit step) detect reward-hacking by inspection — see `adoption-guides/external-orchestrator-directive.md` § Section 5 for the full four-fact rule and why the v2.9 adoption guide's stricter form is binding for adopters.

## Section 5 — Bootstrap probe + protocol degradation

Per `BRIDGE_REQUIREMENTS.md` § Versioning & capability discovery, every session probes the bridge once at startup:

```bash
PROTOCOL=$(codex-task-bridge version 2>/dev/null)
[[ "$PROTOCOL" =~ ^[0-9]+$ ]] || PROTOCOL=1
```

The probe distinguishes three states — keep them separate:

1. **Bridge binary missing entirely** (the `codex-task-bridge` command is not on `$PATH` and `binary_path` does not resolve). Probe fails fast → adapter `available: false` in the framework's `agents.config.yaml` cache. The orchestrator's degradation chain (per `40-runtime/bootstrap-and-degradation.md`): (a) try equivalent supported path on same adapter; (b) re-route the role to the orchestrator inline (`claude-main` fulfils it directly, with a warning logged to `iterations/current/execution-log.md`); (c) **if no inline fallback can fulfil the role** (e.g. capability gap), write `iterations/current/escalation.md` reason `agent-unavailable` and stop the pipeline. The "graceful degradation" framing holds only when (a) or (b) succeeds; (c) is a real halt path adopters MUST plan for.
2. **Bridge present but `version` exits non-zero** (or returns non-integer). The bridge IS available but predates the protocol-version surface — treat as **protocol 1 (MVP)**. Only `run`/`start --mode design|implement`, `status`, `tail`, `result`, `list` are guaranteed. The orchestrator MUST NOT call `--mode review`, `raw`, `--output-schema`, or `--json-events`.
3. **Bridge present and `version` returns integer N ≥ 2**. Orchestrator additionally runs `capabilities --json` and feature-tests the surface; protocol-2 calls become available iff `capabilities` advertises them.
   - **Protocol 3.** When `version` returns `3`, `capabilities --json` additionally advertises `subagent`/`agent` in `subcommands`, plus `subagent_actions`, `agent_actions`, `agent_storage`, and `agent_files`. The `subagent`/`agent` subcommands MUST be guarded behind a protocol-≥3 probe — calling them against a protocol-1/2 bridge is an orchestrator-side bug. Host-local-services default-deny (below) is **unchanged** by protocol 3.

**Host-local services (v2.10).** The bridge does NOT advertise host-local service access (PostgreSQL, Redis, Docker sockets) until `capabilities --json` ships with explicit `host_access: {loopback_tcp, unix_sockets}` fields set to `true`. Until that advertisement lands, default-deny applies for roles in `policy.host_local_service_dependent_roles` (typically `executor.commercial`, `kb_linter`): the orchestrator MUST NOT dispatch them to codex-bridge **while the role's prompt still requires host-local access**. Dispatch may proceed once the orchestrator pre-injects required query results or invokes a host-side wrapper outside the delegated job and passes the output as read-only evidence in `inputs[]`.

## Section 6 — Pinning (codex-bridge specific)

KB-Orchestrator-Core pinning is covered in `external-orchestrator-directive.md` § Section 4 — follow that for the framework side.

The codex-bridge-specific pinning rule: pin to whatever protocol level your `agents.config.yaml.adapters.codex-bridge.cached_protocol_probe.protocol` declares it tested against. The MVP bridge is protocol 1 (the rows marked **shipped** in `BRIDGE_REQUIREMENTS.md` § Implementation status). Protocol-2-only code paths in your slash commands MUST guard behind the probe result; calling planned-but-not-shipped surface against an MVP bridge is an orchestrator-side bug, not a bridge bug.

When adopting a new bridge protocol (the sibling shipped **protocol 3** at `d3f2965` — sub-agents + persistent agents), bump `agents.config.yaml.adapters.codex-bridge.cached_protocol_probe.protocol` to the tested level (e.g. `3`), re-run `tools/build-bundle.sh --check` and `tools/verify-config.sh`, and re-run the post-vendoring smoke test in `README.md` § "Post-vendoring smoke test".

## Section 7 — Adopter sanity check (codex-bridge specific)

After install + wire-up, run:

1. `codex --version` — confirms the underlying CLI is installed and on `$PATH`.
2. `codex login status` — confirms Codex auth is good (otherwise every dispatch will fail with `codex_exec_failure`).
3. `<binary_path> version` — exits 0 with an integer iff the bridge is protocol ≥ 2; exits non-zero on MVP. Either is fine — the orchestrator's bootstrap probe handles both states.
4. `<binary_path> capabilities --json` (if protocol ≥ 2) — pretty-prints the supported surface; cross-check `agent_actions`/`subagent_actions`/`agent_storage` against the `50-adapters/capability-matrix.md` codex-bridge row.
5. **Protocol 3 only** — exercise the new surface:
   - `<binary_path> subagent run --kind audit -- "smoke: summarize README"` → returns a final message.
   - `<binary_path> agent create smoke-expert --kind domain --system-prompt "You are a smoke-test expert."` then `<binary_path> agent run smoke-expert -- "smoke: 2+2"` → `agent_name=smoke-expert` appears in `status --json`, and `<agent_storage_root>/smoke-expert/sessions.jsonl` is non-empty.
6. Trigger a dry dispatch via `/audit` or `/evaluate` — observe the orchestrator-emitted four-fact block in the dispatch envelope at Step 4, the DISPATCH ledger row inside Step 4, the bridge job artifact directory populated at `<artifact_dir_root>/<job_id>/`, the CONSUME ledger row inside Step 10. If all five appear with correct schema (per `60-schemas/verification-ledger.jsonl.md`), the wiring is sound.

For a deeper degradation test (forcing the binary to be missing and verifying the orchestrator routes the role inline rather than halting the pipeline), see `40-runtime/bootstrap-and-degradation.md` — that test belongs with the runtime degradation contract, not the per-adapter sanity check.

## Note — agent-state storage (protocol 3)

Persistent agents write under `<agent_storage_root>` (`../claude-codex-orchestration/codex_scaffold/runtime/codex-agents/`). Adopters MUST ensure that directory is **writable**. The sibling repo gitignores `runtime/codex-agents/*` (keeping a `.gitkeep`), so agent profiles are local-only by default. Adopters who want **shared team agents** should intentionally un-ignore specific profiles — accepting that the profile's `memory.md` then becomes version-controlled (and reviewable like any other artifact).

## Cross-references

- `50-adapters/codex-bridge.md` — the framework's adapter contract (slot definition)
- `claude-codex-orchestration/BRIDGE_REQUIREMENTS.md` — the implementation's authoritative spec
- `claude-codex-orchestration/CLAUDE.md` — the implementation's role/boundary contract (sibling §2 bridge-resolver chain, §5 install paths)
- `adoption-guides/external-orchestrator-directive.md` — for adopters wiring foreign orchestrators that consume this adapter
- `adoption-guides/v2.9-invariant-10.md` — INV 10 four-fact form (orchestrator-emitted-block fallback explained)
- `40-runtime/bootstrap-and-degradation.md` — graceful degradation when the bridge is unavailable; deeper failure-mode tests

---

**Last reviewed:** 2026-05-10
**Status:** revised post-Codex-pass-1 (HIGH/MEDIUM/LOW findings closed)
