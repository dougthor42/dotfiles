#!/usr/bin/env bash
# Run this when first cloning the dotfiles repo to
# a new user directory.
#
# Disable "not following" shellcheck notice.
# shellcheck disable=SC1091

echo "Making symlinks for dotfiles..."

# Save the current directory so we can CD back to it.
curdir=$(pwd)

# Change to the home dir. This isn't really needed.
cd ~ || return

echo "Deleting old dotfiles."
cp "$HOME/.inputrc" "$HOME/.inputrc.bak" || true
rm "$HOME/.bashrc"
rm "$HOME/.bash_logout"
rm "$HOME/.gitconfig"
rm "$HOME/.lessfilter"
rm "$HOME/.profile"
rm -r "$HOME/.vim"
rm "$HOME/.toprc"
rm "$HOME/.tmux.conf"
rm "$HOME/.gnupg/gpg-agent.conf"

echo "Creating symlinks for dotfiles."
ln -s "$HOME/dotfiles/.inputrc" "$HOME/.inputrc"
ln -s "$HOME/dotfiles/.bashrc" "$HOME/.bashrc"
ln -s "$HOME/dotfiles/.bash_logout" "$HOME/.bash_logout"
ln -s "$HOME/dotfiles/.gitconfig" "$HOME/.gitconfig"
ln -s "$HOME/dotfiles/.lessfilter" "$HOME/.lessfilter"
ln -s "$HOME/dotfiles/.profile" "$HOME/.profile"
ln -s "$HOME/dotfiles/.vim" "$HOME/.vim"
ln -s "$HOME/dotfiles/.toprc" "$HOME/.toprc"
ln -s "$HOME/dotfiles/.tmux.conf" "$HOME/.tmux.conf"
ln -s "$HOME/dotfiles/.gnupg/gpg-agent.conf" "$HOME/.gnupg/gpg-agent.conf"

echo "Applying $HOME/.bashrc"
source "$HOME/.bashrc"

# Make sure we move back to the dir the user was in.
cd "$curdir" || return

echo "Complete."
