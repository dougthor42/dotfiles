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
        echo "Unknown option: ${1}" >&2
        usage >&2
        exit 1
        ;;
    *)
        if [[ -n "${SOURCE_REF}" ]]; then
            echo "Error: Multiple source branches specified ('${SOURCE_REF}' and '${1}')." >&2
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
    echo "Error: Base ref '${BASE_REF}' does not exist." >&2
    exit 1
fi

mapfile -t COMMITS < <(git rev-list --reverse "${BASE_REF}..${SOURCE_REF}")

if [[ ${#COMMITS[@]} -eq 0 ]]; then
    echo "No commits found in ${BASE_REF}..${SOURCE_REF}."
    exit 0
fi

# Verify every commit has a Gerrit Change-Id trailer before starting.
for sha in "${COMMITS[@]}"; do
    if ! git log -n 1 --format='%B' "${sha}" | grep -q '^Change-Id: I[0-9a-f]\{40\}$'; then
        short_sha="$(git rev-parse --short "${sha}")"
        subject="$(git log -n 1 --format='%s' "${sha}")"
        echo "Error: Commit ${short_sha} ('${subject}') is missing a valid Change-Id trailer." >&2
        exit 1
    fi
done

echo "Found ${#COMMITS[@]} commit(s) in ${BASE_REF}..${SOURCE_REF}:"
for sha in "${COMMITS[@]}"; do
    git --no-pager log -n 1 --oneline "${sha}"
done
echo ""

if [[ ${DRY_RUN} -eq 1 ]]; then
    echo "DRY RUN - verifying each commit cherry-picks cleanly onto ${BASE_REF} (nothing will be pushed)."
fi

total="${#COMMITS[@]}"
idx=0
for sha in "${COMMITS[@]}"; do
    idx=$((idx + 1))
    short_sha="$(git rev-parse --short "${sha}")"
    subject="$(git log -n 1 --format='%s' "${sha}")"
    echo "[${idx}/${total}] Processing ${short_sha}: ${subject}"

    if ! tree="$(git merge-tree --write-tree --no-messages --merge-base="${sha}^" "${BASE_REF}" "${sha}")"; then
        echo "Error: Commit ${short_sha} ('${subject}') failed to cherry-pick cleanly onto ${BASE_REF}." >&2
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
        echo "  [dry-run] Would run: git push ${REMOTE} ${new_sha}:refs/for/${TARGET_BRANCH}"
    else
        git push "${REMOTE}" "${new_sha}:refs/for/${TARGET_BRANCH}"
    fi
done

echo ""
echo "Done."
