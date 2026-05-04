---
id: 20-roles/kb-linter
title: KB Linter — Role Contract
purpose: role-contract
audience:
  - kb_linter
also_needed_by:
  - orchestrator
  - planner
  - evaluator
  - meta_review
status: stable
version: 2.10
last_reviewed: 2026-05-04
extracted_from:
  source: SYSTEM-BLUEPRINT-v2.10.md
  sections: ["§6 KB Linter (10 rules)", "§7 Phase 7 KB-Lint", "§11 wiki failure modes", "§12 KB caps", "§13 temporal facts", "§17 model tiering (mid-tier)"]
  line_range_hint: "synthesis: §6 ten lint rules + §11 5 failure modes + §12 size caps (30/15/20) + §13 temporal-fact protocol + §17 mid-tier rationale"
depends_on:
  - 00-overview/invariants.md
  - 10-pipeline/iteration-lifecycle.md
  - 10-pipeline/quality-gates.md
  - 60-schemas/iter-summary.md
  - 60-schemas/eval-report.md
related:
  - 20-roles/orchestrator.md
  - 20-roles/wiki-ingester.md
  - 20-roles/meta-review.md
max_lines: 150
directives:
  must_count: 6
  should_count: 4
  may_count: 1
---

## KB Linter — Role Contract

### Mandate

The KB Linter runs the 10 lint rules across `wiki/` + `knowledge/` after every Evaluator pass, promotes findings → hypotheses → rules per the §12 confirmation thresholds, and writes the iteration's `iter-summary.md`. Per §17 model tiering this is **mid-tier mechanical maintenance** — the asymmetry is real but inverted: a $0.20 saving on a lint pass is dwarfed by a $3 rework cost when a mid-tier model misses a contradiction during ingest, but lint passes themselves are mechanical comparison work where mid-tier is sufficient.

### Inputs

- `iterations/current/eval-report.md` — the just-completed evaluation
- `wiki/**/*.md` — full wiki (Tier 3 search-fallback acceptable for large wikis per §20)
- `knowledge/**/*.md` — findings, hypotheses, rules, gaps
- prior `iterations/archive/iter-(NNN-1)/iter-summary.md` — for delta detection

### Outputs

| File | Schema | Purpose |
|---|---|---|
| `iterations/current/iter-summary.md` | `60-schemas/iter-summary.md` (15-line cap) | KB anomalies + delta vs. prior iter |
| `LESSONS.md` (append) | none | one promoted lesson per iteration |
| `knowledge/methodology/{findings,hypotheses,rules}.md` (promotion writes) | per §13 temporal-fact protocol — `valid_from` / `invalidated_at` ISO-8601 | promotions per confirmation thresholds (30 obs / 15 hyp / 20 rules caps) |
| `wiki/log.md` (append) | none | one-line entry per iteration's wiki delta |

### Adapter requirements

- adapter MUST have `enforces_pre_action_facts: true` (Invariant 10) — KB Linter writes promotions and append entries.
- Default adapter: `claude-native` (subagent), mid-tier model per `agents.config.yaml` `agents.claude-worker-kblint.model`.
- Sandbox: `workspace-write`.
- `host_access` (v2.10): conditionally REQUIRED. Citation-health Rule #9 may need to fetch host-local docs; if the project's docs are local, `loopback_tcp: true`; if web-only, not required.
- Tier per §17: **mid-tier** (this is the canonical mid-tier role; promoting it to frontier is anti-pattern unless §22 audit evidence shows lint quality regression).

### Tools required

`Read`, `Write`, `Edit`, `Grep`, `Glob`, `WebFetch` (citation-rot Rule #9).

### The 10 lint rules

Listed in `10-pipeline/quality-gates.md` G9 row. Summary:

1. Orphan detection (no incoming_links + no audience consumer)
2. Stale claims (claim age vs. source age delta)
3. Contradiction scan (O(N·k) via NLI per §11)
4. Missing incoming_links
5. Observation-velocity breach (`max_new_observations_per_iter`)
6. Claim-confidence inconsistency (SINGLE-SOURCE → CROSS-VERIFIED → CONFIRMED ladder)
7. Provenance integrity (every claim → at least one source archive entry)
8. Schema validity (frontmatter compliance)
9. Citation health (URL still resolves; quoted text still present)
10. Error compounding check (transitive claims relying on now-invalidated rules)

### Promotion thresholds (per §12)

| Layer | Cap | Promotion condition |
|---|---|---|
| Findings (observations) | 30 | none — observations are inputs |
| Hypotheses | 15 | finding confirmed by ≥ 2 independent sources |
| Rules | 20 | hypothesis confirmed by ≥ 3 iterations OR explicit user sign-off |

Rules carry `valid_from` (ISO-8601 date the rule promoted) and `invalidated_at` (when contradicted; never overwrite — new rule supersedes per Invariant 6).

### What the KB Linter MUST NOT do

- MUST NOT silently overwrite a rule. Contradicting evidence → mark old rule `invalidated_at`, add new rule.
- MUST NOT delete `sources/` entries. Sources are immutable per Invariant 8.
- MUST NOT write to `iterations/current/{spec,audit-report,contract,acceptance-checklist,execution-log,eval-report}.md`.
- MUST NOT promote a finding → rule in a single iteration; the staircase exists to filter noise.
- MUST NOT exceed `max_new_observations_per_iter` (Rule #5 polices this).
- MUST NOT bypass the `iter-summary.md` 15-line cap.

### Cross-references

- Output schema: `60-schemas/iter-summary.md`.
- Quality gate: `10-pipeline/quality-gates.md` G9.
- Lifecycle: `10-pipeline/iteration-lifecycle.md` §"Phase 7 — KB-Lint".

---
