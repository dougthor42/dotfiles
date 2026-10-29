#!/usr/bin/env bash
#
# This script deletes all local branches that were squashed and merged (such
# as from the GitHub / GitLab web UI).
#
# Modified from https://stackoverflow.com/a/56026209/1354930
#
# It's really only used in a git alias 'prune-squash-merged' (see
# https://stackoverflow.com/a/46435987/1354930).
#
# It supports a "dry run" mode with either the '-n' or '--dry-run' arg.

# Parse args
# See https://stackoverflow.com/a/33826763/1354930
DRY_RUN=0
VERBOSE=0
SUBJECT_WIDTH=80

MAIN_BRANCH="main"
ALT_MAIN_BRANCH="master"

readonly C_REDBRIGHT=$'\033[1;31m'
readonly C_YELLOWBRIGHT=$'\033[1;33m'
readonly C_BLUEBRIGHT=$'\033[1;34m'
readonly C_WHITEBRIGHT=$'\033[1;37m'
readonly C_RESET=$'\033[0m'

usage() {
    cat <<EOF
Usage: git prune-squash-merged [options]

Delete local branches that were squashed and merged onto main (or master).

Options:
  -n, --dry-run   Show which branches would be deleted without deleting them
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

while [[ "$#" -gt 0 ]]; do
    case $1 in
    -n | --dry-run)
        DRY_RUN=1
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
        VERBOSE=1
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
        echo "${C_REDBRIGHT}Unknown parameter passed:${C_RESET} $1" >&2
        usage >&2
        exit 1
        ;;
    esac
done

echo "Pruning local branches that were squashed and merged onto $MAIN_BRANCH..."
if [[ $DRY_RUN -eq 1 ]]; then
    echo "${C_YELLOWBRIGHT}DRY RUN - no branches will be deleted.${C_RESET}"
fi

if ! $(git show-ref --quiet refs/heads/${MAIN_BRANCH}); then
    echo "Branch '${C_WHITEBRIGHT}${MAIN_BRANCH}${C_RESET}' not found, trying '${C_WHITEBRIGHT}${ALT_MAIN_BRANCH}${C_RESET}'."
    MAIN_BRANCH=$ALT_MAIN_BRANCH
fi

# Prune local branches that we squashed and merged.
# See https://stackoverflow.com/a/56026209/1354930
CURRENT_BRANCH="$(git branch --show-current)"
if [[ "${CURRENT_BRANCH}" != "${MAIN_BRANCH}" ]]; then
    echo "Switching from '${C_WHITEBRIGHT}${CURRENT_BRANCH}${C_RESET}' to '${C_WHITEBRIGHT}${MAIN_BRANCH}${C_RESET}'"
    git checkout -q $MAIN_BRANCH
fi

git for-each-ref refs/heads/ "--format=%(refname:short)" |
    while read branch; do
        if [[ $VERBOSE -eq 2 ]]; then
            echo "Checking ${C_WHITEBRIGHT}$branch${C_RESET} ..."
        fi
        # Get the merge-base. The merge-base is the "best common ancestor(s)
        # between two commits". Eg: the commit on master that a branch was
        # created from.
        mergeBase=$(git merge-base $MAIN_BRANCH "$branch")

        # uncomment these two lines to see what the mergeBase for each branch is
        # branch_name=$(git --no-pager show -s --format="%D" $mergeBase)
        # echo "Merge base for $branch is $mergeBase and has branch=$branch_name";

        # Default case: we don't delete anything.
        WILL_DELETE=0

        # Test if that branch has been squash-merged onto master.
        # This is black magic to me.
        if [[ $(git cherry $MAIN_BRANCH $(git commit-tree $(git rev-parse "$branch^{tree}") -p "$mergeBase" -m _)) == "-"* ]]; then
            # Technically we don't need to set this here, but I like having it.
            WILL_DELETE=1
        else
            # Branch isn't squash-merged, we con't need to check anything else
            continue
        fi

        # If we got down here then we already know that $branch is merged into
        # master. We still want to check if it's a dependency of other branches.

        # Is the branch included in any other branch?
        # `--contains` will always show itself, so remove that line.
        # |$ git branch --contains master
        # |  apt-app-factory-save
        # |* master
        # |  u/dthor/29267-apt-app-factory
        # becomes
        # |$ git branch --contains master
        # |  apt-app-factory-save
        # |  u/dthor/29267-apt-app-factory
        CONTAINS=$(git branch --contains "$branch" | sed -e "\:^[\* ] $branch$:d")

        # Is $CONTAINS empty?
        if [[ -z $CONTAINS ]]; then
            # If so, it's safe to delete this branch.
            WILL_DELETE=1
            if [[ $VERBOSE -eq 1 ]]; then
                echo "${C_WHITEBRIGHT}$branch${C_RESET} is not a dependency on any other branch. Deleting"
            fi
        else
            # If not, we only delete if --force is given. (TODO)
            if [[ $VERBOSE -eq 1 ]]; then
                echo "${C_WHITEBRIGHT}$branch${C_RESET} is a dependency of other branch(es). Not deleting without --force"
            fi
            if [[ $VERBOSE -eq 3 ]]; then
                echo "$CONTAINS"
            fi
            continue
        fi

        if [[ $DRY_RUN -eq 1 ]]; then
            WILL_DELETE=0
            echo "${C_WHITEBRIGHT}$branch${C_RESET} is merged into $MAIN_BRANCH and can be deleted"
            print_subject "$branch"
        fi

        if [[ $WILL_DELETE -eq 1 ]]; then
            # Capture the subject before deleting, since the ref is gone afterwards.
            branch_sha="$(git rev-parse --verify --quiet "refs/heads/${branch}")"
            git branch -D "$branch" |
                sed -E "s/^(Deleted branch )(.+)( \(was .*\)\.)$/\1${C_WHITEBRIGHT}\2${C_RESET}\3/"
            print_subject "${branch_sha}"
        fi

    done
