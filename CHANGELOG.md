# Changelog — SYSTEM-BLUEPRINT.md

## v2.5 — 2026-04-07

**Source**: Adopted project sprint-001 run. 7 suggestions filed and tracked in `suggestions/pending.md`.

### Critical fix

**Contract.md sequencing bug** (SUGGESTION-3, Section 6 Planner): The blueprint previously stated the Planner writes contract.md "after TruthSayer APPROVED." This is wrong — TruthSayer approves the spec before pre-check runs. Pre-check can introduce ambiguity resolution cycles that alter deliverables, scope, or acceptance criteria. Writing contract.md before pre-check COMPLETE locks a contract against a spec that is not yet stable. Fixed: contract.md is now written only after TruthSayer APPROVED **and** after pre-check COMPLETE (`pipeline_state: pre-check-complete`). A new "Sequencing constraint" note makes the ordering explicit.

### High-severity fixes

**Pipeline diagram contradiction** (SUGGESTION-7, Section 7): The diagram showed `[CONTRACTED] Executor writes/proposes contract.md` — directly contradicting Section 6 which states the Planner writes it. Fixed by splitting the transition into two states: `[PRE-CHECK COMPLETE]` (Planner writes contract.md, spec now stable) and `[CONTRACTED]` (Executor reads contract.md + acceptance-checklist.md). The contradiction existed since v2.1.

**`pre-check-complete` state added to PROGRESS.md** (SUGGESTION-2, Section 5): The pipeline_state enum had no state between `pre-checking` (ambiguities may still be open) and `contracted` (contract.md written). Added `pre-check-complete` as the explicit intermediate state, making PROGRESS.md machine-readable at this transition. Linked to the sequencing fix above — the new state is what triggers the Planner to write contract.md.

### Medium fix

**spec.md Hypothesis field scoped to research** (SUGGESTION-5, Section 8): Template was ambiguous — commercial specs don't have a `Hypothesis` field, but the template listed it without qualification. Schema validation could falsely flag a commercial spec as malformed. Fixed: template now shows `Hypothesis` (research) and `User Story` + `Acceptance Criteria` (commercial) as alternates, with an explicit note that `Hypothesis` absence does not malform a commercial spec.

### Low fixes

**TOC cosmetic bug** (SUGGESTION-1): "Five-File" → "Six-File" in Section 8 TOC entry. The section header was already correct; only the TOC was stale.

**Commercial Executor protocol strengthened** (SUGGESTION-4, Section 6): Added two per-unit protocol steps grounded in sprint-001 observed failures: (2a) type-check after each unit (`npx tsc --noEmit`) — deferred type errors compound across units; (2b) multi-tenancy gate after each API route unit — verify tenant-isolation clause on every new DB query before marking unit done. Multi-tenancy failures are silent at runtime.

**Manual harness note for mid-project adoption** (SUGGESTION-6, Section 23): Without `iterate.sh`, `pre_check_cycle_current` is not auto-incremented. Added a note to Phase B of the Mid-Project Adoption guide documenting the required manual discipline and warning about duplicate PROGRESS.md field entries (which are silently read as the first occurrence only).

### Infrastructure

`suggestions/` directory created with `pending.md` index. Adoption projects file suggestions there; blueprint owner reviews and applies generalizable ones. This batch moved from `pending` to `APPLIED` status on the same day.

## v2.4 — 2026-04-07

**Source**: Gap analysis against Claude Code best practices documentation (April 2026). All MCP memory tool schemas verified against live mcp__memory__ tool definitions.

### New: Section 24 — Claude Code Harness Integration

**Folder-specific CLAUDE.md hierarchy** (Section 24): Blueprint previously relied on a single flat product CLAUDE.md. Now specifies a three-level hierarchy — workspace root, product root, and subdirectory (wiki/ and knowledge/ each get their own CLAUDE.md). Agents working in wiki/ load wiki-specific rules without the full orchestration context; agents in knowledge/ load KB rules. Hard cap of ≤ 200 lines per file enforced at every level. `@path/to/import` syntax for supplements. Also clarified that slash commands must live in `.claude/commands/` (not `commands/` at project root) for Claude Code resolution.

**Hooks protocol** (Section 24): Previously, INVARIANT 8 (sources/ immutability) was advisory-only. Now specifies a `PreToolUse` hook that blocks Write to any existing file in `sources/` at the harness level — structurally unbreakable regardless of model behavior. Also specifies `PostCompact` hook for PROGRESS.md re-injection after context compaction, and escalation `Notification` hook.

**Permission mode guidance** (Section 24): No previous guidance on which Claude Code permission mode to use per pipeline phase. Now specifies: `plan` mode for planning/auditing/pre-check (read-only), `acceptEdits` for execution and KB linting, `auto` for unattended `./iterate.sh` runs (background safety classifier), `dontAsk` for CI. Also specifies `--allowedTools` per `claude -p` call — harness-level role enforcement, not just instructional.

**Session-level context management** (Section 24): Blueprint documented iteration-level KB loading (Section 20) but not session-level context management. Now specifies: `/clear` between pipeline phases in interactive sessions, `/compact` before KB Linting on long iterations, `claude --continue` for resuming interrupted iterations (not fresh sessions).

**MCP server recommendations** (Section 24): First explicit MCP guidance in the blueprint. Specifies `memory` + `playwright` as required for all projects (research and commercial), `github` as recommended for commercial, `cloudflare` as conditional for Cloudflare deployments, `qmd` as recommended when sources > ~100 (already mentioned in Section 10, now tied to an MCP server recommendation). Defines project-scoped vs. user-scoped server placement with credential handling rule.

**MCP memory usage protocol** (Section 24): Defines the boundary between file-based KB (project-scoped, iteration-tracked) and MCP memory (cross-project, permanent, semantic). Specifies tagging schema mirroring the KB taxonomy (type:rule/lesson/decision/observation, status:active/deprecated/superseded, confidence levels). Session-start ritual: `memory_search` before reading project files, `quality_boost=0.3` for important lookups.

**MCP memory deprecation protocol** (Section 24): Mirrors INVARIANT 6 (never silent overwrite) for MCP memory. Lifecycle: active → deprecated (tag update) → deleted (30d grace period). Specifies `memory_quality(analyze)` for candidate identification, `memory_update` for tag-only deprecation, `memory_cleanup()` for duplicates. Hard rule: never delete in same session as deprecation. Added item 11 to meta-reviewer checklist (Section 21).

**Quick Reference Card updated** with CLAUDE.md hierarchy, hooks, permission modes, MCP server requirements, and MCP memory lifecycle rules.

## v2.3 — 2026-04-06

**Source**: Deep research into Karpathy's LLM wiki gist + community implementations (5,000+ stars, 1,251 forks). Research archived in `research/sources/karpathy-llm-wiki-deep-research.md`.

### Gaps filled from Karpathy research

**wiki/index.md format specified** (Section 11): Previously mentioned but unformatted. Now has: one-line entries per page under category headers, entry format `[name](path) — hook (type, confidence, date)`, 200-line hard cap with overflow to `wiki/index-extended.md`. The index IS what makes the wiki navigable at moderate scale — without a well-maintained index in a consistent format, the wiki degrades to a directory of orphaned files.

**wiki/log.md parseable prefix format** (Section 11): Now specifies `## [YYYY-MM-DD] {iter} ({desc}) | {type}` as the prefix convention. The `|` delimiter enables automated log parsing — meta-reviewer can compute ingest frequency, query-compounding rate, and lint health trends from the log without reading every entry.

**Source delta tracking via sources/.manifest.json** (Section 11): Manifest tracks SHA-256 of every source file with first/last ingested iteration and pages created/updated. Executor checks manifest before re-ingesting — skips unchanged sources. KB Linter maintains the manifest post-iteration. Prevents duplicate observations and redundant reprocessing — a pain point hit by every real implementation at scale.

**Coverage indicators on wiki page frontmatter** (Section 11): Added `coverage: {section: HIGH | MEDIUM | LOW}` and `origin: ingest | query-compounding | synthesis` fields. HIGH = 3+ independent sources for that section's claims; MEDIUM = 2 or 1 strong primary; LOW = 1 source or inference. Agents reading LOW-coverage sections must fall back to sources/. The page-level `confidence` field was insufficient — a CROSS-VERIFIED page can still have individual sections with only 1 source.

**"Prefer update over create" in Executor** (Section 6): Added explicit rule and ingest depth check. Executor defaults to updating existing pages rather than creating new ones — wiki sprawl from unnecessary new pages degrades the index. Expectation: 10-15 wiki pages touched per substantive source ingest; fewer than 5 signals shallow work.

**Query compounding operationalized** (Section 6, Section 9): `/wiki-query` now explicitly files valuable query syntheses back as wiki pages (type: `query-synthesis`, origin: `query-compounding`). This is Karpathy's most underappreciated innovation — the wiki grows from every research question answered, not just from ingest cycles. Previously described in philosophy (Section 1) but not wired into the command spec.

**Wiki Operating Rules added to product CLAUDE.md template** (Section 5): Eight canonical rules for wiki maintenance (never modify sources/, update-over-create, always update index.md and log.md, cite every claim, mark uncertainty, propose schema changes as diffs, file query answers back, 10-15 page ingest depth). These are the "coding standards" for wiki maintenance — without them, different agents produce structurally incompatible wikis.

**outputs/ directory added** (Section 4): Optional directory for rendered deliverables (reports, slides, charts) produced from wiki content. Separates what is known (wiki/) from what was delivered (outputs/). The absence of this distinction caused wiki/ to accumulate rendered artifacts that weren't wiki pages, degrading the index.

**qmd named as recommended search tool at scale** (Section 10): Previously said "hybrid search (BM25 + vector + LLM re-ranking)" without naming a tool. qmd (https://github.com/tobi/qmd) is the Karpathy-recommended implementation — available as both CLI (shell-out) and MCP server (native tool use). Relevant when sources > ~100.

**Schema co-evolution principle** (Section 10): Added Karpathy's insight that the CLAUDE.md wiki schema is not written once and frozen — it co-evolves with the domain as the agent discovers what naming conventions, entity categories, and connection types add the most value. "Building the schema well is itself a form of thinking about the domain."

**Fine-tuning endpoint documented as Layer 5** (Section 10): Karpathy's stated long-term vision: wiki → synthetic Q&A pairs → domain-specific fine-tuning. Tools: Distilabel, Axolotl, Unsloth. Not in scope now but the wiki architecture is designed to support this. Documents the full evolution path: ingest-and-compile → compile-and-query → query-compounds → synthetic-data → fine-tuned-model.

**Quick Reference Card updated** with new conventions: wiki operations, ingest log format, index entry format, delta tracking, qmd, raw save order, outputs/ directory.

## v2.1 — 2026-04-06

**Audit source**: 3 independent adversarial agents with web search/fetch access. Reports archived in `audits/2026-04-06-agent{1,2,3}-*.md`.

### Critical fixes

**Semantic prompt injection gap (Agent 3 CRITICAL)**: Schema validation of inter-agent files validates header presence but not field value content. A structurally valid spec.md can embed imperative instructions within field values that pass schema checks but get executed by downstream agents (OWASP LLM01:2025, arXiv:2506.23260). INVARIANT 3 and Section 19 now explicitly require semantic isolation of field values — treat content as opaque data strings, not instruction text.

**Token self-estimation is not a real capability (Agent 2 CRITICAL)**: The Claude API does not expose a running session token total to agents during execution. Agents cannot accurately self-report consumption. Section 17 now specifies harness-level enforcement: iterate.sh reads API response `usage` fields and writes totals to PROGRESS.md externally.

**Two unbounded loops (Agent 2 CRITICAL)**: (a) SPEC-FLAW route reset audit cycle counter without a global cap → infinite Evaluator→Planner loop possible. Fixed: `spec_flaw_count` global counter in PROGRESS.md (never reset); `spec_flaw_count >= 2` → ESCALATE. (b) Pre-check ambiguity resolution had no exit condition. Fixed: `pre_check_cycle_current` with max 2 rounds before auto-escalation.

**contract.md had no specified author (Agent 2 CRITICAL)**: Pipeline had [CONTRACTED] state but no agent assigned to create it. Planner now explicitly writes contract.md as initial draft after TruthSayer APPROVED.

### High severity fixes

**Anthropic attribution errors (Agent 1 HIGH)**: Post is dated March 2026, not 2025. Phrase "harness assumptions decay" does not appear in source; actual text is "those assumptions...can quickly go stale as models improve." Phrase "vastly outperform" (re: live-tool evaluators) not in source — blog presents live-tool evaluation as qualitative best practice, not a measured comparison. All three corrected.

**Bi-temporal model incomplete (Agent 1 HIGH)**: Zep arXiv:2501.13956 defines FOUR timestamps, not three. Blueprint had collapsed `transactional_expired_at` and `valid_until` into a single `invalidated_at`, losing the ability to represent retroactive corrections. Section 13 now implements the full four-timestamp model with a documented simplified fallback.

**No escalation timeout (Agent 3 HIGH)**: `pipeline_state: escalated` + "await human" with no timeout could halt a pipeline indefinitely. `escalation_deadline` field added to escalation.md format (default 48h).

**escalations_last_5 >= 3 halts pipeline (Agent 3 MEDIUM)**: Was ambiguous whether this triggered meta-review only or a full halt. Now explicit: full pipeline halt until human-approved meta-review applied.

### Medium severity fixes

**Karpathy attribution clarified (Agents 1+3)**: Renamed Section 10 to "Two-Layer Karpathy Pattern + Process Learning Extension." The `knowledge/` OBS→HYP→RULE promotion ladder is original blueprint architecture, not something Karpathy described. The raw/+wiki/ two-layer core is accurately attributed.

**400K word threshold removed (Agent 1)**: Karpathy mentions ~100 sources, not ~400K words. The word count was an interpolation. Replaced with Karpathy's actual quoted text.

**CROSS-VERIFIED vs CROSS-VERIFIED contradiction (Agent 2)**: Immediate escalation mid-pipeline would halt active projects with any contradictions. Changed to deferred+CONTESTED path: log to synthesis/contradictions/, mark claims [CONTESTED], allow pipeline to continue. Escalate only if contradiction affects current iteration's contract.md.

**KB eviction formula defined (Agent 2)**: All four terms now have explicit units: recency = 1/(1+iterations_since_last_validated), citation_frequency = incoming_links count, confidence_score = 1/2/3, information_density = inline citation count.

**Tier 2 decision procedure (Agent 2)**: "Load on demand based on current task" was entirely agent judgment. Added explicit decision procedure table per agent role.

**Incoming links maintenance (Agent 2)**: KB Linter now explicitly responsible for scanning written pages for outgoing links and updating linked pages' incoming_links frontmatter.

**Observation velocity cap (Agent 3)**: Added `max_new_observations_per_iter` to PROJECT.md (default 10). KB Linter rejects iterations writing more than this number of new SINGLE-SOURCE claims without human review.

**Pinned rules (Agent 3)**: Added `pinned: true` flag to rule format. Pinned rules exempt from eviction policy. Limit ≤ 3 per domain.

**Adaptive meta-review cadence (Agents 2+3)**: Fixed iteration-only cadence to `min(5 iterations, meta_review_max_days)`. Added `last_meta_review_date` to PROGRESS.md.

**Reward hacking Check 1 (Agents 2+3)**: Tool-call count heuristic ("5+ tool calls") is unreliable — sophisticated agents mimic expected call patterns (METR 2025 research). Replaced with source-coverage check: compare sources actually fetched vs. sources listed in spec.md.

**32% attribution corrected (Agent 3)**: Contextualized as Liu et al. arXiv:2502.14282, PC-Eval desktop automation benchmark (25 tasks). Not a general multi-agent architecture result.

**Cascade amplification note (Agent 1)**: Added note to Section 7 citing arXiv:2603.04474 (Google DeepMind) — sequential pipelines exhibit 17x error amplification without gates. TruthSayer and Pre-Check Evaluator explained as cascade breakers.

**INVARIANT 1 carve-out (Agent 1)**: "Generator ≠ Evaluator" is too absolute for mechanically verifiable outputs (test suite pass/fail, schema validation, URL reachability). Carve-out added: structural Evaluator separation required for quality scoring and acceptance determination; self-verification acceptable for mechanical pre-checks.

**pipeline.log.jsonl schema (Agent 2)**: Replaced 3 example entries with complete 13-event-type enumeration (wiki_write, wiki_update, claim_unverified, claim_verified, obs_recorded, stub_created, rule_promoted, rule_invalidated, rule_demoted, escalation_triggered, eval_pass, eval_fail, spec_flaw) with required fields per type.

**Harness decay rationale recording (Agent 2)**: Added `compensates_for` and `evidence_threshold_for_removal` frontmatter fields to command file standard. Future auditors can evaluate decay without reverse-engineering intent from behavior.

**Independence test tie-breaker (Agent 2)**: Added organizational test as deterministic fallback for ambiguous independence cases.

**Harness audit dual trigger (Agent 2)**: min(25 iterations, 6 months). Added `last_harness_audit` to PROGRESS.md.

### Unresolved items (deferred to v2.2)
- Machine-readable schema (JSON Schema) for the 6 inter-agent files — currently schema validation is prose-described
- Technical failure protocol (network errors, tool call exceptions) — blueprint handles semantic failures but not technical failures
- Trust boundary for human-modified configuration files — no change-approval requirement defined for CLAUDE.md and PROJECT.md
- Domain-driven TTL for time-sensitive rules (competitor pricing, API terms) — current staleness check at 20 iterations is domain-agnostic
- Concurrency model for multi-product shared resources (central-kb/ write conflicts)
- KB drift detection at scale (100+ iterations on fast-moving domains)

## v2.0 — 2026-04-06

**Breaking changes**: New `acceptance-checklist.md` file added to the six-file communication chain. Pipeline is now a directed graph, not a linear chain (SPEC-FLAW route added).

**New invariant added**: INVARIANT 7 — Evaluator must use execution tools (static-only = CONDITIONAL PASS at best).

**New agent role**: Pre-Check Evaluator (`/pre-check`) — reviews spec and produces acceptance checklist before execution begins. Eliminates the most common non-convergence failure mode where Executor and Evaluator operate from different implicit interpretations of the spec.

**New sections**:
- Section 13: Temporal Fact Management Protocol — bi-temporal model, contradiction resolution algorithm. Facts are `invalidated_at`, never silently overwritten. Validated against Zep/Graphiti arXiv:2501.13956.
- Section 14: Provenance and Audit Chain — every confirmed rule traces back to raw source via HYP→OBS→source-file chain. `pipeline.log.jsonl` records every KB write for full auditability.
- Section 17: Token Budget Management — per-session budget cap, 80% pressure mode, 100% escalation. Addresses quadratic token growth failure mode documented in production.
- Section 18: Reward Hacking Detection — 4 mandatory checks. FLAGGED = automatic FAIL. Based on Shopify production experience (opt-out hacking, tag hacking, schema violation patterns).
- Section 19: Agent Trust Model — content-from-agent treated as low-trust structured data, schema-validated. Web content = untrusted. Addresses prompt injection vulnerability in multi-agent pipelines.
- Section 20: Selective KB Retrieval (Three-Tier Memory Model) — always-loaded Tier 1 (indexes + LESSONS.md), on-demand Tier 2 (relevant rules + entity pages), search-only Tier 3 (sources + archive). Hard caps: wiki/index.md ≤ 200 lines.
- Section 22: Harness Assumption Decay Protocol — quarterly audit to prune scaffolding that compensates for model limitations already solved by newer models. Based on Anthropic engineering blog finding that harness assumptions decay with model capability.

**Significant changes to existing sections**:
- Section 6 (Agent Roles): KB Linter now has 8 mandatory lint rules (previously underdefined). Eviction policy specified: quality-score-ranked compaction before archive; never delete.
- Section 7 (Iteration Lifecycle): Pipeline redrawn as directed graph. SPEC-FLAW route (Evaluator → Planner) added. Pre-checking phase added between auditing and contracting.
- Section 8 (Communication Chain): Now six-file chain (spec, audit-report, acceptance-checklist, contract, execution-log, eval-report). `spec-feedback.md` and `escalation.md` as optional files.
- Section 12 (Knowledge Layer): Rule format upgraded with full temporal metadata fields (`status`, `created_at`, `invalidated_at`, `superseded_by`, `last_validated`).
- Section 5 (Config Files): `PROJECT.md` now includes `token_budget_per_session` and `token_budget_alert_pct`. `PROGRESS.md` includes token tracking fields.
- Section 15 (Quality Criteria): Added `evaluator-tool-use` and `reward-hacking-clean` as critical criteria to both research and commercial templates.
- Section 21 (Meta-Review): Added harness decay check and reward hacking frequency to meta-reviewer's analysis list.

**Sources that informed v2.0**:
- Anthropic Engineering: "Harness Design for Long-Running Apps" (2025) — sprint contract pattern, evaluator tool access, harness assumption decay
- Karpathy: LLM Wiki Architecture gist (2025) — three-tier memory model, scale threshold (~100 articles), index caps
- Zep/Graphiti (arXiv:2501.13956, 2025) — bi-temporal fact model, temporal invalidation
- Shopify Engineering: "Building Production-Ready Agentic Systems" (2025) — reward hacking taxonomy
- metaswarm: 18-agent framework (github.com/dsifry/metaswarm) — JSONL provenance log, adversarial DoD compliance checks
- InfoQ Production Playbook 2025 — hierarchical vs. flat comparison, token growth patterns
- Claude Code harness architecture (wavespeed.ai analysis) — three-tier memory, autoDream/KB-Linter parallel

## v1.0 — 2026-04 (initial)

Source: Internal commercial monorepo.
First formalization of: 5-agent adversarial pipeline, three-layer KB (Karpathy pattern), file-based inter-agent communication, wiki confidence levels, size caps, escalation protocols, cycle limits, meta-review cadence.
