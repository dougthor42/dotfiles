# Dotfiles

This project contains my dotfiles.

## Prerequisites

+ GNU Privacy Guard (gpg) should be installed: `sudo apt install gpg`
+ tmux should be installed: `sudo apt install tmux`
  + tmux Plugin Manager (tpm) will be installed via basic GitHub checkout automatically. See
    the [tpm repo](https://github.com/tmux-plugins/tpm).
+ pyenv should be installed via basic GitHub checkout. See the
  [pyenv repo](https://github.com/pyenv/pyenv#basic-github-checkout).
+ `diff-highlight` should be compiled:
   `sudo make -C /usr/share/doc/git/contrib/diff-highlight`


## Setup

When first adding this to a host, follow these steps:

1.  `cd ~`
2.  `git clone https://github.com/dougthor42/dotfiles.git`
3.  `. ./dotfiles/mklinks.sh`
