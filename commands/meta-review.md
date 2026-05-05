---
description: Run the §22 harness audit — produces meta/audit-YYYY-MM-DD.md
argument-hint: (no arguments — reads trailing-window ledger + iter-summaries)
---

# /meta-review — Meta-Review

Composes `/_delegate` with `role=meta_review`. Role contract: `20-roles/meta-review.md`. Bundle: `bundles/meta-review.yaml`. Output: `meta/audit-YYYY-MM-DD.md` (verdicts only — Apply-Meta enacts them).

Runs the §22 harness audit: for every protective scaffold with `compensates_for` + `evidence_threshold` frontmatter, decides RETAIN | DOWNGRADE | ARCHIVE based on trailing-window catch counts.

## Cadence

- Automatic when `PROGRESS.md.iter_count` crosses a multiple of 25 OR `meta/last-audit-date` is older than 180 days (per `policy.meta_review_cadence`).
- On-demand via `claude /meta-review` (e.g. after a major adapter change or v.X bump).

## Preconditions

- `pipeline/verification-ledger.jsonl` MUST contain ≥ 1 trailing-window iteration's worth of dispatch+consume rows.
- `meta/` directory exists (orchestrator creates if absent).

## Dispatch

```
/_delegate
  role: meta_review
  inputs:
    - pipeline/verification-ledger.jsonl                # trailing-window read
    - iterations/archive/iter-<N..>/iter-summary.md     # one per iter in window
    - agents.config.yaml                                # current scaffold config
    - 00-overview/invariants.md
    - 10-pipeline/quality-gates.md
    - meta/audit-<prior>.md                             # for delta detection
  expected_schema: (none — meta/audit-YYYY-MM-DD.md is project-defined sectioned format)
  iter_id: <current>
```

Default adapter: `claude-native` (subagent or sdk). Sandbox: `read-only`. Tier per §17: **frontier** (judgment on whether scaffolds still earn their cost is high-leverage; mid-tier under-prunes).

## Output sections (per `40-runtime/harness-decay.md`)

- **Scaffold inventory** — every scaffold with `compensates_for` frontmatter
- **Per-scaffold verdict** — RETAIN | DOWNGRADE | ARCHIVE with evidence cited from ledger
- **MCP memory cleanup checklist** — per §24 item 11
- **Next audit date** — set per cadence

## Routing

This command produces verdicts only. Enaction requires `/apply-meta`.

## Next command

After review → user reads `meta/audit-YYYY-MM-DD.md`, then runs `/apply-meta` to enact the verdicts.

---
