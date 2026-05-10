# Adoption guide — External orchestrator directive + bootstrap prompt

**Use this when** an external agentic orchestrator (any harness — Claude Code, Claude Agent SDK, Codex, OpenAI-compatible, MCP-native, custom) needs to operate inside the KB-Orchestrator-Core workflow without forking the project. Paste **Section 1** into the foreign orchestrator's persistent system prompt. Load **Section 2** at session start. Wire your harness per **Section 3**.

**Prerequisite.** This guide assumes the KB-Orchestrator-Core runtime files are vendored under a readable root in the foreign project — the relative paths in the artifacts (`INDEX.md`, `bundles/<role>.yaml`, `agents.config.yaml`, `commands/_delegate.md`, `pipeline/verification-ledger.jsonl`, `30-knowledge/`) resolve against that root. If your harness needs absolute paths, rewrite the paths in Section 1 / Section 2 before pasting. Vendoring instructions are in `README.md` § "Vendoring for external orchestrators"; the post-vendoring smoke test lives there as well.

---

## Section 1 — The Directive (drop-in)

```text
COPY START — KB-Orchestrator-Core directive (v3.0)

You operate inside the KB-Orchestrator-Core workflow. The runtime entrypoint is INDEX.md (Layer-3); never load SYSTEM-BLUEPRINT.md for runtime work. Bind every concrete agent you spawn to a role (20-roles/<role>.md) via agents.config.yaml, and load only that role's bundle (bundles/<role>.yaml). Every delegation flows through the 11-step dispatch shim documented in commands/_delegate.md and 40-runtime/dispatch-shim.md. Every dispatch and every consume MUST append a row to pipeline/verification-ledger.jsonl — that ledger is the audit trail and is non-optional. The 10 invariants in 00-overview/invariants.md cannot be relaxed. INVARIANT 9 (orchestrator role non-delegable; the orchestrator alone writes PROGRESS.md, the ledger, escalation.md, dispatch decisions, and schema-validation outcomes — workers DO write their own role artifacts) and INVARIANT 10 (pre-action fact presentation, four-fact form per Section 5) are load-time enforcement points. Knowledge writes go through /wiki-ingest; knowledge reads go through /wiki-query. You are not free to invent roles, skip the shim, or write to the ledger out-of-band. When in doubt, re-read INDEX.md.

COPY END
```

That paragraph is the entire commitment surface.

---

## Section 2 — The Bootstrap Prompt (loadable)

Loaded once at session start (system-prompt appendix, MCP `initialize` resource, or first user message). Names entrypoints; does not duplicate them — the orchestrator reads the named files for content. This is deliberate: a bootstrap that re-states `INDEX.md` and the bundles is itself context bloat.

```text
COPY START — KB-Orchestrator-Core bootstrap (v3.0)

You are an orchestrator inside the KB-Orchestrator-Core workflow.

LOAD ORDER (session start)
  1. Read INDEX.md — the runtime entrypoint. It maps roles → bundles, lists the 11 slash commands, names the dispatch shim, the audit ledger, and the wiki contract.
  2. Read bundles/orchestrator-core.yaml — your steady-state context manifest (~6,500 tokens). Load only the files it names. Do NOT load SYSTEM-BLUEPRINT.md.
  3. Read agents.config.yaml — confirm schema_version: 2 and that every agent declares loads_bundle:.

PER-DISPATCH (every role-bearing slash command)
  1. Resolve the role's bundle from bundles/<role>.yaml.
  2. Run the 11-step shim defined in commands/_delegate.md. The canonical step names are LOAD, PROBE, PREPARE, DISPATCH, AWAIT, FETCH, AUTH, SCHEMA, VERIFY, CONSUME (or REJECT), STATE. Do not invent your own.
  3. Append the DISPATCH ledger row inside Step 4. Append the CONSUME ledger row inside Step 10. Schema: 60-schemas/verification-ledger.jsonl.md. Rows are append-only.
  4. Emit pre-action facts before any state-mutating tool call (INVARIANT 10 — see Section 5 for the four-fact form, which is binding for adopters).

WIKI
  /wiki-ingest writes; /wiki-query reads. Do not read or write wiki pages directly. Architecture: 30-knowledge/.

INVARIANT 9 — what the orchestrator ALONE writes (so you don't over-claim)
  PROGRESS.md, pipeline/verification-ledger.jsonl, iterations/current/escalation.md, dispatch decisions, and schema-validation outcomes. Worker roles DO write their own artifacts: planner -> spec.md, truthsayer -> audit-report.md, executor -> execution-log.md + code/wiki, evaluator -> eval-report.md, kb_linter -> iter-summary.md + LESSONS.md append, wiki_ingest -> wiki pages. Every legal artifact path is named in commands/_delegate.md.

MUST NOT
  - Load SYSTEM-BLUEPRINT.md for runtime work (it is a compiled view of Layer-2; bundles cover what you need).
  - Invent a role not in 20-roles/.
  - Dispatch outside commands/_delegate.md.
  - Append to the verification ledger out-of-band.
  - Mutate state without emitting the four-fact INV 10 block.

COPY END
```

---

## Section 3 — Per-adapter wiring

The Directive is harness-agnostic; the enforcement mechanism is not. Each adapter MUST satisfy the four-row contract below.

### Claude Code (`claude-orchestrator` / `claude-native`, shipped)

| Slot | Required value |
|---|---|
| Bootstrap injection point | `CLAUDE.md` (project or user scope) — auto-loaded each session |
| INV 10 enforcement | gateguard skill (`everything-claude-code:gateguard`) — `PreToolUse` hook |
| Probe response MUST contain | `available: true`, `enforces_pre_action_facts: true`, `host_access: { loopback_tcp: bool, unix_sockets: bool }` |
| Dispatch output MUST return | exit code, artifact paths matching the role's `expected_schema`, one `execution-log.md` row per state-mutating tool call (with the four-fact block) |

Reference: `adoption-guides/v2.9-invariant-10.md` § "Claude Code".

### Claude Agent SDK (custom orchestrator, shipped)

| Slot | Required value |
|---|---|
| Bootstrap injection point | system message at SDK client construction |
| INV 10 enforcement | `PreToolUse` callback that requires the four-fact block before any state-mutating `tool_use` (regex template in `adoption-guides/v2.9-invariant-10.md` § "Claude Agent SDK") |
| Probe response MUST contain | `available: true`, `enforces_pre_action_facts: true`, full `host_access` map |
| Dispatch output MUST return | structured `{ exit_code, artifacts[], log_rows[] }` (paths relative to the iteration directory) |

### Codex (`codex-bridge`, shipped)

| Slot | Required value |
|---|---|
| Bootstrap injection point | dispatch envelope (the bridge cannot intercept tool calls inside a job, so the Directive is re-asserted per-dispatch) |
| INV 10 enforcement | orchestrator-emitted block — see `agents.config.yaml.adapters.codex-bridge.pre_action_fact_mechanism: orchestrator-emitted-block`. The orchestrator emits the four-fact block in the prompt envelope before each `codex-task-bridge run`. |
| Probe response MUST contain | `available: true`, `enforces_pre_action_facts: "orchestrator-side"`, `protocol: int`, full `host_access` map (default-deny applies if any subfield is missing) |
| Dispatch output MUST return | `artifact_dir/` populated with the role's expected schema; bridge job exit code; for `--mode review` (protocol ≥ 2) a structured findings JSON |

Bindings already shipped in `agents.config.yaml`: `codex-audit` → `truthsayer`, `codex-eval` → `evaluator`, `codex-implement` → `executor.commercial`. Add new bindings the same way; never invent a role to fit a Codex agent's capabilities.

**For full installation + wiring instructions** (binary install paths, `agents.config.yaml` block, INV 10 orchestrator-emitted-block contract, bootstrap-probe degradation, Model-C ownership rationale, codex-bridge-specific sanity check), see `adoption-guides/codex-bridge-adapter.md`. The canonical implementation lives in the sibling project `claude-codex-orchestration`.

### OpenAI-compatible HTTP (`openai-compat-http`, planned)

| Slot | Required value |
|---|---|
| Bootstrap injection point | system message on every request (HTTP layer is stateless) |
| INV 10 enforcement | mirror Claude Agent SDK if the harness exposes a tool-use interceptor; otherwise mirror codex-bridge (orchestrator-side) |
| Probe response MUST contain | minimum schema: `{ available: bool, protocol: int, capabilities: string[], enforces_pre_action_facts: bool \| "orchestrator-side", host_access: { loopback_tcp: bool, unix_sockets: bool } }` |
| Dispatch output MUST return | structured JSON `{ artifacts: [{ path, sha256, schema }], exit_code, log_rows }` |

Adapter contract: `50-adapters/_README.md` and `50-adapters/capability-matrix.md`.

### MCP-native (`mcp-agent`, planned)

| Slot | Required value |
|---|---|
| Bootstrap injection point | MCP resources: expose `kb-orc://bootstrap` and `kb-orc://bundles/<role>` |
| INV 10 enforcement | per the MCP server's hook surface; if absent, fall back to orchestrator-side |
| Probe response MUST contain | same minimum schema as `openai-compat-http` |
| Dispatch output MUST return | MCP `tool_result` content blocks naming each artifact + a structured JSON summary block |

### Any other harness

Produce a probe response that names which INV 10 enforcement mode you implement (`true`, `"orchestrator-side"`, or `false`). Adapters reporting `false` MAY only fulfil read-only roles (`wiki_query`, `meta_review`, `truthsayer`, `pre_check`, `evaluator`, `planner`) — enforcement is in `commands/_delegate.md` Step 2.

---

## Section 4 — Pinning

**As of 2026-05-10:** wait for `v3.0.0` (target 2026-05-13, post-Phase-6b soak) before vendoring. Mid-soak adopters re-sync once the monolith is regenerated and the `monolith-edit-guard` CI gate flips on.

**Pre-v3.0.0:** pin to commit `ed5e08f` (Phase 6a, last fully tagged phase). Track `pipeline/soak-state.json.status` upstream — when it flips to `"passed"`, the v3.0.0 tag is safe.

**Do not pin to `main`.** The Phase 6b initiation work is uncommitted on `main` as of this writing — pulling `main` mid-soak surfaces partial state.

---

## Section 5 — INV 10 fact-count rule for adopters (authoritative resolution)

The canonical text in `00-overview/invariants.md` (lines 119–120) lists **two** facts: (a) restated request, (b) what the action verifies/produces. The v2.9 adoption guide (`adoption-guides/v2.9-invariant-10.md`) and the `gateguard` Claude Code `PreToolUse` session hook installed in this project's harness demand **four** facts: + (c) impacted files, (d) verbatim quote of the directive being acted upon. (Note: gateguard runs at session-time per tool call; it is not part of `.github/workflows/ci.yml` — that workflow runs `verify-frontmatter`, `verify-cross-refs`, `build-bundle`, and `monolith-edit-guard` only.)

**For external adopters, the four-fact form is binding.** Reasons: (i) the v2.9 guide is the operational specification — it is what the `gateguard` Claude Code `PreToolUse` session hook (`everything-claude-code:gateguard`) enforces interactively against every state-mutating tool call in this repo's harness (note: this is a per-session hook, not a CI workflow check; this repo's CI in `.github/workflows/ci.yml` runs `verify-frontmatter`, `verify-cross-refs`, `build-bundle`, and `monolith-edit-guard` only); (ii) facts (c) and (d) are what allow the orchestrator to detect reward-hacking by inspection — impacted-files lets the auditor see if the action's scope matches the directive, and the quote lets the auditor see if the model paraphrased the directive into something easier. The two-fact text in `invariants.md` is a documented under-specification scheduled for next-minor revision (tracked in `CHANGELOG.md` v2.9 unresolved items).

If your harness can only enforce the two-fact form, your adapter probe MUST report `enforces_pre_action_facts: "orchestrator-side"`, and the orchestrator MUST emit the missing facts (c) + (d) on the adapter's behalf in the dispatch envelope.

---

## Section 6 — Reciprocal upstream acknowledgment (Model C)

Once your project has adopted this framework, add a top-level "Upstream framework" section to your project's `CLAUDE.md` (or harness equivalent: `AGENTS.md`, `GEMINI.md`, `README.md`, MCP `initialize` resource) naming KB-Orchestrator-Core as the upstream framework that owns the role abstraction, the §25 dispatch shim, the verification ledger, the capability matrix, and INV 9 / INV 10 enforcement.

This is the **Model C reciprocal acknowledgment** pattern. It serves three purposes:

1. **Discoverability** — future readers of your project (humans or agents) immediately see it is a downstream consumer of a larger framework, not a standalone harness.
2. **Sync rule** — your `CLAUDE.md` should state: changes to KB-Orchestrator-Core's role abstraction, dispatch envelope, or verification-ledger schema require updating your project's slash commands / prompt envelopes accordingly. Conversely, any local concept that overlaps an upstream-owned concept (role, dispatch shim, ledger, INV 9/10, capability matrix) MUST defer to upstream — no local redefinition.
3. **Boundary precedence** — if your project has its own intra-project boundary contract (e.g., "agent A writes here, agent B writes there"), the upstream-framework boundary takes precedence: nothing in your project may redefine a concept KB-Orchestrator-Core owns.

For a concrete reference example, see the sibling project `claude-codex-orchestration/CLAUDE.md` § 0 "Upstream framework" — it ships an owned-by-upstream / owned-by-this-repo split table, the operating rules, and the bidirectional sync contract. Mirror that structure (adapt the rows to your project's actual owned scope) in your own `CLAUDE.md`. The same project's `BRIDGE_REQUIREMENTS.md` § "Upstream framework" applies the pattern to a contract-level spec file (rather than a project-level CLAUDE.md) — use whichever placement matches your project's primary entry document.

The minimum acceptable acknowledgment is a single sentence: *"This project is a downstream consumer of KB-Orchestrator-Core (`<vendoring-path-or-url>`); it owns `<your-concrete-scope>`; upstream owns roles, dispatch, ledger, INV 9 / INV 10."* Anything more is value-add for future readers.

### Integrating with an existing CLAUDE.md

Most adopting projects already have a CLAUDE.md with their own directives (commit conventions, code style, deployment process, domain rules). The Directive paragraph (Section 1) and the Upstream framework section above **add to** that file; they do not replace it. CLAUDE.md is concatenated markdown — multiple sections coexist cleanly. Three integration patterns:

**Pattern A — Append as labeled sections (recommended for most adopters).** Add the Upstream framework section and the Directive paragraph as their own `## ...` blocks separated by `---` rules. Both heading lines SHOULD explicitly note the content was vendored from upstream (e.g. `## KB-Orchestrator-Core directive (v3.0 — vendored from upstream)`) so future readers immediately understand these are not project-local decisions. Existing project directives stay above/below unchanged. Pro: the contract is at-a-glance visible in CLAUDE.md. Con: framework version bumps require a manual edit.

**Pattern B — `@`-import the vendored guide.** Claude Code's CLAUDE.md supports `@<path>` to inline another file's contents at session load. Reference your vendored copy of this guide directly (e.g. `@vendor/kb-orc/adoption-guides/external-orchestrator-directive.md`). Pro: framework upgrades are a single `git pull` in the vendored copy with no CLAUDE.md edit. Con: the contract is one indirection away from a casual CLAUDE.md reader. Choose Pattern B when long-term maintenance burden matters more than at-a-glance discoverability.

**Pattern C — Hierarchical CLAUDE.md (rarely right).** Claude Code concatenates CLAUDE.md from `~/.claude/`, the project root, and subdirectories. You could put the Directive in `~/.claude/CLAUDE.md` if every project on your machine adopts this framework — uncommon, but documented for completeness.

**Conflict resolution.** Where a project-local directive overlaps an upstream-owned concept (role abstraction, §25 dispatch shim, verification ledger, INV 9 / INV 10, capability matrix), the upstream-owned concept wins per the Boundary precedence rule above — your project-local directive must change to match. Anywhere else (commit conventions, code style, deployment process, CI rules, your domain logic), project directives govern unchanged. In practice 99% of existing CLAUDE.md content lives in domains the framework does not touch, so most adoptions are pure addition with no conflict resolution needed. The realistic friction is two minutes of finding the right insertion point in your existing CLAUDE.md, not a rewrite of project conventions.

---

## Cross-references

- `INDEX.md` — runtime entrypoint named by the Directive
- `commands/_delegate.md` — the 11-step shim, canonical step names + ledger write timing
- `adoption-guides/v2.9-invariant-10.md` — INV 10 per-harness enforcement (binding for the four-fact form)
- `claude-codex-orchestration/CLAUDE.md` § 0 + `BRIDGE_REQUIREMENTS.md` § Upstream framework — concrete reference for Section 6 reciprocal acknowledgment

---

**Last reviewed:** 2026-05-10
**Status:** revised post-Codex-audit (HIGH/MEDIUM/LOW findings closed)
