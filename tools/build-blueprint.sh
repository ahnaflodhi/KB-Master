#!/usr/bin/env bash
# build-blueprint.sh — regenerate SYSTEM-BLUEPRINT.md from Layer-2 sources
#
# Per ~/.claude/plans/crispy-sniffing-conway.md "The monolith as compiled artifact"
# + "Phase 6: Run tools/build-blueprint.sh → regenerate monolith from Layer-2"
# + "Phase 6 exit criteria #3" + "Continuous verification: CI hook blocks any direct
# edit to SYSTEM-BLUEPRINT.md".
#
# Phase 6b (v3.0, 2026-05-07): real concat logic. Three modes:
#
#   tools/build-blueprint.sh             — write candidate to SYSTEM-BLUEPRINT.candidate.md
#                                          (NON-DESTRUCTIVE; live monolith untouched)
#   tools/build-blueprint.sh --write     — replace live SYSTEM-BLUEPRINT.md
#                                          (DESTRUCTIVE; only run at soak end)
#   tools/build-blueprint.sh --dry-run   — print Layer-2 inventory in concat order
#
# Concat algorithm:
#   1. Walk LAYER2_DIRS in declared order (00-overview/ first, 80-status/ last).
#   2. For each dir, list *.md files alphabetically; skip *_README.md.
#   3. For each file: strip YAML frontmatter (between first two `---`); promote
#      its frontmatter `title:` to a `##` heading; append body verbatim.
#   4. Insert a `# Layer 2 — <dir>` heading before each directory's first file.
#   5. Prepend a synthesized preamble (version, regenerated-at timestamp,
#      regeneration disclaimer); append a footer.
#
# Until --write is run at soak end, the live monolith remains canonical and the
# candidate is for diff inspection only.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LIVE="$REPO_ROOT/SYSTEM-BLUEPRINT.md"
CANDIDATE="$REPO_ROOT/SYSTEM-BLUEPRINT.candidate.md"
LAYER2_DIRS=(00-overview 10-pipeline 20-roles 30-knowledge 40-runtime 50-adapters 60-schemas 70-adoption 80-status)

usage() {
    sed -n '2,/^$/p' "$0" | sed 's/^# \?//'
    exit 2
}

[[ "${1:-}" == "-h" || "${1:-}" == "--help" ]] && usage

MODE="${1:-candidate}"

# ----- helpers -----

strip_frontmatter() {
    awk 'BEGIN { state=0 }
         state==0 && /^---[[:space:]]*$/ { state=1; next }
         state==1 && /^---[[:space:]]*$/ { state=2; next }
         state==2 { print }' "$1"
}

fm_title() {
    awk '/^---[[:space:]]*$/{c++; if (c==2) exit; next}
         c==1 && /^title:/ {
             sub(/^title:[[:space:]]*/, "")
             gsub(/^"|"$/, "")
             print
             exit
         }' "$1"
}

inventory() {
    for dir in "${LAYER2_DIRS[@]}"; do
        full="$REPO_ROOT/$dir"
        [[ -d "$full" ]] || continue
        find "$full" -maxdepth 1 -type f -name '*.md' \
            -not -name '_README.md' \
            | sort
    done
}

generate() {
    local dest="$1"
    local now
    now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local current_version
    current_version=$(grep -E '^\*\*Version\*\*:' "$LIVE" 2>/dev/null \
        | head -1 | sed -E 's/.*\*\*Version\*\*:[[:space:]]*//; s/[[:space:]].*$//' || echo "unknown")

    {
        echo "# Agent Orchestration + Self-Learning Knowledge Base — System Blueprint"
        echo
        echo "> ⚠️ **Regenerated from Layer-2 sources by \`tools/build-blueprint.sh\` on $now.**"
        echo "> This file is a **compiled view** for backwards compatibility. **DO NOT EDIT DIRECTLY** — modify the relevant file under \`00-overview/\`–\`80-status/\` and re-run \`tools/build-blueprint.sh --write\`."
        echo "> Runtime entrypoint for agents: \`INDEX.md\` (Layer-3) + \`bundles/<role>.yaml\`."
        echo
        echo "**Version**: $current_version | **Owner**: KB-Orchestrator-Core (Claude Code)"
        echo "**Regenerated**: $now"
        echo "**Source layout**: $(echo "${LAYER2_DIRS[@]}" | tr ' ' ', ')"
        echo
        echo "---"
        echo

        local current_dir=""
        while IFS= read -r file; do
            [[ -z "$file" ]] && continue
            local rel="${file#$REPO_ROOT/}"
            local dir="${rel%%/*}"
            if [[ "$dir" != "$current_dir" ]]; then
                echo
                echo "# Layer 2 — $dir"
                echo
                current_dir="$dir"
            fi

            local title
            title=$(fm_title "$file")
            [[ -z "$title" ]] && title="$rel"
            echo "## $title"
            echo
            echo "<!-- source: $rel -->"
            echo
            strip_frontmatter "$file"
            echo
        done < <(inventory)

        echo
        echo "---"
        echo
        echo "## Regeneration trailer"
        echo
        echo "This blueprint was assembled from $(inventory | wc -l) Layer-2 files across ${#LAYER2_DIRS[@]} directories."
        echo "Re-run \`tools/build-blueprint.sh --write\` after editing any source file."
        echo "CI gates (\`tools/verify-frontmatter.sh --strict\`, \`tools/verify-cross-refs.sh\`, \`tools/build-bundle.sh --check\`) must remain green."
    } > "$dest"
}

# ----- entry -----

case "$MODE" in
    --dry-run)
        echo "build-blueprint --dry-run: Layer-2 files in canonical concat order:"
        files=$(inventory)
        if [[ -z "$files" ]]; then
            echo "  (none — Layer-2 dirs empty)"
            exit 0
        fi
        echo "$files" | sed "s|$REPO_ROOT/|  |"
        echo
        echo "Total: $(echo "$files" | wc -l) files."
        exit 0
        ;;
    --write)
        echo "build-blueprint --write: regenerating live SYSTEM-BLUEPRINT.md from Layer-2..."
        if [[ ! -f "$LIVE" ]]; then
            echo "build-blueprint: live monolith not found at $LIVE; aborting." >&2
            exit 1
        fi
        ts=$(date -u +"%Y%m%dT%H%M%SZ")
        backup="$REPO_ROOT/.SYSTEM-BLUEPRINT.pre-regen.$ts.md"
        cp "$LIVE" "$backup"
        generate "$LIVE"
        echo "build-blueprint: live monolith regenerated."
        echo "build-blueprint: pre-regen snapshot saved to $(basename "$backup")"
        exit 0
        ;;
    candidate|"")
        generate "$CANDIDATE"
        echo "build-blueprint: candidate written to $(basename "$CANDIDATE")"
        echo "build-blueprint: live monolith untouched."
        echo "build-blueprint: diff against live with: diff SYSTEM-BLUEPRINT.md $(basename "$CANDIDATE")"
        exit 0
        ;;
    -*)
        usage
        ;;
    *)
        usage
        ;;
esac
