#!/usr/bin/env bash
# Run this when first cloning the dotfiles repo to
# a new user directory.

echo "Making symlinks for dotfiles..."

# TODO: Refactor to not be brute-force...
pwd
cd ~
ln -s "/home/$USER/dotfiles/.bashrc" "/home/$USER/.bashrc"
ln -s "/home/$USER/dotfiles/.bash_logout" "/home/$USER/.bash_logout"
ln -s "/home/$USER/dotfiles/.gitconfig" "/home/$USER/.gitconfig"
ln -s "/home/$USER/dotfiles/.lessfilter" "/home/$USER/.lessfilter"
ln -s "/home/$USER/dotfiles/.profile" "/home/$USER/.profile"
ln -s "/home/$USER/dotfiles/.vim" "/home/$USER/.vim"
ln -s "/home/$USER/dotfiles/.toprc" "/home/$USER/.toprc"

echo "Complete."

