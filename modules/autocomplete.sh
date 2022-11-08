#########################
# autocomplete
#########################

# # howto
# by default $BASH_COMPLETION_USER_DIR is ~/.config/bash-completion
# 
# use this folder or override it in the .coatrc
# 
# to enable an autocomplete for a script, just
# copy&paste the autocomplete script inside $BASH_COMPLETION_USER_DIR,
# or like I do, link the ones you need
#
# !! a lot of those scripts can slow down your shell.
# also it is highly possible this loop bellow is doing that
# TODO: check load time for a loop and a list of sourced files

for _complete__file in $BASH_COMPLETION_USER_DIR/*
do
  [[ -f "$_complete__file" ]] && source "$_complete__file"
done