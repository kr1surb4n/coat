#!/bin/bash

# key bindings only work in an interactive shell, skip them in scripts
if [[ $- != *i* ]]; then
  return 0 2>/dev/null || exit 0
fi

# How to run interactive bash commands with a shortcut using bind function?
#
# bind function is for non-interactive commands only. 
# The read function will block the script. User will
# be unable to enter any text.
# 
# To start an interactive command with a shortcut, use
# tmux or xdotool to type in the command and press enter.   
#
bind -x '"\es": "tmux send-keys eval_line_with_fzf Enter"'  # -> throw a spell using a Spellbook
bind -x '"\et": "tmux send-keys connect_with_ssh Enter"'    # -> connect with ssh to hosts

bind -x '"\ei": insert_line_with_fzf'       # -> type in a spell into prompt   
bind -x '"\ew": spellforge'                 # -> run Nano to edit spells , not working

bind -x '"\eg": cdg'                        # -> Folder Bookmarks

# bind -x '"\eb": FREE'                     # TODO tmuxp selector

bind -x '"\en": paczek'

bind -x '"\eh": grimoire'                   # -> every function and alias

bind -x '"\el": trail'                      # -> where you have been
bind -x '"\eq": quest list'                 # -> pick the active quest

