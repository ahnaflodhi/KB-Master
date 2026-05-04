#!/usr/bin/env bash
# build-bundle.sh — generate / verify bundle manifests from Layer-2 frontmatter
#
# Per ~/.claude/plans/crispy-sniffing-conway.md "Bundle manifest format" +
# "Programmatic bundle generation" + "Phase 6 exit criteria #4" + "Continuous
# verification: Quarterly tools/build-bundle.sh --check".
#
# Phase 1 (today, v2.8.1): skeleton only. The generation rule is documented but
# the actual rule executes meaningfully only after 20-roles/ + 60-schemas/ are
# populated (Phase 3-5). Until then:
#   - generate mode (no flag): exits 0, no-op (nothing to generate from)
#   - --check mode: exits 0 if no bundles exist; otherwise verifies each bundle
#     exists and has minimal valid YAML structure
#
# Generation rule (documented for future implementation):
#   file ∈ bundle(R) iff
#     R ∈ frontmatter.audience
#     OR (R ∈ frontmatter.also_needed_by AND included_by_dependency_closure)
#     OR (frontmatter.purpose == "invariant")
#     OR (frontmatter.purpose == "schema" AND role's primary output schema id matches)
#
# Exit codes:
#   0 — success (or no work to do at this phase)
#   1 — drift detected (--check mode) or generation error
#   2 — usage error
#
# Usage:
#   tools/build-bundle.sh <role>         — generate bundles/<role>.yaml from frontmatter
#   tools/build-bundle.sh --check        — verify all existing bundles match frontmatter-derived membership
#   tools/build-bundle.sh --check <role> — verify a single bundle

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUNDLES_DIR="$REPO_ROOT/bundles"
MODE="${1:-generate}"
ROLE="${2:-}"

usage() {
    sed -n '2,/^$/p' "$0" | sed 's/^# \?//'
    exit 2
}

if [[ "$MODE" == "-h" || "$MODE" == "--help" ]]; then
    usage
fi

if [[ "$MODE" == "--check" ]]; then
    if [[ ! -d "$BUNDLES_DIR" ]]; then
        echo "build-bundle: bundles/ directory does not exist yet (Phase 1 — expected); exiting 0"
        exit 0
    fi
    shopt -s nullglob
    BUNDLE_FILES=("$BUNDLES_DIR"/*.yaml)
    shopt -u nullglob
    if (( ${#BUNDLE_FILES[@]} == 0 )); then
        echo "build-bundle --check: no bundles exist yet (Phase 5 not yet executed); exiting 0"
        exit 0
    fi
    ERRORS=0
    for bundle_file in "${BUNDLE_FILES[@]}"; do
        rel="${bundle_file#$REPO_ROOT/}"
        for required in 'bundle:' 'version:' 'loads:'; do
            if ! grep -qE "^${required}" "$bundle_file"; then
                echo "FAIL: $rel — missing required field: ${required%:}"
                ERRORS=$((ERRORS + 1))
            fi
        done
    done
    if (( ERRORS > 0 )); then
        echo
        echo "build-bundle --check: $ERRORS errors across ${#BUNDLE_FILES[@]} bundle(s)"
        exit 1
    fi
    echo "build-bundle --check: ${#BUNDLE_FILES[@]} bundles checked, structure valid"
    echo "(NOTE: full frontmatter-derived membership drift check lands in Phase 5.)"
    exit 0
fi

if [[ -z "$ROLE" || "$MODE" =~ ^- ]]; then
    usage
fi

echo "build-bundle: generate mode for role='$ROLE'"
echo "build-bundle: full generation logic lands in v3.0 Phase 5 (per plan)."
echo "build-bundle: Phase 1 skeleton — no bundles generated."
exit 0
