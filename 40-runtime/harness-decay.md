---
id: 40-runtime/harness-decay
title: Harness Assumption Decay Protocol
purpose: runtime-spec
audience:
  - meta_review
  - apply_meta
also_needed_by:
  - orchestrator
  - kb_linter
status: stable
version: 2.10
last_reviewed: 2026-05-04
extracted_from:
  source: SYSTEM-BLUEPRINT-v2.10.md
  sections: ["§22 Harness Assumption Decay Protocol", "§21 Meta-Review cadence", "§6 KB Linter (audit-input source)"]
  line_range_hint: "synthesis: §22 RETAIN/DOWNGRADE/ARCHIVE outcomes + §21 min(25 iter, 6 month) cadence + §6 ledger as evidence source"
depends_on:
  - 00-overview/invariants.md
  - 00-overview/design-principles.md
  - 40-runtime/verification-ledger.md
related:
  - 20-roles/meta-review.md
  - 20-roles/apply-meta.md
  - 50-adapters/capability-matrix.md
max_lines: 180
directives:
  must_count: 6
  should_count: 4
  may_count: 1
---

## Harness Assumption Decay Protocol

Every protective scaffold this blueprint mandates — cycle limits, reward-hacking checks, schema-validation rigor, gate enforcement, fact-presentation, host-access denials, semantic-isolation, retry budgets — is a model-version snapshot. It exists because at the time it was added, a documented failure mode required a structural countermeasure. As models improve, some scaffolds become redundant. As project shape changes, others stop catching what they were meant to catch.

A system that cannot retire its own scaffolds eventually drowns in them. The decay protocol is the structural countermeasure to that drowning. **This is a design principle (`00-overview/design-principles.md`), not a roadmap item.** It runs on cadence, regardless of whether new work is in flight.

### The cadence

`min(25 iterations, 6 months)`. Whichever comes first. Triggered automatically by the orchestrator when `PROGRESS.md.iter_count` crosses a multiple of 25 OR `meta/last-audit-date` is older than 180 days.

May also fire on demand via `/meta-review` (e.g. after a major adapter change like v2.10 host_access — though for v2.10 the policy was added without an explicit decay run since it was source-attributed evidence rather than scaffold-decay evidence).

### Per-scaffold frontmatter requirements

Every scaffold this protocol applies to MUST carry two frontmatter fields:

```yaml
compensates_for: <failure-mode-id>     # which §1 failure mode this scaffold prevents
evidence_threshold: <int>              # minimum catches per audit window to RETAIN
```

Examples:
- `00-overview/invariants.md` Invariant 1 (Generator≠Evaluator): `compensates_for: sycophancy-collapse-fm2`, `evidence_threshold: 1`
- `10-pipeline/quality-gates.md` G7 (reward-hacking): `compensates_for: reward-hacking-fm7`, `evidence_threshold: 2`
- `agents.config.yaml` `policy.assume_host_access_false_unless_probed: true`: `compensates_for: bridge-stage4-psql-blocked`, `evidence_threshold: 1`

Scaffolds without `compensates_for` are exempt from decay (they are not protective scaffolds; they are core architecture).

### The three outcomes

| Verdict | Trigger | Action |
|---|---|---|
| **RETAIN** | catches ≥ `evidence_threshold` over the audit window | no-op; record `Applied: RETAIN` in `meta/audit-YYYY-MM-DD.md` |
| **DOWNGRADE** | 1 ≤ catches < `evidence_threshold` | flip scaffold `status: stable → advisory`; flip relevant `policy.on_X_missing: reject → warn`; bump `config_revision` |
| **ARCHIVE** | catches == 0 AND no documented near-miss | remove from active config; move slash command to `commands/_archived/<name>-YYYY-MM-DD.md`; flip frontmatter `status: archived`; record specification in audit's `Archived:` block; bump `config_revision` |

A scaffold whose `compensates_for` failure mode has itself been retired by a model improvement (per §22) is automatically ARCHIVE-eligible regardless of catch count.

### Decision procedure (per scaffold)

```
1. Read trailing-window audit data:
   - From pipeline/verification-ledger.jsonl: count consume rows where the
     scaffold's `compensates_for` failure mode contributed to a rejection
   - From iterations/archive/iter-NNN/iter-summary.md: count KB-Linter anomalies
     attributed to this scaffold
   - From meta/last-audit.md: count near-misses (cases where the scaffold
     would have caught something if its threshold were lower)

2. Compare catches vs. evidence_threshold:
   - catches >= threshold → RETAIN
   - 1 <= catches < threshold → DOWNGRADE
   - catches == 0 → ARCHIVE candidate

3. For ARCHIVE candidates, check the model-improvement column:
   - If a recent model release (per knowledge/methodology/rules.md temporal facts)
     documents that the failure mode is now self-prevented → confirm ARCHIVE
   - Otherwise downgrade ARCHIVE to DOWNGRADE (uncertain — keep as advisory)

4. Write meta/audit-YYYY-MM-DD.md per Meta-Review's contract
5. Apply-Meta then enacts per 20-roles/apply-meta.md
```

### Why this is hard to design and easy to skip

Two failure modes the protocol itself is vulnerable to:

- **Status-quo bias**: every scaffold has a strong "this might catch something next quarter" defence. The protocol's countermeasure is `evidence_threshold` — if the scaffold was added with `evidence_threshold: 2`, it MUST catch 2 over the audit window or it is not earning its `add_to_harness` cost.
- **Survivorship blindness**: a scaffold catches nothing because the architecture downstream stopped allowing the failure mode to reach it. This isn't grounds for ARCHIVE — record `near-miss-prevented-upstream` in the audit. Apply-Meta keeps it.

### Evidence sources by scaffold class

| Scaffold class | Evidence source |
|---|---|
| Verification gates (G0-G9) | `pipeline/verification-ledger.jsonl` consume rows where the gate's verdict was the rejection cause |
| Cycle limits | `iterations/archive/iter-NNN/iter-summary.md` count of cycle-exhaustion escalations |
| Reward-hacking checks | `pipeline/verification-ledger.jsonl` consume rows where `reward_hacking_check: FLAGGED` |
| Invariants | `iterations/archive/iter-NNN/iter-summary.md` near-miss notes; `escalation.md` records that cite the invariant |
| Adapter capability denials (v2.10) | `pipeline/verification-ledger.jsonl` consume rows with `final_verdict: rejected` and `notes: host_access_degradation*` |
| KB lint rules | KB Linter's per-rule findings appended to LESSONS.md |

### What the protocol MUST NOT do

- MUST NOT skip a scaffold from the audit because "it's obviously still needed" — every scaffold gets evaluated against evidence.
- MUST NOT compress the audit window to make a particular scaffold look more or less effective.
- MUST NOT downgrade an Invariant (1–10). Invariants are properties, not scaffolds; their amendment requires a blueprint version bump (§22 + CLAUDE.md update protocol).
- MUST NOT publish the verdict before Apply-Meta has acted (verdicts in `meta/` are proposals until enacted).
- MUST NOT skip recording the Apply-Meta enaction in `pipeline/verification-ledger.jsonl` (one apply-meta audit row per Apply-Meta run).
- MUST NOT auto-rotate the ledger to make room for a fresh audit window — the audit reads a trailing window, not the entire ledger.

### Cross-references

- Meta-Review role contract: `20-roles/meta-review.md`
- Apply-Meta role contract: `20-roles/apply-meta.md`
- Verification ledger semantics: `40-runtime/verification-ledger.md`
- Design principle this enforces: `00-overview/design-principles.md` "Harness components decay"

---
