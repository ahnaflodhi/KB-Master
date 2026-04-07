---
name: Pending Upstream Suggestions
description: Index of adoption-project suggestions awaiting blueprint review/application
type: suggestions-index
---

# Pending Blueprint Suggestions

Suggestions are filed here by adopted projects when they observe deviations, friction points, or gaps
during real pipeline runs. Each batch is reviewed by the blueprint owner, applied if generalizable,
and then moved to `applied.md`.

**Format**: Source → file link → status → brief note

---

## Batch: adopted-project-001 sprint-001 (2026-04-07)

**Source file**: (private — adoption project knowledge/methodology/blueprint-suggestions.md)
**Observed at**: iter-001 (sprint-001)
**Submitted**: 2026-04-07
**Status**: APPLIED — all 7 suggestions incorporated in v2.5 (see CHANGELOG)

| ID | Section | Type | Severity | Status |
|----|---------|------|----------|--------|
| SUGGESTION-1 | TOC / Section 8 | Cosmetic bug fix | LOW | Applied |
| SUGGESTION-2 | Section 5 PROGRESS.md | State machine addition | HIGH | Applied |
| SUGGESTION-3 | Section 6 Planner | Sequencing bug fix | CRITICAL | Applied |
| SUGGESTION-4 | Section 6 Executor | Protocol strengthening | LOW | Applied |
| SUGGESTION-5 | Section 8 spec.md | Ambiguity removal | MEDIUM | Applied |
| SUGGESTION-6 | Section 23 | Manual harness guidance | LOW | Applied |
| SUGGESTION-7 | Section 7 diagram | Diagram accuracy / contradiction | HIGH | Applied |

**Critical finding**: SUGGESTION-3 was a real architectural sequencing bug — contract.md could be
written while pre-check ambiguities were still open (after TruthSayer APPROVED but before pre-check
COMPLETE), locking a contract against a spec that was not yet stable. Fixed in v2.5.

**Contradiction found**: SUGGESTION-7 exposed a direct contradiction — Section 7 diagram stated
`[CONTRACTED] Executor writes/proposes contract.md` while Section 6 states Planner writes it.
Fixed in v2.5 by splitting into [PRE-CHECK COMPLETE] and [CONTRACTED] states.

---

*To add a new batch: append a new `## Batch:` section above with source link and table.*
*Move fully applied batches to `applied.md` once CHANGELOG entry is confirmed.*
