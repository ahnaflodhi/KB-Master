---
id: 30-knowledge/knowledge-base
title: Knowledge Base — Process-Learning Extension
purpose: knowledge-spec
audience:
  - kb_linter
  - meta_review
also_needed_by:
  - orchestrator
  - planner
  - truthsayer
  - executor
  - apply_meta
status: stable
version: 2.10
last_reviewed: 2026-05-04
extracted_from:
  source: SYSTEM-BLUEPRINT-v2.10.md
  sections: ["§10 Karpathy two-layer + process-learning extension", "§12 KB caps + eviction policy", "§17 model tiering (KB Linter mid-tier rationale)"]
  line_range_hint: "synthesis: §10 KB rationale (process truth vs domain truth) + §12 30/15/20 caps and confirmation thresholds"
depends_on:
  - 00-overview/invariants.md
  - 30-knowledge/temporal-facts.md
  - 30-knowledge/wiki-architecture.md
related:
  - 20-roles/kb-linter.md
  - 20-roles/meta-review.md
  - 60-schemas/iter-summary.md
max_lines: 200
directives:
  must_count: 6
  should_count: 3
  may_count: 1
---

## Knowledge Base — Process-Learning Extension

The `knowledge/` directory captures **what the team has learned about how to build this project** — observations, hypotheses, rules. This is distinct from `wiki/` which captures **what is known about the project's subject domain**. Conflating them collapses both: the wiki bloats with process notes; the KB drifts toward domain trivia. Keep them separate.

This is the project's extension to Karpathy's original two-layer model — Karpathy gave us `sources/` + `wiki/`; the process-learning extension adds `knowledge/` with its own promotion ladder, caps, and temporal-fact protocol.

### Directory shape

```
knowledge/
├── INDEX.md                          ← Tier-1 always-loaded entry point
├── findings/
│   └── knowledge.md                  ← raw observations (cap 30)
├── methodology/
│   ├── hypotheses.md                 ← promoted from findings (cap 15)
│   └── rules.md                      ← promoted from hypotheses (cap 20; temporal facts)
└── gaps/
    └── knowledge.md                  ← known unknowns
```

### Per-layer caps (§12)

| Layer | Cap | Why this number |
|---|---|---|
| Findings (observations) | 30 | A single iteration generates ~3-5 observations; 30 is ~6-10 iterations of trailing memory before the KB Linter MUST evict the lowest-scoring entries |
| Hypotheses | 15 | Half the findings cap; forces the KB Linter to be selective about what gets promoted |
| Rules | 20 | Higher than hypotheses (some hypotheses get superseded but the originals stay around as `invalidated_at`-stamped historical records); the cap is on *active* rules — invalidated entries don't count |
| Gaps | uncapped | Known unknowns are cheap to record and high-value when an iteration discovers one |

When a layer reaches its cap, the KB Linter evicts the lowest-scoring entry (or the oldest invalidated rule, for the rules layer). Eviction is recorded in `iter-summary.md` so the audit trail captures it.

### Promotion thresholds

```
finding → hypothesis: confirmed by ≥ 2 independent sources
hypothesis → rule:    confirmed by ≥ 3 iterations OR explicit user sign-off
```

Promotion is the KB Linter's job during Phase 7 (`20-roles/kb-linter.md`). The Linter reads the trailing window of `iter-summary.md` files to count confirmations. Promotion is **not** automatic on threshold crossing — the Linter still applies judgment (e.g. "this finding was confirmed in two iterations but both used the same source; the confirmations are not independent"). The threshold is the floor, not the ceiling.

### Per-entry frontmatter

Findings (observations):

```yaml
finding_id: <ULID>
created_at: <ISO-8601>
provenance:
  - <source-id>            # link back to where this observation came from
confirmation_count: <int>  # incremented each iteration the finding holds
```

Hypotheses:

```yaml
hypothesis_id: <ULID>
created_at: <ISO-8601>
promoted_from: [<finding_id>...]
confirmation_count: <int>
last_confirmed_iter: <iter-NNN>
```

Rules (the entries with full temporal-fact metadata — see `temporal-facts.md`):

```yaml
rule_id: <ULID>
valid_from: <ISO-8601>     # the date the rule was promoted
invalidated_at: <ISO-8601 | null>   # null while active; date when contradicted
provenance:
  - <hypothesis_id>
  - <source-id>
supersedes: <rule_id | null>        # if this rule replaces an older rule
superseded_by: <rule_id | null>     # back-reference once invalidated
```

Gaps:

```yaml
gap_id: <ULID>
recorded_at: <ISO-8601>
recorded_by: <agent_id>
suspected_owner_role: <role>        # which role would resolve this gap
```

### Why the KB is mid-tier per §17

Per `00-overview/design-principles.md` design-principle 6: mechanical maintenance work runs on mid-tier models, fact-producing work runs on frontier. The KB Linter is the canonical mid-tier role:

- Lint passes are mechanical comparison work (does this finding match the structure? does this rule have a `valid_from`?).
- The asymmetric cost-benefit favors mid-tier: a $0.20 saving on a lint pass is dwarfed by a $3 rework cost when a mid-tier model misses a contradiction *during ingest* — but the KB Linter is not the ingest agent. The Wiki Ingester (frontier) is.

Promoting the KB Linter to frontier is anti-pattern unless §22 audit evidence shows lint-quality regression.

### What the KB does NOT do

- MUST NOT promote a finding directly to a rule (the staircase exists to filter noise).
- MUST NOT exceed `max_new_observations_per_iter` (KB Linter Rule #5 polices this).
- MUST NOT silently overwrite an invalidated rule — Inv 6 / `temporal-facts.md` requires creating a new rule with `supersedes`.
- MUST NOT delete a gap entry without first promoting it to a finding or marking it `resolved_at`.
- MUST NOT mix domain knowledge (`wiki/`) with process knowledge (`knowledge/`) — different audiences, different cadences, different lint rules.
- MUST NOT bypass the eviction policy when a layer reaches its cap; choosing not to evict is a meta-review proposal, not a KB Linter decision.

### Cross-references

- Producer/maintainer: `20-roles/kb-linter.md`
- Auditor: `20-roles/meta-review.md`
- Sister artifact: `30-knowledge/wiki-architecture.md`
- Temporal-fact protocol the rules layer uses: `30-knowledge/temporal-facts.md`
- Per-iteration summary that feeds promotion confirmations: `60-schemas/iter-summary.md`

---
