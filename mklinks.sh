#!/usr/bin/env bash
# Run this when first cloning the dotfiles repo to
# a new user directory.

echo "Making symlinks for dotfiles..."

# TODO: Refactor to not be brute-force...
pwd
cd ~
ln -s dotfiles/.bashrc .bashrc
ln -s dotfiles/.bash_logout .bash_logout
ln -s dotfiles/.gitconfig .gitconfig
ln -s dotfiles/.lessfilter .lessfilter
ln -s dotfiles/.profile .profile
ln -s dotfiles/.vim/ .vim

echo "Complete."

