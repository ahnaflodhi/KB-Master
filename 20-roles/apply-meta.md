---
id: 20-roles/apply-meta
title: Apply-Meta — Role Contract
purpose: role-contract
audience:
  - apply_meta
also_needed_by:
  - orchestrator
  - meta_review
status: stable
version: 2.10
last_reviewed: 2026-05-04
extracted_from:
  source: SYSTEM-BLUEPRINT-v2.10.md
  sections: ["§6 Apply-Meta", "§22 Harness Assumption Decay Protocol (RETAIN/DOWNGRADE/ARCHIVE actions)", "§5 PROGRESS.md schema", "§9 Invariant 9 (orchestrator-only writes)"]
  line_range_hint: "synthesis: §6 Apply-Meta protocol + §22 enaction details + §5 config_revision bump + Inv 9 orchestrator-only mutation locus"
depends_on:
  - 00-overview/invariants.md
  - 10-pipeline/iteration-lifecycle.md
related:
  - 20-roles/orchestrator.md
  - 20-roles/meta-review.md
max_lines: 150
directives:
  must_count: 7
  should_count: 3
  may_count: 1
---

## Apply-Meta — Role Contract

### Mandate

The Apply-Meta role enacts the verdicts the Meta-Review produced. For each `RETAIN` it does nothing (the scaffold stays as-is). For each `DOWNGRADE` it flips the scaffold's `status:` frontmatter from `stable` to `advisory` and updates any `policy.on_X_missing` knob from `reject` to `warn`. For each `ARCHIVE` it removes the scaffold from `agents.config.yaml`, archives the slash command, and records the removal in `meta/audit-YYYY-MM-DD.md` so the decision is retrievable.

This role is the **only** role authorised (besides the orchestrator on its own files) to mutate `agents.config.yaml` outside of a developer-initiated edit. The orchestrator-inline binding ensures Invariant 9 is preserved — Apply-Meta runs as the orchestrator, not as a separate spawn that could promote itself.

### Inputs

- `meta/audit-YYYY-MM-DD.md` — the most recent meta-audit (proposals)
- `agents.config.yaml` — current configuration
- `commands/*.md` — slash commands that may need archiving
- Layer-2 files (`00-overview/*.md`, `20-roles/*.md`, etc.) — frontmatter status flips
- `pipeline/verification-ledger.jsonl` — for cross-checking that proposed downgrades are evidence-based

### Outputs

| File | Mutation |
|---|---|
| `agents.config.yaml` | `config_revision: int` bump per edit; `last_updated: YYYY-MM-DD`; remove archived adapter/agent/role entries; flip `policy.*` knobs per downgrade |
| `commands/<archived>.md` | move to `commands/_archived/<archived>-YYYY-MM-DD.md` (audit trail) |
| Layer-2 file frontmatter | flip `status: stable → advisory` for downgraded; flip `status: stable → archived` for archived; update `last_reviewed` |
| `meta/audit-YYYY-MM-DD.md` | append `Applied:` block with per-verdict enaction record |
| `pipeline/verification-ledger.jsonl` | append a single `apply-meta` audit row per Apply-Meta run |

### Adapter requirements

- adapter MUST be `claude-orchestrator` (orchestrator-inline). Apply-Meta is NOT delegated to a separate worker because the act of mutating `agents.config.yaml` mid-session is itself an Invariant-9 boundary case.
- `enforces_pre_action_facts: true` (Invariant 10).
- Sandbox: host shell (no sandbox; same scope as orchestrator).
- `host_access` (v2.10): `loopback_tcp: true`, `unix_sockets: true` (orchestrator's own).
- Tier per §17: **frontier** (decisions about which scaffolds to retire are high-leverage).

### Tools required

`Read`, `Edit`, `Write`, `Bash` (for `git mv` of archived commands), `Grep`, `Glob`.

### Cadence

- Runs immediately after every Meta-Review verdict that contains at least one DOWNGRADE or ARCHIVE.
- May also fire on demand via `/apply-meta` after a manual review of `meta/audit-YYYY-MM-DD.md`.
- Never runs autonomously without a corresponding Meta-Review file — the audit trail must precede the action.

### Enaction procedure (per verdict)

| Verdict | Action |
|---|---|
| RETAIN | no-op; record `Applied: RETAIN` in audit |
| DOWNGRADE | flip scaffold `status: advisory`; flip relevant `policy.on_X_missing` from `reject` → `warn`; bump `config_revision`; record |
| ARCHIVE | remove from `agents.config.yaml`; move slash command to `commands/_archived/`; flip frontmatter `status: archived`; record specification in `meta/audit-YYYY-MM-DD.md` `Archived:` block; bump `config_revision` |

After enaction, `agents.config.yaml.config_revision` is recorded in the next dispatch ledger row so the audit trail is end-to-end.

### What Apply-Meta MUST NOT do

- MUST NOT enact a verdict that is not present in a Meta-Review audit file (no autonomous downgrades).
- MUST NOT delete a `meta/audit-YYYY-MM-DD.md` file or any of its constituent verdict records.
- MUST NOT remove an invariant (1–10) — invariants are not scaffolds; they are properties. Decisions to amend invariants require a blueprint version bump, not an Apply-Meta run.
- MUST NOT bypass `git mv` for archived commands — the move must preserve git history.
- MUST NOT skip the `pipeline/verification-ledger.jsonl` audit row.
- MUST NOT mutate any file without first reading the corresponding `meta/audit-YYYY-MM-DD.md` verdict and quoting it in the Edit's pre-action fact block.
- MUST NOT be invoked when the orchestrator's `pipeline_state` is mid-iteration (`planned`, `audited`, `executing`, etc.) — Apply-Meta runs only at `idle`.

### Cross-references

- Source of verdicts: `20-roles/meta-review.md`.
- §22 Harness Assumption Decay Protocol — the rationale for the action set.
- Invariant 9 — why this role is orchestrator-inline and not delegated.

---
