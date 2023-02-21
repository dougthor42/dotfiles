#!/usr/bin/env bash
#
# This script pushes all local branches to remote, appending a timestamp to
# the branch name.
#
# It's inspired by (and takes code from) `git fire` https://github.com/qw3rtman/git-fire
# but does some things slightly differently.
#
# + Instead of prepending "fire-", it _appends_ "-backup"
# + Instead of using seconds-since-epoch, it uses ISO8601 timestamp.
# + Other minor differences
#
# What it does:
# + Changes directory to the root of the repo
# + Fetches origin
# + Creates a new branch `<branch name>-<user email>-backup-wip-<timestamp>`
# + Adds all files, respecting .gitignore
# + Commits with "git backup"
# + pushes commits to remote
# + pushes stashes to remote
# + Looks through all local branches
# + For any that are up to date with origin: does nothing
# + For any branch that is ahead of origin:
#   + Fast-forward push. If it can't do that, then
#   + create new branch `<branch name>-<user email>-backup-<timestamp>` and pushes
#     that instead.
# + When all that's done: return to the original working dir and branch.

function show_help() {
	cat <<-EOF

usage:
  git backup [options]

options:
  -h, --help				Display this help information

EOF
	exit 0
}

function current_branch() {
	basename "$(git symbolic-ref HEAD)"
}

function current_timestamp() {
	date --iso-8601=seconds
}

function user_email() {
	git config user.email
}

function new_branch() {
	echo "$(current_branch)"
}


ORIGINAL_DIR=$(pwd)
ORIGINAL_BRANCH=$(current_branch)


function backup() {
	echo "backing up"
	DRY_RUN=1

	initial_branch="$(current_branch)"

	if [[ $DRY_RUN -eq 1 ]]
	then
		echo "Would create branch: $(new_branch)"
	else
		git checkout -b "$(new_branch)"
	fi

	if [[ $DRY_RUN -eq 1 ]]
	then
		echo "Would switch to repo root."
	else
		cd "$(git rev-parse --show-toplevel)"
	fi

	if [[ $DRY_RUN -eq 1 ]]
	then
		echo "Would add all files."
	else
		git add -A
	fi

	message="Git backup. Branch $(current_branch)."
	if [[ $DRY_RUN -eq 1 ]]
	then
		echo "Would commit with message '$message'"
	else
		git commit -m "$message" --no-verify
	fi

	for remote in $(git remote); do
		if [[ $DRY_RUN -eq 1 ]]
		then
			echo "Would push to remote '${remote}'"
		else
			git push --no-verify --set-upstream "${remote}" "$(current_branch)" || true
		fi
	done

	# Push stashes too
	if [[ "$(git stash list)" != "" ]]
	then
		for sha in $(git rev-list -g stash)
		do
			if [[ $DRY_RUN -eq 1 ]]
			then
				echo "Would push to remote stash '${sha}'"
			else
				echo ""
			fi
		done
	else
		echo "No local stashes."
	fi

}

case $1 in
	-n|--dry-run) echo "dry run"; exit 0 ;;
	-h|--help) show_help; exit 0 ;;
esac

backup "$@"
