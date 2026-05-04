---
id: 40-runtime/claude-code-integration
title: Claude Code Harness Integration
purpose: runtime-spec
audience:
  - orchestrator
also_needed_by:
  - planner
  - executor
  - kb_linter
  - meta_review
status: stable
version: 2.10
last_reviewed: 2026-05-04
extracted_from:
  source: SYSTEM-BLUEPRINT-v2.10.md
  sections: ["§24 Claude Code Harness Integration"]
  line_range_hint: "synthesis: §24 verbatim — folder-specific CLAUDE.md hierarchy + hooks protocol + permission modes + MCP memory deprecation lifecycle + session-level context management"
depends_on:
  - 00-overview/invariants.md
  - 50-adapters/claude-orchestrator.md
  - 50-adapters/claude-native.md
related:
  - 40-runtime/dispatch-shim.md
  - 40-runtime/bootstrap-and-degradation.md
max_lines: 180
directives:
  must_count: 5
  should_count: 6
  may_count: 2
---

## Claude Code Harness Integration

This file documents the Claude-Code-specific wiring an adopter needs to do. Other harnesses (Claude Agent SDK, Cursor, Codex CLI, custom shells) implement equivalent mechanisms or substitute MCP servers — see the relevant adapter file for non-Claude-Code paths.

### Folder-specific CLAUDE.md hierarchy

Claude Code reads `CLAUDE.md` from every parent directory of the current working file, plus the project root. This architecture uses that to scope context per work area:

| File | Audience | Cap |
|---|---|---|
| `CLAUDE.md` (project root) | Orchestrator + every role | ≤ 200 lines — System Owner Brain (this project's own) |
| `wiki/CLAUDE.md` | Wiki Ingester + Wiki Querier | ≤ 200 lines — wiki schema, frontmatter, claim-promotion rules |
| `wiki/<cluster>/CLAUDE.md` | Cluster-specific | ≤ 200 lines — per-cluster conventions |
| `knowledge/CLAUDE.md` | KB Linter + Meta-Review | ≤ 200 lines — KB caps (30/15/20), promotion thresholds, temporal-fact protocol |
| `iterations/current/CLAUDE.md` | Per-phase actor | ≤ 200 lines — phase-specific reminders |

Use `@<path>` syntax inside any CLAUDE.md to import another file (chain resolution). Keep each file under 200 lines so the Tier-1 always-loaded context budget stays bounded (§20 lost-in-the-middle guidance applies).

### Hooks protocol

Hooks live in `.claude/settings.local.json` (project) or `~/.claude/settings.json` (user). Three mandatory hooks for this architecture:

| Event | Hook | Purpose |
|---|---|---|
| `PreToolUse` | gateguard skill | Invariant 10 fact-presentation gate — blocks Bash/Edit/Write/MultiEdit/NotebookEdit/Task/WebFetch (outside sources/)/mcp:write until the orchestrator emits the user-visible 4-fact block |
| `PreToolUse` (Bash specifically) | Inv-8 source-save check | refuses WebFetch/WebSearch outputs that are not first written to `sources/research/iter-NNN/` |
| `PostCompact` | context-reinforcement | re-injects PROGRESS.md + LESSONS.md into the post-compaction context so pipeline state survives compaction |

Optional but recommended hooks:
- `PreToolUse` for Edit/Write: enforces the per-file 4-fact block
- `Notification` for escalation: pages the human when `iterations/current/escalation.md` is written
- `PostToolUse` for Bash: appends every Bash call to `iterations/current/execution-log.md` if the dispatched role is the executor

### Permission modes by pipeline phase

| Phase | Recommended Claude Code permission mode |
|---|---|
| Phase 1 Plan | `read-only` (Planner only writes spec.md via orchestrator's CONSUME) |
| Phase 2 Audit | `read-only` |
| Phase 3 Pre-Check | `read-only` |
| Phase 4 Contract | `read-only` (Planner re-engaged briefly) |
| Phase 5 Execute | `workspace-write` (Executor needs Bash/Edit/Write within project) |
| Phase 6 Evaluate | `read-only` for static checks; `workspace-write` if Evaluator needs to run tests |
| Phase 7 KB-Lint | `workspace-write` (KB Linter promotes findings → hypotheses → rules) |
| Phase 8 Archive | host shell (orchestrator-only; archives `iterations/current/` to `iterations/archive/iter-NNN/`) |

Switch via `--allowedTools` per `claude -p` call when invoking workers, or via the `/permissions` command interactively. Per §25 the sandbox MUST always be passed explicitly at dispatch time.

### Session-level context management

- Use `/clear` between phases when context-heavy work is complete and the next phase needs a clean slate. PROGRESS.md, LESSONS.md, and the active iteration files survive — only the conversation context resets.
- Use `--allowedTools` per `claude -p` call to scope subagent permissions tighter than the parent session.
- Slash commands MUST live in `.claude/commands/` (project) or `~/.claude/commands/` (user). Project-level commands take precedence.
- The `commands/_delegate.md` shim (Phase 5) is a non-user-invokable meta-command — other commands compose it via `@.claude/commands/_delegate.md` reference at the top of their body.

### MCP server recommendations by project type

| Project type | Required | Recommended | Optional |
|---|---|---|---|
| Research project | `memory`, `playwright` (for UI-bearing research) | `github` (for repo-bearing research) | `cloudflare` (deployment), `qmd` (Quarto authoring) |
| Commercial project | `memory`, `playwright` (E2E testing), `github` | `cloudflare` (deployment) | `qmd` |

`memory` is required for cross-session persistence (LESSONS.md is project-scoped; MCP memory is cross-project). `playwright` is required for any project that ships UI — it lets the Evaluator (Invariant 7) run real browser tests rather than static-only evaluation.

### MCP memory protocol

Memory entries follow this lifecycle:

```
active   → in-use; loaded at session start per `also_needed_by` tags
deprecated → past-tense; still readable but flagged as stale; 30-day grace period
deleted  → removed; specification recorded in meta/audit-YYYY-MM-DD.md before deletion
```

Tagging schema (every memory entry):

```yaml
scope: cross-project | project-only
project: <project-name>     # only when scope=project-only
created_at: <ISO-8601>
deprecated_at: <ISO-8601>   # null until deprecated
related_files: [<path>...]  # for change-impact analysis
```

`memory_cleanup` cadence: same as harness decay — `min(25 iterations, 6 months)`. Every cleanup pass MUST be checklist item 11 of the meta-audit (per §24).

### What this integration does NOT do

- MUST NOT bypass the gateguard skill via `--no-hooks` or equivalent flags.
- MUST NOT mutate `.claude/settings.local.json` mid-session without recording the change in `iterations/current/execution-log.md`.
- MUST NOT load CLAUDE.md files larger than 200 lines (the §20 Tier-1 cap applies — split if you need more).
- MUST NOT delete an MCP memory entry without first deprecating it for the 30-day grace period.
- MUST NOT register a PreToolUse hook that is not idempotent — hooks may fire twice on retried tool calls.

### Cross-references

- Adapter that uses this harness: `50-adapters/claude-orchestrator.md`, `50-adapters/claude-native.md`
- Hook-equivalent mechanism for non-CC harnesses: `40-runtime/bootstrap-and-degradation.md`
- Three-tier memory model that bounds CLAUDE.md sizes: `30-knowledge/three-tier-memory.md` (planned)

---
