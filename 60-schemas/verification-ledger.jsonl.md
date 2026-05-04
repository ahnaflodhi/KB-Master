---
id: 60-schemas/verification-ledger
title: verification-ledger.jsonl schema
purpose: schema
audience: [orchestrator, evaluator, kb_linter, meta_review]
status: stable
version: 2.9
last_reviewed: 2026-05-04
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
{"ts":"2026-05-03T14:22:01Z","event":"dispatch","iter":"iter-042","role":"truthsayer","agent_id":"codex-audit","adapter":"codex-bridge","prompt_hash":"sha256:abc...","sandbox":"read-only","model":"gpt-5-codex","config_revision":1,"job_id":"cb-20260503-142201-7a3b"}
{"ts":"2026-05-03T14:24:18Z","event":"consume","iter":"iter-042","role":"truthsayer","agent_id":"codex-audit","job_id":"cb-20260503-142201-7a3b","output_hash":"sha256:def...","auth_verdict":"PASS","schema_verdict":"PASS","verification_verdict":"PASS","reward_hacking_check":"CLEAN","source_recheck_sample":[{"url":"https://example.com/x","status":"verified"}],"final_verdict":"accepted","verifier":"claude-main"}
```

Field semantics:
- `auth_verdict`: did the output's job_id, dispatch hash, and artifact path match the dispatch ledger entry?
- `schema_verdict`: did the output conform to the role's expected schema (e.g. audit-report.md headers)?
- `verification_verdict`: did the output pass semantic-isolation, reward-hacking checks, and source-recheck sample?
- `final_verdict`: one of `accepted | rejected-auth | rejected-schema | rejected-verification | re-delegated`

The ledger is the audit trail for "did the orchestrator actually verify this output before consuming it." Meta-review (§21) reads it to identify agents/roles with persistently high rejection rates — a signal to swap agents in `agents.config.yaml`.

---
