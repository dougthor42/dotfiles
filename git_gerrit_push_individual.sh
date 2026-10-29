#!/usr/bin/env bash
#
# Push each commit on a branch (relative to origin/main) as an individual,
# non-chained Gerrit CL by creating an in-memory cherry-pick onto the base ref
# and pushing to refs/for/<target>.
#
# Intended to be called via the `git cl-push-individual` alias.

set -Eeuo pipefail

DRY_RUN=0
REMOTE="origin"
TARGET_BRANCH="main"
SOURCE_REF=""

readonly C_GREYBRIGHT=$'\033[1;30m'
readonly C_REDBRIGHT=$'\033[1;31m'
readonly C_GREENBRIGHT=$'\033[1;32m'
readonly C_YELLOWBRIGHT=$'\033[1;33m'
readonly C_BLUEBRIGHT=$'\033[1;34m'
readonly C_WHITEBRIGHT=$'\033[1;37m'
readonly C_RESET=$'\033[0m'

usage() {
    cat <<EOF
Usage: git cl-push-individual [options] [<branch>]

Push each commit on <branch> (default: current HEAD) as an independent,
non-chained Gerrit CL rooted at <remote>/<target>.

Options:
  -n, --dry-run           Verify cherry-picks onto base and show push commands
                          without actually pushing to Gerrit
  -t, --target <branch>   Target branch on remote (default: main)
  -r, --remote <remote>   Remote name (default: origin)
  -h, --help              Show this help message
EOF
}

while [[ $# -gt 0 ]]; do
    case "${1}" in
    -n | --dry-run)
        DRY_RUN=1
        shift
        ;;
    -t | --target)
        TARGET_BRANCH="${2:?Error: --target requires a branch name}"
        shift 2
        ;;
    -r | --remote)
        REMOTE="${2:?Error: --remote requires a remote name}"
        shift 2
        ;;
    -h | --help)
        usage
        exit 0
        ;;
    -*)
        echo "${C_REDBRIGHT}Unknown option:${C_RESET} ${1}" >&2
        usage >&2
        exit 1
        ;;
    *)
        if [[ -n "${SOURCE_REF}" ]]; then
            echo "${C_REDBRIGHT}Error:${C_RESET} Multiple source branches specified ('${SOURCE_REF}' and '${1}')." >&2
            usage >&2
            exit 1
        fi
        SOURCE_REF="${1}"
        shift
        ;;
    esac
done

if [[ -z "${SOURCE_REF}" ]]; then
    SOURCE_REF="$(git symbolic-ref --quiet --short HEAD || git rev-parse HEAD)"
fi

BASE_REF="${REMOTE}/${TARGET_BRANCH}"
if ! git rev-parse --verify --quiet "${BASE_REF}" >/dev/null; then
    echo "${C_REDBRIGHT}Error:${C_RESET} Base ref '${BASE_REF}' does not exist." >&2
    exit 1
fi

mapfile -t COMMITS < <(git rev-list --reverse "${BASE_REF}..${SOURCE_REF}")

if [[ ${#COMMITS[@]} -eq 0 ]]; then
    echo "No commits found in ${C_WHITEBRIGHT}${BASE_REF}..${SOURCE_REF}${C_RESET}."
    exit 0
fi

# Verify every commit has a Gerrit Change-Id trailer before starting.
for sha in "${COMMITS[@]}"; do
    if ! git log -n 1 --format='%B' "${sha}" | grep -q '^Change-Id: I[0-9a-f]\{40\}$'; then
        short_sha="$(git rev-parse --short "${sha}")"
        subject="$(git log -n 1 --format='%s' "${sha}")"
        echo "${C_REDBRIGHT}Error:${C_RESET} Commit ${C_YELLOWBRIGHT}${short_sha}${C_RESET} ('${subject}') is missing a valid Change-Id trailer." >&2
        exit 1
    fi
done

echo "Found ${#COMMITS[@]} commit(s) in ${C_WHITEBRIGHT}${BASE_REF}..${SOURCE_REF}${C_RESET}:"
for sha in "${COMMITS[@]}"; do
    git --no-pager log -n 1 --format="  ${C_YELLOWBRIGHT}%h${C_RESET} ${C_BLUEBRIGHT}%s${C_RESET}" "${sha}"
done
echo ""

if [[ ${DRY_RUN} -eq 1 ]]; then
    echo "${C_YELLOWBRIGHT}DRY RUN - verifying each commit cherry-picks cleanly onto ${BASE_REF} (nothing will be pushed).${C_RESET}"
fi

total="${#COMMITS[@]}"
idx=0
for sha in "${COMMITS[@]}"; do
    idx=$((idx + 1))
    short_sha="$(git rev-parse --short "${sha}")"
    subject="$(git log -n 1 --format='%s' "${sha}")"
    echo "[${idx}/${total}] Processing ${C_YELLOWBRIGHT}${short_sha}${C_RESET}: ${C_BLUEBRIGHT}${subject}${C_RESET}"

    if ! tree="$(git merge-tree --write-tree --no-messages --merge-base="${sha}^" "${BASE_REF}" "${sha}")"; then
        echo "${C_REDBRIGHT}Error:${C_RESET} Commit ${C_YELLOWBRIGHT}${short_sha}${C_RESET} ('${subject}') failed to cherry-pick cleanly onto ${C_WHITEBRIGHT}${BASE_REF}${C_RESET}." >&2
        echo "It likely depends on changes from an earlier commit in the series." >&2
        exit 1
    fi

    new_sha="$(
        GIT_AUTHOR_NAME="$(git log -n 1 --format='%an' "${sha}")" \
        GIT_AUTHOR_EMAIL="$(git log -n 1 --format='%ae' "${sha}")" \
        GIT_AUTHOR_DATE="$(git log -n 1 --format='%aI' "${sha}")" \
        git commit-tree "${tree}" -p "${BASE_REF}" -F <(git log -n 1 --format='%B' "${sha}")
    )"

    if [[ ${DRY_RUN} -eq 1 ]]; then
        echo "  ${C_GREYBRIGHT}[dry-run] Would run: git push ${REMOTE} ${new_sha}:refs/for/${TARGET_BRANCH}${C_RESET}"
    else
        git push "${REMOTE}" "${new_sha}:refs/for/${TARGET_BRANCH}"
    fi
done

echo ""
echo "${C_GREENBRIGHT}Done.${C_RESET}"
