# KB-Orchestrator-Core — System Owner Brain

## Purpose

This project IS the reference system. It maintains the canonical blueprint for self-learning knowledge base architecture + adversarial agentic orchestration. Other projects adopt from this. This project never adopts from others.

## My Role as System Owner

I (Claude Code) own this system. Responsibilities:
- Maintain SYSTEM-BLUEPRINT.md as the authoritative reference (never let it stagnate)
- Absorb lessons from adopted projects back into the blueprint
- Version and changelog every non-trivial update
- Run quarterly harness audits to prune architecture that has become overhead
- Keep this project's own research and memory up to date

## Project Structure

```
KB-Orchestrator-Core/
├── CLAUDE.md                      # This file
├── SYSTEM-BLUEPRINT.md            # Canonical v2.x reference
├── CHANGELOG.md                   # Version history with audit findings
├── audits/                        # Independent audit reports (dated)
│   └── YYYY-MM-DD-agent{N}-{lens}.md
├── commands/                      # Canonical slash command definitions
│   └── pre-check.md               # ← only this exists; others are stubs to be written
│   [plan.md, audit.md, execute.md, evaluate.md, kb-lint.md, wiki-ingest.md,
│    wiki-query.md, escalate.md, meta-review.md, apply-meta.md — to be written
│    from the role descriptions in Sections 6 and 9 of SYSTEM-BLUEPRINT.md]
├── templates/                     # Copy-paste scaffolds — to be populated
├── research/                      # Background research and source analysis
│   └── sources/
└── adoption-guides/               # Scenario-specific porting instructions — to be populated
```

**Honest completeness state**: Only `pre-check.md` is written as a canonical command. The remaining 11 command files need to be written from the Section 6 and 9 descriptions. Templates and adoption guides directories are scaffolded but empty. This is tracked as a known gap — see CHANGELOG v2.1 "Unresolved items."

## Update Protocol

When updating SYSTEM-BLUEPRINT.md:
1. Increment the patch version for editorial fixes (1.0.x)
2. Increment the minor version for new sections or significant additions (1.x.0)
3. Increment the major version for architectural breaks (x.0.0)
4. Always append to CHANGELOG.md before committing

## Promotion Protocol (Lessons from Adopted Projects)

When a lesson from an adopted project warrants blueprint update:
1. Confirm the lesson is generalizable (not project-specific)
2. Find the most relevant section to update or add
3. Attribute the source in a comment or note (e.g., "confirmed by adopted-project/cluster-c, iter-007")
4. Version bump and changelog

## Invariants for This Project

- SYSTEM-BLUEPRINT.md is the canonical document. Other files exist to serve it.
- Do not add features speculatively. Only document what has been validated.
- Research sources go in research/sources/ with standard frontmatter.
- Never delete old blueprint versions — archive as SYSTEM-BLUEPRINT-v{N}.md.
