---
description: KB Linter runs 10 lint rules + promotes findings → hypotheses → rules — produces iter-summary.md
argument-hint: (no arguments — reads eval-report.md and the wiki/knowledge tree)
---

# /kb-lint — KB Linter

Composes `/_delegate` with `role=kb_linter`. Role contract: `20-roles/kb-linter.md`. Bundle: `bundles/kb-linter.yaml`. Output: `iterations/current/iter-summary.md` per `60-schemas/iter-summary.md` (15-line cap) + LESSONS.md append + KB promotion writes.

Per **§17 model tiering**, this is the canonical mid-tier role. Lint passes are mechanical comparison work — frontier-tier promotion is anti-pattern unless §22 audit evidence shows lint-quality regression.

## Preconditions

- `PROGRESS.md.pipeline_state` MUST be `evaluated` (post-Evaluator PASS).
- `iterations/current/eval-report.md` MUST exist with `Route: PASS`.
- Prior `iterations/archive/iter-(NNN-1)/iter-summary.md` (if iter > 1) for delta detection.

## Dispatch

```
/_delegate
  role: kb_linter
  inputs:
    - iterations/current/eval-report.md
    - wiki/                          # full tree, Tier-3 search-fallback acceptable
    - knowledge/                     # full tree
    - iterations/archive/iter-<N-1>/iter-summary.md   # if applicable
  expected_schema: iter-summary
  iter_id: <current>
```

Default adapter: `claude-native` (subagent), mid-tier model. Sandbox: `workspace-write`.

## v2.10 host_access (conditional)

If KB Linter Rule #9 (citation health) needs to fetch host-local docs, the adapter MUST advertise `host_access.loopback_tcp: true`. For wiki projects whose docs are web-hosted, host_access is not required.

## The 10 lint rules (per `30-knowledge/wiki-failure-modes.md` + `10-pipeline/quality-gates.md` G9)

1. Orphan detection (no incoming_links + no audience consumer)
2. Stale claims (claim age vs. source age delta)
3. Contradiction scan (O(N·k) NLI per §11; uses typed `contradicts:` frontmatter)
4. Missing incoming_links
5. Observation-velocity breach (`max_new_observations_per_iter`)
6. Claim-confidence inconsistency (SINGLE-SOURCE → CROSS-VERIFIED → CONFIRMED ladder)
7. Provenance integrity (every claim → at least one source archive entry)
8. Schema validity (frontmatter compliance)
9. Citation health (URL still resolves; quoted text still present)
10. Error compounding check (transitive claims relying on now-invalidated rules)

## Promotion thresholds (per `30-knowledge/knowledge-base.md`)

- finding → hypothesis: ≥ 2 independent sources
- hypothesis → rule: ≥ 3 iterations OR explicit user sign-off

Per `30-knowledge/temporal-facts.md`: contradicting evidence creates a NEW rule with `supersedes: <old-id>`; old rule gets `invalidated_at` stamp. NEVER overwrite.

## Routing

After write:
- `pipeline_state: kb-linted` → orchestrator archives the iteration; `iter_count` increments at archive (orchestrator-internal step, not a slash command).
- If `iter-summary.md` flags severity > threshold → user runs `/escalate`.

## Next command

Next iteration starts with `/plan`.

---
