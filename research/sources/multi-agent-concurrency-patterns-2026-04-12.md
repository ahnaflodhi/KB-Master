---
name: Multi-agent concurrency patterns for wiki editing
type: reference
researched: 2026-04-12
primary_sources:
  - https://purplehorizons.io/blog/tick-md-multi-agent-coordination-markdown
  - https://claude.com/blog/multi-agent-coordination-patterns
  - https://gist.github.com/rohitg00/2067ab416f7bbe447c1977edaaa681e2
  - https://arxiv.org/pdf/2510.18893
---

# Multi-Agent Concurrency Patterns for Wiki Editing

## tick-md: File-Based Task Coordination

Open-source protocol (MIT). Single TICK.md file as source of truth. Git-tracked.

Key mechanisms:
- **File locking**: when agent claims a task, file is locked to prevent concurrent edits
- **Claim-execute-release cycle**: agent claims → works → marks done → dependents auto-unblock
- **Append-only history**: every state change recorded with timestamps and authors
- **MCP server integration**: Claude, other MCP-compatible agents can read/write tasks natively
- **Dependency tracking**: tasks can block other tasks; completion auto-unblocks

Production bugs fixed in v1.2.0: race conditions, circular dependency edge cases, YAML parsing issues.

## Anthropic's Five Coordination Patterns

1. **Generator-Verifier**: one produces, one evaluates against criteria
2. **Orchestrator-Subagent**: lead plans, delegates bounded subtasks
3. **Agent Teams**: persistent workers claim from shared queue, accumulate context
4. **Message Bus**: event-driven pub/sub through central router
5. **Shared State**: all agents read/write persistent store directly, no coordinator

For wiki editing specifically:
- Agent Teams pattern is most relevant — agents claim wiki pages from a work queue
- Shared State is the simplest but needs "locking, versioning, partitioning" for concurrent writes
- Two failure modes identified: concurrent writes on same file, incompatible changes across files

## rohitg00's mesh sync pattern

From LLM Wiki v2:
- **Timestamp-based conflict resolution**: last-write-wins for most cases
- **Manual override** for genuine conflicts
- **Scope management**: distinguish personal (private) from team (shared) knowledge

## CRDT approaches

CodeCRDT (arXiv 2510.18893): Multi-agent LLM code generation using CRDTs
- Strong eventual consistency guaranteed
- Deterministic conflict resolution
- No character-level data loss
- BUT: plain-text CRDTs don't handle Markdown formatting well under concurrent edits (Peritext paper, Ink & Switch)

## Synthesis for our blueprint

Our blueprint has multiple agents (Planner, Executor, KB Linter, Wiki Ingester) writing to wiki/ across iterations. Current gap: we do not specify how conflicts are prevented or resolved.

Recommended pattern for our context (sequential iterations, not true real-time collaboration):
1. **Page-level file locking** (simplest, sufficient for sequential agent pipeline)
2. **Claim-before-write**: agent declares intent to modify a page, gets lock, writes, releases
3. **Optimistic concurrency with version check**: read page + version hash → modify → write only if hash unchanged → retry on conflict
4. **Append-only sections** (like log.md) need no locking — only append conflict possible, resolved by concatenation

For true multi-user/multi-agent parallel editing:
- Agent Teams + shared queue of pages to update
- tick-md-style task coordination for larger workflows
- CRDTs NOT recommended for markdown wikis (formatting issues)
