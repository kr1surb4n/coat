#!/bin/bash
export TERM="screen-256color"

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

# colored GCC warnings and errors
export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'
