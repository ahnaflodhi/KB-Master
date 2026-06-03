#!/usr/bin/env bash
# verify-no-monolith.sh — prove no runtime role loads SYSTEM-BLUEPRINT.md.
#
# Replaces the retired Phase-6b 5-iteration "soak" (see adoption-guides/static-
# regeneration-gate.md). The soak observed 5 live iterations to infer the monolith
# is unused at runtime; this proves it statically by inspecting the actual load
# surfaces, which is strictly stronger for declared paths (it checks every role,
# not a 5-iteration sample). Per JCC design review (ledger job jcc-gate-design-001),
# this scans STRUCTURED load surfaces, not raw mentions — prose prohibitions like
# "Do NOT load SYSTEM-BLUEPRINT.md" are not load instructions and must not fail.
#
# Limitation (honest): a static scan cannot see runtime-only loads (dynamic context
# composition, a semantic router resolving the monolith without the literal string,
# or external-harness code). For a quiescent owner repo with no live pipeline that
# is the best available signal; the standing exact-reproducibility gate (CI) covers
# the post-demotion invariant.
#
# Checks:
#   1. bundles/*.yaml — no loads:/optional:/adapter_specific: entry is the monolith
#      (live, any SYSTEM-BLUEPRINT-v*.md snapshot, or *.candidate.md). HARD FAIL.
#   2. agents.config.yaml — every `loads_bundle: <name>` resolves to bundles/<name>.yaml. HARD FAIL.
#   3. Runtime files (INDEX.md, commands/*.md, 20-roles/*.md) — report any monolith
#      mention that is NOT a negative prohibition, as WARN for human review.
#
# Exit 0 = clean (warnings allowed). Exit 1 = hard fail.

set -uo pipefail
cd "$(dirname "$0")/.." || exit 2

MONO_RE='SYSTEM-BLUEPRINT(-v[0-9.]+)?\.md|SYSTEM-BLUEPRINT\.candidate\.md'
fail=0
warn=0

# --- Check 1: bundle load surfaces ---------------------------------------------
for b in bundles/*.yaml; do
  [ -s "$b" ] || continue
  # Extract list-item paths under loads:/optional:/adapter_specific: (lines like "  - path").
  # awk tracks the active key; only list items under a load key are load surfaces.
  loaded=$(awk '
    /^(loads|optional|adapter_specific):/ { inkey=1; next }
    /^[a-zA-Z_]+:/      { inkey=0 }
    inkey && /^[[:space:]]*-[[:space:]]/ {
      line=$0; sub(/^[[:space:]]*-[[:space:]]*/,"",line); sub(/[[:space:]]*#.*/,"",line); print line }
  ' "$b")
  while IFS= read -r p; do
    [ -z "$p" ] && continue
    if printf '%s' "$p" | grep -Eq "$MONO_RE"; then
      echo "FAIL: $b loads the monolith via a load surface: '$p'"
      fail=1
    fi
  done <<< "$loaded"
done

# --- Check 2: loads_bundle integrity -------------------------------------------
while IFS= read -r name; do
  [ -z "$name" ] && continue
  if [ ! -f "bundles/${name}.yaml" ]; then
    echo "FAIL: agents.config.yaml references loads_bundle: ${name} but bundles/${name}.yaml is missing"
    fail=1
  fi
done < <(grep -oE 'loads_bundle:[[:space:]]*[A-Za-z0-9_-]+' agents.config.yaml | sed -E 's/.*:[[:space:]]*//' | sort -u)

# --- Check 3: runtime-file mentions that are not prohibitions (WARN) ------------
# A mention is a prohibition if the line says do not / never / not load / no SYSTEM-BLUEPRINT.
runtime_files=(INDEX.md commands/*.md 20-roles/*.md)
for f in "${runtime_files[@]}"; do
  [ -f "$f" ] || continue
  while IFS= read -r ln; do
    n="${ln%%:*}"; text="${ln#*:}"
    # skip negative prohibitions
    if printf '%s' "$text" | grep -Eiq 'do not|don.t|never|not load|no .?SYSTEM-BLUEPRINT|CARVE-OUT|carve-out'; then
      continue
    fi
    # skip frontmatter provenance (extracted_from.source: records the snapshot a
    # Layer-2 file was carved from — that is lineage, not a runtime load instruction)
    if printf '%s' "$text" | grep -Eq '^[[:space:]]*source:[[:space:]]*SYSTEM-BLUEPRINT'; then
      continue
    fi
    echo "WARN: $f:$n positive monolith mention (review — runtime files should not point roles at the monolith): ${text:0:90}"
    warn=$((warn+1))
  done < <(grep -nE "$MONO_RE" "$f" 2>/dev/null)
done

echo "---"
if [ "$fail" -ne 0 ]; then
  echo "verify-no-monolith: HARD FAIL — a runtime load surface references the monolith."
  exit 1
fi
echo "verify-no-monolith: load surfaces clean; ${warn} warning(s) for human review."
exit 0
