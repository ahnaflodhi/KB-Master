---
name: JCC workflow-improvement research — 18 Codex proposals + external patterns + deferred roadmap
type: reference
researched: 2026-06-03
provenance:
  jcc_ledger_job: jcc-workflow-research-001
  codex_stream: codex-cli-0.130.0 (degraded-path codex exec; bridge present but called directly)
  claude_stream: web search pass (5 queries)
primary_sources:
  - https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills
  - https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents
  - https://www.mindstudio.ai/blog/claude-code-skills-architecture-progressive-context-loading
  - https://www.morphllm.com/context-rot
  - https://towardsdatascience.com/single-agent-vs-multi-agent-when-to-build-a-multi-agent-system/
  - https://techcommunity.microsoft.com/blog/azure-ai-foundry-blog/three-tiers-of-agentic-ai---and-when-to-use-none-of-them/4510377
  - https://arxiv.org/html/2509.18970v1
  - https://www.mdpi.com/2076-3417/16/6/3013
  - https://fast.io/resources/reflection-pattern-self-correcting-agents/
  - https://arxiv.org/pdf/2603.24639
---

# JCC workflow-improvement research (v3.1.0 cycle)

A joint Claude–Codex (JCC) research pass on how to improve the framework's *suggested
workflow* across five axes: simplify, efficiency, skill invocation/suggestion, context-bloat
control, hallucination control. Codex (cross-family, read-only) produced 18 grounded proposals
with `file:line` evidence; Claude ran a parallel web pass for validated external patterns.
Filtered hard against the project's anti-speculation invariant (prefer net-removals).

**Status:** 3 proposals landed in **v3.1.0** (see "Landed" below). The rest are an open roadmap.

---

## Codex's 18 proposals (grounded, with repo evidence)

Format: `proposal — repo mechanism it improves/replaces — net complexity — impact/effort — status`.

### Simplify
1. **Thin slash-command wrappers** — `commands/pre-check.md:1` is still direct-role prose while others compose `/_delegate`; role contracts + schemas become the only source of truth. − / H,M / **DEFERRED** (needs content-diff vs role contract to avoid losing prose). *Codex's single highest-leverage simplification.*
2. **Collapse `apply_meta` role→orchestrator command mode** — already orchestrator-inline & non-delegable (`20-roles/apply-meta.md:56`); separate role/bundle adds ceremony. − / M,M / open.
3. **Replace 2nd Planner `/plan` contract pass with deterministic contract assembly** from signed spec + checklist (`20-roles/planner.md:43`); the guarantee is contract existence, not new judgment. − / H,M / **DEFERRED** (Codex: "grounded, needs validation").
4. **`/wiki-ingest` as maintenance/manual only**; default research execution invokes ingest internally (`commands/wiki-ingest.md:47`). − / M,L / open.
5. **`40-runtime/dispatch-shim.md` = synopsis, `commands/_delegate.md` canonical** — both restate the 11 steps (`_delegate.md:51`, `dispatch-shim.md:43`). − / M,L / open.

### Efficiency
6. **Lazy adapter probing** — probe only the adapter the next dispatch needs (`iteration-lifecycle.md:38` says probe-all-at-startup; shim already supports on-demand `_delegate.md:69`). − / H,L / **DEFERRED** (spec semantics, wider blast radius). *Top-ranked.*
7. **Drop `80-status/shipped-vs-planned.md` from routine role bundles**; reserve for orchestrator/meta-review (`bundles/_README.md:35`). − / M,L / open.
8. **Parallelize Step 9 semantic checks** (reward-hack count, source recheck, role checks are independent, `_delegate.md:145`). ~ / M,M / open.
9. **Use bridge protocol-2 `output.json`/`--output-schema`** when available, retaining orchestrator verification (`shipped-vs-planned.md:78`). ~ / M,M / open.

### Skill invocation/suggestion
10. **Add optional `skills:` metadata to bundles** (name, trigger, path, max_tokens); load only after trigger match — natural extension of bundle manifests + `context_selection_mechanism` (`bundles/_README.md:23`). +small/−always-loaded / H,M / **DEFERRED** (new capability surface — deliberate design). *This is the framework-native answer to "invoke/suggest skills."*
11. **Record `skills_suggested`/`skills_loaded` in the dispatch ledger** (ledger already records context source/mechanism, `verification-ledger.jsonl.md:33`). + / M,M / open (pairs with #10).
12. **Never auto-run side-effecting skills; only auto-suggest or load read-only skill instructions** — INV 9/10 guard side effects (`invariants.md:150`). ~ / H,L / open (pairs with #10).

### Context-bloat control
13. **Enforce measured bundle token caps in CI** — `estimated_tokens` is informational today (`three-tier-memory.md:85`). + / H,M / open (a measured-token version of `verify-config`'s spirit).
14. **Single-source the `pipeline_state` enum** + generate command preconditions from it (`progress.md:35` drifted from `kb-lint.md:14`). − / H,M / **LANDED in v3.1.0** (enum fixed to 9 canonical states; `verify-config` enforces no drift).
15. **CI stale-reference lint** for "planned/old-path/status" prose in runtime docs (e.g. `glossary.md:70`). + / M,M / open. *(Note: v3.1.0 de-staled several of these by hand; a lint would prevent recurrence.)*

### Hallucination control
16. **Make PASS impossible when `eval-report.md` `Uncited Claims` is non-empty** (`eval-report.md:37`). + / H,L / **LANDED in v3.1.0** (citation-completeness gate in `eval-report.md` + `quality-gates.md`).
17. **Require claim-to-source-file mapping, not URL-only citations**, for research outputs (`execution-log.md:95` already requires source files for WebFetch/Search; promote to a consume gate). + / H,M / open.
18. **Risk-tiered source recheck** — critical claims 100%, keep 20% sample for low-risk (G8 is uniform 20%, `quality-gates.md:106`). + / H,M / open.
19. **Source recheck via independent evaluator family** when available (INV 1.A already requires family separation, `invariants.md:36`; G8 is orchestrator-side today). ~ / M,M / open.

**Codex's top 5 (impact/effort):** (1) lazy probing, (2) thin command wrappers, (3) measured bundle token caps, (4) citation PASS gate, (5) deterministic contract assembly.

---

## External validated patterns (Claude web pass, 2025–2026)

- **Agent Skills standard** (Anthropic, Dec 2025) — *progressive disclosure*: ~100-token metadata always loaded → ~5k body on relevance → resources on demand. Adopted by OpenAI/Google/GitHub/Cursor within weeks. Grounds proposals #10–#12. [anthropic](https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills), [mindstudio](https://www.mindstudio.ai/blog/claude-code-skills-architecture-progressive-context-loading)
- **Over-orchestration caution** — "multi-agent only when the task genuinely needs it; it increases latency, cost, complexity." Specialization solves monolith failure modes, but don't run N roles for a trivial task. [towardsdatascience](https://towardsdatascience.com/single-agent-vs-multi-agent-when-to-build-a-multi-agent-system/), [microsoft](https://techcommunity.microsoft.com/blog/azure-ai-foundry-blog/three-tiers-of-agentic-ai---and-when-to-use-none-of-them/4510377)
- **Context rot + subagent isolation** — degradation is measurable/avoidable; subagents explore in tens-of-thousands of tokens but return a 1–2k *distilled summary*; new context-editing + memory primitives. Anthropic multi-agent (Opus lead + Sonnet subagents) +90.2% on research. [anthropic](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents), [morph](https://www.morphllm.com/context-rot)
- **Hallucination** — RAG alone insufficient (17–34% even when grounded, Stanford); add span/claim-level verification, **citation-enforced gates** (citation consistency ∝ correctness), best-of-N reranking, multi-agent verify (MS CORE −25.8% false positives). Grounds #16–#18. [arxiv survey](https://arxiv.org/html/2509.18970v1), [mdpi](https://www.mdpi.com/2076-3417/16/6/3013)
- **Reflexion + scope guardrails** — "generate → reflect → refine" with persisted failure/success summaries; cheap guardrail: abort the loop if the diff touches files outside task scope. [fast.io](https://fast.io/resources/reflection-pattern-self-correcting-agents/), [arxiv ERL](https://arxiv.org/pdf/2603.24639)

---

## Landed in v3.1.0 (from this research)

- **#14** single-source `pipeline_state` enum → enum completed to 9 canonical states; `tools/verify-config.sh` enforces no drift (commands/roles/pipeline ⊆ enum). Caught a real missing state (`escalated`) on first run.
- **#16** citation-completeness gate → `eval-report.md` + `quality-gates.md`: non-empty `Uncited Claims` forbids PASS.
- (Config-completeness checker `verify-config.sh` is a narrower, mechanical cousin of #13's "enforce in CI" spirit.)

## Deferred roadmap (open; ordered by leverage)

1. **`skills:` progressive-disclosure mechanism** (#10–#12) — the explicitly-requested "invoke/suggest skills" capability. Design as: optional `skills:` block in bundle manifests (name/trigger/path/max_tokens), metadata-only until trigger match; ledger `skills_suggested`/`skills_loaded`; never auto-run side-effecting skills (INV 9/10). New surface → its own design pass.
2. **Lazy adapter probing** (#6) — change `iteration-lifecycle.md` + `dispatch-shim.md` from probe-all-at-startup to probe-on-demand (shim already supports it). Net-simplify; deferred for blast-radius care.
3. **Thin command wrappers** (#1) — make `/pre-check` compose `/_delegate` like the others; needs a content-diff vs `20-roles/pre-check.md` to avoid losing prose.
4. **Measured bundle token caps in CI** (#13) — turn `estimated_tokens` from informational into an enforced cap (needs a tokenizer).
5. **Planner contract-pass removal** (#3) — Codex flagged "needs validation"; touches a correctness guarantee. Validate before adopting.

**Meta-finding:** the C-UAS migration friction (hand-built config, enum drift, `adapter_degraded` unschematized, no skill mechanism) mapped 1:1 onto these axes — fixing the *workflow* and easing *adoption* are the same work.
