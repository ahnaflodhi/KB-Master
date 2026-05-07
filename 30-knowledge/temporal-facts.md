---
id: 30-knowledge/temporal-facts
title: Temporal-Fact Protocol — Inv 6
purpose: knowledge-spec
audience:
  - kb_linter
  - wiki_ingest
also_needed_by:
  - orchestrator
  - meta_review
  - apply_meta
  - planner
  - truthsayer
  - executor
status: stable
version: 2.10
last_reviewed: 2026-05-04
extracted_from:
  source: SYSTEM-BLUEPRINT-v2.10.md
  sections: ["§13 Temporal Fact Management", "§2 Invariant 6 (temporal facts, never silent overwrites)"]
  line_range_hint: "synthesis: §13 protocol detail + Inv 6 statement"
depends_on:
  - 00-overview/invariants.md
related:
  - 30-knowledge/knowledge-base.md
  - 30-knowledge/wiki-architecture.md
  - 20-roles/kb-linter.md
max_lines: 200
directives:
  must_count: 6
  should_count: 2
  may_count: 1
---

## Temporal-Fact Protocol (Invariant 6)

A current-state knowledge base cannot answer "what did we believe last sprint, and what changed?" Without that capability, contradiction-resolution fails, meta-review cannot reconstruct decision history, and the rule-promotion pipeline (which depends on counting confirmations across iterations) breaks.

The temporal-fact protocol is the structural countermeasure: every rule carries `valid_from` and `invalidated_at` timestamps. New evidence never silently overwrites — it creates a new rule and stamps the old one `invalidated_at = now()`. The KB is an audit trail, not a current-state snapshot.

### Where the protocol applies

| Artifact | Has temporal facts? | Why |
|---|---|---|
| `knowledge/methodology/rules.md` | YES — full protocol | Rules are the highest-confidence layer; superseded rules MUST remain queryable |
| `knowledge/methodology/hypotheses.md` | partial — `created_at` and `last_confirmed_iter` | Hypotheses don't get `invalidated_at` because they're not load-bearing yet |
| `knowledge/findings/knowledge.md` | minimal — `created_at` only | Findings are observations; they don't get invalidated, they get evicted past the cap |
| `wiki/claims/verified/*.md` | YES per-page | Same logic as rules — verified claims that get contradicted MUST stay queryable |
| `wiki/entities/**/*.md` | partial — `created_at`, `incoming_links` | Entity pages are mutable; they don't carry the same audit-trail discipline as claims |
| `pipeline/verification-ledger.jsonl` | YES — every row has `ts` | The ledger is itself a temporal artifact |

### Required fields on temporal-fact entries

```yaml
valid_from: <ISO-8601 date>           # YYYY-MM-DD when the entry was promoted
invalidated_at: <ISO-8601 | null>     # null while active; date when contradicted
provenance:                            # the chain that justified this entry
  - <source-id-1>
  - <source-id-2>
supersedes: <entry_id | null>         # if this entry replaces an older one
superseded_by: <entry_id | null>      # back-reference filled when this entry is invalidated
```

The `supersedes` / `superseded_by` pair is what makes the audit trail navigable. Given any entry, one query walks back through `supersedes` to recover the full historical chain; the symmetric `superseded_by` walks forward.

### The protocol — what to do when evidence contradicts a rule

When the KB Linter (or any agent during evaluation) detects new evidence that contradicts an active rule:

```
1. Do NOT modify the existing rule.
2. Create a new rule with:
   - new rule_id (ULID)
   - valid_from: <today's date>
   - supersedes: <old rule_id>
   - provenance: includes the new contradicting evidence
3. Update the old rule:
   - set invalidated_at: <today's date>
   - set superseded_by: <new rule_id>
4. Log to iter-summary.md: "Rule <old_id> superseded by <new_id>: <one-line reason>"
5. Append to LESSONS.md: cross-iteration record
```

The old rule's `valid_from` stays unchanged. The audit trail can answer "what was rule R between dates X and Y?" by checking entries where `valid_from <= X AND (invalidated_at > Y OR invalidated_at IS NULL)`.

### Promotion + temporal facts together

Promotion (finding → hypothesis → rule per `knowledge-base.md` thresholds) creates a new entry at the higher tier with `valid_from` = today. The lower-tier entry is NOT deleted; it becomes a historical record with a `promoted_to` reference (a soft cross-reference, not a temporal-fact required field).

```
finding F1 (created_at: 2026-01-10)
   ↓ confirmed by 2 sources →
hypothesis H1 (created_at: 2026-02-15, promoted_from: [F1])
   ↓ confirmed in 3 iterations →
rule R1 (valid_from: 2026-04-01, provenance: [H1, source-x])
```

If R1 is later contradicted on 2026-05-04:

```
rule R1 (valid_from: 2026-04-01, invalidated_at: 2026-05-04, superseded_by: R2)
rule R2 (valid_from: 2026-05-04, supersedes: R1, provenance: [H2, source-y])
```

### Querying historical state

To answer "what did we believe on 2026-04-15?":

```
SELECT * FROM rules
WHERE valid_from <= '2026-04-15'
  AND (invalidated_at > '2026-04-15' OR invalidated_at IS NULL)
```

In Markdown-on-disk reality this is a Bash + awk pattern, not SQL — but the principle is the same: filter by the temporal bounds, don't assume current-state.

### Anti-patterns the protocol prevents

| Anti-pattern | What it would do | Why the protocol prevents it |
|---|---|---|
| Silent rule overwrite | Replace rule body in place when contradicted | New evidence creates a new rule (step 2 above); never edit the old |
| Dropping `valid_from` on supersession | Set the old rule's `valid_from` to today when invalidating | `valid_from` is set once at promotion and never changes |
| Treating `invalidated_at` as deletion | Removing invalidated rules from the file to "clean up" | Invalidated rules MUST remain queryable; eviction (cap-driven) only removes oldest invalidated entries when over cap |
| Promoting a hypothesis without creating a new rule | Editing the hypothesis in place to upgrade its tier | Promotion creates a new entry at the higher tier; the lower-tier entry stays as a cross-reference target |

### What the protocol MUST NOT do

- MUST NOT modify `valid_from` after the entry is created.
- MUST NOT delete an invalidated rule until it is the oldest invalidated entry AND the rules layer is over cap (per `knowledge-base.md` eviction policy).
- MUST NOT silently overwrite — every supersession creates a new entry with `supersedes` set.
- MUST NOT skip the `supersedes` / `superseded_by` back-reference pair (audit-trail navigation depends on both directions).
- MUST NOT use a date format other than ISO-8601 for `valid_from` / `invalidated_at`.
- MUST NOT promote a finding directly to a rule (skipping the hypothesis tier breaks the staircase).

### Cross-references

- Promotion thresholds + caps: `30-knowledge/knowledge-base.md`
- Wiki claim ladder (uses similar promotion logic): `30-knowledge/wiki-architecture.md`
- Producer/maintainer: `20-roles/kb-linter.md`
- Audit consumer: `20-roles/meta-review.md`

---
