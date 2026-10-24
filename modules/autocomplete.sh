# shellcheck shell=bash
# Load the completion scripts from BASH_COMPLETION_USER_DIR.

# # howto
# by default $BASH_COMPLETION_USER_DIR is ~/.config/bash-completion
#
# use this folder or override it in the .coatrc
#
# to enable an autocomplete for a script, just
# copy&paste the autocomplete script inside $BASH_COMPLETION_USER_DIR,
# or like I do, link the ones you need
#
# Warning: a lot of those scripts can slow down your shell.
# also it is highly possible this loop bellow is doing that
# TODO: check load time for a loop and a list of sourced files

# fall back to the default folder, an unset variable would make the glob hit /*
BASH_COMPLETION_USER_DIR=${BASH_COMPLETION_USER_DIR:-$HOME/.config/bash-completion}

# source every completion script in that folder, if there is one
if [ -d "$BASH_COMPLETION_USER_DIR" ]; then
  for _complete__file in "$BASH_COMPLETION_USER_DIR"/*; do
    [ -f "$_complete__file" ] && source "$_complete__file"
  done
  unset _complete__file
fi
