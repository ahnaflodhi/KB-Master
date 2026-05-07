#!/usr/bin/env bash
# build-bundle.sh — generate / verify bundle manifests against Layer-2 frontmatter
#
# Per ~/.claude/plans/crispy-sniffing-conway.md "Bundle manifest format" +
# "Programmatic bundle generation" + "Phase 6 exit criteria" + "Continuous
# verification: Quarterly tools/build-bundle.sh --check".
#
# Phase 6 (v3.0, 2026-05-07): real --check semantics. The committed v1 bundles
# in bundles/*.yaml are hand-curated (per bundles/_README.md). --check enforces
# REFERENTIAL INTEGRITY rather than byte-equivalent regeneration:
#
#   1. Each bundle has the structural fields (bundle:, version:, loads:).
#   2. Every path in loads:/optional:/adapter_specific: exists on disk.
#   3. Every loads: file (excluding "universal" files — invariants, glossary,
#      pipeline kernel, adapter contracts, status) declares the consuming role
#      in its frontmatter `audience` or `also_needed_by`. This catches drift
#      where a frontmatter edit removes a role from audience without the bundle
#      being updated.
#
# Byte-equivalent deterministic regeneration (the "tools/build-bundle.sh
# regenerates the manifest exactly" behaviour) remains a future enhancement —
# the v1 bundles include subjective ordering and curated optional/adapter
# sections that pure frontmatter rules don't reproduce. Until then, generate
# mode emits a CANDIDATE manifest (audience-derived loads list) to stdout for
# human review against the committed file.
#
# Generation rule (used by generate mode for the candidate, by --check for the
# audience match):
#   file ∈ bundle(R) iff
#     R ∈ frontmatter.audience
#     OR R ∈ frontmatter.also_needed_by
#     OR file is in the universal-loadables allowlist (invariants, glossary,
#        pipeline kernel files, adapter contracts, shipped-vs-planned)
#
# Exit codes:
#   0 — success
#   1 — drift / referential-integrity failure (--check mode) or generation error
#   2 — usage error
#
# Usage:
#   tools/build-bundle.sh <role>         — emit candidate bundles/<role>.yaml to stdout
#   tools/build-bundle.sh --check        — verify all bundles
#   tools/build-bundle.sh --check <role> — verify a single bundle

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUNDLES_DIR="$REPO_ROOT/bundles"
LAYER2_DIRS=(00-overview 10-pipeline 20-roles 30-knowledge 40-runtime 50-adapters 60-schemas 70-adoption 80-status)

usage() {
    sed -n '2,/^$/p' "$0" | sed 's/^# \?//'
    exit 2
}

# ----- frontmatter extraction -----

fm_block() {
    awk '/^---[[:space:]]*$/{c++; if (c==2) exit; next} c==1' "$1"
}

# Reads frontmatter block on stdin, prints values of YAML list field $1.
# Handles both inline (field: [a, b]) and block (field:\n  - a\n  - b) forms.
fm_list() {
    local field="$1"
    awk -v field="$field" '
        BEGIN { in_block=0 }
        $0 ~ "^"field":[[:space:]]*\\[" {
            line=$0
            sub("^"field":[[:space:]]*\\[", "", line)
            sub("\\][[:space:]]*$", "", line)
            n = split(line, parts, ",")
            for (i=1; i<=n; i++) {
                gsub(/^[[:space:]]+|[[:space:]]+$/, "", parts[i])
                gsub(/^"|"$/, "", parts[i])
                if (parts[i] != "") print parts[i]
            }
            next
        }
        $0 ~ "^"field":[[:space:]]*$" { in_block=1; next }
        in_block && /^[[:space:]]*-[[:space:]]/ {
            v=$0
            sub(/^[[:space:]]*-[[:space:]]+/, "", v)
            sub(/[[:space:]]+#.*$/, "", v)
            gsub(/^"|"$/, "", v)
            sub(/[[:space:]]*$/, "", v)
            if (v != "") print v
            next
        }
        in_block && /^[a-zA-Z_]+:/ { in_block=0 }
    '
}

# ----- bundle extraction -----

bundle_list() {
    local file="$1" field="$2"
    awk -v field="$field" '
        $0 ~ "^"field":[[:space:]]*$" { in_block=1; next }
        in_block && /^[[:space:]]*-[[:space:]]/ {
            v=$0
            sub(/^[[:space:]]*-[[:space:]]+/, "", v)
            sub(/[[:space:]]+#.*$/, "", v)
            sub(/[[:space:]]*$/, "", v)
            if (v != "") print v
            next
        }
        in_block && /^[a-zA-Z_]+:/ { in_block=0 }
    ' "$file"
}

bundle_adapter_specific() {
    awk '
        BEGIN { adapter=""; in_block=0 }
        /^adapter_specific:[[:space:]]*$/ { in_block=1; next }
        in_block && /^[a-zA-Z_]+:/ && $0 !~ /^[[:space:]]/ { in_block=0; adapter="" }
        in_block && /^[[:space:]]{2}[a-zA-Z_-]+:[[:space:]]*$/ {
            a=$0
            sub(/^[[:space:]]+/, "", a)
            sub(/:[[:space:]]*$/, "", a)
            adapter=a
            next
        }
        in_block && adapter != "" && /^[[:space:]]*-[[:space:]]/ {
            v=$0
            sub(/^[[:space:]]*-[[:space:]]+/, "", v)
            sub(/[[:space:]]+#.*$/, "", v)
            sub(/[[:space:]]*$/, "", v)
            if (v != "") print adapter ":" v
        }
    ' "$1"
}

# ----- bundle-name → role-name normalization -----
# Bundle filenames use dashes (apply-meta.yaml); audience fields use the role
# names from agents.config.yaml, which are underscored (apply_meta). A few
# bundles are sub-specializations (executor-research → executor) or composites
# (orchestrator-core, agent-onboarding) that don't map to a single role.
bundle_to_role() {
    case "$1" in
        agent-onboarding|orchestrator-core) echo "*" ;;       # any-audience match
        executor-research|executor-commercial) echo "executor" ;;
        *) echo "${1//-/_}" ;;
    esac
}

# ----- universal-loadables allowlist -----

is_universal_file() {
    case "$1" in
        00-overview/invariants.md) return 0 ;;
        00-overview/glossary.md) return 0 ;;
        00-overview/design-principles.md) return 0 ;;
        00-overview/philosophy.md) return 0 ;;
        00-overview/system-map.md) return 0 ;;
        10-pipeline/state-machine.md) return 0 ;;
        10-pipeline/file-contracts.md) return 0 ;;
        10-pipeline/iteration-lifecycle.md) return 0 ;;
        10-pipeline/quality-gates.md) return 0 ;;
        10-pipeline/escalation-rules.md) return 0 ;;
        50-adapters/*.md) return 0 ;;
        80-status/shipped-vs-planned.md) return 0 ;;
        *) return 1 ;;
    esac
}

# ----- core check -----

check_bundle() {
    local bundle_file="$1"
    local rel="${bundle_file#$REPO_ROOT/}"
    local errors=0

    for required in 'bundle:' 'version:' 'loads:'; do
        if ! grep -qE "^${required}" "$bundle_file"; then
            echo "FAIL: $rel — missing required field: ${required%:}"
            errors=$((errors + 1))
        fi
    done
    if (( errors > 0 )); then
        return 1
    fi

    local bundle_name role
    bundle_name=$(grep -E '^bundle:' "$bundle_file" | head -1 \
        | sed -E 's/^bundle:[[:space:]]*//; s/[[:space:]]*#.*$//; s/^"//; s/"$//')
    role=$(bundle_to_role "$bundle_name")

    while IFS= read -r path; do
        [[ -z "$path" ]] && continue
        local full="$REPO_ROOT/$path"
        if [[ ! -f "$full" ]]; then
            echo "FAIL: $rel — loads: file does not exist: $path"
            errors=$((errors + 1))
            continue
        fi
        # _README.md files are meta (no frontmatter) — skip audience check
        if [[ "$(basename "$path")" == "_README.md" ]]; then
            continue
        fi
        if is_universal_file "$path"; then
            continue
        fi
        # Composite bundles (orchestrator-core, agent-onboarding) accept any audience.
        if [[ "$role" == "*" ]]; then
            continue
        fi
        local audience also_needed combined
        audience=$(fm_block "$full" | fm_list audience)
        also_needed=$(fm_block "$full" | fm_list also_needed_by)
        combined=$(printf '%s\n%s\n' "$audience" "$also_needed" | grep -v '^$' || true)
        if ! grep -qxF "$role" <<< "$combined"; then
            echo "FAIL: $rel — loads: $path does not declare audience including '$role' (audience: $(echo "$audience" | paste -sd, -); also_needed_by: $(echo "$also_needed" | paste -sd, -))"
            errors=$((errors + 1))
        fi
    done < <(bundle_list "$bundle_file" loads)

    while IFS= read -r path; do
        [[ -z "$path" ]] && continue
        local full="$REPO_ROOT/$path"
        if [[ ! -f "$full" ]]; then
            echo "FAIL: $rel — optional: file does not exist: $path"
            errors=$((errors + 1))
        fi
    done < <(bundle_list "$bundle_file" optional)

    while IFS= read -r entry; do
        [[ -z "$entry" ]] && continue
        local path="${entry#*:}"
        local full="$REPO_ROOT/$path"
        if [[ ! -f "$full" ]]; then
            echo "FAIL: $rel — adapter_specific: file does not exist: $path"
            errors=$((errors + 1))
        fi
    done < <(bundle_adapter_specific "$bundle_file")

    if (( errors > 0 )); then
        return 1
    fi
    return 0
}

# ----- generate-candidate mode -----

generate_candidate() {
    local role="$1"
    local declared=()
    local universal=()

    for dir in "${LAYER2_DIRS[@]}"; do
        local full_dir="$REPO_ROOT/$dir"
        [[ -d "$full_dir" ]] || continue
        while IFS= read -r -d '' file; do
            [[ "$(basename "$file")" == "_README.md" ]] && continue
            local rel="${file#$REPO_ROOT/}"
            local audience also_needed combined
            audience=$(fm_block "$file" | fm_list audience)
            also_needed=$(fm_block "$file" | fm_list also_needed_by)
            combined=$(printf '%s\n%s\n' "$audience" "$also_needed" | grep -v '^$' || true)
            if grep -qxF "$role" <<< "$combined"; then
                declared+=("$rel")
            elif is_universal_file "$rel"; then
                universal+=("$rel")
            fi
        done < <(find "$full_dir" -maxdepth 1 -type f -name '*.md' -print0 | sort -z)
    done

    echo "bundle: $role"
    echo "version: 1"
    echo "# CANDIDATE — derived from frontmatter audience/also_needed_by + universal allowlist."
    echo "# Compare against committed bundles/$role.yaml. Committed file is the source of truth."
    echo "loads:"
    if (( ${#declared[@]} > 0 )); then
        for f in "${declared[@]}"; do echo "  - $f"; done
    fi
    if (( ${#universal[@]} > 0 )); then
        echo "# universal-loadables (any bundle may include):"
        for f in "${universal[@]}"; do echo "  - $f"; done
    fi
    echo "# optional: (curated — not derivable from frontmatter)"
    echo "# adapter_specific: (curated — not derivable from frontmatter)"
    echo "# estimated_tokens: (run wc -w on resolved files; multiply by ~1.3)"
    echo "loadable_by_protocol: 1"
}

# ----- entry -----

if [[ $# -eq 0 ]]; then
    usage
fi

MODE="$1"
ROLE="${2:-}"

case "$MODE" in
    -h|--help)
        usage
        ;;
    --check)
        if [[ ! -d "$BUNDLES_DIR" ]]; then
            echo "build-bundle --check: bundles/ directory does not exist; exiting 0"
            exit 0
        fi
        shopt -s nullglob
        if [[ -n "$ROLE" ]]; then
            BUNDLE_FILES=("$BUNDLES_DIR/$ROLE.yaml")
            if [[ ! -f "${BUNDLE_FILES[0]}" ]]; then
                echo "build-bundle --check: bundle does not exist: bundles/$ROLE.yaml" >&2
                exit 1
            fi
        else
            BUNDLE_FILES=("$BUNDLES_DIR"/*.yaml)
        fi
        shopt -u nullglob
        if (( ${#BUNDLE_FILES[@]} == 0 )); then
            echo "build-bundle --check: no bundle manifests in bundles/; exiting 0"
            exit 0
        fi
        FAILED_BUNDLES=0
        for f in "${BUNDLE_FILES[@]}"; do
            if ! check_bundle "$f"; then
                FAILED_BUNDLES=$((FAILED_BUNDLES + 1))
            fi
        done
        if (( FAILED_BUNDLES > 0 )); then
            echo
            echo "build-bundle --check: $FAILED_BUNDLES of ${#BUNDLE_FILES[@]} bundle(s) failed referential-integrity check"
            exit 1
        fi
        echo "build-bundle --check: ${#BUNDLE_FILES[@]} bundle(s) passed referential-integrity check"
        exit 0
        ;;
    -*)
        usage
        ;;
    *)
        ROLE="$MODE"
        generate_candidate "$ROLE"
        exit 0
        ;;
esac
