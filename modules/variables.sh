#!/bin/bash
export TERM="screen-256color"

export PATH=$PATH:~/bin:~/.coat/lib
export PATH="$PATH:$PATH_TO_COAT/lib/foxer:/usr/bin/go:~/.config/composer/vendor/laravel/installer/bin:~/.config/composer/vendor/bin"
export PATH="$PATH:~/.local/bin"

export QUICK_STATUS=$PATH_TO_COAT/storage/status

export GREP_OPTIONS=""

# History
# control whats ignored
export HISTCONTROL=ignorespace:ignoredups
# which command are ignored
export HISTIGNORE="history:ls:pwd:cd:"

# size 
export HISTSIZE=10000
export HISTFILESIZE=10000

# append every command
# export PROMPT_COMMAND="${PROMPT_COMMAND}; history -a"

# batcat  fails without it
export BAT_PAGER="less -RF"

# append to bash history
shopt -s histappend
