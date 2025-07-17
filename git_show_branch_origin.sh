#!/usr/bin/env bash
#
# This script shows which commit (with branch or tag name) a given branch
# originated from.
#

function help()
                {
    echo "Usage: $0 [<branch>...]"
    echo "  -h, --help   Show this help text"
    echo ""
    echo "Example:"
    echo "  $0"
    echo "    branch1 is branched from 1234abcd (master)"
    echo "    branch2 is branched from c0ffee01"
    echo "    branch3 is branched from abcd1324 (tag1)"
    exit 1
}

# Set all args to an array.
# We don't have to worry about -h/--help because that function exits.
# https://stackoverflow.com/a/12711837/1354930
BRANCHES=("$@")

# Parse args
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -h | --help)
            help
            shift
            ;;
    esac
    shift
done

# If the user did not supply any branch args, get all local branches
if [[ -z "$BRANCHES" ]]; then
    echo "No branches specified, using all local branches."
    # https://stackoverflow.com/a/32931403/1354930
    mapfile -t BRANCHES < <(git branch -l | cut -c 3-)
fi

# git rev-parse $(git cherry master {branch} | head -n 1 | cut -d ' ' -f 2)^
# git merge-base master <branch>
#
# Almost the same format that we define for 'gl' bash alias in .bashrc
GIT_PRETTY_FORMAT='format:"%C(bold yellow)%h %C(bold red)%ai %C(bold cyan)%an %C(bold green)%d %C(white)%s"'

for branch_name in "${BRANCHES[@]}"; do
    # BRANCH_ORIGIN_COMMIT=$(git cherry master "$branch_name" | head -n 1 | cut -d ' ' -f 2)
    # ORIGINATING_COMMIT=$(git rev-parse "$BRANCH_ORIGIN_COMMIT"^)
    ORIGINATING_COMMIT=$(git merge-base master "$branch_name")

    # Skip if bad branch name
    if [[ $? -ne 0 ]]; then
        continue
    fi

    # Show the message
    MESSAGE=$(git show --color=always --pretty="$GIT_PRETTY_FORMAT" --no-patch "$ORIGINATING_COMMIT")
    echo -e "\033[1;32m$branch_name\033[0m is branched from: $MESSAGE\033[0m"
done
