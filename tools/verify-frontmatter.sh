#!/usr/bin/env bash
# verify-frontmatter.sh — validate every Layer-2 file has the required v3.0 frontmatter
#
# Per ~/.claude/plans/crispy-sniffing-conway.md "Frontmatter standard" + "Phase 1" +
# 80-status/shipped-vs-planned.md row "tools/ scripts (in migration)".
#
# Today (Phase 1, v2.8.1): walks 00-overview/…/80-status/ and exits 0 if no Layer-2
# files exist yet (only 80-status/shipped-vs-planned.md does at v2.8.1) or if every
# existing Layer-2 file has valid frontmatter. Real validation logic (max_lines,
# enum value checks, directives.must_count drift) expands per phase.
#
# Exit codes:
#   0 — all files valid (or no Layer-2 files yet)
#   1 — at least one file missing/malformed frontmatter
#   2 — usage error
#
# Usage: tools/verify-frontmatter.sh [--strict]
#   --strict — also enforce max_lines (default off in Phase 1; on in Phase 2+)

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LAYER2_DIRS=(00-overview 10-pipeline 20-roles 30-knowledge 40-runtime 50-adapters 60-schemas 70-adoption 80-status)
STRICT="${1:-}"
ERRORS=0
CHECKED=0

# Required frontmatter keys per the v3.0 standard. Phase 1 enforces only the
# minimal set; Phase 2+ expands to the full schema.
REQUIRED_KEYS_MINIMAL=(id title purpose status version last_reviewed)

check_file() {
    local file="$1"
    local rel="${file#$REPO_ROOT/}"
    CHECKED=$((CHECKED + 1))

    if ! head -n 1 "$file" | grep -qE '^---[[:space:]]*$'; then
        echo "FAIL: $rel — missing frontmatter (no opening --- on line 1)"
        ERRORS=$((ERRORS + 1))
        return
    fi

    local frontmatter
    frontmatter=$(awk '/^---[[:space:]]*$/{c++; if (c==2) exit; next} c==1 {print}' "$file")

    for key in "${REQUIRED_KEYS_MINIMAL[@]}"; do
        if ! grep -qE "^${key}:" <<< "$frontmatter"; then
            echo "FAIL: $rel — missing required frontmatter key: $key"
            ERRORS=$((ERRORS + 1))
        fi
    done

    if [[ "$STRICT" == "--strict" ]]; then
        local max_lines
        max_lines=$(grep -E '^max_lines:' <<< "$frontmatter" | sed 's/^max_lines:[[:space:]]*//' | tr -d '[:space:]' || true)
        if [[ -n "$max_lines" ]]; then
            local actual
            actual=$(wc -l < "$file")
            if (( actual > max_lines )); then
                echo "FAIL: $rel — file is $actual lines, exceeds declared max_lines: $max_lines"
                ERRORS=$((ERRORS + 1))
            fi
        fi
    fi
}

for dir in "${LAYER2_DIRS[@]}"; do
    full="$REPO_ROOT/$dir"
    [[ -d "$full" ]] || continue
    while IFS= read -r -d '' file; do
        [[ "$(basename "$file")" == "_README.md" ]] && continue
        check_file "$file"
    done < <(find "$full" -maxdepth 1 -type f -name '*.md' -print0)
done

if (( ERRORS > 0 )); then
    echo
    echo "verify-frontmatter: $ERRORS errors across $CHECKED files"
    exit 1
fi

echo "verify-frontmatter: $CHECKED files checked, all valid"
exit 0
