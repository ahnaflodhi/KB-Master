# 00-overview/ — Layer-2 frontmatter standard

This file is intentionally **not** subject to the frontmatter check (`tools/verify-frontmatter.sh` excludes any `_README.md` by name). It is the canonical reference for what frontmatter every other Layer-2 file must carry.

Source of truth at runtime: this file. Source of design intent: `~/.claude/plans/crispy-sniffing-conway.md` §"Frontmatter standard".

## Why frontmatter at all

The v3.0 restructure replaces the 2,464-line monolith with ~58 small files. Without machine-readable frontmatter, the orchestrator cannot:

- Decide which files to load for a given role (`bundles/<role>.yaml` derives membership from `audience` + `also_needed_by` + `purpose`).
- Detect drift between a role's "must" directives and its source-of-truth count over time (`directives.must_count`).
- Enforce per-file line caps (`max_lines`) to prevent re-monolithification.
- Trace any extracted file back to the section of `SYSTEM-BLUEPRINT-v2.8.md` it came from (`extracted_from.line_range`).
- Verify cross-references between files (`depends_on`, `related`).

Every Layer-2 file under `00-overview/`…`80-status/` (excluding `_README.md` files like this one) MUST carry frontmatter that opens with `---` on line 1 and closes with `---` on a later line. `tools/verify-frontmatter.sh` enforces this.

## The schema

```yaml
---
# IDENTITY (required)
id: 20-roles/truthsayer            # stable hook = path without .md; survives directory renames
title: TruthSayer Role Contract
purpose: role-contract             # enum: invariant | role-contract | adapter-contract | schema | runtime-spec | knowledge-spec | adoption-guide | status

# AUDIENCE & LOAD ORCHESTRATION (drives bundle generation in Phase 5)
audience:                          # primary bundle membership — required
  - truthsayer
also_needed_by:                    # secondary loaders — optional
  - orchestrator
  - meta_review
load_when:                         # conditional load expression — optional
  - "role == truthsayer"

# LIFECYCLE (required: status, version, last_reviewed)
status: stable                     # enum: stable | active | planned | deprecated
version: 2.8                       # the monolith version this was extracted from
last_reviewed: 2026-05-04          # ISO-8601 date YYYY-MM-DD; bumped at meta-review (§21) cadence
extracted_from:                    # provenance back to Layer-1 — required when extracted from monolith
  source: SYSTEM-BLUEPRINT-v2.8.md
  sections: ["§6 TruthSayer", "§2 Invariant 2"]
  line_range: [407, 466]           # in the v2.8 monolith
replaces:                          # what this file makes obsolete — optional
  - "SYSTEM-BLUEPRINT.md §6 TruthSayer subsection"

# DEPENDENCIES (drives tools/verify-cross-refs.sh) — both optional but encouraged
depends_on:                        # files this assumes the reader has loaded
  - 00-overview/invariants.md
  - 10-pipeline/state-machine.md
  - 60-schemas/audit-report.md
related:                           # files a curious reader may want
  - 50-adapters/codex-bridge.md
  - 40-runtime/verification-ledger.md

# CONSTRAINTS (max_lines required for files in 00-/10-/20-/30-/40-/50-/60-/80-)
max_lines: 150                     # enforced by tools/verify-frontmatter.sh --strict
directives:                        # drift detector — optional but recommended for role/invariant files
  must_count: 5                    # number of "must" directives in body
  should_count: 3
  may_count: 1
---
```

## Enforcement levels by phase

| Phase | What `verify-frontmatter.sh` checks |
|---|---|
| 1 (today, v2.8.1) | Required keys: `id`, `title`, `purpose`, `status`, `version`, `last_reviewed`. `--strict` flag enforces `max_lines` if declared. |
| 2 (kernel extraction) | Above + valid `purpose` enum + valid `status` enum. `--strict` becomes default in CI. |
| 3 (role contracts) | Above + `audience` and `extracted_from` required for files under `20-roles/`. |
| 5 (bundles wired) | Above + `directives.must_count` required for `20-roles/*` and `00-overview/invariants.md`; drift between declared and actual count fails the check. |
| 6 (post-restructure) | Full schema enforced; CI hook blocks PRs that violate. |

## Per-directory line caps

Declare `max_lines` in every Layer-2 file. Recommended caps (enforced by `--strict`):

| Directory | Cap |
|---|---|
| `00-overview/*` | 120 |
| `10-pipeline/*` | 180 |
| `20-roles/*` | 150 |
| `30-knowledge/*` | 200 |
| `40-runtime/*` | 180 |
| `50-adapters/*` | 150 |
| `60-schemas/*` | 100 |
| `70-adoption/*` | 250 |
| `80-status/*` | 100 |

Files exceeding their cap should split into a sub-file (`<topic>-extras.md`) and become its own loadable chunk — not bloat the parent.

## What NOT to put in frontmatter

- Long prose (use the body)
- Anything that changes per session (use the body or `pipeline.log.jsonl`)
- Secrets, credentials, paths to private resources
- Arbitrary user-defined fields — frontmatter schema is closed; new fields require updating this file first.
