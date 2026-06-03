#!/usr/bin/env bash
# verify-blueprint.sh — the standing post-demotion gate for SYSTEM-BLUEPRINT.md.
#
# Replaces the weak `monolith-edit-guard` check (which only required "some Layer-2
# co-change" and so could wave through a hand-edited semantic delta). Per JCC design
# review (ledger job jcc-gate-design-001), the real invariant after demotion is
# EXACT REPRODUCIBILITY: the committed monolith must equal what the generator emits.
#
# Two checks:
#   COVERAGE   — every Layer-2 content file's stripped body appears verbatim in a
#                fresh generation. Proves no source was silently dropped/truncated.
#                (Run this BEFORE the one-time --write demotion as the coverage
#                 sign-off; it stays valid forever after.)
#   REPRODUCE  — the live SYSTEM-BLUEPRINT.md, with the volatile "Regenerated"
#                timestamp lines normalized out, byte-equals a fresh generation.
#                BEFORE demotion this is EXPECTED TO FAIL (the live monolith is still
#                the hand-authored original) — that failure is the signal that
#                demotion has not happened yet. AFTER --write it must pass, and CI
#                enforces it on every push.
#
# Usage:
#   tools/verify-blueprint.sh             # both checks; non-zero if either fails
#   tools/verify-blueprint.sh --coverage  # coverage only (the pre-demotion gate)
#
# Exit 0 = pass. Exit 1 = fail.

set -uo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT" || exit 2
LIVE="$REPO_ROOT/SYSTEM-BLUEPRINT.md"
ONLY="${1:-}"

# Fresh generation into a temp candidate (build-blueprint writes the candidate path).
tools/build-blueprint.sh >/dev/null 2>&1 || { echo "verify-blueprint: generation failed"; exit 1; }
GEN="$REPO_ROOT/SYSTEM-BLUEPRINT.candidate.md"

python3 - "$LIVE" "$GEN" "$ONLY" <<'PY'
import sys, re, pathlib
live_path, gen_path, only = sys.argv[1], sys.argv[2], sys.argv[3]
gen = pathlib.Path(gen_path).read_text()

LAYER2 = ["00-overview","10-pipeline","20-roles","30-knowledge",
          "40-runtime","50-adapters","60-schemas","70-adoption","80-status"]

def strip_frontmatter(text):
    lines = text.splitlines(keepends=True)
    out, state = [], 0
    for ln in lines:
        if state == 0 and re.match(r'^---[ \t]*$', ln): state = 1; continue
        if state == 1 and re.match(r'^---[ \t]*$', ln): state = 2; continue
        if state == 2: out.append(ln)
    return "".join(out) if state == 2 else text  # no frontmatter -> whole body

# ---- COVERAGE ----
missing = []
checked = 0
root = pathlib.Path(".")
for d in LAYER2:
    dd = root / d
    if not dd.is_dir(): continue
    for f in sorted(dd.glob("*.md")):
        if f.name == "_README.md": continue
        body = strip_frontmatter(f.read_text()).strip()
        if not body:
            continue
        checked += 1
        if body not in gen:
            missing.append(str(f))
cov_ok = not missing
print(f"COVERAGE: {checked} content files checked; {'all bodies present verbatim' if cov_ok else str(len(missing))+' MISSING'}")
for m in missing:
    print(f"  MISSING body: {m}")

if only == "--coverage":
    sys.exit(0 if cov_ok else 1)

# ---- REPRODUCE ----
def normalize(text):
    out = []
    for ln in text.splitlines():
        if ln.startswith("**Regenerated**:"): continue
        if "Regenerated from Layer-2 sources" in ln: continue
        out.append(ln.rstrip())
    return "\n".join(out)

live = pathlib.Path(live_path).read_text()
rep_ok = normalize(live) == normalize(gen)
print(f"REPRODUCE: live monolith {'== generator output (timestamp-normalized)' if rep_ok else '!= generator output'}")
if not rep_ok:
    # show first divergence for the operator
    a, b = normalize(live).splitlines(), normalize(gen).splitlines()
    for i,(x,y) in enumerate(zip(a,b)):
        if x != y:
            print(f"  first divergence at normalized line {i+1}:")
            print(f"    live: {x[:100]}")
            print(f"    gen : {y[:100]}")
            break
    else:
        print(f"  length differs: live {len(a)} vs gen {len(b)} normalized lines")

sys.exit(0 if (cov_ok and rep_ok) else 1)
PY
rc=$?
echo "---"
if [ "$rc" -eq 0 ]; then echo "verify-blueprint: PASS"; else echo "verify-blueprint: FAIL (rc=$rc)"; fi
exit $rc
