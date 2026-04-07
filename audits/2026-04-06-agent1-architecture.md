# Architecture Validity Audit — Agent 1
**Date**: 2026-04-06 | **Verdict**: REVISE

## Verified Claims
- Generator ≠ Evaluator: Confirmed by Anthropic harness blog (self-praise behavior documented)
- Karpathy three-layer architecture: Confirmed — raw/ + wiki/ + schema/config layer. Blueprint's mapping (sources/→wiki/→knowledge/rules.md) is a reasonable adaptation.
- ~100 sources scale threshold: Confirmed in gist ("works surprisingly well at moderate scale (~100 sources)")
- arXiv:2501.13956 as Zep/Graphiti paper: Confirmed, exists, bi-temporal model described
- Self-preference bias in LLM self-evaluation: Confirmed (NeurIPS 2024, arXiv:2404.13076)
- Shopify reward hacking patterns (opt-out hacking, tag hacking, schema violation): Confirmed exact terms in post
- Prompt injection as real threat: Confirmed (OWASP LLM01:2025, arXiv:2410.07283)

## Disputed Claims

### HIGH severity

**"Validated against Anthropic Engineering (2025)"** — Post is dated March 2026, not 2025. "Harness assumptions decay" phrase NOT in source. Actual text: "those assumptions are worth stress testing...they can quickly go stale as models improve." Blueprint over-attributes.

**Blueprint bi-temporal model is incomplete vs. arXiv:2501.13956** — Zep paper uses FOUR timestamps: t'_created, t'_expired (transactional), t_valid, t_invalid (reality). Blueprint collapses t'_expired and t_invalid into single invalidated_at, losing bi-temporal distinction between "when we recorded it" and "when it was true in reality." Cannot represent retroactive corrections.

**"Harness Assumption Decay Protocol" — phrase not in Anthropic source** — Concept is real, attribution is to a third-party summary (understandingdata.com), not the primary Anthropic blog.

### MEDIUM severity

**"Quadratic token growth" + "50x cost"** — Not sourced to metaswarm. Figure appears in Stevens Institute economics blog referencing a Reflexion loop paper. With prompt caching (which Anthropic uses), cost does NOT grow quadratically. Blueprint presents this as universal without caching exception.

**"Three-Layer Karpathy Pattern" label** — Karpathy describes raw→wiki + schema/config. The knowledge/rules.md OBS→HYP→RULE promotion ladder is the blueprint's own invention. Calling it the Karpathy Pattern is brand-borrowing.

**~400K word threshold** — Not in Karpathy's gist. He mentions ~100 sources; the 400K word figure is an interpolation.

**Three-tier memory model is prompt-level convention** — Not enforced by Claude Code architecture. Subagents spawn with blank contexts. This is a discipline instruction to the LLM, not a structural guarantee.

**32% figure decontextualized** — Liu et al. (arXiv:2502.14282) PC-Eval benchmark, 25-task desktop GUI automation. Not a general multi-agent architecture study. InfoQ is a secondary source.

### LOW severity
**Shopify as architectural validator** — Shopify's post actually recommends AGAINST early multi-agent adoption ("Simple single-agent systems can handle more complexity than you might expect"). It validates reward hacking detection, not the pipeline sequence.

## Missing Architecture
1. **Error cascade amplification** — 17x error amplification in sequential pipelines (arXiv:2603.04474, Google DeepMind). 41–86.7% production failure rates. Blueprint has no cascade detection.
2. **Centralized control plane** — Centralized orchestrator suppresses 17x amplification. Blueprint's flat sequential pipeline has no centralized arbitration.
3. **Prompt caching** — Essential for multi-session cost control. Not mentioned.
4. **LLM-to-LLM prompt infection propagation** — Malicious prompts self-replicate across agents (arXiv:2410.07283). Schema validation insufficient against adversarially crafted content designed to survive schema checks.

## Structural Weaknesses
1. Size caps are unprincipled (no cited research basis)
2. SPEC-FLAW route creates unbounded audit cycle reset vulnerability
3. File-based state not race-condition safe for concurrent product runs
4. Contradiction resolution escalates too eagerly (Zep paper's actual approach uses temporal ordering for common cases)
5. Generator ≠ Evaluator too absolute — test suite pass/fail doesn't require structural separation

## Recommendations
- Fix Anthropic attribution date + wording
- Add 4th bi-temporal timestamp (transactional_expired_at)
- Rename Section 10 to "Two-Layer Karpathy Pattern + Process Learning Extension"
- Scope INVARIANT 1 with carve-out for mechanically verifiable outputs
- Fix SPEC-FLAW loop with global counter
- Contextualize 32% figure attribution
- Add cascade amplification note to Section 7
