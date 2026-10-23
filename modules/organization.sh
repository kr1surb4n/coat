#!/bin/bash

# Spot File a.k.a Teleport Back
# 
# Mark a spot, or a location. Use 
# current location copy&paste
[ ! -a $SPOT_FILE ] && eval "touch ${SPOT_FILE}"

# the trail remembers every folder you visit and every spot you mark
TRAIL_FILE="${TRAIL_FILE:-$COAT_STORAGE/trail}"
[ -f "$TRAIL_FILE" ] || eval "touch ${TRAIL_FILE}"

# add one line to the trail: time, what happened, folder
trail_add() {
  local kind="${1:-cd}" last_path

  # a plain cd to the folder you are already in is not worth a line
  last_path=$(tail -n 1 "$TRAIL_FILE" 2>/dev/null | cut -f3)
  if [ "$kind" = "cd" ] && [ "$last_path" = "$PWD" ]; then
    return 0
  fi

  printf '%s\t%s\t%s\n' "$(date +'%Y-%m-%d %H:%M')" "$kind" "$PWD" >> "$TRAIL_FILE"
}

# mark the folder where you stopped, and note it in the trail
mark() {
  pwd > "$SPOT_FILE"
  trail_add "mark"
  type -t coat_award >/dev/null && coat_award 2
  type -t coat_achievement >/dev/null && coat_achievement camper
}

alias spot='cat $SPOT_FILE'
alias goto='cd `spot`'

# browse the trail, newest first, and jump back to a folder
# ALT + l - open the trail
trail() {
  local pick dir

  pick=$(tac "$TRAIL_FILE" | awk -F'\t' '!seen[$3]++' | fzf --delimiter='\t' \
    --with-nth=1,2,3 --prompt='trail> ' \
    --header='where you have been, newest first | Enter: go there' \
    --preview 'ls --color -lah "{3}" 2>/dev/null | head -20') || return 0

  # nothing picked, nothing to do
  [ -n "$pick" ] || return 0

  dir=$(printf '%s' "$pick" | cut -f3)
  if [ ! -d "$dir" ]; then
    echo "trail: $dir is gone" >&2
    return 1
  fi

  cd "$dir"
}

# folder bookmarks with fzf
# 
# ALT + g - open the bookmarks
# see shourtcuts.sh
[ ! -a $FOLDER_BOOKMARK_FILE ] && eval "touch ${FOLDER_BOOKMARK_FILE}"
alias bookmarkfolder='pwd >> $FOLDER_BOOKMARK_FILE'

# look for list of files
#
# this is binded to the alt + g
alias cdg='cat $FOLDER_BOOKMARK_FILE | fzf'
unalias cdg 2> /dev/null
cdg() {
   local dest_dir=$(cat $FOLDER_BOOKMARK_FILE | fzf )
   if [[ $dest_dir != '' ]]; then
      cd "$dest_dir"
   fi
}
export -f cdg > /dev/null