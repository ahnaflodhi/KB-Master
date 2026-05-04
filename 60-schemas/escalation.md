---
id: 60-schemas/escalation
title: escalation.md schema
purpose: schema
audience: [orchestrator, planner, truthsayer, pre_check, executor, evaluator, kb_linter]
status: stable
version: 2.9
last_reviewed: 2026-05-04
extracted_from:
  source: SYSTEM-BLUEPRINT-v2.9.md
  sections: ["§16 Escalation Protocol — escalation.md Format"]
  line_range_hint: "search for ### escalation.md Format"
depends_on:
  - 10-pipeline/escalation-rules.md
  - 00-overview/invariants.md
related:
  - 60-schemas/eval-report.md
  - 60-schemas/audit-report.md
max_lines: 80
directives:
  must_count: 0
  should_count: 0
  may_count: 0
---
### escalation.md Format

```markdown
DEADLOCK ESCALATION
- Project type:        {research | commercial}
- Iteration:           {iter_unit} {iter_count}
- Phase:               {Planning | Auditing | Pre-Check | Execution | Evaluation | Budget | Spec-Too-Vague | Systemic}
- Unit:                {feature / claim / page name}
- System Status:       {paused | placeholder running}
- escalation_deadline: {YYYY-MM-DDTHH:MM:SSZ}  ← 48h default; iterate.sh auto-aborts and re-notifies after this timestamp
- The Conflict:        {2-sentence objective summary}
- Agent Stances:
    {Agent A}: {1-sentence position}
    {Agent B}: {1-sentence position}
- Options:
  1. Pivot:      {simpler alternative approach}
  2. Force Pass: {accept current output, append condition to Planner context}
  3. Abort:      {drop unit, clean up placeholder, remove from active_stubs}
  4. Custom:     {reply with open text}
```

### Response Routing

| Response | Action |
|---|---|
| Option 1 (Pivot) | Update contract.md, resume /execute |
| Option 2 (Force Pass) | Mark eval-report.md CONDITIONALLY PASSED, add condition as hypothesis to knowledge/ |
| Option 3 (Abort) | Remove placeholder, update active_stubs, mark unit aborted |
| Option 4 (Custom) | Parse directive → route to agent or dispatch Planner to research |

