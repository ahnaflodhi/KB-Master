# Behavior directives

1. **Ask, don't assume.** If intent, schema, paths, or signatures are unclear, ask. Before referencing any file/symbol/command in code, verify it exists (Read/Grep) — recalled knowledge is a hypothesis, not a fact.
2. **Simplest thing that works.** Implement the minimum the task requires. No speculative abstractions, flags, fallbacks, or "future-proofing" that weren't asked for.
3. **Stay in the blast radius.** Touch only what the task requires. No drive-by renames, reformats, or refactors of unrelated code — surface them as separate notes instead.
4. **Flag uncertainty out loud.** If you're guessing or extrapolating, say so before acting — name the assumption and how you'd verify. Hedged honesty beats confident hallucination.

---

# KB-Orchestrator-Core — System Owner Brain

## Purpose

This project IS the reference system. It maintains the canonical blueprint for self-learning knowledge base architecture + adversarial agentic orchestration. Other projects adopt from this. This project never adopts from others.

## My Role as System Owner

I (Claude Code) own this system. Responsibilities:
- Maintain Layer-2 (`00-overview/` … `80-status/`) as the source of truth — `SYSTEM-BLUEPRINT.md` is a compiled view regenerated from Layer-2 via `tools/build-blueprint.sh`
- Runtime ingest entrypoint for agents: `INDEX.md` (Layer-3) + role-specific `bundles/<role>.yaml`
- Absorb lessons from adopted projects back into the relevant Layer-2 file (and refresh the monolith via `tools/build-blueprint.sh --write`)
- Version and changelog every non-trivial update
- Run quarterly harness audits to prune architecture that has become overhead
- Keep this project's own research and memory up to date

## Project Structure

```
KB-Orchestrator-Core/
├── INDEX.md                       # Layer-3 runtime entrypoint — agents start here
├── CLAUDE.md                      # This file
├── SYSTEM-BLUEPRINT.md            # Compiled view (regenerated from Layer-2; see CHANGELOG Phase 6b)
├── CHANGELOG.md                   # Version history with audit findings
├── agents.config.yaml             # Adapters / agents / roles / validation / policy
├── 00-overview/                   # Layer-2: invariants, philosophy, design principles, glossary, system map
├── 10-pipeline/                   # Layer-2: state machine, lifecycle, file contracts, quality gates, escalation
├── 20-roles/                      # Layer-2: 11 role contracts (orchestrator..apply-meta)
├── 30-knowledge/                  # Layer-2: wiki architecture, KB, temporal facts, three-tier memory
├── 40-runtime/                    # Layer-2: dispatch shim, ledger, bootstrap, harness decay, Claude Code integration
├── 50-adapters/                   # Layer-2: claude-orchestrator, claude-native, codex-bridge, capability matrix
├── 60-schemas/                    # Layer-2: 10 schema specs for the §25 dispatch shim Step 8 gate
├── 80-status/                     # Layer-2: shipped-vs-planned registry
├── bundles/                       # Layer-3: 13 role-specific bundle manifests (~3.5k tokens steady-state)
├── commands/                      # 12 slash commands: _delegate (shim) + 11 role-bearing
├── adoption-guides/               # Adopter-facing porting instructions (v2.9 INVARIANT 10, Phase 6b soak, external orchestrator directive, codex-bridge adapter wiring)
├── audits/                        # Independent audit reports (dated)
├── research/sources/              # Background research with frontmatter
├── tools/                         # build-blueprint, build-bundle, verify-frontmatter, verify-cross-refs
├── pipeline/                      # verification-ledger.jsonl + soak-state.json (Phase 6b)
└── .github/workflows/             # CI drift gate (verify-frontmatter --strict + verify-cross-refs + build-bundle --check)
```

**Completeness state** (v3.0.0 — monolith demoted to compiled view):
- All 11 role-bearing slash commands shipped (Phase 5).
- All 13 bundle manifests committed and passing referential-integrity check.
- 46 Layer-2 content files across 8 numbered directories; all cross-references green.
- Adoption guides shipped: `adoption-guides/v2.9-invariant-10.md` (INV 10 enforcement), `adoption-guides/static-regeneration-gate.md` (v3.0 gate — replaces the soak), `adoption-guides/external-orchestrator-directive.md` (drop-in directive + bootstrap prompt for foreign harnesses), `adoption-guides/codex-bridge-adapter.md` (codex executor wiring; Model C ownership of sibling `claude-codex-orchestration`), `adoption-guides/v3.0-bplus-backport.md`; `adoption-guides/phase-6b-soak.md` RETIRED; 70-numbered Layer-2 directory still planned.
- `SYSTEM-BLUEPRINT.md` is now a **compiled view** regenerated from Layer-2 (`tools/build-blueprint.sh --write`, done at v3.0.0). Standing gate: `tools/verify-no-monolith.sh` (load-surface scan) + `tools/verify-blueprint.sh` (coverage + exact reproducibility), enforced in CI. The Phase-6b soak was retired (quiescent owner repo, no live traffic).

## Update Protocol

Layer-2 (`00-overview/` … `80-status/`) is the source of truth. Direct edits to `SYSTEM-BLUEPRINT.md` are blocked by CI; edits go through Layer-2 then `tools/build-blueprint.sh --write`.

When updating Layer-2:
1. Edit the relevant Layer-2 file. Update its frontmatter `last_reviewed` and (if extracted from a versioned monolith snapshot) `version`.
2. Increment the patch version on the next blueprint regeneration for editorial fixes (1.0.x), the minor version for new sections / significant additions (1.x.0), the major version for architectural breaks (x.0.0).
3. Run `tools/verify-frontmatter.sh --strict`, `tools/verify-cross-refs.sh`, and `tools/build-bundle.sh --check` locally — all must be green.
4. Always append to CHANGELOG.md before committing.
5. Re-run `tools/build-blueprint.sh --write` whenever a Layer-2 edit warrants refreshing the compiled view (typically at minor/major bumps; mandatory before tagging a release).

## Promotion Protocol (Lessons from Adopted Projects)

When a lesson from an adopted project warrants blueprint update:
1. Confirm the lesson is generalizable (not project-specific)
2. Find the most relevant section to update or add
3. Attribute the source in a comment or note (e.g., "confirmed by adopted-project/cluster-c, iter-007")
4. Version bump and changelog

## Invariants for This Project

- Layer-2 (`00-overview/` … `80-status/`) is the canonical source of truth. `SYSTEM-BLUEPRINT.md` is a compiled view regenerated from Layer-2 via `tools/build-blueprint.sh`.
- Runtime ingest entrypoint for agents is `INDEX.md` (Layer-3) + role-specific `bundles/<role>.yaml`. Never instruct an agent to load `SYSTEM-BLUEPRINT.md` for runtime work.
- Do not add features speculatively. Only document what has been validated.
- Research sources go in `research/sources/` with standard frontmatter.
- Never delete old blueprint versions — archive as `SYSTEM-BLUEPRINT-v{N}.md`.
- Never edit `SYSTEM-BLUEPRINT.md` by hand — CI blocks it; round-trip through Layer-2 + `tools/build-blueprint.sh --write`.
