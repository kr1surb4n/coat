#!/bin/bash

# Dungeons -- the tmuxp sessions, the rooms you work in.
#
# A dungeon is a yaml file in $TMUXP_CONFIGDIR.  Entering one loads the
# whole layout, so you land on the same windows and panes as last time.

# list the saved dungeons and enter the chosen one
dungeon() {
  local config_dir="${TMUXP_CONFIGDIR:-$HOME/.tmuxp}" pick

  if [ ! -d "$config_dir" ]; then
    echo "dungeon: $config_dir does not exist" >&2
    return 1
  fi

  # no layouts saved yet
  if ! compgen -G "$config_dir/*.yaml" >/dev/null; then
    echo "dungeon: no layouts in $config_dir, save one with save_the_workshop" >&2
    return 1
  fi

  pick=$(find "$config_dir" -maxdepth 1 -name '*.yaml' -printf '%f\n' 2>/dev/null \
    | sed 's/\.yaml$//' \
    | fzf --prompt='dungeon> ' --header='Enter: enter this dungeon' \
          --preview "cat \"$config_dir/{}.yaml\" 2>/dev/null | head -40") || return 0
  [ -n "$pick" ] || return 0

  tmuxp load "$pick"
  type -t coat_award >/dev/null && coat_award 5
  type -t coat_achievement >/dev/null && coat_achievement dungeoneer
}

# a small map of the current session (the plain map alias is xargs)
sessionmap() {
  if [ -z "$TMUX" ]; then
    echo "sessionmap: you are not inside tmux" >&2
    return 1
  fi
  tmux list-windows -F '#{window_index}: #{window_name}#{?window_active,  <== you are here,}'
}
