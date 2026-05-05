---
description: Selective wiki retrieval per §20 three-tier model — returns a page bundle
argument-hint: <free-text query OR structured: entity=X OR claim=Y OR relationship=R>
---

# /wiki-query — Wiki Querier (read-only)

Composes `/_delegate` with `role=wiki_query`. Role contract: `20-roles/wiki-querier.md`. Bundle: `bundles/wiki-query.yaml`. Returns a structured page bundle to the caller; does NOT write to disk.

Per **§20**, the Querier achieves ~93% recall at ~98.4% token reduction vs. naive bulk-load by applying the three-tier model strictly. Tier-1 always; Tier-2 selective; Tier-3 only when Tier-1+2 fail to satisfy.

## Preconditions

- `wiki/index.md` MUST exist (Tier-1 entry point).
- Query MUST be specific enough to scope Tier-2; vague queries trigger a refusal with a Tier-1-only return + note.

## Dispatch

```
/_delegate
  role: wiki_query
  inputs:
    - wiki/index.md                # Tier 1 always-loaded
    - <query target>               # Tier 2 selectively
  expected_schema: (none — returns in-context bundle, not a file)
  iter_id: <current>
```

Default adapter: `claude-native` (subagent). Sandbox: `read-only`. Tier per §17: frontier OR mid-tier (project-configurable; relevance ranking benefits from frontier judgment, raw lookup is mid-tier sufficient).

## Bundle return shape

```yaml
pages:
  - id: <page-id>
    confidence: SINGLE-SOURCE | CROSS-VERIFIED | CONFIRMED
    provenance: [<source-id>...]
    relationships:                       # typed per §11
      uses: [<page-id>...]
      depends_on: [<page-id>...]
      contradicts: [<page-id>...]
      supersedes: [<page-id>...]
    body: <verbatim page content>
bundle_size_tokens: ~<int>
tier_distribution: {tier1: <int>, tier2: <int>, tier3: <int>}
notes: "<any escalations or refusals>"
```

A bundle with `tier_distribution.tier3 > 0` is an observability signal that the Tier-1+2 model didn't satisfy the query; the caller should refine the query or accept the cost.

## What this command MUST NOT do

- MUST NOT bulk-load `wiki/` — refuse and return Tier-1 only with a note.
- MUST NOT escalate to Tier-3 without explicit caller acceptance (one-way per query).
- MUST NOT write to `wiki/`, `iterations/current/`, or any other persistent state.

## Routing

This command does not advance pipeline state. It is a service called by other commands or by the user directly.

---
