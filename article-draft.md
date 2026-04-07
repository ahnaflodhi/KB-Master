# We Read Karpathy's KB Gist. Then We Added the Part That Actually Keeps It Honest.

*A complete guide to orchestrating a self-learning, adversarial knowledge base for any project — research, commercial, or anything in between — at any stage of development.*

---

222,000 people viewed the @godofprompt breakdown of Karpathy's LLM knowledge base pattern this week.

Karpathy's original tweet drew 95,000 X bookmarks and 17 million views. The GitHub gist he dropped two days later hit 5,000+ stars and 1,400+ forks.

Most will never build it.

And the ones who do build it will hit a wall around week six that nobody warned them about.

This is that warning — and the architecture that solves it.

---

## What Karpathy Got Right (And Why You Should Build It)

Karpathy's insight is genuinely important: instead of searching raw documents every time you ask a question, let the LLM compile a structured wiki once — entity pages, cross-references, synthesis — then query the wiki.

Knowledge compounds instead of resetting.

The two-layer pattern he describes:

```
raw/      ← immutable source documents (LLM reads, never writes)
wiki/     ← LLM-compiled markdown wiki (LLM owns entirely)
```

A single ingest cycle reads a source, creates or updates 10-15 wiki pages, adds cross-references, flags contradictions, and logs the work. Every new source makes existing pages richer. Every question you ask can be filed back in.

This is correct. It works. At ~100 sources with a well-maintained index, it works without any vector database or embeddings.

Build this foundation. It is the right starting point.

---

## Where It Breaks (The Part Nobody Covers)

Karpathy himself called the pattern "a hacky collection of scripts." The failure modes are real, and patching them with best-effort prompts doesn't hold.

**Error compounding**: The AI writes a wiki page with a subtle mistake. You file a query answer back. Now two pages reinforce the same error. Monthly linting helps, but the AI running the lint has the same blind spots as the AI that made the error.

**Sycophancy**: A single-agent system has no adversarial pressure. The same context that wrote the wiki also evaluates it. There is no structural challenge — only the agent's self-assessment of its own work.

**Spec drift**: When you start building on top of your knowledge base, there is no mechanism to ensure what gets built matches what was agreed. The spec exists as a chat message. By execution day three, it's reinterpreted.

**Reward hacking**: Agents optimise for satisfying the evaluator's surface checks. A wiki page that *looks* well-cited isn't the same as one that *is* well-sourced. Without independent verification, these are indistinguishable.

**Context blindspots**: LLMs deprioritize information in the middle of long context windows — the "lost in the middle" effect (Liu et al., 2023). Bulk-loading the entire wiki means the facts you most need are often exactly where attention is weakest.

The basic Karpathy pattern solves the compounding problem. It doesn't solve any of these five.

---

## The Architecture We Built On Top

**KB-Orchestrator-Core** is a canonical blueprint that takes the Karpathy foundation and adds the structural layer that makes it production-safe.

The full blueprint lives at [github.com/ahnaflodhi/KB-Master](https://github.com/ahnaflodhi/KB-Master). Pass `SYSTEM-BLUEPRINT.md` to any agent on any project. The agent adopts applicable components based on project state, type, and scale.

Here is what we added and why.

---

## Addition 1: Two Separate Artifacts That Compound

Karpathy's pattern has one compounding artifact: the wiki (what you know about the domain).

We split this into two:

**The Wiki (`wiki/`)**: What is known about the subject domain. Built during research, maintained during build. Every page has a source citation, a confidence level, and a timestamp. Cross-references between entities are the primary value — not individual page depth. Never degrades — only gets richer.

**The Knowledge Base (`knowledge/`)**: What the *team* has learned about how to build *this project*. This is the part the basic pattern entirely misses.

The knowledge layer tracks process learning:

```
Observation (OBS-NNN)     ← raw: "API rate limits caused 3 failures in iter-004"
      ↓  2+ occurrences
Hypothesis (HYP-NNN)      ← pattern: "rate limits are bottleneck for ingestion speed"
      ↓  3+ confirmations
Confirmed Rule (RULE-NNN) ← "batch API calls with 500ms delay between requests"
```

Rules are capped (max 20 per domain) to stay dense. They carry full temporal metadata — when confirmed, when last applied, when invalidated. Old rules are marked `invalidated_at`, never deleted.

By iteration 10, the system doesn't just know your domain. It knows how to run your project.

---

## Addition 2: Generator ≠ Evaluator (Structural Separation)

This is the single most important structural change.

In the basic Karpathy pattern, one agent ingests, queries, lints, and evaluates. The agent that produced the wiki also judges its quality. That is not evaluation — it is self-congratulation.

Our pipeline enforces a hard structural separation:

```
Planner    → writes spec.md
TruthSayer → adversarial review (finds what is wrong, weak, missing)
Pre-Check  → signs acceptance criteria BEFORE execution begins
Executor   → produces output
Evaluator  → independently verifies using tools (not just reading files)
KB Linter  → post-iteration knowledge maintenance
```

**Generator ≠ Evaluator** is an invariant. It cannot be overridden by task context, time pressure, or instruction. The agent that produces output is never the same invocation that evaluates it.

The TruthSayer's mandate: *"Find what is wrong, weak, or missing. Not here to praise."* A TruthSayer that consistently approves is malfunctioning.

The Evaluator's mandate: run tools, not just read files. For commercial projects: run the test suite, invoke linters, use browser automation. For research: fetch cited URLs and verify claims exist at source. An evaluation without tool use produces a `CONDITIONAL PASS`, not a `PASS`.

This one structural change eliminates sycophancy entirely.

---

## Addition 3: Sprint Contract Before Execution

The most common convergence failure in multi-agent systems is the Planner and Evaluator working from different implicit understandings of the spec.

The Planner writes the spec. The Executor builds it. The Evaluator judges it. If the Evaluator re-interprets the spec at judgment time, the Executor can be marked failed for work that correctly matched the original intent.

Our fix: before execution begins, the Pre-Check Evaluator reads the spec and writes a concrete acceptance checklist. The Executor cannot write a single line of code or a single wiki page without:

1. A signed `contract.md` in `iterations/current/`
2. An Evaluator-signed `acceptance-checklist.md` with no unresolved ambiguities

The Evaluator's later judgment must reference this signed checklist — not re-interpret the original spec.

This eliminates non-convergence. In our first commercial adoption run, three of five evaluation failures traced back to spec ambiguities that pre-check would have caught before a single line of code was written.

---

## Addition 4: Temporal Facts, Never Silent Overwrites

In the basic KB pattern, when you discover that an old fact is wrong, you update the wiki page. The old claim disappears. No trace.

This is a problem.

When the system is reading the wiki to inform a new decision, it has no way to know whether a fact was always true, recently updated, or contradicted by new evidence. The wiki looks equally authoritative for all three.

Our approach: **facts are invalidated, never deleted**.

Every confirmed rule carries four timestamps:

```yaml
created_at: iter-004 (2026-04-01)
confirmed_iterations: 7
invalidated_at: null
superseded_by: null
```

When contradicting evidence is found:

```yaml
# Old rule
status: invalidated
invalidated_at: iter-018 (2026-04-15)
superseded_by: RULE-022

# New rule
status: active
created_at: iter-018 (2026-04-15)
source_hypotheses: [HYP-009]
```

The KB is an audit trail, not a current-state snapshot.

Contradictions between equal-confidence claims get flagged, categorized by severity, and either auto-resolved (if one source clearly postdates the other) or escalated to human review.

---

## Addition 5: Three-Tier Context Loading (Lost-in-the-Middle Defense)

LLMs deprioritize information in the center of long context windows. Loading the full KB means your most critical facts are often buried exactly where attention is lowest.

The three-tier model ensures every agent loads exactly what it needs:

```
TIER 1 — always loaded, always at top of context:
  wiki/index.md        (200-line hard cap)
  knowledge/INDEX.md   (100-line domain index)
  LESSONS.md           (last 25 entries only)

TIER 2 — loaded on demand, by role:
  knowledge/{domain}/rules.md  (only domains relevant to current task)
  wiki/entities/{entity}.md    (only entities in current spec)

TIER 3 — search only, never bulk-loaded:
  sources/             (LLM searches specific files by name)
  iterations/archive/  (meta-review only)
```

Each agent role has a defined loading procedure. The Planner always loads methodology rules. The Executor loads only entity pages named in the current spec's Decomposition list. The Evaluator loads the acceptance checklist and output entities.

No agent ever loads the full wiki. The index tells you what exists. You load what the current task needs.

---

## Addition 6: Claude Code Native Harness

The system is built to run natively in Claude Code with hooks that enforce invariants at the harness level — not just at the instruction level.

**Source immutability hook**: A `PreToolUse` hook blocks any write to an existing file in `sources/`. INVARIANT 8 (save sources before extracting claims) cannot be bypassed by the model, regardless of instruction.

**Escalation notification hook**: A `PostToolUse` hook fires a system notification when `escalation.md` is written, so the human knows immediately that manual review is needed.

**Permission modes per phase**: Planning and auditing run in `plan` mode (read-only). Execution runs in `acceptEdits` (auto-approve file writes, prompt on shell commands). Unattended `./iterate.sh` pipeline runs use `auto` mode — a background safety classifier approves routine actions and blocks scope escalation.

**MCP memory for cross-project learning**: Confirmed rules that generalise across multiple projects are stored in the MCP memory server with semantic tags. Every new project session searches memory for relevant cross-project rules before reading any project files. The system learns not just within a project, but across your entire portfolio.

---

## How to Adopt This at Any Stage

### Starting from scratch

```bash
# 1. Clone the reference
git clone https://github.com/ahnaflodhi/KB-Master

# 2. Copy the blueprint to your project
cp KB-Master/SYSTEM-BLUEPRINT.md your-project/

# 3. Tell Claude Code to scaffold
# "Read SYSTEM-BLUEPRINT.md. Scaffold this as a [research|commercial|hybrid] project.
#  Primary objective: [your goal]. Run /onboard."

# 4. Initialize git immediately
git init && git add . && git commit -m "initial scaffold"

# 5. Run your first iteration
./iterate.sh 'Sprint 1 goal'
```

### Adopting mid-project (your project already exists)

The system is designed to be adopted incrementally. You don't need everything at once.

**Phase A — Minimum structure** (30 minutes):
- Create `PROJECT.md` with project_type and primary_objective
- Create `PROGRESS.md` with `pipeline_state: idle`
- Create `wiki/index.md` and `wiki/log.md` (empty is fine)
- Create `knowledge/gaps/knowledge.md` — list every unverified assumption you're currently operating on

**Phase B — Wire the adversarial agents** (2 hours):
- Add `.claude/commands/` with at minimum: `plan.md`, `audit.md`, `pre-check.md`, `execute.md`, `evaluate.md`, `kb-lint.md`
- Copy `pre-check.md` from the reference repo as your starting template
- Initialize git: `git init && git add . && git commit -m "adopt KB-Orchestrator scaffold"`

**Phase C — Backfill the wiki** (ongoing):
- Run `/wiki-ingest` on existing source documents
- For each assumption currently in the project: create an entity page with SINGLE-SOURCE confidence

**Phase D — Stabilize** (after 3 iterations):
- Run `/meta-review` to calibrate thresholds
- Identify which agent is causing the most rework and adjust that prompt first

### Absolute minimum (if full adoption isn't feasible)

Three elements. In this order. They eliminate 80% of the failure modes documented in production:

1. **File-based iteration state**: `iterations/current/` with `spec.md` + `eval-report.md`. Prevents drift. Enables review.
2. **Generator ≠ Evaluator**: Even manually — review your own spec from an adversarial lens before executing.
3. **Claim confidence tracking**: Inline citations + `unverified/` folder. Prevents hallucination laundering.

---

## The Honest Part: Where Our System Also Breaks

In the spirit of Karpathy (who called his own work "a hacky collection of scripts"), here is where our system has its own ceiling.

**Setup overhead is real**: The full pipeline — Planner, TruthSayer, Pre-Check, Executor, Evaluator, KB Linter — is six agent invocations per iteration. For a 30-minute task, this is overkill. The Minimum Viable Adoption path exists for a reason.

**The adversarial agents can deadlock**: TruthSayer and Evaluator can enter revision cycles that consume tokens without convergence. The cycle limits (2 for audit, 3 for evaluation) and escalation triggers are the structural response, but they're only as good as the prompts behind them. Badly written agent commands will hit these limits constantly.

**Cross-project MCP memory requires discipline**: The memory server is only as good as what you store. A team that never stores confirmed cross-project rules gets no compounding benefit. The session-start search ritual only works if the store has been maintained.

**The blueprint itself can go stale**: Models improve. Scaffolding that compensated for a 2025 model limitation may be overhead by 2027. Section 22 (Harness Assumption Decay) defines a quarterly audit protocol for exactly this reason — but someone has to run it.

---

## Get the Blueprint

Everything described in this article is in the open-source reference repo:

**[github.com/ahnaflodhi/KB-Master](https://github.com/ahnaflodhi/KB-Master)**

What's there:
- `SYSTEM-BLUEPRINT.md` — the full 24-section canonical reference
- `commands/pre-check.md` — the canonical Pre-Check Evaluator slash command (starting template for all other commands)
- `audits/` — three independent adversarial audit reports of the blueprint itself
- `research/sources/` — the Karpathy deep research and source library
- `suggestions/pending.md` — how to submit improvements from your own project runs

The blueprint is designed to be passed directly to an agent. The agent reads it and adapts what applies to your project.

---

*The system described here is v2.6 of an actively maintained blueprint. Improvements from production adoption runs are accepted via the suggestions protocol in the repo.*

---

**Sources & attribution**

- Andrej Karpathy — LLM Knowledge Base Architecture (GitHub Gist, April 2026)
- @godofprompt — "Karpathy's second brain: how to build it" (X/Twitter, April 7 2026, 222K views)
- Liu et al. (2023) — "Lost in the Middle: How Language Models Use Long Contexts" — NeurIPS 2023
- Zep / Graphiti (arXiv:2501.13956) — bi-temporal knowledge graph, four-timestamp model
- Anthropic Engineering (March 2026) — sprint contract pattern, harness assumption decay
- Google DeepMind (arXiv:2603.04474) — error cascade amplification in sequential pipelines
- OWASP LLM Top 10 (2025) — prompt injection (LLM01), vector weaknesses (LLM08)
- Shopify Engineering (2025) — reward hacking taxonomy
