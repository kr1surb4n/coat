#!/bin/bash

# Quests -- the log of what you are working on.
#
# One quest per line in storage/quests:
#   id <TAB> state <TAB> created <TAB> finished <TAB> text
# state is open, active or done, and only one quest is active.

QUEST_FILE="${QUEST_FILE:-$COAT_STORAGE/quests}"
[ -f "$QUEST_FILE" ] || : > "$QUEST_FILE"

# yes when the id names a quest
quest_exists() {
  awk -F'\t' -v id="$1" '$1 == id { found = 1 } END { exit !found }' "$QUEST_FILE"
}

# the state of one quest
quest_state() {
  awk -F'\t' -v id="$1" '$1 == id { print $2; exit }' "$QUEST_FILE"
}

# the text of one quest
quest_text() {
  awk -F'\t' -v id="$1" '$1 == id { print $5; exit }' "$QUEST_FILE"
}

# the next free id
quest_next_id() {
  awk -F'\t' 'BEGIN { id = 1 } $1 + 0 >= id { id = $1 + 1 } END { print id }' "$QUEST_FILE"
}

# add a quest, the text is everything after 'add'
quest_add() {
  local id text="$*"
  if [ -z "$text" ]; then
    echo "usage: quest add <what you want to do>" >&2
    return 1
  fi
  id=$(quest_next_id)
  printf '%s\t%s\t%s\t\t%s\n' "$id" "open" "$(printf '%(%F)T' -1)" "$text" >> "$QUEST_FILE"
  printf 'quest %s added: %s\n' "$id" "$text"
}

# make one quest active and put it in the heads-up display
quest_activate() {
  local id=$1 tmp
  if ! quest_exists "$id"; then
    echo "quest: no quest $id" >&2
    return 1
  fi

  tmp=$(mktemp)
  awk -F'\t' -v OFS='\t' -v id="$id" '
    $2 == "active" { $2 = "open" }
    $1 == id { $2 = "active" }
    { print }
  ' "$QUEST_FILE" > "$tmp" && mv "$tmp" "$QUEST_FILE"

  type -t coat_hud_update >/dev/null && coat_hud_update
  printf 'active quest: %s\n' "$(quest_text "$id")"
}

# pick an unfinished quest with fzf and make it active
quest_pick() {
  local pick
  pick=$(awk -F'\t' -v OFS='\t' '$2 != "done" { print $1, $2, $3, $5 }' "$QUEST_FILE" \
    | fzf --delimiter='\t' --prompt='quest> ' \
          --header='Enter: make this the active quest') || return 0
  [ -n "$pick" ] || return 0
  quest_activate "${pick%%$'\t'*}"
}

# finish a quest, by id or by picking one, and collect the reward
quest_done() {
  local id=${1:-} pick state tmp

  # no id given, so pick from the unfinished quests
  if [ -z "$id" ]; then
    pick=$(awk -F'\t' -v OFS='\t' '$2 != "done" { print $1, $2, $3, $5 }' "$QUEST_FILE" \
      | fzf --delimiter='\t' --prompt='done> ' \
            --header='Enter: finish this quest') || return 0
    [ -n "$pick" ] || return 0
    id=${pick%%$'\t'*}
  fi

  state=$(quest_state "$id")
  if [ -z "$state" ]; then
    echo "quest: no quest $id" >&2
    return 1
  fi
  if [ "$state" = "done" ]; then
    echo "quest $id is already done" >&2
    return 1
  fi

  tmp=$(mktemp)
  awk -F'\t' -v OFS='\t' -v id="$id" -v today="$(printf '%(%F)T' -1)" '
    $1 == id { $2 = "done"; $4 = today }
    { print }
  ' "$QUEST_FILE" > "$tmp" && mv "$tmp" "$QUEST_FILE"

  printf 'quest %s done: %s\n' "$id" "$(quest_text "$id")"
  type -t coat_award >/dev/null && coat_award 25
  type -t coat_achievement >/dev/null && coat_achievement first_quest
  type -t coat_hud_update >/dev/null && coat_hud_update
}

# the quests you have finished, newest first
quest_history() {
  awk -F'\t' '$2 == "done" { printf "%s  %s\n", $4, $5 }' "$QUEST_FILE" | sort -r
}

# show the active quest, or explain how to get one
quest_show() {
  local active
  active=$(awk -F'\t' '$2 == "active" { print $1 "\t" $5; exit }' "$QUEST_FILE")
  if [ -n "$active" ]; then
    printf '⚔ %s  (quest %s)\n' "${active#*$'\t'}" "${active%%$'\t'*}"
    return 0
  fi
  if [ -s "$QUEST_FILE" ]; then
    echo "no active quest, pick one with 'quest list'"
  else
    echo "no quests yet, add one with 'quest add <text>'"
  fi
}

# the quest command: no argument shows the active quest
quest() {
  case "${1:-show}" in
    add) shift; quest_add "$@" ;;
    list|ls|start) shift; quest_pick ;;
    done|finish) shift; quest_done "$@" ;;
    log|history) quest_history ;;
    show|active) quest_show ;;
    *)
      echo "usage: quest [add <text> | list | done [id] | log]" >&2
      return 1
      ;;
  esac
}
