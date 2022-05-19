#!/usr/bin/env bash
# Run this when first cloning the dotfiles repo to
# a new user directory.

echo "Making symlinks for dotfiles..."

# Save the current directory so we can CD back to it.
curdir=$(pwd)

# Change to the home dir. This isn't really needed.
cd ~

# Add support for different home directories.
homedir="/home/$USER"
# homedir="/usr/local/google/home/dthor"

echo "Deleting old dotfiles."
rm "$homedir/.bashrc"
rm "$homedir/.bash_logout"
rm "$homedir/.gitconfig"
rm "$homedir/.lessfilter"
rm "$homedir/.profile"
rm -r "$homedir/.vim"
rm "$homedir/.toprc"
rm "$homedir/.tmux.conf"

echo "Creating symlinks for dotfiles."
ln -s "$homedir/dotfiles/.bashrc" "$homedir/.bashrc"
ln -s "$homedir/dotfiles/.bash_logout" "$homedir/.bash_logout"
ln -s "$homedir/dotfiles/.gitconfig" "$homedir/.gitconfig"
ln -s "$homedir/dotfiles/.lessfilter" "$homedir/.lessfilter"
ln -s "$homedir/dotfiles/.profile" "$homedir/.profile"
ln -s "$homedir/dotfiles/.vim" "$homedir/.vim"
ln -s "$homedir/dotfiles/.toprc" "$homedir/.toprc"
ln -s "$homedir/dotfiles/.tmux.conf" "$homedir/.tmux.conf"

echo "Applying $homedir/.bashrc"
source "$homedir/.bashrc"

# Make sure we move back to the dir the user was in.
cd "$curdir"

echo "Complete."

