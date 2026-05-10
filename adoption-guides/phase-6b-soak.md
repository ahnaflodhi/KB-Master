# Phase 6b — Soak procedure

**Started:** 2026-05-08
**Target end:** 2026-05-13 (5-day window)
**State file:** `pipeline/soak-state.json`
**Soak-end action:** `tools/build-blueprint.sh --write`

This guide is the operating contract for the v3.0 Phase 6b soak — the last gate before `SYSTEM-BLUEPRINT.md` is demoted from canonical truth-source to compiled view, and Layer-2 becomes the only thing humans and agents edit. The soak exists because the regeneration is hard to reverse: once the monolith is auto-generated and the CI gate blocks direct edits, every claim that "Layer-2 covers everything" is load-bearing.

## What the soak verifies

Phase 6 exit criterion #8 (per `~/.claude/plans/crispy-sniffing-conway.md`):

> **5 consecutive iterations of any agent role complete without reading `SYSTEM-BLUEPRINT.md`** (verified by ledger inspection over the soak period).

Operationalised against `INVARIANT 11` (minimum-viable context per role; principle-centric — see `00-overview/invariants.md`): during the 5-day window, every dispatched role MUST satisfy INV 11. The verification mechanism is the DISPATCH ledger row's `context_sources` field at `pipeline/verification-ledger.jsonl` — `SYSTEM-BLUEPRINT.md` appearing in any row's `context_sources` is a hard fail. The recommended selection mechanism is `bundles/<role>.yaml` (the framework's default); adopters using a different mechanism (semantic routing, dynamic composition) record it in the row's `context_selection_mechanism` field. The soak audits the *outcome* (no monolith load, recorded), not the *mechanism* (bundle vs other) — meta-review may flag mechanism drift across iterations but does not fail the soak on it. If any verification-ledger entry violates INV 11, the soak fails and restarts.

## Pre-soak preconditions (all required, all already satisfied as of 2026-05-08)

1. ✅ `tools/verify-frontmatter.sh --strict` exits 0.
2. ✅ `tools/verify-cross-refs.sh` exits 0.
3. ✅ `tools/build-bundle.sh --check` exits 0.
4. ✅ `tools/build-blueprint.sh` writes `SYSTEM-BLUEPRINT.candidate.md`.
5. ✅ `agents.config.yaml` has `schema_version: 3` (was 2 at Phase-6b initiation; bumped to 3 for INV 1.A `family:` field requirement); every agent declares `loads_bundle: <name>` AND `family: <name>`.
6. ✅ `CLAUDE.md` and `README.md` name `INDEX.md` as the runtime entry, not `SYSTEM-BLUEPRINT.md`.
7. ✅ `commands/_delegate.md` Step 3 (PREPARE) loads minimum-viable context per INV 11. Bundles are the framework's recommended selection mechanism; the shim records `context_sources` + `context_selection_mechanism` in the Step 4 DISPATCH ledger row for INV 11 enforcement at Step 10 CONSUME.
8. ✅ All 11 role-bearing slash commands and the `_delegate` shim exist.
9. ✅ `pipeline/verification-ledger.jsonl` carries the full restructure dispatch+consume audit trail.
10. ⏳ This soak completes; only then does criterion #8 turn green.

## Day-by-day checklist

### Day 1 (2026-05-08) — initiation + semantic check

**Operator actions:**
- Confirm `pipeline/soak-state.json` shows `started_at: 2026-05-08T...Z`, `status: "in-progress"`, `monolith_reads_during_soak: 0`, `iterations_observed: 0`.
- Generate the candidate (`tools/build-blueprint.sh`) and sample 20% of role files for a per-section semantic-equivalence check against the live monolith. Record gaps in `pipeline/soak-state.json` `notes`. Sample = 2 files from `20-roles/` chosen at random. Verify the body content of each file appears (in any structural form) in the live monolith's §6 / §25 / §8 content.
- If any sampled file's content is missing from the live monolith: STOP. The Layer-2 extraction is incomplete. Append the gap to the audit log and resolve before re-starting the soak.

**Pass condition for the day:** sampled content covered; no monolith reads logged.

### Days 2–4 — observation

**Operator actions per day:**
- Inspect `pipeline/verification-ledger.jsonl` for any new dispatch+consume rows. For each, confirm:
  - The `prompt_hash` was derived from a bundle (recoverable via the role's `loads_bundle:` field), not the monolith.
  - No row's `notes` field references `SYSTEM-BLUEPRINT.md`.
- If any agent (orchestrator, worker, or delegated bridge job) ran a `Read` against `SYSTEM-BLUEPRINT.md` during this window: STOP. Increment `monolith_reads_during_soak` and reset `iterations_observed` to 0. The soak restarts on the next clean day.
- Increment `iterations_observed` by the count of fully-completed iterations (start → archive) where every dispatched role passed verification.

**Pass condition cumulative:** `iterations_observed ≥ N` (where N is the day number) and `monolith_reads_during_soak == 0`.

### Day 5 (2026-05-13) — completion or abort

**Pass condition (all required):**
- `iterations_observed ≥ 5`.
- `monolith_reads_during_soak == 0`.
- Latest re-runs of `tools/verify-frontmatter.sh --strict`, `tools/verify-cross-refs.sh`, `tools/build-bundle.sh --check` all green.
- `tools/build-blueprint.sh` produces a candidate that line-diffs against the prior day's candidate by **structural-only** changes (no semantic surprises).

**On pass — execute the swap:**
1. Update `pipeline/soak-state.json` `status` to `"passed"`, `passed_at` to current UTC.
2. Run `tools/build-blueprint.sh --write` — overwrites `SYSTEM-BLUEPRINT.md` with the candidate; backup snapshot saved to `.SYSTEM-BLUEPRINT.pre-regen.<UTC-ts>.md`.
3. `mv SYSTEM-BLUEPRINT.candidate.md /tmp/` (or `rm` if the diff is satisfactory) — the candidate has served its role.
4. Tag the repo `v3.0.0`. Add the `v3.0` comprehensive CHANGELOG entry (criterion #10).
5. Confirm the CI `monolith-edit-guard` job in `.github/workflows/ci.yml` is active (it was enabled at Phase-6b initiation, not at day-5 swap — this step is verification, not enablement). The job already blocks direct edits to `SYSTEM-BLUEPRINT.md` outside of `tools/build-blueprint.sh --write` runs.

**On any failure during the soak — abort:**
- Update `pipeline/soak-state.json` `status` to `"failed"`, `failed_at` to current UTC, `notes` describing the failure mode.
- Do NOT run `tools/build-blueprint.sh --write`. The live monolith remains canonical.
- File a CHANGELOG entry describing what failed, what Layer-2 extraction needs improving, and the new `started_at` for the next soak attempt.
- Re-run preconditions (especially #1–#4) before scheduling another attempt.

## Soak failure modes (any one resets the counter)

| Mode | How it manifests | Reset action |
|---|---|---|
| **Monolith read by an agent** | Any verification-ledger row referencing `SYSTEM-BLUEPRINT.md` in `inputs[]` or notes | Increment `monolith_reads_during_soak`; reset `iterations_observed: 0` |
| **CI gate breaks** | `verify-frontmatter --strict` or `verify-cross-refs` or `build-bundle --check` fails on a PR | Fix the underlying drift; reset day counter |
| **Bundle drift** | `tools/build-bundle.sh --check` reports a referential-integrity failure | Patch the offending frontmatter or bundle; reset day counter |
| **Candidate semantic drift** | Daily candidate diff vs. prior day's candidate shows non-structural changes (semantic content moved between files unintentionally) | Investigate; if Layer-2 was edited, this is expected — confirm and continue. Otherwise reset. |
| **Agent skips bundle** | A dispatched role somehow loads more than its bundle declares | Tighten the role's `_delegate.md` PREPARE step; reset day counter |

## Where the live monolith stays during soak

Untouched. `tools/build-blueprint.sh` writes the candidate to `SYSTEM-BLUEPRINT.candidate.md` (gitignore'd or committed at maintainer discretion — committing makes diffs reviewable; gitignoring keeps the repo small). The live `SYSTEM-BLUEPRINT.md` is not regenerated until day 5 passes.

## After successful swap (post-soak)

- `SYSTEM-BLUEPRINT.md` becomes a compiled view. CI blocks direct edits.
- All edits go through Layer-2 + `tools/build-blueprint.sh --write`.
- Quarterly: re-run `tools/build-bundle.sh --check` and confirm bundles still match frontmatter.
- Annually: re-extract any Layer-2 file whose `last_reviewed` is more than 12 months old.

## Cross-references

- `tools/build-blueprint.sh` — the regenerator
- `tools/build-bundle.sh` — bundle integrity check
- `pipeline/soak-state.json` — soak day-counter
- `commands/_delegate.md` — dispatch shim consuming bundles, not the monolith
- `~/.claude/plans/crispy-sniffing-conway.md` — Phase 6 exit criteria (canonical)
- `CHANGELOG.md` — v2.10, Phase 6a (carry-forwards), Phase 6b (this soak)

---

**Last reviewed:** 2026-05-08
**Status:** in-progress
