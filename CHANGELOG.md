# Changelog — SYSTEM-BLUEPRINT.md

## v3.0.0 — 2026-06-03 — monolith demoted; soak retired; static regeneration gate

**Source**: User directive — retire the Phase-6b soak ("can't generate enough traffic so soak on its own won't work… soak should not be part of our workflow"), use the substitute-and-tag path, and **involve Codex in designing and building a better gate** (JCC — joint Claude-Codex operations).

This is the comprehensive v3.0 entry (Phase 6 exit criterion #10). It completes the Phase-6 work that Phase 6a (tooling + carry-forward) and Phase 6b (soak initiation) set up: `SYSTEM-BLUEPRINT.md` is now a **compiled view** regenerated from Layer-2, not a canonical source.

### Why the soak was retired (criterion #8 superseded, not "passed")

The Phase-6b soak required *5 consecutive live iterations without a monolith read, observed over a 5-day window*. That assumed a live production pipeline. This repo is the quiescent **System Owner Brain**: the soak window (2026-05-08→13) and the 26 days after accrued **zero** new ledger rows; `iterations_observed` never left 0. A calendar-window observation gate with no traffic to observe cannot complete. The soak's *guarantee* (no runtime role depends on the monolith) is real and is now enforced **statically** — strictly stronger for every declared load path than sampling 5 runs.

### JCC design review (ledger job `jcc-gate-design-001`)

Codex (degraded-path `codex exec`, bridge binary absent per `codex-bridge-adapter.md §5`) adversarially reviewed the proposed replacement and caught three real defects, all folded in: (1) raw grep false-positives on prohibition prose → scan **structured load surfaces** only; (2) "structural-only diff" too weak → **paragraph-level coverage** + **standing exact-reproducibility**; (3) the INV-11 carve-out was too broad → **narrowed** to declared reason codes. DISPATCH+CONSUME rows recorded in `pipeline/verification-ledger.jsonl`.

### Added

- **`adoption-guides/static-regeneration-gate.md`** — the v3.0 replacement gate. One-time (pre-`--write`): frontmatter/cross-ref/bundle checks + `verify-no-monolith` + `verify-blueprint --coverage` + human semantic sign-off. Standing (CI): exact reproducibility + no-monolith.
- **`tools/verify-no-monolith.sh`** — proves no `bundles/*.yaml` load surface or `loads_bundle` references the monolith (structured scan, not raw mentions). Hard-fail on load surfaces; WARN on stale `§`-citations in runtime files.
- **`tools/verify-blueprint.sh`** — COVERAGE (every Layer-2 content body present verbatim in a fresh generation; 47/47 with the new schema) + REPRODUCE (committed monolith == generator output, timestamp-normalized).
- **`60-schemas/progress.md`** — first-class `PROGRESS.md` schema (the 7 verified pipeline-state fields), closing the gap the JCC citation map flagged (the old `§5` was never extracted). Wired into `bundles/orchestrator-core.yaml`; `20-roles/orchestrator.md` now points its PROGRESS.md row here.

### Changed

- **`SYSTEM-BLUEPRINT.md`** regenerated via `tools/build-blueprint.sh --write` (pre-regen backup saved as `.SYSTEM-BLUEPRINT.pre-regen.<ts>.md`); version bumped 2.10 → 3.0.0. It is now a compiled view; direct edits are blocked by CI.
- **`.github/workflows/ci.yml`** — `monolith-edit-guard` (weak "some Layer-2 co-change") replaced by `monolith-reproducible` (exact-reproducibility) + a no-monolith step.
- **`00-overview/invariants.md`** — INVARIANT 11 carve-out narrowed: `meta_review`/`apply_meta` may load the monolith only for a declared `monolith_load_reason` ∈ {`regeneration-diff`, `migration-audit`, `backcompat-inspection`}, no downstream propagation.
- **`README.md`** — vendoring copy block + smoke test now require registering `.claude/commands/` (the most common adoption miss: vendored command *specs* are not invokable slash commands until placed there); adoption-guides table updated.
- **`80-status/shipped-vs-planned.md`** — `max_lines` 100 → 105 (codex-bridge protocol-2 rows).
- **`adoption-guides/phase-6b-soak.md`** — banner: RETIRED, superseded by the static regeneration gate (kept for history).

### Human semantic sign-off (criterion #6 of the new gate)

Maintainer confirmed the regenerated monolith is a faithful **expansion** of the prior v2.10 monolith (2,531 → ~3,800 lines; growth is per-file headings + source comments + frontmatter promotion), not a meaning-altering reshuffle. COVERAGE proved all 46 content bodies present verbatim.

## Phase 6b (v3.0) — 2026-05-08 — soak initiated

**Source**: User-driven directive — *"start phase 6b"* — the second half of v3.0 Phase 6: demote `SYSTEM-BLUEPRINT.md` from canonical truth-source to compiled view regenerated from Layer-2. This entry documents soak **initiation**; soak completion (criterion #8: "5 consecutive iterations of any agent role complete without reading SYSTEM-BLUEPRINT.md") lands at day 5 (target 2026-05-13) and ships the `v3.0.0` tag plus the comprehensive v3.0 CHANGELOG entry (criterion #10).

### Phase 6 exit criteria — current state

| # | Criterion | Status |
|---|---|---|
| 1 | `tools/verify-frontmatter.sh` exits 0 | ✅ green (46 files) |
| 2 | `tools/verify-cross-refs.sh` exits 0 | ✅ green (74 refs) |
| 3 | `tools/build-blueprint.sh` regenerates the blueprint | ✅ Phase 6b — real concat logic (was Phase-1 skeleton) |
| 4 | All 13 bundles + `build-bundle --check` zero drift | ✅ Phase 6a |
| 5 | `agents.config.yaml.schema_version == 2`; every agent has `loads_bundle:` | ✅ Phase 6b — schema_version 1→2, config_revision 3→4, all 11 agents annotated |
| 6 | CLAUDE.md and README.md point at INDEX.md | ✅ Phase 6b — repointed |
| 7 | All 11 role-bearing slash commands exist | ✅ Phase 5 |
| 8 | 5 consecutive iterations without reading SYSTEM-BLUEPRINT.md | ⏳ soak in progress |
| 9 | Verification ledger contains restructure audit trail | ✅ 134 entries |
| 10 | Comprehensive v3.0 CHANGELOG entry | ⏳ at soak end |

### Added

- **`tools/build-blueprint.sh` — real concat logic** (criterion #3). Three modes: default (writes candidate to `SYSTEM-BLUEPRINT.candidate.md`, non-destructive), `--write` (replaces live monolith with backup), `--dry-run` (inventory only). Walks Layer-2 dirs in canonical order (`00-overview/` first, `80-status/` last); strips frontmatter; promotes `title:` to `##` heading; inserts `# Layer 2 — <dir>` separators. Synthesises preamble + regeneration-trailer. The default mode is deliberately non-destructive so the candidate can be inspected during the soak without touching the canonical file.
- **`adoption-guides/phase-6b-soak.md`** — operating contract for the 5-day soak. Day-by-day checklist, failure modes, abort/restart rules, day-5 swap procedure (`tools/build-blueprint.sh --write` + tag + CI gate enable). Day 1 includes a 20% sample semantic-equivalence check between Layer-2 role files and live monolith §6/§25/§8 content.
- **`pipeline/soak-state.json`** — soak day-counter. Fields: `phase`, `started_at` (ISO-8601), `target_end`, `status` (in-progress/passed/failed/aborted), `iterations_observed`, `monolith_reads_during_soak`, `candidate_path`, `notes`. Operator updates daily; agents that read `SYSTEM-BLUEPRINT.md` during the window cause `monolith_reads_during_soak` to increment and `iterations_observed` to reset to 0.
- **`.github/workflows/ci.yml` `monolith-edit-guard` job** — blocks PRs/pushes that change `SYSTEM-BLUEPRINT.md` without an accompanying Layer-2 edit, `tools/build-blueprint.sh` edit, or `pipeline/soak-state.json` update. Prints a clear remediation message pointing at the soak procedure.

### Changed — agents.config.yaml schema bump (criterion #5)

- `schema_version: 1 → 2` — signals the new REQUIRED `loads_bundle: <name>` field on every agent.
- `config_revision: 3 → 4`; `last_updated: 2026-05-04 → 2026-05-07`.
- All 11 agents annotated with `loads_bundle:`:
  - `claude-main` → `orchestrator-core` | `claude-worker-planner` → `planner` | `claude-worker-precheck` → `pre-check`
  - `claude-worker-research` → `executor-research` | `claude-worker-commercial` → `executor-commercial`
  - `claude-worker-kblint` → `kb-linter` | `claude-worker-wiki-ingest` → `wiki-ingest` | `claude-worker-wiki-query` → `wiki-query`
  - `codex-audit` → `truthsayer` | `codex-eval` → `evaluator` | `codex-implement` → `executor-commercial`

### Changed — CLAUDE.md and README.md repointed (criterion #6)

- **`CLAUDE.md`**: "My Role as System Owner" reframes the responsibility from "maintain SYSTEM-BLUEPRINT.md" to "maintain Layer-2 — the monolith is a compiled view". Project Structure tree replaced with current actual state (47 Layer-2 files, 13 bundles, 11 commands, 1 adoption guide, CI workflow). "Update Protocol" now reads as: edit Layer-2 → run verify gates → CHANGELOG → re-run `tools/build-blueprint.sh --write` for compiled-view refresh. New invariant: never edit SYSTEM-BLUEPRINT.md by hand — round-trip through Layer-2.
- **`README.md`**: blueprint-version badge bumped v2.8 → v2.10 and re-linked to INDEX.md (was SYSTEM-BLUEPRINT.md). Restructure-status badge bumped to "Phase 6b — Soak". The "Pass SYSTEM-BLUEPRINT.md to any agent" line replaced with "Point any agent at INDEX.md (or the role-specific bundle)". "What's Included" tree replaced with current reality. Quick Start "Option A" updated to copy the full Layer-2/bundle/tool/command set, and to instruct Claude Code to read INDEX.md (not the monolith).

### Pending until soak end

- Run `tools/build-blueprint.sh --write` (regenerates live `SYSTEM-BLUEPRINT.md` from Layer-2; saves backup snapshot).
- Tag `v3.0.0`.
- Append the comprehensive v3.0 CHANGELOG entry (criterion #10) summarising Phases 0 through 6 cumulatively.
- Delete the candidate `SYSTEM-BLUEPRINT.candidate.md` (its work is done once the live file is regenerated).
- Soft-delete or migrate the `70-adoption/` numbered directory placeholder once `adoption-guides/` is the established location.

### Files changed

| File | Change |
|---|---|
| `tools/build-blueprint.sh` | Real concat logic; replaces Phase-1 skeleton |
| `agents.config.yaml` | schema_version 1→2; config_revision 3→4; last_updated; 11 `loads_bundle:` fields added |
| `CLAUDE.md` | Repointed to INDEX.md as runtime entry; Project Structure refreshed; Update Protocol rewritten; new no-hand-edit-monolith invariant |
| `README.md` | Badge target; v3.0 banner; "Pass SYSTEM-BLUEPRINT.md" → "Point any agent at INDEX.md"; What's Included tree; Quick Start |
| `adoption-guides/phase-6b-soak.md` | **NEW** — soak procedure |
| `adoption-guides/external-orchestrator-directive.md` | **NEW** — drop-in directive + Bootstrap Prompt for foreign orchestrators (Claude Code, Claude Agent SDK, Codex, OpenAI-compatible, MCP-native); vendoring, per-adapter wiring, soak pinning, adopter sanity check |
| `80-status/shipped-vs-planned.md` | New rows for `external-orchestrator-directive.md` and `codex-bridge-adapter.md`; deduplicated stray double-row; `last_reviewed` 2026-05-04 → 2026-05-10 |
| `adoption-guides/codex-bridge-adapter.md` | **NEW** — Model C ownership formalization. Codex executor wiring guide naming sibling `claude-codex-orchestration` as canonical implementation of the codex-bridge adapter slot. 7 sections: ownership rationale, install paths, agents.config wiring, INV 10 enforcement, protocol probe + degradation, pinning, sanity check. |
| `INDEX.md` | "Architecture in 30 seconds" Adapters bullet now names the sibling project as the codex-bridge canonical implementation and points at the new adoption guide |
| `50-adapters/codex-bridge.md` | New "Ownership (Model C, 2026-05-10)" paragraph in body (not just frontmatter); cross-refs section adds `adoption-guides/codex-bridge-adapter.md`; `last_reviewed` 2026-05-04 → 2026-05-10 |
| `adoption-guides/external-orchestrator-directive.md` | Section 3 Codex row appended pointer to `adoption-guides/codex-bridge-adapter.md` for full installation + wiring; Section 5 paragraph 1 fixed (gateguard is a Claude Code PreToolUse session hook, NOT a CI workflow check) — Codex audit pass 4 verdict READY |
| `pipeline/soak-state.json` | **NEW** — soak day-counter (status: in-progress) |
| `.github/workflows/ci.yml` | New `monolith-edit-guard` job |
| `CHANGELOG.md` | this entry |

### Why no SYSTEM-BLUEPRINT version bump (yet)

The live `SYSTEM-BLUEPRINT.md` content is unchanged in this commit. Frontmatter `version: 2.10` stays. The `--write` swap at soak end will regenerate the file in place; that swap is when v2.10 effectively becomes "v3.0.0 — compiled view".

### What Phase 6b initiation does NOT do

- Does NOT overwrite the live `SYSTEM-BLUEPRINT.md`. The candidate is generated; the live file is canonical until day 5.
- Does NOT delete the v2.10 archive snapshot or any prior version archive.
- Does NOT change INDEX.md, the bundles, or any role contract.
- Does NOT shorten the soak window. 5 days is fixed; counter resets on any failure mode.

## Phase 6a (v3.0) — 2026-05-07

**Source**: User-driven directive — *"fold in the carry-forward items"* — folding the v2.9 and v2.10 unresolved-items list into v3.0 Phase 6 alongside the planned bundle generation tooling and CI drift gate. No SYSTEM-BLUEPRINT.md content/version bump (`commands/_delegate.md` is the operationalisation layer; the blueprint already promises the gates this release implements). Phase 6 is now split into 6a (this release: tooling + carry-forward closures) and 6b (planned: monolith demotion + 5-day soak).

### Added — Tooling (Phase 6 primary scope)

- **`tools/build-bundle.sh` — full referential-integrity check.** Replaces the Phase-1 skeleton. `--check` mode walks every `bundles/*.yaml` and verifies: (1) structural fields present (`bundle:`, `version:`, `loads:`); (2) every path in `loads:`/`optional:`/`adapter_specific:` exists on disk; (3) every non-universal `loads:` file declares the consuming role in its frontmatter `audience` or `also_needed_by`. Bundle-name normalisation handles dash-vs-underscore (`apply-meta` → `apply_meta`), executor sub-specialisations (`executor-research`/`executor-commercial` → `executor`), and composite bundles (`orchestrator-core`/`agent-onboarding` → wildcard match). Generate mode (`tools/build-bundle.sh <role>`) emits a CANDIDATE manifest to stdout for human review against the committed bundle. Byte-equivalent deterministic regeneration deferred to a future release.
- **`.github/workflows/ci.yml` — CI drift gate.** Runs on every push to `main` and every pull request to `main`. Three steps: `verify-frontmatter --strict` (required keys + `max_lines`); `verify-cross-refs`; `build-bundle --check`. Realises the "Phase 6 onward" promise from `bundles/_README.md`.

### Added — Carry-forward closures

- **`commands/_delegate.md` Step 4 host_access re-check** (v2.10 carry-forward). Defense-in-depth re-evaluation of `policy.host_local_service_dependent_roles` against the resolved `(adapter, effective_sandbox)` pair after `sandbox_override` is applied in Step 3 — Step 2's cached probe response can be stale, and the cached check is the failure mode v2.10 codified the rule against. On miss: re-route per `policy.on_host_access_missing_for_required_role` (escalate / reroute / inline).
- **`commands/_delegate.md` Step 8 INVARIANT-10 sub-check** (v2.9 carry-forward). When the artifact bundle includes `iterations/current/execution-log.md` and the dispatched adapter's `enforces_pre_action_facts != true`, the orchestrator scans the log for a four-fact block preceding every state-mutating tool invocation. Read-only invocations carved out per INVARIANT 10. Missing/malformed block: `schema_verdict = FAIL` with subtype `inv10-fact-missing`.
- **`60-schemas/execution-log.md` — Pre-action fact presentation section.** Documents the format the Step 8 sub-check validates against. Frontmatter version 2.9 → 2.10; `last_reviewed: 2026-05-07`; `max_lines: 100 → 130`. Validation enumeration extended to mention the INV-10 block.
- **`adoption-guides/v2.9-invariant-10.md` — first adopter-facing guide** (v2.9 carry-forward). Per-runtime enforcement instructions: Claude Code (`gateguard` skill), Claude Agent SDK (PreToolUse callback), bridge-only adapters (`enforces_pre_action_facts: "orchestrator-side"` + orchestrator-emitted block), custom CLIs (host-side wrapper). Migration path for `config_revision: 1` projects.

### Fixed — Real frontmatter drift surfaced by the new `--check`

- **`30-knowledge/temporal-facts.md`** `also_needed_by:` adds `executor`. The file was already loaded by `bundles/executor-research.yaml` but the frontmatter never named the executor role — the new check caught the asymmetry.
- **`60-schemas/audit-report.md`** `audience:` adds `pre_check`. Loaded by `bundles/pre-check.yaml` (pre-check evaluator reads truthsayer's audit-report); audience never named pre_check.
- **`60-schemas/quality-criteria.md`** `audience:` adds `pre_check`. Loaded by `bundles/pre-check.yaml`; audience never named pre_check.

### Updated

- **`bundles/_README.md`** — drift-detection paragraph rewritten to describe Phase 6a's referential-integrity semantics + the candidate-manifest fallback for the deferred byte-equivalent regen.
- **`80-status/shipped-vs-planned.md`** — `commands/_delegate.md`, Layer-2-directories, Bundle-manifests, and `tools/` rows updated to reflect Phase 6a closures. Two new rows added (`.github/workflows/ci.yml`, `adoption-guides/v2.9-invariant-10.md`). Phase-status table: Phase 6 split into 6a (shipped 2026-05-07) and 6b (planned: monolith demotion).

### Why no SYSTEM-BLUEPRINT version bump

`SYSTEM-BLUEPRINT.md` already states the gates this release implements (§25 promises Step 8 validates; §2 INVARIANT 10 promises pre-action facts; §25 v2.10 promises host_access compatibility). The blueprint is the contract; `commands/_delegate.md` is the operationalisation. This release adds operational fidelity to the existing contract — no new contract surface. Frontmatter `version` field on `60-schemas/execution-log.md` bumped 2.9 → 2.10 to reflect that it now mirrors the v2.10 source rather than the v2.9 source; the SYSTEM-BLUEPRINT.md front-matter remains 2.10.

### What Phase 6a does NOT do

- Does not regenerate `SYSTEM-BLUEPRINT.md` from Layer-2 (that's Phase 6b — "demote monolith").
- Does not implement byte-equivalent deterministic bundle regeneration. Bundles remain hand-curated v1; the candidate-manifest mode is informational.
- Does not write a reference `tools/host-shell-wrapper.sh` for custom-CLI INVARIANT-10 enforcement (still tracked in v2.10 unresolved items).
- Does not change the iteration lifecycle, ledger schema, or any blueprint section.

### Files changed

| File | Change |
|---|---|
| `tools/build-bundle.sh` | Real `--check` (referential-integrity) + candidate-manifest generate mode; replaces Phase-1 skeleton |
| `.github/workflows/ci.yml` | **NEW** — CI drift gate (frontmatter + cross-refs + bundle check) |
| `commands/_delegate.md` | Step 4 host_access re-check; Step 8 INVARIANT-10 sub-check |
| `60-schemas/execution-log.md` | Pre-action fact presentation section; frontmatter version 2.9 → 2.10; max_lines 100 → 130; validation enumeration extended |
| `30-knowledge/temporal-facts.md` | `also_needed_by:` adds `executor` |
| `60-schemas/audit-report.md` | `audience:` adds `pre_check` |
| `60-schemas/quality-criteria.md` | `audience:` adds `pre_check` |
| `adoption-guides/v2.9-invariant-10.md` | **NEW** — first adoption guide; closes v2.9 unresolved item |
| `bundles/_README.md` | Drift-detection paragraph rewritten |
| `80-status/shipped-vs-planned.md` | Asset rows updated; two new rows; Phase 6 split into 6a (shipped) and 6b (planned) |
| `CHANGELOG.md` | this entry |

### Unresolved items (deferred)

- **Phase 6b — monolith demotion** (regenerate `SYSTEM-BLUEPRINT.md` from Layer-2 + 5-day soak). `tools/build-blueprint.sh` operational; soak procedure still to be drafted.
- **Byte-equivalent deterministic bundle regeneration.** Phase 6a ships referential-integrity; deterministic regen requires a richer derivation rule that captures the ordering and curation in v1 hand-written bundles.
- **`tools/host-shell-wrapper.sh`** — reference INVARIANT-10 wrapper for custom CLI adapters (carried forward from v2.10 unresolved).
- **`70-adoption/` numbered Layer-2 directory** — separate from `adoption-guides/`; per the v3.0 plan, future adoption-guides should be moved here once the format is settled.

## v2.10 — 2026-05-04

**Source**: Codex-authored update to the bridge contract — `../claude-codex-orchestration/BRIDGE_REQUIREMENTS.md` §"Local service / socket access" (lines 165-192). Trigger: a Stage-4 failure where a Codex job launched via `codex-task-bridge run --mode implement` specifically to run `psql` reported the database cluster as unavailable, despite holding `workspace-write` and `--full-auto`. Codex correctly diagnosed that `workspace-write`, `--full-auto`, and `implement` mode are filesystem and approval-mode directives that do NOT imply loopback TCP or Unix-socket reachability, and recommended an additive `host_access: {loopback_tcp: bool, unix_sockets: bool}` capability on `capabilities --json`. This release propagates the lesson to the orchestrator side of the contract.

### Added

- **`SYSTEM-BLUEPRINT.md` §25 adapter `probe` row.** Extended return shape to require `host_access: {loopback_tcp: bool, unix_sockets: bool}`. Missing/partial fields default to `false` (deny). Adapters that have not advertised a capability MUST NOT be dispatched to roles that require host-local services.
- **`SYSTEM-BLUEPRINT.md` §25 — new subsection "Sandbox flags do not imply host-local service access (v2.10)".** Formalises the orchestrator-side rule mirrored from BRIDGE_REQUIREMENTS:165-192. Documents the degradation pattern: pre-inject required query results, or invoke a host-side wrapper outside the delegated job.
- **`SYSTEM-BLUEPRINT.md` §25 "does NOT do".** New bullet: this section does not grant host-local service access by virtue of any sandbox flag.
- **`agents.config.yaml` policy section.** New knobs: `assume_host_access_false_unless_probed: true` (default-deny), `on_host_access_missing_for_required_role: escalate`, and `host_local_service_dependent_roles: [executor.commercial, kb_linter]`. `config_revision` bumped 2 → 3.
- **`agents.config.yaml` adapter blocks.** All three adapters annotated with `host_access`: `claude-orchestrator` and `claude-native` get `{loopback_tcp: true, unix_sockets: true}` (host shell, no sandbox); `codex-bridge` gets `{loopback_tcp: false, unix_sockets: false}` until the bridge protocol exposes `capabilities --json` with the field.
- **`SYSTEM-BLUEPRINT-v2.10.md`** — snapshot per CLAUDE.md "never delete old blueprint versions" invariant.

### Why this is a minor bump (2.9 → 2.10), not a patch

Same logic as v2.9: the adapter contract surface is meaningfully extended (one new REQUIRED probe field, one new `does NOT do` bullet, one new policy block). No existing behaviour silently changes for adopters; an adopter pinning `config_revision: ≤ 2` continues to operate but with no host-access guarantees, and the orchestrator emits a warning recommending the bump on next edit.

### What v2.10 does NOT do

- Does not introduce a new invariant. INVARIANTS 1–10 are unchanged. Host access is an adapter-contract field, not a system-wide property.
- Does not change the iteration lifecycle, pipeline state machine, ledger schema, or any other §-section.
- Does not modify any Layer-2 file beyond what Phase 3 (introduced in the same session) introduces. The host-access rule is layered into §25 only; Layer-2 invariants.md is untouched (no INVARIANT 11). Phase-3 role contracts (20-roles/) reference the new field where relevant.
- Does not require any adopting project to re-implement the bridge today. Projects that pin `config_revision: ≤ 2` continue to operate; the orchestrator emits a one-time warning at session start and recommends bumping when `agents.config.yaml` is next edited.
- Does not change the bridge contract — the bridge already requires the orchestrator to handle this; this release codifies the orchestrator's compliance.

### Files changed

| File | Change |
|---|---|
| `SYSTEM-BLUEPRINT.md` | §25 probe row extended with `host_access`; new §25 subsection "Sandbox flags do not imply host-local service access"; new §25 "does NOT do" bullet; Version History row; front-matter Version 2.9 → 2.10 |
| `SYSTEM-BLUEPRINT-v2.10.md` | NEW — snapshot |
| `agents.config.yaml` | `config_revision` 2 → 3; new policy block (host_access default-deny + denied-roles); 3 adapter blocks annotated with `host_access` |
| `pipeline/verification-ledger.jsonl` | 1 re-extraction audit row attributing the change to BRIDGE_REQUIREMENTS:165 |
| `CHANGELOG.md` | this entry |

### Unresolved items

- A future bridge protocol bump SHOULD add `host_access` to the bridge's `capabilities --json` output. Until then `codex-bridge.host_access` in `agents.config.yaml` is a static-declaration placeholder (`false/false`) rather than a probed value.
- `commands/_delegate.md` Step 2 (PROBE) and Step 4 (DISPATCH) should add a host_access compatibility check before invoking the adapter. Deferred to Phase 5 when commands are rewritten.
- The orchestrator-degradation pattern (pre-inject query results / host-side wrapper) is described in prose; a templated wrapper script in `tools/host-shell-wrapper.sh` is a candidate for Phase 4.

## v2.9 — 2026-05-04

**Source**: User-driven directive during v3.0 Phase 2 dispatch. Trigger: the harness fact-forcing gate (gateguard skill) blocked a Bash/Edit call mid-dispatch; the user's response — *"my directives are to prevent such a condition from any project that inherits the orchestration from this build"* — promoted the gate's behaviour from a local hook configuration to a structural blueprint property. The condition the gate prevents (state-mutating tool calls without prior user-visible alignment between request and action) is the same failure mode INVARIANT 8 prevents for source-saving and INVARIANT 9 prevents for state writes — but at the per-tool-call granularity rather than per-iteration granularity.

### Added

- **`SYSTEM-BLUEPRINT.md` §2 — INVARIANT 10: Pre-action fact presentation.** Every state-mutating tool call (Bash, Edit, Write, MultiEdit, NotebookEdit, delegated dispatch, network POST/PUT/DELETE, MCP write tools) MUST be preceded by a user-visible statement of (a) the current request restated in one sentence, AND (b) what the action verifies/produces. CARVE-OUT for read-only tools (Read, Grep, Glob, Ls, WebFetch→sources/, WebSearch) and task-tracker operations. ENFORCEMENT: harness-enforced via PreToolUse hook; in Claude Code the gateguard skill provides this. PROPAGATION clause: any project loading `agents.config.yaml` inherits the gate.
- **`SYSTEM-BLUEPRINT.md` §25 adapter contract.** New required field in adapter probe response: `enforces_pre_action_facts: bool | "orchestrator-side"`. Adapters reporting `false` may only fulfil read-only roles. The `"orchestrator-side"` tri-state value is for adapters (such as the MVP codex-bridge) that lack an in-process callback — the orchestrator emits the fact block on their behalf before each dispatch.
- **`SYSTEM-BLUEPRINT.md` §25 "What this section does NOT do".** New bullet: this section does not exempt any agent from Invariant 10.
- **`agents.config.yaml` policy section.** New knobs: `pre_action_fact_presentation_required: true` (default), `pre_action_fact_enforcement_mechanism: gateguard-skill`, `on_pre_action_fact_missing: reject`, plus a canonical `state_mutating_tools:` list. `config_revision` bumped 1 → 2; `last_updated` bumped to 2026-05-04.
- **`agents.config.yaml` adapter blocks.** `claude-orchestrator`, `claude-native`, and `codex-bridge` annotated with `enforces_pre_action_facts` (true / true / orchestrator-side respectively) and `pre_action_fact_mechanism`.
- **`SYSTEM-BLUEPRINT-v2.9.md`** — version snapshot per CLAUDE.md "never delete old blueprint versions" invariant.
- **`00-overview/invariants.md`** — re-extracted to mirror the new INVARIANT 10. `max_lines` bumped 120 → 180 to accommodate the new invariant body. Re-extraction logged in `pipeline/verification-ledger.jsonl`.

### Why this is a minor (2.x) bump, not a patch (2.x.y)

INVARIANT 10 is architectural — it changes the adapter contract (probe response now has a required field), the orchestrator's dispatch-validation behaviour (config-load fails fast on a state-mutating role bound to a non-enforcing adapter), and the inheritance contract (every adopting project now gates state mutations). No existing behaviour silently changes — adopters that were not previously running gateguard see no breakage at adoption (default knob is `true`, but absence is treated as "unknown / warn" until config_revision ≥ 2 in their own file). But the surface is meaningfully extended; that is a minor bump.

### What v2.9 does NOT do

- Does not change any other invariant (1–9 unchanged).
- Does not modify the iteration lifecycle or pipeline state machine.
- Does not change the ledger schema.
- Does not extract any further Phase-2 files (those resume after this version bump lands).
- Does not require any adopting project to re-implement the gate today — projects that pin `config_revision: 1` continue to operate; the orchestrator emits a warning and recommends bumping when next edited.

### Files changed

| File | Change |
|---|---|
| `SYSTEM-BLUEPRINT.md` | §2 INVARIANT 10 added; §25 adapter-contract row updated; §25 "does NOT do" bullet added; Version History row added; front-matter Version 2.8 → 2.9 |
| `SYSTEM-BLUEPRINT-v2.9.md` | NEW — snapshot |
| `agents.config.yaml` | `config_revision` 1 → 2; `last_updated` 2026-05-04; new policy knobs (Invariant 10); 3 adapter blocks annotated |
| `00-overview/invariants.md` | INVARIANT 10 mirrored; frontmatter `version` 2.8 → 2.9; `extracted_from.source` → v2.9; `max_lines` 120 → 180 |
| `pipeline/verification-ledger.jsonl` | 2 new entries (dispatch + consume for the invariants.md re-extraction) |
| `CHANGELOG.md` | this entry |

### Unresolved items (for v3.0 Phase 2 continuation)

- 17 remaining Phase-2 file extractions resume now that the source is at v2.9 (sources to extract from will reference v2.9 going forward).
- `commands/_delegate.md` step 8 (SCHEMA gate) should add an Invariant-10 sub-check: confirm the delegated agent's output execution-log shows pre-action fact presentation. Deferred to Phase 5 when commands are rewritten.
- Adoption guides for v2.9 — adoption-guides/ remains empty per known gap; new guide entry "v2.9 INVARIANT 10 adoption" should describe the minimum viable enforcement mechanism per runtime (Claude Code: install gateguard; Claude Agent SDK: register PreToolUse callback; other CLIs: write a wrapper script).

## v2.8.1 — 2026-05-04

**Source**: Audit-driven stabilisation pass — Phase 0 of the v3.0 restructure approved by user (plan: `~/.claude/plans/crispy-sniffing-conway.md`). Triggered by `auditor-central/KB-Orchestrator/audit.md` findings #1, #3, #4, #5 (high+medium severity). No content rewrites; this release fixes drift and adds forward-pointing scaffolding before the larger restructure begins.

### Fixed (audit finding #1)

- **`commands/pre-check.md` line 55**: `pipeline_state: 'pre-checked'` → `'pre-check-complete'`. The canonical enum value was added in v2.5 (per CHANGELOG v2.5 row) but the slash-command file was never synced. Also added inline reference to Invariant 9 (orchestrator-only writes to pipeline_state).

### Updated (audit findings #3, #4)

- **`README.md`**: badge bumped from `v2.5` → `v2.8`; added `v3.0-in-migration` badge linking to CHANGELOG; added prominent v3.0 restructure note explaining the bundle-loading direction; "What's Included" tree updated to show `agents.config.yaml` and `commands/_delegate.md`; "What the blueprint covers" table extended with §25 row; Quick Start updated to show `agents.config.yaml` copy + the 10 (not 11) remaining commands.
- **`SYSTEM-BLUEPRINT.md`**: front-matter `**Version**: 2.7` → `2.8` (the v2.8 row had been added to the Version History table without syncing the front-matter — drift fix). Added the v3.0 forward-pointing banner at the top per audit finding #4 ("the blueprint violates its own selective-retrieval philosophy"): banner explicitly tells agents this file is the canonical reference, not the runtime ingest entrypoint after Phase 4, and points at `INDEX.md` (forthcoming) as the new entry.

### Added (audit finding #5)

- **`80-status/shipped-vs-planned.md`** — first file of the v3.0 numbered-directory structure to land. Three-section capability-maturity registry: blueprint architecture (what's in the spec); repository assets (what's actually in the repo vs. planned); Codex bridge capabilities (mirrors BRIDGE_REQUIREMENTS implementation-status table — distinguishes MVP-shipped surface from planned surface that requires `capabilities --json` probe gating). Also tracks v3.0 restructure phase status (Phase 0 → in progress; Phases 1–6 → planned). Frontmatter follows the v3.0 standard (id/title/purpose/audience/status/version/last_reviewed/extracted_from/related/max_lines).
- **`80-status/` directory** — created. First Layer-2 directory of the v3.0 structure.

### What v2.8.1 does NOT do

- Does not extract any blueprint section into Layer-2 files (that's Phases 2–4 of v3.0).
- Does not write the missing 10 role-bearing slash commands (Phase 5).
- Does not change the `_delegate.md` dispatch path to bundle-loading (Phase 5).
- Does not invoke the Codex bridge (no extraction work yet).
- Does not modify `agents.config.yaml` schema (still `schema_version: 1`; bumps to `2` in Phase 5).

### Files changed

| File | Change |
|---|---|
| `commands/pre-check.md` | Drift fix: `pre-checked` → `pre-check-complete`; Invariant 9 reference added |
| `README.md` | Version badge, restructure note, project tree, command status, sections table, Quick Start |
| `SYSTEM-BLUEPRINT.md` | Front-matter version line synced to 2.8; v3.0 forward-pointing banner added |
| `80-status/shipped-vs-planned.md` | **NEW** — capability-maturity registry |
| `80-status/` | **NEW** directory — first Layer-2 home |
| `CHANGELOG.md` | This entry |

### Unresolved items (deferred to subsequent v3.0 phases)

- All extraction work — see `~/.claude/plans/crispy-sniffing-conway.md` Phases 2–6.
- Schema files under `templates/schemas/` referenced by `_delegate.md` step 8 (Phase 2).
- A reference adapter implementation for `claude-native` and `codex-bridge` (carried from v2.8 unresolved).

## v2.8 — 2026-05-03

**Source**: User-driven architectural extension. Trigger: review of `../claude-codex-orchestration/BRIDGE_REQUIREMENTS.md` and the question "how can we enable our systems to take advantage of this orchestration?" The follow-up clarification — "Claude is both orchestrator AND a first-class executor; the architecture must be service-agnostic; a config file should declare role assignments" — drove the framing. This release codifies the protocol; it does not yet wire the eleven role-bearing slash commands (which remain on the gap list from v2.1).

### New: Section 25 — External Agent Delegation Protocol

The blueprint now defines a **service-agnostic protocol** for delegating any blueprint role (§6) to any agent runtime — additional Claude instances (workers via Task tool / Agent SDK), Codex (via codex-task-bridge), and any future agent (Mistral, Devstral, Cursor, MCP-exposed agents).

**Three-layer architecture:**
1. **Roles** (blueprint, §6) — semantic responsibilities. Stable. The blueprint never names a specific agent.
2. **Agents** — concrete instances. Multiple agents can share an adapter with different config.
3. **Adapters** — protocol drivers (`claude-orchestrator`, `claude-native`, `codex-bridge`; future: `openai-compat-http`, `cursor-cli`, `mcp-agent`). Adding a new agent type = adding one adapter block; existing agents and roles untouched.

**Decoupling principle:** roles change rarely (blueprint truth), agents change as we discover better tools (operational truth), adapters change with transport (protocol truth). A new agent type requires no blueprint edit — only a new adapter and registry entries.

**Claude is both orchestrator and first-class executor.** A common misreading is "Claude orchestrates, Codex executes." The accurate framing: `claude-main` is the orchestrator (singleton, non-delegable per Invariant 9). It dispatches role work to other Claude instances (`claude-worker-*`) for the same reason it dispatches to Codex — process/context isolation enforces Generator≠Evaluator (Invariant 1). Spawning a fresh Claude subagent is architecturally equivalent to spawning Codex; both are "delegate to a separate context." The orchestrator picks based on cost (§17), capability, and adversarial-diversity preference.

### New: Invariant 9 — Orchestrator role is non-delegable

The orchestrator role is exclusively `claude-main` and cannot be assigned to any other agent. The orchestrator owns, exclusively: PROGRESS.md writes and pipeline_state transitions, verification ledger writes, escalation.md authorship, dispatch decisions, and schema validation of every artifact consumed from a delegated agent. Why non-delegable: if any other agent could promote itself to orchestrator mid-pipeline, the trust model (§19) collapses — a delegated agent could approve its own output by writing PROGRESS.md, defeating Invariant 1. Scope: applies the moment `agents.config.yaml` exists; trivially satisfied for projects that have not yet adopted external-agent delegation.

### New: §19 addendum — Trust level for delegated-agent output + verification ledger

- Trust Levels table extended: any output from a delegated agent (Claude worker, Codex via bridge, future) is **Low trust — same as agent-written pipeline files**. The model family of the delegated agent does not affect trust level. Trust derives from the orchestrator's verification of the *output*, not from the identity of the *producer*.
- **Authentication ≠ Verification** distinction made explicit. Both gates required on every consume. Authentication = "did this output come from the dispatch we made?" (job-id + content-hash check). Verification = "is the output correct, hallucinated, or reward-hacked?" (schema validation + reward-hacking checks + source re-check sample). Common failure mode: treating successful authentication as if it were verification. Both can fail independently; neither substitutes for the other.
- **Verification ledger** at `pipeline/verification-ledger.jsonl` — append-only audit trail. Two entries per delegation: dispatch (records request) and consume (records verdicts). Field schema fully specified. Meta-review (§21) reads it to identify agents/roles with persistent rejection rates — informs reassignment decisions.

### New: agents.config.yaml — the registry

Project-root file declaring adapters, agents, role assignments, and validation policy. Editing this file is the supported way to swap agents, add new agents, or A/B test agent assignments — no blueprint edit required. Schema fully specified (`schema_version`, `config_revision`, `last_updated`, `adapters`, `agents`, `roles`, `validation`, `policy`). Default config wires Claude workers to most roles, Codex to truthsayer + evaluator (for adversarial-family diversity), and reserves `apply_meta` to claude-main by policy.

### New: commands/_delegate.md — the dispatch shim

Meta-command (not user-invokable) that role-bearing slash commands compose. Specifies the canonical eleven-step dispatch sequence: LOAD config → PROBE adapter → PREPARE prompt (with semantic isolation) → DISPATCH (write ledger entry) → AWAIT → FETCH → AUTH (gate 1: provenance) → SCHEMA (gate 2a: structural) → VERIFY (gate 2b: reward-hacking + source-recheck + role-specific) → CONSUME or REJECT (write ledger entry) → STATE (orchestrator-only PROGRESS.md update). The shim is the single, identical dispatch path for every role; role-bearing commands stay clean of agent-specific plumbing.

### Changes to existing sections

- **Table of Contents**: added entry 25.
- **Quick Reference Card**: added DELEGATION and VERIFY GATE summary lines.

### Bridge adapter — Codex specifics

Section 25 includes a Codex-specific subsection covering: the bootstrap rule (probe `version` first, treat non-responsive as protocol 1, gate non-MVP surface behind `capabilities --json`); mode mapping (`design` for read-only roles, `implement` for workspace-write roles, `review` preferred for `codex-eval` once protocol ≥ 2); sandbox precedence (per BRIDGE_REQUIREMENTS); artifact mapping (bridge `last_message.txt` → blueprint `iterations/current/<role-output>.md` after schema validation); and the Invariant-9 boundary (pipeline state stays in PROGRESS.md, never delegated to bridge job state).

### What v2.8 does NOT do

- Does not change the role taxonomy of §6.
- Does not relax §19's trust model — delegated-agent output is Low trust regardless of agent identity.
- Does not introduce a new state machine — the pipeline state machine (§7) is unchanged; delegation is invisible to the iteration lifecycle.
- Does not authorise any agent except claude-main to write PROGRESS.md, the verification ledger, escalation.md, or to make pipeline state transitions.
- Does not write the eleven outstanding role-bearing slash commands. They remain a tracked gap (CHANGELOG v2.1 unresolved items, project CLAUDE.md "Honest completeness state"). When written, they will compose `/_delegate` per the per-role wiring table in `commands/_delegate.md`.

### Files changed

| File | Change |
|---|---|
| `SYSTEM-BLUEPRINT.md` | Added INVARIANT 9 (§2); §19 addendum (delegated-output trust + verification ledger); §25 (External Agent Delegation Protocol); TOC entry 25; Quick Reference Card additions; Version History row |
| `agents.config.yaml` | **NEW** — agent registry, role assignments, validation policy |
| `commands/_delegate.md` | **NEW** — orchestrator dispatch shim spec |
| `CHANGELOG.md` | This entry |

### Unresolved items (deferred to v2.9 or follow-up sprints)

- Eleven role-bearing slash commands (`plan`, `audit`, `execute`, `evaluate`, `kb-lint`, `wiki-ingest`, `wiki-query`, `escalate`, `meta-review`, `apply-meta`, `onboard`) still need to be written and retrofitted to compose `/_delegate`. Currently only `pre-check.md` exists.
- Schema files under `templates/schemas/` referenced by step 8 of the dispatch shim — to be populated as the role-bearing commands are written.
- A reference adapter implementation for `claude-native` (Task tool wrapper) — currently described in the spec but not implemented as code; the orchestrator follows the spec inline.
- A reference adapter implementation for `codex-bridge` — currently described in the spec; the orchestrator will shell out per the BRIDGE_REQUIREMENTS canonical CLI emission order.
- A/B audit lane: planned one-iteration trial of `/audit` inline (Claude) vs. delegated (Codex) to populate `audits/` with first comparative data on agent assignment quality.

## v2.7 — 2026-04-11

**Source**: Deep research pass across LLM wiki/KB implementations — GitHub repos, academic papers (WikiCollide, RefChecker, Practical GraphRAG), production case studies, and community implementations. 14 source files saved to `research/sources/`. Full findings report: `research/sources/findings-llm-wiki-deep-research-2026-04-11.md`.

### New: Five wiki-specific failure modes (Section 11)

Named and documented five failure modes distinct from general LLM hallucination — these are structural risks of the wiki architecture itself:

1. **Error compounding** — the wiki-unique risk. Wiki errors persist and self-reinforce through query-compounding. A subtle mistake in one page gets cited by a query answer, which gets filed back, creating two pages reinforcing the same error. Detection: trace provenance; flag wiki-citing-wiki chains with no source backing. New lint rule #10 added to KB Linter.

2. **Claim drift** — paraphrase loses precision over compilation rounds. Detection: embed compiled claim and source passage; flag cosine similarity drop below 0.85.

3. **False consolidation** — LLM merges similar-but-distinct entities into one page. Detection: incompatible attributes from different sources on same entity page.

4. **Citation rot** — source URL changes content or disappears. Detection: periodic re-fetch + diff. New lint rule #9 (citation health check) added.

5. **Confidence inflation** — hedging language lost during compilation. Detection: compare source hedging ("reportedly", "approximately") against definitive wiki claims.

### New: O(N*k) NLI contradiction scan (Section 6, lint rule #1)

Replaced the implicit O(N^2) pairwise contradiction scan with an O(N*k) NLI pipeline validated by WikiCollide (arXiv:2509.23233). Pipeline: extract claims as knowledge triplets → embed → retrieve top-k similar triplets from other pages → NLI classify pairs. Key metrics from WikiCollide: ~3.3% of facts are internally inconsistent at baseline; domain variation up to 17.7% for narrative content; automated detection ceiling ~75% AUROC — manual review at meta-review cadence remains necessary. This also resolves the "Concurrency model" and "KB drift detection at scale" items from v2.1 unresolved items.

### New: Typed relationships in wiki frontmatter (Section 11)

Added `relationships:` field with typed directional links: `uses`, `depends-on`, `contradicts`, `supersedes`, `caused`, `fixed`. Enables structural queries that untyped backlinks cannot: "what downstream pages affected if source X retracted?" (traverse depends-on), "unresolved contradictions?" (scan contradicts edges). KB Linter validates that `contradicts` relationships have corresponding entries in `wiki/synthesis/contradictions/`. Source: rohitg00 LLM Wiki v2, Microsoft GraphRAG.

**Budget extraction path**: SpaCy dependency parsing achieves 94% of LLM extraction quality for relationship types (arXiv:2507.03226). Pipeline: passive voice normalization → phrasal merging → coreference resolution → dependency triple extraction. Use LLM for frontier ingest; SpaCy for batch maintenance.

### New: Concrete scale thresholds (Sections 10, 20)

Replaced "moderate scale" with validated numeric breakpoints:
- <200 wiki pages: `wiki/index.md` only (Tier 1 always-loaded)
- 200-500 pages: Hybrid — index.md + BM25/vector retrieval (wiki-recall: 93% recall vs 60% wiki-only)
- \>500 pages: Full BM25 + vector + LLM reranker (qmd MCP)

Activation criteria for wiki/entities/ embeddings: `wiki/index.md` exceeds 150 lines (75% cap) AND agents need cross-entity semantic matching.

Section 20 updated with wiki-recall quantified performance: 98.4% token reduction, ~550 token wake-up cost, validated to 1,000 entities.

### New: Archive-on-ingest protocol (Section 14)

Following Wikipedia's own archival policy ("always archive web sources at time of citation"), added archive-on-ingest to the INVARIANT 8 sequence: SAVE → **ARCHIVE** → READ → EXTRACT → WRITE CLAIM. Protocol: submit URL to Wayback Machine Save API after source save; record `archive_url` + `archived_at` in source frontmatter. Archival failure is logged but non-blocking.

WebFetch file format updated with `archive_url` and `archived_at` fields.

Self-hosted alternative documented: ArchiveBox for compliance-grade local archival.

Optional hash-chain audit log documented: `prev_hash` field on pipeline.log.jsonl entries for tamper-evident provenance. 3.4ms/step overhead (AuditableLLM, MDPI 2026). EU AI Act / GDPR aligned.

### New: Wiki concurrency protocol (Section 11)

Added page-level optimistic locking protocol: `version_hash` (SHA-256 first 8 chars) in wiki page frontmatter. Read → modify → verify hash unchanged → write (or re-read and retry on mismatch). CRDTs explicitly not recommended for Markdown (Peritext, Ink & Switch). Append-only files (log.md, pipeline.log.jsonl) exempt from locking.

Source: tick-md file locking system, Anthropic multi-agent coordination patterns blog.

### Extended: KB Linter (Section 6)

Two new mandatory lint rules:
- **Rule #9 — Citation health check**: Re-fetch URLs in `source_urls` for pages modified in last 10 iterations. Flag 404/403 as `CITATION-ROT`, content change >30% as `SOURCE-CHANGED`.
- **Rule #10 — Error compounding check**: Trace provenance of `CROSS-VERIFIED`/`CONFIRMED` claims. If all evidence is wiki-citing-wiki with no independent `sources/` backing, downgrade to `SINGLE-SOURCE`.

### Updated: Quick Reference Card

Added: wiki failure modes (5), typed relationships, contradiction scan algorithm, concurrency protocol, archive-on-ingest, lint rules count (8→10), scale thresholds.

---

## v2.5 — 2026-04-07

**Source**: Adopted project sprint-001 run. 7 suggestions filed and tracked in `suggestions/pending.md`.

### Critical fix

**Contract.md sequencing bug** (SUGGESTION-3, Section 6 Planner): The blueprint previously stated the Planner writes contract.md "after TruthSayer APPROVED." This is wrong — TruthSayer approves the spec before pre-check runs. Pre-check can introduce ambiguity resolution cycles that alter deliverables, scope, or acceptance criteria. Writing contract.md before pre-check COMPLETE locks a contract against a spec that is not yet stable. Fixed: contract.md is now written only after TruthSayer APPROVED **and** after pre-check COMPLETE (`pipeline_state: pre-check-complete`). A new "Sequencing constraint" note makes the ordering explicit.

### High-severity fixes

**Pipeline diagram contradiction** (SUGGESTION-7, Section 7): The diagram showed `[CONTRACTED] Executor writes/proposes contract.md` — directly contradicting Section 6 which states the Planner writes it. Fixed by splitting the transition into two states: `[PRE-CHECK COMPLETE]` (Planner writes contract.md, spec now stable) and `[CONTRACTED]` (Executor reads contract.md + acceptance-checklist.md). The contradiction existed since v2.1.

**`pre-check-complete` state added to PROGRESS.md** (SUGGESTION-2, Section 5): The pipeline_state enum had no state between `pre-checking` (ambiguities may still be open) and `contracted` (contract.md written). Added `pre-check-complete` as the explicit intermediate state, making PROGRESS.md machine-readable at this transition. Linked to the sequencing fix above — the new state is what triggers the Planner to write contract.md.

### Medium fix

**spec.md Hypothesis field scoped to research** (SUGGESTION-5, Section 8): Template was ambiguous — commercial specs don't have a `Hypothesis` field, but the template listed it without qualification. Schema validation could falsely flag a commercial spec as malformed. Fixed: template now shows `Hypothesis` (research) and `User Story` + `Acceptance Criteria` (commercial) as alternates, with an explicit note that `Hypothesis` absence does not malform a commercial spec.

### Low fixes

**TOC cosmetic bug** (SUGGESTION-1): "Five-File" → "Six-File" in Section 8 TOC entry. The section header was already correct; only the TOC was stale.

**Commercial Executor protocol strengthened** (SUGGESTION-4, Section 6): Added two per-unit protocol steps grounded in sprint-001 observed failures: (2a) type-check after each unit (`npx tsc --noEmit`) — deferred type errors compound across units; (2b) multi-tenancy gate after each API route unit — verify tenant-isolation clause on every new DB query before marking unit done. Multi-tenancy failures are silent at runtime.

**Manual harness note for mid-project adoption** (SUGGESTION-6, Section 23): Without `iterate.sh`, `pre_check_cycle_current` is not auto-incremented. Added a note to Phase B of the Mid-Project Adoption guide documenting the required manual discipline and warning about duplicate PROGRESS.md field entries (which are silently read as the first occurrence only).

### Infrastructure

`suggestions/` directory created with `pending.md` index. Adoption projects file suggestions there; blueprint owner reviews and applies generalizable ones. This batch moved from `pending` to `APPLIED` status on the same day.

## v2.6 — 2026-04-07

**Source**: Gap analysis against godofprompt/@karpathy knowledge base article (222K views, Apr 7 2026). Three additions from cross-referencing their failure mode documentation against our blueprint coverage.

**"Lost in the middle" named in Section 20**: The three-tier loading model existed but its motivation was under-documented. Added explicit paragraph naming the LLM attention deprioritization effect and explaining why Tier 1 files are always positioned at the top of context. Helps adopters understand *why* the tiering matters, not just *what* it does.

**Model tiering table added to Section 17**: Production cost analysis shows that using frontier models for mechanical maintenance (KB linting, simple cross-reference updates) is a significant source of unnecessary spend. Added a phase-by-phase model tier recommendation with the asymmetry rationale: quality errors at ingest/eval phase compound into the KB and cost far more to fix than the savings from using a cheaper model.

**Git init added to Sections 23**: Both the new-project scaffold (step 7) and mid-project adoption (Phase B.5) now explicitly include `git init` as a required step. Rationale: the wiki and knowledge base are markdown files. Git provides full audit history, branch-based experimentation, and instant undo for bad AI passes — at zero incremental cost.

**Article draft published**: `article-draft.md` — full newsletter/article for external publication covering the full orchestration workflow, six structural additions beyond Karpathy's pattern, adoption at any stage, and honest failure modes.

## v2.4 — 2026-04-07

**Source**: Gap analysis against Claude Code best practices documentation (April 2026). All MCP memory tool schemas verified against live mcp__memory__ tool definitions.

### New: Section 24 — Claude Code Harness Integration

**Folder-specific CLAUDE.md hierarchy** (Section 24): Blueprint previously relied on a single flat product CLAUDE.md. Now specifies a three-level hierarchy — workspace root, product root, and subdirectory (wiki/ and knowledge/ each get their own CLAUDE.md). Agents working in wiki/ load wiki-specific rules without the full orchestration context; agents in knowledge/ load KB rules. Hard cap of ≤ 200 lines per file enforced at every level. `@path/to/import` syntax for supplements. Also clarified that slash commands must live in `.claude/commands/` (not `commands/` at project root) for Claude Code resolution.

**Hooks protocol** (Section 24): Previously, INVARIANT 8 (sources/ immutability) was advisory-only. Now specifies a `PreToolUse` hook that blocks Write to any existing file in `sources/` at the harness level — structurally unbreakable regardless of model behavior. Also specifies `PostCompact` hook for PROGRESS.md re-injection after context compaction, and escalation `Notification` hook.

**Permission mode guidance** (Section 24): No previous guidance on which Claude Code permission mode to use per pipeline phase. Now specifies: `plan` mode for planning/auditing/pre-check (read-only), `acceptEdits` for execution and KB linting, `auto` for unattended `./iterate.sh` runs (background safety classifier), `dontAsk` for CI. Also specifies `--allowedTools` per `claude -p` call — harness-level role enforcement, not just instructional.

**Session-level context management** (Section 24): Blueprint documented iteration-level KB loading (Section 20) but not session-level context management. Now specifies: `/clear` between pipeline phases in interactive sessions, `/compact` before KB Linting on long iterations, `claude --continue` for resuming interrupted iterations (not fresh sessions).

**MCP server recommendations** (Section 24): First explicit MCP guidance in the blueprint. Specifies `memory` + `playwright` as required for all projects (research and commercial), `github` as recommended for commercial, `cloudflare` as conditional for Cloudflare deployments, `qmd` as recommended when sources > ~100 (already mentioned in Section 10, now tied to an MCP server recommendation). Defines project-scoped vs. user-scoped server placement with credential handling rule.

**MCP memory usage protocol** (Section 24): Defines the boundary between file-based KB (project-scoped, iteration-tracked) and MCP memory (cross-project, permanent, semantic). Specifies tagging schema mirroring the KB taxonomy (type:rule/lesson/decision/observation, status:active/deprecated/superseded, confidence levels). Session-start ritual: `memory_search` before reading project files, `quality_boost=0.3` for important lookups.

**MCP memory deprecation protocol** (Section 24): Mirrors INVARIANT 6 (never silent overwrite) for MCP memory. Lifecycle: active → deprecated (tag update) → deleted (30d grace period). Specifies `memory_quality(analyze)` for candidate identification, `memory_update` for tag-only deprecation, `memory_cleanup()` for duplicates. Hard rule: never delete in same session as deprecation. Added item 11 to meta-reviewer checklist (Section 21).

**Quick Reference Card updated** with CLAUDE.md hierarchy, hooks, permission modes, MCP server requirements, and MCP memory lifecycle rules.

## v2.3 — 2026-04-06

**Source**: Deep research into Karpathy's LLM wiki gist + community implementations (5,000+ stars, 1,251 forks). Research archived in `research/sources/karpathy-llm-wiki-deep-research.md`.

### Gaps filled from Karpathy research

**wiki/index.md format specified** (Section 11): Previously mentioned but unformatted. Now has: one-line entries per page under category headers, entry format `[name](path) — hook (type, confidence, date)`, 200-line hard cap with overflow to `wiki/index-extended.md`. The index IS what makes the wiki navigable at moderate scale — without a well-maintained index in a consistent format, the wiki degrades to a directory of orphaned files.

**wiki/log.md parseable prefix format** (Section 11): Now specifies `## [YYYY-MM-DD] {iter} ({desc}) | {type}` as the prefix convention. The `|` delimiter enables automated log parsing — meta-reviewer can compute ingest frequency, query-compounding rate, and lint health trends from the log without reading every entry.

**Source delta tracking via sources/.manifest.json** (Section 11): Manifest tracks SHA-256 of every source file with first/last ingested iteration and pages created/updated. Executor checks manifest before re-ingesting — skips unchanged sources. KB Linter maintains the manifest post-iteration. Prevents duplicate observations and redundant reprocessing — a pain point hit by every real implementation at scale.

**Coverage indicators on wiki page frontmatter** (Section 11): Added `coverage: {section: HIGH | MEDIUM | LOW}` and `origin: ingest | query-compounding | synthesis` fields. HIGH = 3+ independent sources for that section's claims; MEDIUM = 2 or 1 strong primary; LOW = 1 source or inference. Agents reading LOW-coverage sections must fall back to sources/. The page-level `confidence` field was insufficient — a CROSS-VERIFIED page can still have individual sections with only 1 source.

**"Prefer update over create" in Executor** (Section 6): Added explicit rule and ingest depth check. Executor defaults to updating existing pages rather than creating new ones — wiki sprawl from unnecessary new pages degrades the index. Expectation: 10-15 wiki pages touched per substantive source ingest; fewer than 5 signals shallow work.

**Query compounding operationalized** (Section 6, Section 9): `/wiki-query` now explicitly files valuable query syntheses back as wiki pages (type: `query-synthesis`, origin: `query-compounding`). This is Karpathy's most underappreciated innovation — the wiki grows from every research question answered, not just from ingest cycles. Previously described in philosophy (Section 1) but not wired into the command spec.

**Wiki Operating Rules added to product CLAUDE.md template** (Section 5): Eight canonical rules for wiki maintenance (never modify sources/, update-over-create, always update index.md and log.md, cite every claim, mark uncertainty, propose schema changes as diffs, file query answers back, 10-15 page ingest depth). These are the "coding standards" for wiki maintenance — without them, different agents produce structurally incompatible wikis.

**outputs/ directory added** (Section 4): Optional directory for rendered deliverables (reports, slides, charts) produced from wiki content. Separates what is known (wiki/) from what was delivered (outputs/). The absence of this distinction caused wiki/ to accumulate rendered artifacts that weren't wiki pages, degrading the index.

**qmd named as recommended search tool at scale** (Section 10): Previously said "hybrid search (BM25 + vector + LLM re-ranking)" without naming a tool. qmd (https://github.com/tobi/qmd) is the Karpathy-recommended implementation — available as both CLI (shell-out) and MCP server (native tool use). Relevant when sources > ~100.

**Schema co-evolution principle** (Section 10): Added Karpathy's insight that the CLAUDE.md wiki schema is not written once and frozen — it co-evolves with the domain as the agent discovers what naming conventions, entity categories, and connection types add the most value. "Building the schema well is itself a form of thinking about the domain."

**Fine-tuning endpoint documented as Layer 5** (Section 10): Karpathy's stated long-term vision: wiki → synthetic Q&A pairs → domain-specific fine-tuning. Tools: Distilabel, Axolotl, Unsloth. Not in scope now but the wiki architecture is designed to support this. Documents the full evolution path: ingest-and-compile → compile-and-query → query-compounds → synthetic-data → fine-tuned-model.

**Quick Reference Card updated** with new conventions: wiki operations, ingest log format, index entry format, delta tracking, qmd, raw save order, outputs/ directory.

## v2.1 — 2026-04-06

**Audit source**: 3 independent adversarial agents with web search/fetch access. Reports archived in `audits/2026-04-06-agent{1,2,3}-*.md`.

### Critical fixes

**Semantic prompt injection gap (Agent 3 CRITICAL)**: Schema validation of inter-agent files validates header presence but not field value content. A structurally valid spec.md can embed imperative instructions within field values that pass schema checks but get executed by downstream agents (OWASP LLM01:2025, arXiv:2506.23260). INVARIANT 3 and Section 19 now explicitly require semantic isolation of field values — treat content as opaque data strings, not instruction text.

**Token self-estimation is not a real capability (Agent 2 CRITICAL)**: The Claude API does not expose a running session token total to agents during execution. Agents cannot accurately self-report consumption. Section 17 now specifies harness-level enforcement: iterate.sh reads API response `usage` fields and writes totals to PROGRESS.md externally.

**Two unbounded loops (Agent 2 CRITICAL)**: (a) SPEC-FLAW route reset audit cycle counter without a global cap → infinite Evaluator→Planner loop possible. Fixed: `spec_flaw_count` global counter in PROGRESS.md (never reset); `spec_flaw_count >= 2` → ESCALATE. (b) Pre-check ambiguity resolution had no exit condition. Fixed: `pre_check_cycle_current` with max 2 rounds before auto-escalation.

**contract.md had no specified author (Agent 2 CRITICAL)**: Pipeline had [CONTRACTED] state but no agent assigned to create it. Planner now explicitly writes contract.md as initial draft after TruthSayer APPROVED.

### High severity fixes

**Anthropic attribution errors (Agent 1 HIGH)**: Post is dated March 2026, not 2025. Phrase "harness assumptions decay" does not appear in source; actual text is "those assumptions...can quickly go stale as models improve." Phrase "vastly outperform" (re: live-tool evaluators) not in source — blog presents live-tool evaluation as qualitative best practice, not a measured comparison. All three corrected.

**Bi-temporal model incomplete (Agent 1 HIGH)**: Zep arXiv:2501.13956 defines FOUR timestamps, not three. Blueprint had collapsed `transactional_expired_at` and `valid_until` into a single `invalidated_at`, losing the ability to represent retroactive corrections. Section 13 now implements the full four-timestamp model with a documented simplified fallback.

**No escalation timeout (Agent 3 HIGH)**: `pipeline_state: escalated` + "await human" with no timeout could halt a pipeline indefinitely. `escalation_deadline` field added to escalation.md format (default 48h).

**escalations_last_5 >= 3 halts pipeline (Agent 3 MEDIUM)**: Was ambiguous whether this triggered meta-review only or a full halt. Now explicit: full pipeline halt until human-approved meta-review applied.

### Medium severity fixes

**Karpathy attribution clarified (Agents 1+3)**: Renamed Section 10 to "Two-Layer Karpathy Pattern + Process Learning Extension." The `knowledge/` OBS→HYP→RULE promotion ladder is original blueprint architecture, not something Karpathy described. The raw/+wiki/ two-layer core is accurately attributed.

**400K word threshold removed (Agent 1)**: Karpathy mentions ~100 sources, not ~400K words. The word count was an interpolation. Replaced with Karpathy's actual quoted text.

**CROSS-VERIFIED vs CROSS-VERIFIED contradiction (Agent 2)**: Immediate escalation mid-pipeline would halt active projects with any contradictions. Changed to deferred+CONTESTED path: log to synthesis/contradictions/, mark claims [CONTESTED], allow pipeline to continue. Escalate only if contradiction affects current iteration's contract.md.

**KB eviction formula defined (Agent 2)**: All four terms now have explicit units: recency = 1/(1+iterations_since_last_validated), citation_frequency = incoming_links count, confidence_score = 1/2/3, information_density = inline citation count.

**Tier 2 decision procedure (Agent 2)**: "Load on demand based on current task" was entirely agent judgment. Added explicit decision procedure table per agent role.

**Incoming links maintenance (Agent 2)**: KB Linter now explicitly responsible for scanning written pages for outgoing links and updating linked pages' incoming_links frontmatter.

**Observation velocity cap (Agent 3)**: Added `max_new_observations_per_iter` to PROJECT.md (default 10). KB Linter rejects iterations writing more than this number of new SINGLE-SOURCE claims without human review.

**Pinned rules (Agent 3)**: Added `pinned: true` flag to rule format. Pinned rules exempt from eviction policy. Limit ≤ 3 per domain.

**Adaptive meta-review cadence (Agents 2+3)**: Fixed iteration-only cadence to `min(5 iterations, meta_review_max_days)`. Added `last_meta_review_date` to PROGRESS.md.

**Reward hacking Check 1 (Agents 2+3)**: Tool-call count heuristic ("5+ tool calls") is unreliable — sophisticated agents mimic expected call patterns (METR 2025 research). Replaced with source-coverage check: compare sources actually fetched vs. sources listed in spec.md.

**32% attribution corrected (Agent 3)**: Contextualized as Liu et al. arXiv:2502.14282, PC-Eval desktop automation benchmark (25 tasks). Not a general multi-agent architecture result.

**Cascade amplification note (Agent 1)**: Added note to Section 7 citing arXiv:2603.04474 (Google DeepMind) — sequential pipelines exhibit 17x error amplification without gates. TruthSayer and Pre-Check Evaluator explained as cascade breakers.

**INVARIANT 1 carve-out (Agent 1)**: "Generator ≠ Evaluator" is too absolute for mechanically verifiable outputs (test suite pass/fail, schema validation, URL reachability). Carve-out added: structural Evaluator separation required for quality scoring and acceptance determination; self-verification acceptable for mechanical pre-checks.

**pipeline.log.jsonl schema (Agent 2)**: Replaced 3 example entries with complete 13-event-type enumeration (wiki_write, wiki_update, claim_unverified, claim_verified, obs_recorded, stub_created, rule_promoted, rule_invalidated, rule_demoted, escalation_triggered, eval_pass, eval_fail, spec_flaw) with required fields per type.

**Harness decay rationale recording (Agent 2)**: Added `compensates_for` and `evidence_threshold_for_removal` frontmatter fields to command file standard. Future auditors can evaluate decay without reverse-engineering intent from behavior.

**Independence test tie-breaker (Agent 2)**: Added organizational test as deterministic fallback for ambiguous independence cases.

**Harness audit dual trigger (Agent 2)**: min(25 iterations, 6 months). Added `last_harness_audit` to PROGRESS.md.

### Unresolved items (deferred to v2.2)
- Machine-readable schema (JSON Schema) for the 6 inter-agent files — currently schema validation is prose-described
- Technical failure protocol (network errors, tool call exceptions) — blueprint handles semantic failures but not technical failures
- Trust boundary for human-modified configuration files — no change-approval requirement defined for CLAUDE.md and PROJECT.md
- Domain-driven TTL for time-sensitive rules (competitor pricing, API terms) — current staleness check at 20 iterations is domain-agnostic
- Concurrency model for multi-product shared resources (central-kb/ write conflicts)
- KB drift detection at scale (100+ iterations on fast-moving domains)

## v2.0 — 2026-04-06

**Breaking changes**: New `acceptance-checklist.md` file added to the six-file communication chain. Pipeline is now a directed graph, not a linear chain (SPEC-FLAW route added).

**New invariant added**: INVARIANT 7 — Evaluator must use execution tools (static-only = CONDITIONAL PASS at best).

**New agent role**: Pre-Check Evaluator (`/pre-check`) — reviews spec and produces acceptance checklist before execution begins. Eliminates the most common non-convergence failure mode where Executor and Evaluator operate from different implicit interpretations of the spec.

**New sections**:
- Section 13: Temporal Fact Management Protocol — bi-temporal model, contradiction resolution algorithm. Facts are `invalidated_at`, never silently overwritten. Validated against Zep/Graphiti arXiv:2501.13956.
- Section 14: Provenance and Audit Chain — every confirmed rule traces back to raw source via HYP→OBS→source-file chain. `pipeline.log.jsonl` records every KB write for full auditability.
- Section 17: Token Budget Management — per-session budget cap, 80% pressure mode, 100% escalation. Addresses quadratic token growth failure mode documented in production.
- Section 18: Reward Hacking Detection — 4 mandatory checks. FLAGGED = automatic FAIL. Based on Shopify production experience (opt-out hacking, tag hacking, schema violation patterns).
- Section 19: Agent Trust Model — content-from-agent treated as low-trust structured data, schema-validated. Web content = untrusted. Addresses prompt injection vulnerability in multi-agent pipelines.
- Section 20: Selective KB Retrieval (Three-Tier Memory Model) — always-loaded Tier 1 (indexes + LESSONS.md), on-demand Tier 2 (relevant rules + entity pages), search-only Tier 3 (sources + archive). Hard caps: wiki/index.md ≤ 200 lines.
- Section 22: Harness Assumption Decay Protocol — quarterly audit to prune scaffolding that compensates for model limitations already solved by newer models. Based on Anthropic engineering blog finding that harness assumptions decay with model capability.

**Significant changes to existing sections**:
- Section 6 (Agent Roles): KB Linter now has 8 mandatory lint rules (previously underdefined). Eviction policy specified: quality-score-ranked compaction before archive; never delete.
- Section 7 (Iteration Lifecycle): Pipeline redrawn as directed graph. SPEC-FLAW route (Evaluator → Planner) added. Pre-checking phase added between auditing and contracting.
- Section 8 (Communication Chain): Now six-file chain (spec, audit-report, acceptance-checklist, contract, execution-log, eval-report). `spec-feedback.md` and `escalation.md` as optional files.
- Section 12 (Knowledge Layer): Rule format upgraded with full temporal metadata fields (`status`, `created_at`, `invalidated_at`, `superseded_by`, `last_validated`).
- Section 5 (Config Files): `PROJECT.md` now includes `token_budget_per_session` and `token_budget_alert_pct`. `PROGRESS.md` includes token tracking fields.
- Section 15 (Quality Criteria): Added `evaluator-tool-use` and `reward-hacking-clean` as critical criteria to both research and commercial templates.
- Section 21 (Meta-Review): Added harness decay check and reward hacking frequency to meta-reviewer's analysis list.

**Sources that informed v2.0**:
- Anthropic Engineering: "Harness Design for Long-Running Apps" (2025) — sprint contract pattern, evaluator tool access, harness assumption decay
- Karpathy: LLM Wiki Architecture gist (2025) — three-tier memory model, scale threshold (~100 articles), index caps
- Zep/Graphiti (arXiv:2501.13956, 2025) — bi-temporal fact model, temporal invalidation
- Shopify Engineering: "Building Production-Ready Agentic Systems" (2025) — reward hacking taxonomy
- metaswarm: 18-agent framework (github.com/dsifry/metaswarm) — JSONL provenance log, adversarial DoD compliance checks
- InfoQ Production Playbook 2025 — hierarchical vs. flat comparison, token growth patterns
- Claude Code harness architecture (wavespeed.ai analysis) — three-tier memory, autoDream/KB-Linter parallel

## v1.0 — 2026-04 (initial)

Source: Internal commercial monorepo.
First formalization of: 5-agent adversarial pipeline, three-layer KB (Karpathy pattern), file-based inter-agent communication, wiki confidence levels, size caps, escalation protocols, cycle limits, meta-review cadence.
