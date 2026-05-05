---
description: Enact meta-review verdicts (RETAIN/DOWNGRADE/ARCHIVE) — orchestrator-inline
argument-hint: <meta/audit-YYYY-MM-DD.md path>
---

# /apply-meta — Apply-Meta (orchestrator-inline)

Composes `/_delegate` with `role=apply_meta`. Role contract: `20-roles/apply-meta.md`. Bundle: `bundles/apply-meta.yaml`. Mutates `agents.config.yaml`, slash command frontmatter, Layer-2 status fields per the meta-audit verdicts.

Per **Invariant 9**, Apply-Meta runs orchestrator-inline (`claude-orchestrator` adapter). It is NOT delegated to a separate worker — mutating `agents.config.yaml` mid-session is itself an Inv-9 boundary case.

## Preconditions

- `meta/audit-YYYY-MM-DD.md` MUST exist (produced by `/meta-review`).
- `PROGRESS.md.pipeline_state` MUST be `idle` (Apply-Meta runs only between iterations, never mid-iteration).
- The audit MUST contain at least one DOWNGRADE or ARCHIVE verdict (RETAIN-only audits are no-ops; this command refuses them with a one-line note).

## Dispatch (no delegation — inline)

```
/_delegate
  role: apply_meta                   # orchestrator-inline; refused if dispatched elsewhere (Inv 9)
  inputs:
    - meta/audit-YYYY-MM-DD.md
    - agents.config.yaml
    - commands/                      # for _archived moves
    - 00-overview/                   # for status frontmatter flips
    - 10-pipeline/, 20-roles/, 30-knowledge/, 40-runtime/, 50-adapters/, 60-schemas/  # same
  expected_schema: (no single output schema — multi-file mutations recorded in the audit's Applied: section)
  iter_id: idle
```

Adapter: `claude-orchestrator` (host shell, full host_access, gateguard). Sandbox: host shell.

## Per-verdict actions (per `40-runtime/harness-decay.md`)

| Verdict | Action |
|---|---|
| RETAIN | no-op; record `Applied: RETAIN` in audit |
| DOWNGRADE | flip scaffold `status: stable → advisory`; flip `policy.on_X_missing: reject → warn`; bump `config_revision`; record `Applied: DOWNGRADE` |
| ARCHIVE | remove from `agents.config.yaml`; `git mv commands/<name>.md commands/_archived/<name>-YYYY-MM-DD.md`; flip frontmatter `status: archived`; record specification in audit's `Archived:` block; bump `config_revision` |

## Audit-trail discipline

- One `apply-meta` audit row appended to `pipeline/verification-ledger.jsonl` per Apply-Meta run, recording which scaffolds were RETAIN/DOWNGRADE/ARCHIVE'd and the source `meta/audit-YYYY-MM-DD.md` filename.
- `git mv` (NOT `git rm` + new file) to preserve git history of archived commands.
- The audit file's `Applied:` block records the exact mutations enacted.

## What this command MUST NOT do

- MUST NOT enact a verdict not present in the linked `meta/audit-YYYY-MM-DD.md`.
- MUST NOT delete a meta-audit file or any of its constituent verdict records.
- MUST NOT remove an Invariant (1-10) — invariants are properties, not scaffolds; their amendment requires a blueprint version bump (CLAUDE.md update protocol).
- MUST NOT bypass `git mv` for archived commands.
- MUST NOT run while `pipeline_state != idle`.

## Routing

After successful enaction → `pipeline_state: idle` (unchanged). Next iteration starts with `/plan` and uses the new `config_revision`.

---
