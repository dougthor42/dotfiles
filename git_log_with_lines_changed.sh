#!/usr/bin/env bash
#
# Print a short-form of commits with number of lines added/removed.
#
# Taken from https://stackoverflow.com/a/40777727/1354930 and modified to
# my liking.

function help() {
    echo "Usage: $0 [PATH]"
    echo "  -h, --help	Show this help text"
    echo ""
    echo "Return a CSV of the commit hashes and how many lines were added/removed."
    echo ""
    echo "Parameters:"
    echo "  PATH: Filter by commits that touch this path. If not given, defaults"
    echo "        to '.'"
    echo ""
    echo "Examples:"
    echo "  $0"
    echo "    Hash,FilesChanged,Insertions,Deletions"
    echo "    45596f9948,1,0,115"
    echo "    a1978492e1,3,11,9"
    echo "    0118afef06,1,51,13"
    echo "    ..."
    echo ""
    echo "  $0 README.md"
    echo "    Hash,FilesChanged,Insertions,Deletions"
    echo "    7673c83,1,14,5"
    echo "    f177c69,1,1,0"
    echo "    c3c2656,1,13,0"
    exit 1
}

PATH_TO_GIT_LOG=$1

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

# If the user did not supply a path, use the cwd.
# N.B.: If the user set -h/--help, techincally $PATH_TO_GIT_LOG will have that value, but
# the help function exits 1 before we get down here so we don't care that PATH_TO_GIT_LOG
# is set wrong.
if [[ ! $PATH_TO_GIT_LOG ]]; then
    echo "No path given, running on cwd '.'"
    PATH_TO_GIT_LOG="."
fi

git log --oneline --pretty="@%h" --stat -- $PATH_TO_GIT_LOG |
    /bin/grep -v \| |
    tr "\n" " " |
    tr "@" "\n" |
    sed -E 's/([a-f0-9]*) +([0-9]+) files? changed, ([0-9]+) insertions?\(\+\), ([0-9]+) deletions?\(-\)/\1,\2,\3,\4/g' |
    sed -E 's/([a-f0-9]*) +([0-9]+) files? changed, ([0-9]+) insertions?\(\+\)/\1,\2,\3,0/g' |
    sed -E 's/([a-f0-9]+) +([0-9]+) files? changed, ([0-9]+) deletions?\(-\)/\1,\2,0,\3/g' |
    sed -E 's/^$/Hash,FilesChanged,Insertions,Deletions/g'

# Explanation:
#
#   git log --pretty="@%h" --stat
#
# returns something like:
#
#   >@a1978492e1
#   >
#   > pyle/experiments/probe_station/CHANGELOG.md             |  2 ++
#   > pyle/experiments/probe_station/probe_main_window_smu.ui |  4 ++--
#   > pyle/experiments/probe_station/probe_station_smu.py     | 14 +++++++-------
#   > 3 files changed, 11 insertions(+), 9 deletions(-)
#   >@0118afef06
#   >
#   > pyle/experiments/probe_station/probe_station_smu.py | 64 +++++++++++++++++++++++++++++++++++++++++++++++++++-------------
#   > 1 file changed, 51 insertions(+), 13 deletions(-)
#
#
# We then remove all lines that have a "|" in them. (I don't know why I can't wrap \| in quotes)
#
#   /bin/grep -v \|
#
# -v: invert match
# \|: match literal '|'
#
# This returns something like:
#
#   >@eb147ae15e
#   >
#   > 7 files changed, 526 insertions(+), 8 deletions(-)
#   >@c3c8e350ca
#   >
#   > 12 files changed, 5247 insertions(+)
#
#
# Next, convert newlines to spaces
#
#   tr "\n " "
#
# This returns:
#
#   >@a1978492e1   3 files changed, 11 insertions(+), 9 deletions(-) @0118afef06   1 file changed, 51 insertions(+), 13 deletions(-)
#
#
# And then we replace "@" with newline, thus getting us back to one-commit-per-line
#
#   tr "@" "\n"
#
#   >4d49ba406d   2 files changed, 24 insertions(+), 503 deletions(-)
#   >eb147ae15e   7 files changed, 526 insertions(+), 8 deletions(-)
#   >c3c8e350ca   12 files changed, 5247 insertions(+)
#
# At this point we have some pretty useful information, especially when joined
# with my bash `gl_csv` alias.
#
# Next, we need to convert this to a csv-like format. The issue is that some
# commits will not have insertions and others will not have deletions.
# There aren't that many permutations, so just do each one at a time.
#
#   sed -E 's/([a-f0-9]+) +([0-9]+) files? changed, ([0-9]+) insertions?\(\+\), ([0-9]+) deletions?\(-\)/\1,\2,\3,\4/g'
#
# Converts a line like this:
#
#   >4d49ba406d   2 files changed, 24 insertions(+), 503 deletions(-)
#
# to this:
#
#   >4d49ba406d,2,24,503
#
#
# Some lines will not have deletions, inject with 0 instead.
#
#   sed -E 's/([a-f0-9]+) +([0-9]+) files? changed, ([0-9]+) insertions?\(\+\)/\1,\2,\3,0/g'
#
# Converts a line like this:
#
#   >bbd1f6f304   2 files changed, 426 insertions(+)
#
# to this:
#
#   >bbd1f6f304,2,426,0
#
#
# Some lines will not have insertions, inject with 0 instead.
#
#   sed -E 's/([a-f0-9]+) +([0-9]+) files? changed, ([0-9]+) deletions?\(-\)/\1,\2,0,\3/g'
#
#   >fd931c3921   1 file changed, 4 deletions(-)
#
#   >fd931c3921,1,0,4
#
#
# In theory we will never see lines that have 0 files changed, so no action
# required there.
#
# Lastly, set our header line.
#
#   sed -E 's/^$/Hash,FilesChanged,Insertions,Deletions/g'
#
# And we get a CSV that looks like:
#
#   >Hash,FilesChanged,Insertions,Deletions
#   >Hash,FilesChanged,Insertions,Deletions
#   >45596f9948,1,0,115
#   >a1978492e1,3,11,9
#   >0118afef06,1,51,13
#   >8e4e989ce4,3,38,4
