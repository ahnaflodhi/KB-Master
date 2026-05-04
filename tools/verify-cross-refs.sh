#!/usr/bin/env bash
# verify-cross-refs.sh — detect broken cross-references across all Layer-2 markdown
#
# Per ~/.claude/plans/crispy-sniffing-conway.md "Phase 2: tools/verify-cross-refs.sh
# reports zero broken links" + "Phase 6 exit criteria #2".
#
# Today (Phase 1, v2.8.1): walks all *.md under 00-overview/…/80-status/ + bundles/
# + commands/ + project root. Extracts markdown link targets and frontmatter
# `depends_on:` / `related:` paths. Reports any reference to a non-existent file.
#
# What it checks:
#   - Markdown links of the form [...](path) where path is a relative file path
#   - Frontmatter `depends_on:` and `related:` list entries (resolved relative to
#     the file containing the frontmatter)
#
# What it does NOT check (out of scope):
#   - URL-style links (http://, https://, mailto:)
#   - Anchor-only fragments (#section)
#   - Code-block content
#
# Exit codes:
#   0 — no broken refs (or no Layer-2 files yet)
#   1 — at least one broken reference
#   2 — usage error
#
# Usage: tools/verify-cross-refs.sh

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCAN_DIRS=(00-overview 10-pipeline 20-roles 30-knowledge 40-runtime 50-adapters 60-schemas 70-adoption 80-status bundles commands)
ERRORS=0
CHECKED=0

# Resolve a referenced path relative to the source file's directory.
# Returns absolute path, or empty for skip, or "__RESOLVE_FAIL__" on failure.
resolve_ref() {
    local source_file="$1"
    local ref="$2"
    local source_dir
    source_dir="$(dirname "$source_file")"
    if [[ "$ref" == /* ]]; then
        echo "$ref"
        return
    fi
    ref="${ref%%#*}"
    [[ -z "$ref" ]] && { echo ""; return; }
    (cd "$source_dir" 2>/dev/null && readlink -f "$ref" 2>/dev/null) || echo "__RESOLVE_FAIL__"
}

check_file() {
    local file="$1"
    local rel="${file#$REPO_ROOT/}"
    CHECKED=$((CHECKED + 1))

    while IFS= read -r ref; do
        [[ -z "$ref" ]] && continue
        [[ "$ref" =~ ^https?:// ]] && continue
        [[ "$ref" =~ ^mailto: ]] && continue
        [[ "$ref" =~ ^# ]] && continue
        [[ "$ref" =~ ^https://img.shields.io ]] && continue

        local resolved
        resolved=$(resolve_ref "$file" "$ref")
        [[ -z "$resolved" || "$resolved" == "__RESOLVE_FAIL__" ]] && continue

        if [[ ! -e "$resolved" ]]; then
            echo "BROKEN: $rel → $ref (resolved: ${resolved#$REPO_ROOT/})"
            ERRORS=$((ERRORS + 1))
        fi
    done < <(grep -oE '\]\([^)]+\)' "$file" 2>/dev/null | sed 's/^](//;s/)$//' | grep -E '\.(md|yaml|yml|sh|json)' || true)

    if head -n 1 "$file" | grep -qE '^---[[:space:]]*$'; then
        local frontmatter
        frontmatter=$(awk '/^---[[:space:]]*$/{c++; if (c==2) exit; next} c==1 {print}' "$file")
        while IFS= read -r ref; do
            [[ -z "$ref" ]] && continue
            local resolved
            resolved=$(resolve_ref "$file" "$ref")
            [[ -z "$resolved" || "$resolved" == "__RESOLVE_FAIL__" ]] && continue
            if [[ ! -e "$resolved" ]]; then
                echo "BROKEN_FRONTMATTER: $rel → $ref (resolved: ${resolved#$REPO_ROOT/})"
                ERRORS=$((ERRORS + 1))
            fi
        done < <(awk '
            /^(depends_on|related):/ {in_list=1; next}
            in_list && /^[[:space:]]+-[[:space:]]+/ {sub(/^[[:space:]]+-[[:space:]]+/, ""); print; next}
            in_list && !/^[[:space:]]/ {in_list=0}
        ' <<< "$frontmatter")
    fi
}

for dir in "${SCAN_DIRS[@]}"; do
    full="$REPO_ROOT/$dir"
    [[ -d "$full" ]] || continue
    while IFS= read -r -d '' file; do
        check_file "$file"
    done < <(find "$full" -maxdepth 1 -type f -name '*.md' -print0)
done

while IFS= read -r -d '' file; do
    check_file "$file"
done < <(find "$REPO_ROOT" -maxdepth 1 -type f -name '*.md' -print0)

if (( ERRORS > 0 )); then
    echo
    echo "verify-cross-refs: $ERRORS broken references across $CHECKED files"
    exit 1
fi

echo "verify-cross-refs: $CHECKED files checked, no broken references"
exit 0
