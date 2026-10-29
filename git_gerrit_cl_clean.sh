#!/bin/bash
#
# Delete local git branches that are fully merged into main or origin/main,
# either as direct git ancestors (fast-forward merges) or because every commit
# on the branch ahead of main/origin/main has a Gerrit Change-Id that has
# landed in main or origin/main.
#
# Intended to be called via the `git cl-clean` alias.

set -Eeuo pipefail

DRY_RUN=0
VERBOSE=0
FORCE=0
SUBJECT_WIDTH=80

readonly C_REDBRIGHT=$'\033[1;31m'
readonly C_YELLOWBRIGHT=$'\033[1;33m'
readonly C_BLUEBRIGHT=$'\033[1;34m'
readonly C_WHITEBRIGHT=$'\033[1;37m'
readonly C_RESET=$'\033[0m'

echo_info() {
    if [[ ${VERBOSE} -ge 1 ]]; then
        echo "$@"
    fi
}

echo_debug() {
    if [[ ${VERBOSE} -ge 2 ]]; then
        echo "$@"
    fi
}

echo_trace() {
    if [[ ${VERBOSE} -ge 3 ]]; then
        echo "$@"
    fi
}

usage() {
    cat <<EOF
Usage: git cl-clean [options]

Delete local branches that are fully merged into main or origin/main
(including branches whose Gerrit Change-Ids have been submitted).

Options:
  -n, --dry-run   Show which branches would be deleted without deleting them
  -f, --force     Delete merged branches even if other unmerged local branches
                  are stacked on top of them
  -v, --verbose   Increase verbosity (-v, -vv, -vvv)
  -w, --subject-width N
                  Max characters of the commit subject (1st line of the commit
                  message) printed under each deleted branch (default: 80,
                  0 to disable)
  -h, --help      Show this help message
EOF
}

# Print the first line of the tip commit message of the given branch, indented
# and truncated to SUBJECT_WIDTH characters (with a trailing "..." if truncated).
print_subject() {
    local ref="${1}"
    local subject
    if [[ ${SUBJECT_WIDTH} -le 0 ]]; then
        return
    fi
    subject="$(git log -n 1 --format='%s' "${ref}" 2>/dev/null || true)"
    if [[ -z "${subject}" ]]; then
        return
    fi
    if [[ ${#subject} -gt ${SUBJECT_WIDTH} ]]; then
        if [[ ${SUBJECT_WIDTH} -gt 3 ]]; then
            subject="${subject:0:$((SUBJECT_WIDTH - 3))}..."
        else
            subject="${subject:0:${SUBJECT_WIDTH}}"
        fi
    fi
    echo "  ${C_BLUEBRIGHT}${subject}${C_RESET}"
}

while [[ $# -gt 0 ]]; do
    case "${1}" in
    -n | --dry-run)
        DRY_RUN=1
        shift
        ;;
    -f | --force)
        FORCE=1
        shift
        ;;
    -w | --subject-width)
        if [[ $# -lt 2 || ! "${2}" =~ ^[0-9]+$ ]]; then
            echo "${C_REDBRIGHT}Error:${C_RESET} ${1} requires a non-negative integer argument" >&2
            exit 1
        fi
        SUBJECT_WIDTH="${2}"
        shift 2
        ;;
    --subject-width=*)
        SUBJECT_WIDTH="${1#*=}"
        if [[ ! "${SUBJECT_WIDTH}" =~ ^[0-9]+$ ]]; then
            echo "${C_REDBRIGHT}Error:${C_RESET} --subject-width requires a non-negative integer argument" >&2
            exit 1
        fi
        shift
        ;;
    -v | --verbose)
        VERBOSE=$((VERBOSE + 1))
        shift
        ;;
    -vv)
        VERBOSE=2
        shift
        ;;
    -vvv)
        VERBOSE=3
        shift
        ;;
    -h | --help)
        usage
        exit 0
        ;;
    *)
        echo "${C_REDBRIGHT}Unknown option:${C_RESET} ${1}" >&2
        usage >&2
        exit 1
        ;;
    esac
done

# Collect base refs to check against (both origin/main and local main if present,
# falling back to origin/master and master).
BASE_REFS=()
BASE_LABELS=()
MAIN_BRANCH=""

for branch_name in "main" "master"; do
    if git show-ref --verify --quiet "refs/remotes/origin/${branch_name}"; then
        BASE_REFS+=("refs/remotes/origin/${branch_name}")
        BASE_LABELS+=("origin/${branch_name}")
    fi
    if git show-ref --verify --quiet "refs/heads/${branch_name}"; then
        BASE_REFS+=("refs/heads/${branch_name}")
        BASE_LABELS+=("${branch_name}")
        MAIN_BRANCH="${branch_name}"
    fi
    if [[ ${#BASE_REFS[@]} -gt 0 ]]; then
        break
    fi
done

if [[ ${#BASE_REFS[@]} -eq 0 ]]; then
    echo "${C_REDBRIGHT}Error:${C_RESET} Could not find 'main' or 'master' branch (local or origin)." >&2
    exit 1
fi

BASE_SUMMARY="$(printf '%s, ' "${BASE_LABELS[@]}")"
BASE_SUMMARY="${BASE_SUMMARY%, }"
echo "Pruning local branches fully merged into ${BASE_SUMMARY}..."
if [[ ${DRY_RUN} -eq 1 ]]; then
    echo "${C_YELLOWBRIGHT}DRY RUN - no branches will be deleted.${C_RESET}"
fi

# Index all Change-Ids present in main / origin/main in a single git log pass.
declare -A MERGED_CHANGE_IDS=()
while IFS= read -r cid; do
    if [[ -n "${cid}" ]]; then
        MERGED_CHANGE_IDS["${cid}"]=1
    fi
done < <(
    git log "${BASE_REFS[@]}" --format='%(trailers:key=Change-Id,valueonly=true)' |
        sed 's/[[:space:]]//g' |
        grep -E '^I[0-9a-fA-F]+$' || true
)

CURRENT_BRANCH="$(git branch --show-current)"

declare -a ALL_BRANCHES=()
mapfile -t ALL_BRANCHES < <(git for-each-ref --format='%(refname:short)' refs/heads/)

declare -A MERGED_REASON=()
declare -A IS_ANCESTOR=()
declare -a KEPT_BRANCHES=()
declare -a MERGED_BRANCHES=()

for branch in "${ALL_BRANCHES[@]}"; do
    if [[ "${branch}" == "main" || "${branch}" == "master" ]]; then
        continue
    fi

    echo_debug "Checking ${branch} ..."

    mapfile -t UNMERGED_SHAS < <(git rev-list "${branch}" --not "${BASE_REFS[@]}")

    if [[ ${#UNMERGED_SHAS[@]} -eq 0 ]]; then
        if [[ "${branch}" == "${CURRENT_BRANCH}" ]]; then
            echo_info "Skipping current branch '${C_WHITEBRIGHT}${branch}${C_RESET}' (0 commits ahead of ${BASE_SUMMARY})"
            KEPT_BRANCHES+=("${branch}")
            continue
        fi
        MERGED_BRANCHES+=("${branch}")
        MERGED_REASON["${branch}"]="ancestor of ${BASE_SUMMARY}"
        IS_ANCESTOR["${branch}"]=1
        continue
    fi

    all_cids_merged=1
    for sha in "${UNMERGED_SHAS[@]}"; do
        mapfile -t cids < <(
            git log -n 1 --format='%(trailers:key=Change-Id,valueonly=true)' "${sha}" |
                sed 's/[[:space:]]//g' |
                grep -E '^I[0-9a-fA-F]+$' || true
        )
        if [[ ${#cids[@]} -eq 0 ]]; then
            echo_trace "  ${sha}: no Change-Id trailer found"
            all_cids_merged=0
            break
        fi
        sha_merged=0
        for cid in "${cids[@]}"; do
            if [[ -n "${MERGED_CHANGE_IDS[${cid}]+isset}" ]]; then
                echo_trace "  ${sha}: Change-Id ${cid} is merged"
                sha_merged=1
                break
            fi
        done
        if [[ ${sha_merged} -eq 0 ]]; then
            echo_trace "  ${sha}: Change-Id(s) ${cids[*]} not in ${BASE_SUMMARY}"
            all_cids_merged=0
            break
        fi
    done

    if [[ ${all_cids_merged} -eq 1 ]]; then
        MERGED_BRANCHES+=("${branch}")
        MERGED_REASON["${branch}"]="all ${#UNMERGED_SHAS[@]} Gerrit Change-Id(s) merged"
        IS_ANCESTOR["${branch}"]=0
    else
        KEPT_BRANCHES+=("${branch}")
    fi
done

for branch in "${MERGED_BRANCHES[@]}"; do
    # For non-ancestor branches (rebased by Gerrit), check if any unmerged
    # local branch is stacked on top of this branch's local commit SHA.
    if [[ ${IS_ANCESTOR["${branch}"]} -eq 0 ]]; then
        DEPENDENT_BRANCHES=()
        for kept in "${KEPT_BRANCHES[@]}"; do
            if git merge-base --is-ancestor "${branch}" "${kept}"; then
                DEPENDENT_BRANCHES+=("${kept}")
            fi
        done

        if [[ ${#DEPENDENT_BRANCHES[@]} -gt 0 && ${FORCE} -eq 0 ]]; then
            echo_info "${C_WHITEBRIGHT}${branch}${C_RESET} is a dependency of unmerged branch(es). Not deleting without --force"
            for dep in "${DEPENDENT_BRANCHES[@]}"; do
                echo_trace "  ${C_WHITEBRIGHT}${dep}${C_RESET}"
            done
            continue
        fi
    fi

    echo_info "${C_WHITEBRIGHT}${branch}${C_RESET}: ${MERGED_REASON["${branch}"]}"

    if [[ ${DRY_RUN} -eq 1 ]]; then
        echo "${C_WHITEBRIGHT}${branch}${C_RESET} is merged into ${BASE_SUMMARY} and can be deleted"
        print_subject "${branch}"
        continue
    fi

    if [[ "${branch}" == "${CURRENT_BRANCH}" ]]; then
        target_checkout="${MAIN_BRANCH:-${BASE_LABELS[0]}}"
        echo "Switching from '${C_WHITEBRIGHT}${CURRENT_BRANCH}${C_RESET}' to '${C_WHITEBRIGHT}${target_checkout}${C_RESET}'"
        git checkout -q "${target_checkout}"
        CURRENT_BRANCH="$(git branch --show-current)"
    fi

    # Capture the subject before deleting, since the ref is gone afterwards.
    branch_sha="$(git rev-parse --verify --quiet "refs/heads/${branch}")"
    git branch -D "${branch}" |
        sed -E "s/^(Deleted branch )(.+)( \(was .*\)\.)$/\1${C_WHITEBRIGHT}\2${C_RESET}\3/"
    print_subject "${branch_sha}"
done
