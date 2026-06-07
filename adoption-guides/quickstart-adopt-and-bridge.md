# Quickstart — adopt the framework + wire the Claude–Codex bridge

A single drop-in prompt to hand another agent so it can adopt KB-Orchestrator-Core
into its project and wire Codex as an executor. It points at the canonical guides
rather than restating their internals, so it stays correct as those guides evolve.

**Pin:** `v3.2.0`. **Deeper guides:** `external-orchestrator-directive.md` (directive +
bootstrap prompt), `codex-bridge-adapter.md` (Codex wiring). **Runtime entrypoint:** `INDEX.md`.

## The prompt

```
You are adopting the KB-Orchestrator-Core framework (orchestration + self-learning
KB + adversarial agentic pipeline) into THIS project, and wiring the Claude–Codex
bridge so Codex can run as an executor. Work in order; verify each step before the next.

SOURCE OF TRUTH
- Upstream repo: git@github.com:ahnaflodhi/KB-Master.git  — pin to tag v3.2.0.
- Read, in this order: README.md §"Quick Start" + §"Vendoring for external orchestrators",
  then adoption-guides/external-orchestrator-directive.md (drop-in directive + bootstrap
  prompt), then adoption-guides/codex-bridge-adapter.md (Codex wiring).
- Runtime entrypoint is INDEX.md + bundles/<role>.yaml. NEVER load SYSTEM-BLUEPRINT.md
  at runtime — it is a compiled view, not a source. Layer-2 (00-overview/…80-status/) is canonical.

ADOPT (framework)
1. Vendor upstream at tag v3.2.0 (sparse-checkout or submodule per README), into e.g. vendor/kb-orc/.
2. REGISTER COMMANDS: the vendored commands/ are specs, NOT invokable. Create .claude/commands/
   and symlink/copy commands/*.md there — else /plan, /wiki-ingest, /wiki-query, /_delegate
   are not callable. (Most common adoption miss.)
3. Run the post-vendoring smoke test (README §"Post-vendoring smoke test"): verify-frontmatter
   --strict, verify-cross-refs, build-bundle --check, verify-no-monolith, AND verify-config (config +
   pipeline_state completeness — catches the most common migration gaps) all exit 0; init pipeline/verification-ledger.jsonl
   (empty) and PROGRESS.md (pipeline_state: idle, per 60-schemas/progress.md); dry /plan iteration
   must emit a DISPATCH row (Step 4) + CONSUME row (Step 10); a state-mutating call WITHOUT the
   four-fact INV 10 block must be rejected.
4. Add the upstream directive + a one-line "downstream consumer" acknowledgment to your CLAUDE.md
   (external-orchestrator-directive.md §"Patterns A/B").

WIRE THE CLAUDE–CODEX BRIDGE
5. Install per codex-bridge-adapter.md §2 — Path A (copy codex_scaffold/ in), Path B (global $PATH),
   or Path C (CODEX_BRIDGE env). Canonical impl: git@github.com:ahnaflodhi/claude-codex-orchestration.git
   — clone it alongside KB-Orchestrator-Core; its codex_scaffold/bin/codex-task-bridge probes at protocol 2.
6. Set agents.config.yaml adapters.codex-bridge.binary_path to the installed bridge. Stock role
   bindings: codex-audit→truthsayer, codex-eval→evaluator (§3). For a Codex research/eval stream,
   declare a codex executor agent explicitly.
7. Confirm INV 10 enforcement mode (§4) and run the §7 adopter sanity check.
8. If the bridge binary is absent, the contract-sanctioned DEGRADED path is direct `codex exec`
   (§5) — fully usable; just record adapter_degraded in the DISPATCH ledger row.

NON-NEGOTIABLES (cannot be relaxed)
- INV 9: orchestrator role is non-delegable; it alone writes PROGRESS.md, the ledger, escalation.md,
  dispatch decisions.
- INV 10: emit the four-fact block before any state-mutating action.
- INV 11: load minimum-viable context per role via bundles (or a substitute you record); never the
  monolith; record context_sources in every DISPATCH row.
- Every dispatch + every consume appends a row to pipeline/verification-ledger.jsonl. Knowledge
  writes go through /wiki-ingest, reads through /wiki-query — never edit wiki/ directly.
- Do not invent roles or bypass the 11-step shim (commands/_delegate.md). When unsure, re-read INDEX.md.

DELIVERABLE: report the smoke-test results, the bridge install path + sanity-check output, and the
first ledger DISPATCH/CONSUME rows. Flag any step that did not pass rather than proceeding.
```

## Two honest caveats for the operator

- The prompt cites the canonical guides instead of duplicating them — keep those guides current.
- Upstream `agents.config.yaml` sets `binary_path: ../claude-codex-orchestration/codex_scaffold/bin/codex-task-bridge` — this is CORRECT when the bridge repo (`git@github.com:ahnaflodhi/claude-codex-orchestration.git`) is cloned alongside KB-Orchestrator-Core: the binary is present there and its `version`/`capabilities` probes return protocol 2 (no codex auth needed). Adopters who install the bridge elsewhere (Path A/B/C) update `binary_path` to match. Only if the binary cannot be resolved does the adapter fall back to the contract-sanctioned **degraded `codex exec`** path (step 8).

## Cross-references

- `README.md` — Quick Start + vendoring + post-vendoring smoke test
- `adoption-guides/external-orchestrator-directive.md` — drop-in directive + bootstrap prompt
- `adoption-guides/codex-bridge-adapter.md` — Codex executor wiring (install, §3 config, §4 INV 10, §5 degradation, §7 sanity check)
- `INDEX.md` — runtime entrypoint
- `60-schemas/progress.md` — PROGRESS.md schema (bootstrap state)
