#!/bin/bash
#
# Find the local git branch(es) containing a given Gerrit Change-Id.
#
# First searches commits on local branches not yet reachable from origin/main
# (which covers both active CLs and lingering local branches whose CLs were
# rebased/squashed onto origin/main by Gerrit). If none are found, falls back
# to checking if any non-main local branch points directly at a fast-forward
# merged commit with that Change-Id.
#
# Intended to be called via the `git cl-search` alias.

set -Eeuo pipefail

SWITCH=0
CHANGE_ID=""

usage() {
    cat <<EOF
Usage: git cl-search [options] <Change-Id>

Find the local branch containing a Gerrit Change-Id.

Options:
  -s, --switch    Switch to the found branch (fails if multiple branches match)
  -h, --help      Show this help message
EOF
}

while [[ $# -gt 0 ]]; do
    case "${1}" in
    -s | --switch)
        SWITCH=1
        shift
        ;;
    -h | --help)
        usage
        exit 0
        ;;
    -*)
        echo "Unknown option: ${1}" >&2
        usage >&2
        exit 1
        ;;
    *)
        if [[ -n "${CHANGE_ID}" ]]; then
            echo "Error: Multiple Change-Ids specified ('${CHANGE_ID}' and '${1}')." >&2
            usage >&2
            exit 1
        fi
        CHANGE_ID="${1}"
        shift
        ;;
    esac
done

if [[ -z "${CHANGE_ID}" ]]; then
    echo "Error: A Gerrit Change-Id is required." >&2
    usage >&2
    exit 1
fi

# Strip optional "Change-Id:" prefix if pasted directly from a commit message.
CHANGE_ID="${CHANGE_ID#Change-Id:}"
CHANGE_ID="${CHANGE_ID#"${CHANGE_ID%%[![:space:]]*}"}"

if [[ ! "${CHANGE_ID}" =~ ^I[0-9a-fA-F]+$ ]]; then
    echo "Error: Invalid Gerrit Change-Id '${CHANGE_ID}' (expected 'I' followed by hex digits)." >&2
    exit 1
fi

# Collect base refs to exclude (both origin/main and local main if present,
# falling back to origin/master and master).
EXCLUDE_REFS=()
for ref in "refs/remotes/origin/main" "refs/heads/main"; do
    if git show-ref --verify --quiet "${ref}"; then
        EXCLUDE_REFS+=("${ref}")
    fi
done

if [[ ${#EXCLUDE_REFS[@]} -eq 0 ]]; then
    for ref in "refs/remotes/origin/master" "refs/heads/master"; do
        if git show-ref --verify --quiet "${ref}"; then
            EXCLUDE_REFS+=("${ref}")
        fi
    done
fi

if [[ ${#EXCLUDE_REFS[@]} -eq 0 ]]; then
    echo "Error: Could not find 'main' or 'master' branch (local or origin)." >&2
    exit 1
fi

GREP_PATTERN="^Change-Id: ${CHANGE_ID}([[:space:]]|$)"

# 1. Search commits on local branches not reachable from main/origin/main.
#    This covers both unmerged CLs and lingering local branches whose CLs were
#    rebased/squashed onto origin/main on Gerrit submit.
mapfile -t MATCHING_SHAS < <(
    git log --branches --not "${EXCLUDE_REFS[@]}" \
        -E --grep="${GREP_PATTERN}" \
        --format='%H'
)

BRANCHES=()
if [[ ${#MATCHING_SHAS[@]} -gt 0 ]]; then
    mapfile -t BRANCHES < <(
        for sha in "${MATCHING_SHAS[@]}"; do
            git for-each-ref --contains "${sha}" --format='%(refname:short)' refs/heads/
        done | sort -u
    )
else
    # 2. Fallback for fast-forward merged branches: check if any non-main local
    #    branch points directly at a merged commit with this Change-Id.
    mapfile -t MERGED_SHAS < <(
        git log "${EXCLUDE_REFS[@]}" \
            -E --grep="${GREP_PATTERN}" \
            --format='%H'
    )
    if [[ ${#MERGED_SHAS[@]} -gt 0 ]]; then
        mapfile -t BRANCHES < <(
            for sha in "${MERGED_SHAS[@]}"; do
                git for-each-ref --points-at "${sha}" --format='%(refname:short)' refs/heads/
            done | grep -v -E '^(main|master)$' | sort -u || true
        )
    fi
fi

if [[ ${#BRANCHES[@]} -eq 0 ]]; then
    echo "No local branch found containing Change-Id '${CHANGE_ID}'." >&2
    exit 1
fi

if [[ ${SWITCH} -eq 1 ]]; then
    if [[ ${#BRANCHES[@]} -gt 1 ]]; then
        echo "Error: Change-Id '${CHANGE_ID}' found in multiple local branches; cannot switch automatically:" >&2
        printf '  %s\n' "${BRANCHES[@]}" >&2
        exit 1
    fi
    git switch "${BRANCHES[0]}"
else
    printf '%s\n' "${BRANCHES[@]}"
fi
