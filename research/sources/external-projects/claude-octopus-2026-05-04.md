---
source_type: external-project
source_url: https://github.com/nyldn/claude-octopus
fetched_at: 2026-05-04T18:10:00Z
fetched_by: claude-main
fetch_method: gh api repos/nyldn/claude-octopus + /contents + /readme + docs/ARCHITECTURE.md
repo: nyldn/claude-octopus
version: 9.30.0
stars: 3222
forks: 288
created_at: 2026-01-15T08:49:38Z
pushed_at: 2026-05-04T13:53:23Z
language: Shell
license: MIT
tagline: "Put up to 8 AI models on every coding task — blind spots surface before you ship. Claude Code plugin."
purpose_of_archive: prior-art comparison for KB-Orchestrator-Core §25 adapter model
---

## Summary

Claude Octopus is a Claude Code plugin (also distributed for Codex CLI, Cursor IDE, OpenCode, and Factory Droid) that orchestrates up to eight AI providers — Codex (OpenAI GPT-5.4), Gemini, Claude, Perplexity, OpenRouter, Copilot, Qwen, Ollama — through a Double Diamond (Discover → Define → Develop → Deliver) workflow with a 75% consensus quality gate. v9.30.0 ships 48 slash commands, 32 personas, 52 skills, an MCP server, an OpenClaw extension for messaging-platform integration, and persistent cross-session memory via `claude-mem`.

Distribution model: `claude plugin marketplace add` + `claude plugin install octo@nyldn-plugins`. Zero external providers required to start; each detected provider activates automatically.

## Provider inventory (8)

| Provider | CLI / API | Underlying model (April 2026) | Cost |
|---|---|---|---|
| Codex CLI | `codex exec --model gpt-5.4` | GPT-5.4 | OPENAI_API_KEY or ChatGPT subscription via OAuth |
| Gemini CLI | `gemini -y -m gemini-3.1-pro-preview` | Gemini 3.1 Pro | GEMINI_API_KEY or Google account OAuth |
| Claude (built-in) | Claude Code session | Sonnet 4.6 / Opus 4.7 | Claude Code subscription |
| Perplexity | API-only | Sonar Pro / Sonar | PERPLEXITY_API_KEY |
| OpenRouter | API-only | 100+ models | OPENROUTER_API_KEY |
| Ollama | `ollama run <model>` | Local (llama3.3, mistral, etc.) | Free (local) |
| Copilot | `copilot -p` | GitHub-hosted Claude/GPT/Gemini | GitHub Copilot subscription |
| Qwen | `qwen -p` | Qwen3-Coder | OAuth free tier (1k–2k req/day) |

## Role → model defaults (v9.29+)

`architect`, `strategist`, `security-reviewer` → Claude Opus 4.7. `code-reviewer`, `implementer` → GPT-5.4. `synthesizer` → Claude Sonnet 4.6. `researcher` → Gemini 3.1 Pro. Opt-out: `OCTOPUS_LEGACY_ROLES=1`. Graceful fallback when preferred CLI unavailable.

## Repository structure (top-level)

`agents/` (config + droids + personas + principles + skills) · `commands/` (48 `.md` files including octo-auto, octo-debate, octo-discover, octo-embrace, octo-factory, octo-tdd, octo-security, etc.) · `hooks/` (~30 shell scripts: architecture-gate, budget-gate, code-quality-gate, codex-exec-guard, discipline-inject, plan-mode-interceptor, post-compact, pre-compact, provider-routing-validator, quality-gate, etc.) · `skills/` (~52 named skills) · `docs/` (AGENTS.md, ARCHITECTURE.md, COMMAND-REFERENCE.md, GPT-5.4-PROMPTING.md, IDE-INTEGRATION.md, KNOWLEDGE-WORKERS.md, SCHEDULER.md) · `config/` (blind-spots, ide-templates, providers, templates, workflows) · `mcp-server/` (TypeScript MCP server) · `openclaw/` (messaging-platform extension) · `bin/` · `tests/` (146 passing).

## Workflow model

Four phases adapted from UK Design Council's Double Diamond:

| Phase | Command | What |
|---|---|---|
| Discover | `/octo:discover` | Multi-AI research and broad exploration |
| Define | `/octo:define` | Requirements clarification with consensus |
| Develop | `/octo:develop` | Implementation with quality gates |
| Deliver | `/octo:deliver` | Adversarial review and go/no-go scoring |

Modes: supervised, semi-autonomous, autonomous. `/octo:embrace` runs all four; `/octo:factory` is the autonomous "spec in, software out" pipeline.

## Reaction engine (auto-handled events)

| Event | Reaction | Limits |
|---|---|---|
| CI failure | Forward logs into agent inbox | 3 retries, escalate after 30 min |
| Changes requested | Forward review comments into agent inbox | 2 retries, escalate after 60 min |
| Agent stuck | Escalate to human | After 15 min no progress |
| PR approved + CI green | Notify ready-to-merge | — |
| PR merged | Mark agent complete | — |

13 lifecycle states tracked: `running` → `pr_open` → `ci_pending` → (`ci_failed` | `review_pending`) → (`changes_requested` | `approved`) → `mergeable` → `merged` → `done`.

## Self-positioning vs prior art (their README's own comparison table)

| | Claude Code alone | Superpowers | Claude Octopus |
|---|---|---|---|
| Core idea | One model, your prompts | Structured methodology for one agent | Up to 8 providers cross-checking |
| Providers | Claude only | Claude only | 8 |
| Workflow | Ad-hoc | Spec → plan → subagent-driven dev | Double Diamond |
| Consensus gates | No | No | Yes — 75% threshold |
| Best for | Quick tasks | Long autonomous runs | Research, review, debates, multi-provider validation |

## Notable contracts and design choices

- **Namespace isolation**: only `/octo:*` commands and `octo` natural-language prefix activate the plugin.
- **Data locations** documented up-front: `~/.claude-octopus/results/`, `~/.claude-octopus/logs/`, project-state `.octo/`.
- **Provider transparency**: 🐙 activation indicator + colored dots show active providers per command.
- **Project-level overrides** via `.octo/reactions.conf` with pipe-delimited rule format: `EVENT|ACTION|MAX_RETRIES|ESCALATE_AFTER_MIN|ENABLED`.
- **MCP server is opt-in** (does not auto-start) to avoid permanent `✘ failed` status in `/mcp` panel for non-users.
- **OpenClaw bridge**: separate package wraps Octopus workflows for Telegram/Discord/Signal/WhatsApp without touching the core plugin.

## Verbatim execution-flow excerpt (Discover phase)

```
User Request → Octopus orchestrator
  ├── Codex CLI (technical analysis)        ← parallel
  └── Gemini CLI (ecosystem research)       ← parallel
        ↓ both complete
  Claude (synthesis)                        ← sequential after both
        ↓
  Final Research Report
```
Typical duration 30-60s; typical cost $0.01–0.05.

## URLs of interest

- Repo root: https://github.com/nyldn/claude-octopus
- README (verbatim quoted above): https://github.com/nyldn/claude-octopus/blob/main/README.md
- Architecture doc: https://github.com/nyldn/claude-octopus/blob/main/docs/ARCHITECTURE.md
- Plugin marketplace install: `claude plugin marketplace add https://github.com/nyldn/plugins.git`

---
