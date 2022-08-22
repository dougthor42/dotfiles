#!/usr/bin/env bash
# This runs through all the folders in the given
# directory and lists the git `branch -lav` result
# for each one

# Check to see that we have a valid argument.
dir=$1
if [[ ! $dir ]]
then
	echo "No directory given; using current working direcotry."
	dir=$(pwd)
elif [ -d "$dir" ]
then
	echo "Looking for git repositories in '$dir'."
else
	echo "Directory '$dir' not found."
	return 1
fi

# Now iterate through the directory looking for subdirectories.
for d in "$dir"/*/; do
	echo "$d"
	git -C "$d" branch --color=always -lav
done
