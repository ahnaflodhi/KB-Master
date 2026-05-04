# 40-runtime/ — Runtime semantics

This directory documents the runtime layer of the architecture: the dispatch shim that every delegated invocation flows through, the verification ledger that records every consume verdict, the bootstrap and graceful-degradation protocol the orchestrator follows at session start, the harness-decay protocol that retires scaffolds when they no longer earn their cost, and the Claude Code harness specifics that adopters need to wire up.

For frontmatter conventions see `00-overview/_README.md`. Per-directory cap for `40-runtime/*` is 180 lines per file.

## Index

| File | Purpose | Source |
|---|---|---|
| [dispatch-shim.md](dispatch-shim.md) | The 11-step LOAD → PROBE → PREPARE → DISPATCH → AWAIT → FETCH → AUTH → SCHEMA → VERIFY → CONSUME → STATE sequence | §25 Dispatch shim subsection |
| [verification-ledger.md](verification-ledger.md) | Append-only `pipeline/verification-ledger.jsonl` schema + two-gate verification model (auth + verification) | §19 v2.8 addendum + §25 Verification mechanism subsection |
| [bootstrap-and-degradation.md](bootstrap-and-degradation.md) | Session-start bootstrap, adapter probe failures, graceful fallback per role; v2.10 host-access degradation pattern | §25 Bootstrap and graceful degradation + v2.10 subsection |
| [harness-decay.md](harness-decay.md) | The §22 protocol: `compensates_for` + `evidence_threshold` per scaffold; RETAIN / DOWNGRADE / ARCHIVE cadence | §22 Harness Assumption Decay Protocol |
| [claude-code-integration.md](claude-code-integration.md) | Folder-specific CLAUDE.md hierarchy, hooks protocol, permission modes, MCP memory deprecation lifecycle | §24 Claude Code harness integration |

## Why these five files

The role contracts (`20-roles/`) and adapter contracts (`50-adapters/`) describe the actors. The runtime layer here describes the **mechanics** that bind them at session time:

- An adopter wiring up a new project reads `dispatch-shim.md` to understand what every slash command is composing.
- An adopter debugging a failed delegation reads `verification-ledger.md` to interpret the consume row's verdict fields.
- An adopter onboarding to a partial-adapter environment reads `bootstrap-and-degradation.md` to know what happens when codex-bridge isn't on PATH.
- A long-lived project runs `harness-decay.md`'s protocol on cadence to prevent scaffold accumulation.
- A Claude Code adopter (most common today) reads `claude-code-integration.md` for hook setup, MCP memory protocol, and permission-mode guidance.

## What NOT to put in 40-runtime/

- Per-role mandate (lives in `20-roles/<role>.md`).
- Per-adapter contract (lives in `50-adapters/<adapter>.md`).
- File schemas (live in `60-schemas/<file>.md`).
- KB structure (lives in `30-knowledge/`).
- Pipeline state machine (lives in `10-pipeline/state-machine.md`).

This directory describes the *runtime mechanism*, not the actors or the data shapes.

---
