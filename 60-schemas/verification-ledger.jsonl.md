---
id: 60-schemas/verification-ledger
title: verification-ledger.jsonl schema
purpose: schema
audience: [orchestrator, evaluator, kb_linter, meta_review]
status: stable
version: 2.9
last_reviewed: 2026-05-11
extracted_from:
  source: SYSTEM-BLUEPRINT-v2.9.md
  sections: ["§19 Agent Trust Model and Prompt Injection Defenses — Verification Ledger"]
  line_range_hint: "search for ### Verification Ledger"
depends_on:
  - 00-overview/invariants.md
related:
  - 10-pipeline/escalation-rules.md
  - 60-schemas/eval-report.md
max_lines: 80
directives:
  must_count: 0
  should_count: 0
  may_count: 0
---
### Verification Ledger

The orchestrator maintains an append-only ledger at `pipeline/verification-ledger.jsonl`. Every delegation produces two entries: one at dispatch (records the request) and one at consume (records the verification verdict).

```jsonl
{"ts":"2026-05-03T14:22:01Z","event":"dispatch","iter":"iter-042","role":"truthsayer","agent_id":"codex-audit","adapter":"codex-bridge","prompt_hash":"sha256:abc...","sandbox":"read-only","model":"gpt-5-codex","config_revision":1,"job_id":"cb-20260503-142201-7a3b","context_sources":["bundles/truthsayer.yaml","00-overview/invariants.md","20-roles/truthsayer.md","60-schemas/audit-report.md","50-adapters/codex-bridge.md"],"context_selection_mechanism":"bundle"}
{"ts":"2026-05-03T14:24:18Z","event":"consume","iter":"iter-042","role":"truthsayer","agent_id":"codex-audit","job_id":"cb-20260503-142201-7a3b","output_hash":"sha256:def...","auth_verdict":"PASS","schema_verdict":"PASS","verification_verdict":"PASS","inv11_verdict":"PASS","reward_hacking_check":"CLEAN","source_recheck_sample":[{"url":"https://example.com/x","status":"verified"}],"final_verdict":"accepted","verifier":"claude-main"}
```

Field semantics:
- `context_sources` (dispatch row, INV 11): the list of file paths the orchestrator passed into the dispatch envelope. `SYSTEM-BLUEPRINT.md` in this list is a hard fail at Step 10 CONSUME (INV 11 violation; meta_review and apply_meta carved out per INV 11). Empty list is also a violation — every dispatch loads SOMETHING.
- `context_selection_mechanism` (dispatch row): names the mechanism that produced `context_sources`. Default `"bundle"`; adopters substituting other mechanisms record `"semantic-routing"`, `"dynamic-composition"`, etc. Required so meta_review can detect mechanism drift across iterations.
- `auth_verdict`: did the output's job_id, dispatch hash, and artifact path match the dispatch ledger entry?
- `schema_verdict`: did the output conform to the role's expected schema (e.g. audit-report.md headers)?
- `verification_verdict`: did the output pass semantic-isolation, reward-hacking checks, and source-recheck sample?
- `inv11_verdict` (consume row, INV 11): did the dispatch's `context_sources` satisfy INV 11 — non-empty, no `SYSTEM-BLUEPRINT.md` (CARVE-OUT for `meta_review`/`apply_meta`), `context_selection_mechanism` named? PASS / FAIL. FAIL feeds into `final_verdict` per `validation.on_validation_failure`.
- `final_verdict`: one of `accepted | rejected-auth | rejected-schema | rejected-verification | re-delegated`

The ledger is the audit trail for "did the orchestrator actually verify this output before consuming it." Meta-review (§21) reads it to identify agents/roles with persistently high rejection rates — a signal to swap agents in `agents.config.yaml`.

---
