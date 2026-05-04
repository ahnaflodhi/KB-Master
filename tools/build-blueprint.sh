#!/usr/bin/env bash
# build-blueprint.sh — regenerate SYSTEM-BLUEPRINT.md from Layer-2 sources
#
# Per ~/.claude/plans/crispy-sniffing-conway.md "The monolith as compiled artifact"
# + "Phase 6: Run tools/build-blueprint.sh → regenerate monolith from Layer-2"
# + "Phase 6 exit criteria #3" + "Continuous verification: CI hook blocks any direct
# edit to SYSTEM-BLUEPRINT.md".
#
# Phase 1 (today, v2.8.1): skeleton. Layer-2 dirs are mostly empty, so concat
# would produce nothing meaningful. Behavior:
#   - default mode: refuse to overwrite existing SYSTEM-BLUEPRINT.md (the live
#     monolith remains the source of truth until Phase 6 demotion); print a note
#     and exit 0.
#   - --dry-run: print what WOULD be concatenated (Layer-2 file inventory).
#
# From Phase 6 onward, default mode regenerates SYSTEM-BLUEPRINT.md by:
#   for dir in 00-overview 10-pipeline 20-roles 30-knowledge 40-runtime \
#              50-adapters 60-schemas 70-adoption 80-status; do
#     for file in "$dir"/*.md; do
#       strip_frontmatter "$file" >> SYSTEM-BLUEPRINT.md
#       echo "" >> SYSTEM-BLUEPRINT.md
#     done
#   done
#
# Exit codes:
#   0 — success (or no-op in Phase 1)
#   1 — concat error or destination conflict
#   2 — usage error
#
# Usage:
#   tools/build-blueprint.sh             — regenerate SYSTEM-BLUEPRINT.md from Layer-2
#   tools/build-blueprint.sh --dry-run   — print Layer-2 file inventory; do not write

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BLUEPRINT="$REPO_ROOT/SYSTEM-BLUEPRINT.md"
ARCHIVE="$REPO_ROOT/SYSTEM-BLUEPRINT-v2.8.md"
LAYER2_DIRS=(00-overview 10-pipeline 20-roles 30-knowledge 40-runtime 50-adapters 60-schemas 70-adoption 80-status)
MODE="${1:-build}"

usage() {
    sed -n '2,/^$/p' "$0" | sed 's/^# \?//'
    exit 2
}

[[ "$MODE" == "-h" || "$MODE" == "--help" ]] && usage

inventory() {
    for dir in "${LAYER2_DIRS[@]}"; do
        full="$REPO_ROOT/$dir"
        [[ -d "$full" ]] || continue
        find "$full" -maxdepth 1 -type f -name '*.md' | sort
    done
}

if [[ "$MODE" == "--dry-run" ]]; then
    echo "build-blueprint --dry-run: Layer-2 files in canonical concat order:"
    files=$(inventory)
    if [[ -z "$files" ]]; then
        echo "  (none — Layer-2 dirs empty or absent; v3.0 Phase 2+ has not landed yet)"
    else
        echo "$files" | sed "s|$REPO_ROOT/|  |"
    fi
    exit 0
fi

# Phase 1 guard: refuse to overwrite live monolith when no real Layer-2 source exists.
if [[ -f "$BLUEPRINT" && -f "$ARCHIVE" ]]; then
    if cmp -s "$BLUEPRINT" "$ARCHIVE"; then
        echo "build-blueprint: SYSTEM-BLUEPRINT.md is byte-identical to v2.8 archive."
        echo "build-blueprint: Layer-2 extraction has not yet diverged from monolith."
        echo "build-blueprint: refusing to overwrite (Phase 1 — expected). Exit 0."
        exit 0
    fi
fi

files=$(inventory)
if [[ -z "$files" ]]; then
    echo "build-blueprint: no Layer-2 files to concatenate yet (Phase 2+ has not landed)."
    echo "build-blueprint: refusing to write empty blueprint. Exit 0."
    exit 0
fi

echo "build-blueprint: full concat logic lands in v3.0 Phase 6 (per plan)."
echo "build-blueprint: Phase 1 skeleton — printing what WOULD be concatenated:"
echo "$files" | sed "s|$REPO_ROOT/|  |"
exit 0
