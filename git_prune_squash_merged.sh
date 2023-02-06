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

MAIN_BRANCH="master"

while [[ "$#" -gt 0 ]];
do
	case $1 in
		-n|--dry-run) DRY_RUN=1; shift ;;
		-v|--verbose) VERBOSE=1; shift ;;
		*) echo "Unknown parameter passed: $1"; exit 1 ;;
	esac
	shift
done

echo "Pruning local branches that were squashed and merged onto master..."
if [[ $DRY_RUN -eq 1 ]]
then
	echo "DRY RUN - no branches will be deleted.";
fi;

# Prune local branches that we squashed and merged.
# See https://stackoverflow.com/a/56026209/1354930
git checkout -q master &&
git for-each-ref refs/heads/ "--format=%(refname:short)" |
while read branch;
do
	# Get the merge-base. The merge-base is the "best common ancestor(s)
	# between two commits". Eg: the commit on master that a branch was
	# created from.
	mergeBase=$(git merge-base master "$branch");

	# Default case: we don't delete anything.
	WILL_DELETE=0;

	# Test if that branch has been squash-merged onto master.
	# This is black magic to me.
	if [[ $(git cherry master $(git commit-tree $(git rev-parse "$branch^{tree}") -p "$mergeBase" -m _)) == "-"* ]]
	then
		# Technically we don't need to set this here, but I like having it.
		WILL_DELETE=1;
	else
		# Branch isn't squash-merged, we con't need to check anything else
		continue
	fi;

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
	CONTAINS=$(git branch --contains "$branch" | sed -e "\:^[\* ] $branch$:d");

	# Is $CONTAINS empty?
	if [[ -z $CONTAINS ]]
	then
		# If so, it's safe to delete this branch.
		WILL_DELETE=1
		if [[ $VERBOSE -eq 1 ]]
		then
			echo "$branch is not a dependency on any other branch. Deleting";
		fi;
	else
		# If not, we only delete if --force is given. (TODO)
		echo "$branch is a dependency of other branch(es). Not deleting without --force"
		if [[ $VERBOSE -eq 1 ]]
		then
			echo "$CONTAINS";
		fi;
		continue
	fi;

	if [[ $DRY_RUN -eq 1 ]]
	then
		WILL_DELETE=0
		echo "$branch is merged into master and can be deleted";
	fi;

	if [[ $WILL_DELETE -eq 1 ]]
	then
		git branch -D "$branch"
	fi;

done
