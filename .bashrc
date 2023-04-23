###########################################################
#                                                         #
# Doug's .bashrc file                                     #
#                                                         #
###########################################################

# Modified from the default for debian/ubuntu using
# a variety of sources (some of which I didn't cite,
# sorry!)

# ~/.bashrc: executd by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# Always print and use physical directories.
set -P

# Constants
# =========================================================
## Colors
## ======
C_GREY='\[\033[0;30m\]'
C_GREYBRIGHT='\[\033[1;30m\]'
C_RED='\[\033[0;31m\]'
C_REDBRIGHT='\[\033[1;31m\]'
C_GREEN='\[\033[0;32m\]'
C_GREENBRIGHT='\[\033[1;32m\]'
C_YELLOW='\[\033[0;33m\]'
C_YELLOWBRIGHT='\[\033[1;33m\]'
C_BLUE='\[\033[0;34m\]'
C_BLUEBRIGHT='\[\033[1;34m\]'
C_PURPLE='\[\033[0;35m\]'
C_PURPLEBRIGHT='\[\033[1;35m\]'
C_CYAN='\[\033[0;36m\]'
C_CYANBRIGHT='\[\033[1;36m\]'
C_WHITE='\[\033[0;37m\]'
C_WHITEBRIGHT='\[\033[1;37m\]'
C_RESET='\[\033[0m\]'

# Set default text editor
# see http://unix.stackexchange.com/a/73486/62799
export VISUAL=vim
export EDITOR="$VISUAL"

if [ "$TERM" == "xterm" ]; then
	export TERM=xterm-256color
fi

# Use Pygments so that less is colored.
# See http://superuser.com/a/337640
export LESS=' -R '
export LESSOPEN='| ~/.lessfilter %s'

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
# HISTSIZE=1000
# HISTFILESIZE=2000

# Eternal bash history
# http://stackoverflow.com/a/19533853
# ---------------------
# Undocumented feature which sets the size to "unlimited".
# http://stackoverflow.com/questions/9457233/unlimited-bash-history
# export HISTFILESIZE=
# export HISTSIZE=
# export HISTTIMEFORMAT="[%F %T] "
# Change the file location because certain bash sessions truncate .bash_history file upon close.
# http://superuser.com/questions/575479/bash-history-truncated-to-500-lines-on-each-login
# export HISTFILE=~/.bash_eternal_history
# Force prompt to write history after every command.
# http://superuser.com/questions/20900/bash-history-loss
PROMPT_COMMAND="history -a; $PROMPT_COMMAND"

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-*color|screen-*color|screen.xterm-*color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
#force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
	# We have color support; assume it's compliant with Ecma-48
	# (ISO/IEC-6429). (Lack of such support is extremely rare, and such
	# a case would tend to support setf rather than setaf.)
	color_prompt=yes
    else
	color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*|screen.xterm*|screen.rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# Aliases
# =========================================================
# allow sudo to use aliases
# See http://askubuntu.com/a/22043
alias sudo='sudo '

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls -A --group-directories-first --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep -n -C 3 --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# Even more aliases (or functions that act as aliases...)
alias ll='ls -alFh'
alias la='ls -A'
alias l='ls -CF'
alias dir='ls -AlFh --group-directories-first'
lsp(){ ls -AlFh --group-directories-first --color=always "$@" | less -R; }
alias df='df -h --total -T --exclude-type=squashfs'
alias du='du -ch'
alias cd..='cd ..'   # because I sometimes type too fast...
alias cd!='cd $OLDPWD'      # allows fast switching to previous directory
alias free='free -ht'
alias mkdir='mkdir -pv'
alias ip='ip -c'

# Use python3 by default
alias python=python3
alias python2=python2

# Git aliases
# Formatting info: 'git log' docs and https://stackoverflow.com/q/1441010/1354930
GIT_PRETTY_FORMAT='format:"%C(bold yellow)%h%x09%C(bold red)%ai %C(bold cyan)%an %C(bold green)%d %C(white)%s"'
GIT_LOG_OPTS='--oneline --decorate --source --graph --pretty='$GIT_PRETTY_FORMAT
GIT_LOG_CSV_FORMAT='format:"%h|%ai|%an|%d|%s"'
alias gl='git log '$GIT_LOG_OPTS
alias glt='git log `git describe --tags --abbrev=0`..HEAD '$GIT_LOG_OPTS
alias gl2t='git log `git tag --sort version:refname | tail -n 2 | head -n 1`..HEAD '$GIT_LOG_OPTS
alias gdt='git diff `git tag --sort version:refname | tail -n 1` HEAD'
alias gd2t='git diff `git tag --sort version:refname | tail -n 2 | head -n 1` HEAD'
# Watch the git log
alias wgl='watch --color '"'"'git log --color=always '$GIT_LOG_OPTS"'"
alias gl_csv='git log --oneline --decorate --source --pretty='$GIT_LOG_CSV_FORMAT

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# Alias to show the Message of the Day
alias motd='sudo run-parts /etc/update-motd.d/'

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# If docker-machine is installed, then also add the docker-machine shell prompt
DOCKER_MACHINE_PS=""
if [ -n docker-machine version 2> /dev/null ]; then
    DOCKER_MACHINE_PS=$(__docker_machine_ps1)
fi

# Have WSL connect to the remote Docker daemon running in Windows
if grep -qE "(Microsoft|WSL)" /proc/version &> /dev/null; then
  export DOCKER_HOST=tcp://0.0.0.0:2375
fi

# set a PS1 prompt with the time, user, host, location, and branch
git_branch() { git branch 2> /dev/null | grep '^*' | colrm 1 2; }
OLD_PWD=$C_PURPLEBRIGHT"Previous Dir: \$OLDPWD\n"
TIME=$C_REDBRIGHT'\t '
HOST=$C_GREENBRIGHT$USER'@\h'
LOCATION=$C_YELLOWBRIGHT' `pwd | sed "s#\(/[^/]\{,\}/[^/]\{1,\}/[^/]\{1,\}/\).*\(/[^/]\{1,\}/[^/]\{1,\}\)/\{0,1\}#\1_\2#g"`'
BRANCH="$C_CYANBRIGHT$(__git_ps1)"
EOI="$C_RESET\n\$ "
PS1="$OLD_PWD$TIME$HOST$LOCATION$C_CYANBRIGHT\$(__git_ps1)$DOCKER_MACHINE_PS$EOI"

# Export some environment variables
export HOSTNAME

# pyenv stuff.
# https://github.com/pyenv/pyenv
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
if command -v pyenv 1>/dev/null 2>&1; then
  eval "$(pyenv init -)"
fi

# Add golang to PATH
export PATH="$PATH:/usr/local/go/bin"

# Add git/contrib/diff-highlight to PATH. See comment in .gitconfig[core]
export PATH="$PATH:/usr/share/doc/git/contrib/diff-highlight"

# PGP (GPG: GnuPG) - Make sure the GPG_TTY is set, otherwise
# you get "Inappropriate ioctl for device" errors.
export GPG_TTY=$(tty)

# Rust/Cargo
. "$HOME/.cargo/env"

complete -C /usr/bin/terraform terraform
