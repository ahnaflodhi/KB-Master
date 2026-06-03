# Static Regeneration Gate — supersedes the Phase-6b soak

**Status:** active (v3.0). **Supersedes:** `adoption-guides/phase-6b-soak.md` (retired).
**Designed via JCC** (Claude orchestrator + Codex co-design), ledger job `jcc-gate-design-001`.

## Why the soak was retired

The Phase-6b soak gated the monolith demotion behind *"5 consecutive iterations of any agent role complete without reading `SYSTEM-BLUEPRINT.md`, verified by ledger inspection over a 5-day window."* That criterion assumed a **live production pipeline** generating dispatch traffic. KB-Orchestrator-Core is the **System Owner Brain** — a quiescent repo that does not run production iterations. The soak window opened 2026-05-08 and accrued **zero** new ledger rows; `iterations_observed` stayed at 0 indefinitely. A calendar-window observation gate with no traffic to observe is not a gate — it is a stall.

The soak's *purpose* was sound: prove no runtime role depends on the monolith before making it a regenerated artifact. That purpose is better served **statically**, by inspecting the actual load surfaces, than by sampling 5 live runs and hoping they touch the risky path. The replacement below is strictly stronger for every declared load path.

**Honest limitation:** a static gate cannot see runtime-only loads (dynamic context composition, a semantic router resolving the monolith without the literal string, or external-harness code). For a quiescent owner repo with no live signal, static inspection plus the standing reproducibility gate is the best available proof. Adopters who DO run a live pipeline should additionally enforce INV 11 on their own ledger (`context_sources` never contains `SYSTEM-BLUEPRINT.md` for non-carve-out roles) — that is the live half the owner repo cannot exercise.

## The gate

### One-time — before the first `--write` demotion

All must hold:

1. `tools/verify-frontmatter.sh --strict` exits 0.
2. `tools/verify-cross-refs.sh` exits 0.
3. `tools/build-bundle.sh --check` exits 0.
4. `tools/verify-no-monolith.sh` exits 0 — **no bundle/`loads_bundle` load surface references the monolith** (structured-surface scan; prose prohibitions are not load instructions). WARNs (runtime files citing monolith `§`-sections) are hygiene, not blockers.
5. `tools/verify-blueprint.sh --coverage` exits 0 — **every Layer-2 content file's stripped body appears verbatim** in a fresh generation (no silent omission/truncation).
6. **Human semantic sign-off.** Automation proves byte/coverage; it cannot prove that moved headings, section scope, and ordering preserve *meaning*. A maintainer confirms the candidate is a faithful compiled view (an expansion of the prior monolith, not a reshuffle that changes intent). Record the sign-off in the CHANGELOG entry for the demotion.

Then: `tools/build-blueprint.sh --write` (overwrites the monolith; saves a `.SYSTEM-BLUEPRINT.pre-regen.<ts>.md` backup), and tag the release.

### Standing — every future regeneration + CI

7. `tools/verify-blueprint.sh` exits 0 — **REPRODUCE**: the committed `SYSTEM-BLUEPRINT.md`, with the volatile `Regenerated` timestamp lines normalized out, byte-equals a fresh generation. This is the durable invariant after demotion: the monolith is *exactly* what the generator emits, so any hand-edit (even one accompanied by an unrelated Layer-2 change) is caught. It replaces the old `monolith-edit-guard`, which only required "some Layer-2 co-change" and so could wave a semantic hand-edit through.
8. `tools/verify-no-monolith.sh` exits 0 on every push.

`.github/workflows/ci.yml` runs 7 + 8 (plus 1–3) on every push/PR.

## Narrowed carve-out (INV 11)

`meta_review` / `apply_meta` may load the monolith ONLY for a declared `monolith_load_reason` ∈ {`regeneration-diff`, `migration-audit`, `backcompat-inspection`}, recorded in the DISPATCH row, and MUST NOT propagate monolith-derived context into downstream non-carve-out dispatches. See `00-overview/invariants.md` INVARIANT 11.

## Cross-references

- `tools/verify-no-monolith.sh` — structured load-surface scan
- `tools/verify-blueprint.sh` — coverage + reproducibility gate
- `tools/build-blueprint.sh` — the regenerator (`--write` is the irreversible demotion)
- `00-overview/invariants.md` — INVARIANT 11 (+ narrowed carve-out)
- `adoption-guides/phase-6b-soak.md` — the retired soak procedure (kept for history)
- `pipeline/verification-ledger.jsonl` — `jcc-gate-design-001` (the JCC design dispatch)
