---
id: 60-schemas/execution-log
title: execution-log.md schema
purpose: schema
audience: [executor, evaluator, kb_linter, orchestrator]
status: stable
version: 2.9
last_reviewed: 2026-05-04
extracted_from:
  source: synthesis
  sections: ["§6 Executor (writer)", "§8 Six-File Inter-Agent Communication Chain (consumers)", "§14 Provenance and Audit Chain (provenance fields)", "§18 Reward Hacking Detection (source-coverage check reads execution-log.md)"]
  line_range_hint: "execution-log.md has no single format block — synthesised from §6 Executor write contract, §8 chain diagram, §14 mandatory provenance fields, §18 source-coverage check"
depends_on:
  - 00-overview/invariants.md
  - 60-schemas/spec.md
  - 60-schemas/contract.md
related:
  - 60-schemas/eval-report.md
  - 10-pipeline/file-contracts.md
  - 10-pipeline/quality-gates.md
max_lines: 100
directives:
  must_count: 0
  should_count: 0
  may_count: 0
---

## execution-log.md — Synthesis schema

**Status**: synthesised from §6 (Executor write contract), §8 (chain diagram), §14 (provenance fields), and §18 (source-coverage check). The blueprint does not give `execution-log.md` a single format block; it is referenced as the Executor's write target, as the Evaluator's mandatory read input, and as the source the source-coverage reward-hacking check inspects.

### Producer

**Executor** (research or commercial) — append-only during the entire `/execute` phase (§6 Executor, line 637: `Writes: wiki pages or code + iterations/current/execution-log.md`).

### Consumers

- **Evaluator** (§8 chain diagram, line 816: `execution-log.md ← Executor writes. Evaluator reads. KB Linter reads.`) — must consult before producing eval-report.md (Invariant 7: tool-using evaluation).
- **KB Linter** — reads to determine what was built/changed and what to lint.
- **Source-coverage reward-hacking check** (§18 Check 1) — counts tool invocations vs claimed citations. A mismatch flags reward-hacking.
- **Orchestrator** — reads to populate `pipeline.log.jsonl` aggregations and to enforce per-unit type-check / multi-tenancy gates (§6 Executor protocol).

### Format — append-only, no overwrite

```markdown
## Iter {iter-NNN} — Executor execution log
Started: {YYYY-MM-DDTHH:MM:SSZ}
Spec: {iterations/current/spec.md}
Contract: {iterations/current/contract.md}
Acceptance: {iterations/current/acceptance-checklist.md}

### Unit {N}: {unit name from spec.md Decomposition}
- Started: {YYYY-MM-DDTHH:MM:SSZ}
- Tool invocations:
  - {tool}({redacted args}) → {outcome — file path written, URL fetched, etc.}
  ...
- Sources fetched: {paths under sources/research/iter-NNN/}      ← research projects, per Invariant 8
- Per-unit type-check: PASSED | FAILED ({tool, error count})    ← commercial projects, per §6 Executor 2a
- Multi-tenancy check: PASSED | FAILED ({reason})               ← commercial, per §6 Executor 2b
- Stubs created: [`# TODO: RESOLVE-STUB at {file}:{line}`]      ← per §6 Stub protocol
- Decisions: {1-line each — only if non-obvious; link to wiki page or knowledge/ rule}
- Completed: {YYYY-MM-DDTHH:MM:SSZ}

### Unit {N+1}: ...
...

## Source anomalies (per §19 prompt-injection defenses)
- {url or file path}: {description — e.g. "contained 'ignore previous instructions' string at offset NNN; flagged and discarded"}
```

### Mandatory provenance fields (§14)

For research projects, each WebFetch/WebSearch invocation logged in `Tool invocations` MUST also write a corresponding source file under `sources/research/iter-NNN/{domain}-{slug}.md` per Invariant 8. The execution-log.md entry references the saved-source path, NOT the URL alone. A claim citing a URL with no corresponding sources/ file = broken provenance = §14 Rule #7 lint failure.

### Source-coverage check (§18 Check 1)

The Evaluator counts:
- N_listed = source URLs in `spec.md` `Sources to Consult` field
- N_fetched = WebFetch/WebSearch invocations in `execution-log.md` Tool invocations
- N_cited = inline citations in the Executor's output (wiki pages or code comments)

If `N_fetched < N_listed` OR `N_cited > N_fetched`, reward-hacking is FLAGGED and the eval-report.md gets `Reward Hacking Check: FLAGGED ({description})`.

### What MUST NOT appear

- Conversation transcripts. The execution log records actions, not internal reasoning.
- Secrets, credentials, API keys (mask before write).
- Speculative work (this is a log of what happened, not what might).
- Full body of fetched sources (those go to `sources/`, this log just references the path).

### Validation

Schema validation in the §25 dispatch shim (Step 8) checks: file exists, is non-empty, contains at least one `### Unit` block, and (for research) every WebFetch/WebSearch tool invocation has a corresponding `sources/research/iter-NNN/*` file.

---
