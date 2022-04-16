#!/bin/bash

bind -x '"\es": "tmux send-keys eval_line_with_fzf Enter"'
bind -x '"\et": "tmux send-keys connect_with_ssh Enter"'
bind -x '"\ei": insert_line_with_fzf'
bind -x '"\ew": spellforge'

bind -x '"\eb": shellsnip'
bind -x '"\en": netspells'

bind -x '"\eg": cdg'
