#!/bin/bash

# Experience, levels and achievements.
#
# Every command is written to storage/xp.log and earns experience.
# The total lives in storage/xp and the command count in storage/xp_count,
# so the prompt hook never has to read the whole log.

XP_LOG="${XP_LOG:-$COAT_STORAGE/xp.log}"
XP_FILE="${XP_FILE:-$COAT_STORAGE/xp}"
XP_COUNT="${XP_COUNT:-$COAT_STORAGE/xp_count}"
QUEST_FILE="${QUEST_FILE:-$COAT_STORAGE/quests}"
QUEST_HUD="${QUEST_HUD:-$COAT_STORAGE/quest_hud}"
ACHIEVEMENTS_FILE="${ACHIEVEMENTS_FILE:-$COAT_STORAGE/achievements}"

# the achievement catalogue: id, name, how to earn it
COAT_ACHIEVEMENTS=(
  'first_spell|Apprentice|run your first command'
  'centurion|Centurion|run 100 commands'
  'veteran|Veteran|run 1000 commands'
  'night_owl|Night Owl|work between midnight and five'
  'first_quest|Quest Taker|finish a quest'
  'dungeoneer|Dungeoneer|enter a dungeon'
  'looter|Looter|take a paczek'
  'camper|Camper|mark a spot'
)

# create the runtime files, never truncate them
for _coat_file in "$XP_LOG" "$XP_FILE" "$XP_COUNT" "$ACHIEVEMENTS_FILE"; do
  [ -f "$_coat_file" ] || : > "$_coat_file"
done
unset _coat_file

# the numbers start at zero when the files are empty
[ -s "$XP_FILE" ]  || printf '0\n' > "$XP_FILE"
[ -s "$XP_COUNT" ] || printf '0\n' > "$XP_COUNT"

# the achievements already earned, kept in memory for the prompt hook
mapfile -t COAT_ACHIEVED < <(cut -f1 "$ACHIEVEMENTS_FILE" 2>/dev/null)

# level for a number of experience points, one level per 100
coat_level() {
  printf '%s' $(( ${1:-0} / 100 + 1 ))
}

# yes when the achievement was already earned
coat_has_achievement() {
  local id
  for id in "${COAT_ACHIEVED[@]}"; do
    [ "$id" = "$1" ] && return 0
  done
  return 1
}

# nice name of an achievement, from the catalogue
coat_achievement_name() {
  local entry rest
  for entry in "${COAT_ACHIEVEMENTS[@]}"; do
    [ "${entry%%|*}" = "$1" ] || continue
    rest=${entry#*|}
    printf '%s' "${rest%%|*}"
    return 0
  done
  printf '%s' "$1"
}

# earn an achievement once, and say it out loud
coat_achievement() {
  local id=$1
  [ -n "$id" ] || return 0
  coat_has_achievement "$id" && return 0
  COAT_ACHIEVED+=("$id")
  printf '%s\t%s\n' "$id" "$(printf '%(%s)T' -1)" >> "$ACHIEVEMENTS_FILE"
  printf '🏆 %s\n' "$(coat_achievement_name "$id")"
}

# add experience, update the heads-up display when the level changes
coat_award() {
  local amount=${1:-0} xp old_level new_level
  xp=$(<"$XP_FILE"); xp=${xp:-0}
  old_level=$(coat_level "$xp")
  xp=$(( xp + amount ))
  printf '%s\n' "$xp" > "$XP_FILE"
  new_level=$(coat_level "$xp")
  [ "$new_level" = "$old_level" ] || coat_hud_update
}

# the single line tmux shows: level and the active quest
coat_hud_update() {
  local xp quest=''
  xp=$(<"$XP_FILE"); xp=${xp:-0}
  if [ -f "$QUEST_FILE" ]; then
    quest=$(awk -F'\t' '$2 == "active" { print $5; exit }' "$QUEST_FILE")
  fi
  if [ -n "$quest" ]; then
    printf 'Lv%s ⚔ %s\n' "$(coat_level "$xp")" "${quest:0:40}" > "$QUEST_HUD"
  else
    printf 'Lv%s\n' "$(coat_level "$xp")" > "$QUEST_HUD"
  fi
}

# write one command to the log, hand out experience and achievements
coat_log_entry() {
  local command=${1:-} status=${2:-0} amount count hour
  [ -n "$command" ] || return 0

  # one line per command: when, how it ended, where, what
  printf '%s\t%s\t%s\t%s\n' "$(printf '%(%s)T' -1)" "$status" "$PWD" "$command" >> "$XP_LOG"

  # one xp for the command, more for a commit, a push or a test run
  amount=1
  case "$command" in
    "git commit"*|"git push"*) amount=$(( amount + 10 )) ;;
    make\ test*|pytest*|npm\ test*|cargo\ test*|go\ test*) amount=$(( amount + 5 )) ;;
  esac
  coat_award "$amount"

  # count the commands, the round numbers unlock achievements
  count=$(<"$XP_COUNT"); count=$(( ${count:-0} + 1 ))
  printf '%s\n' "$count" > "$XP_COUNT"
  case $count in
    1) coat_achievement first_spell ;;
    100) coat_achievement centurion ;;
    1000) coat_achievement veteran ;;
  esac

  # the small hours are worth their own badge
  hour=$(printf '%(%H)T' -1); hour=$(( 10#$hour ))
  [ "$hour" -lt 5 ] && coat_achievement night_owl
  return 0
}

# remember the command line before bash runs it; history settings are irrelevant
coat_capture_command() {
  [ -n "${COAT_XP_READY:-}" ] || return 0
  [ -n "${COAT_IN_CAPTURE:-}" ] && return 0
  # do not capture the commands that run while the prompt is being built
  [ -n "${COAT_IN_PROMPT:-}" ] && return 0
  COAT_IN_CAPTURE=1

  # the prompt hook and the trap itself are not user commands
  case "$BASH_COMMAND" in
    coat_prompt_log*|coat_capture_command*)
      COAT_IN_CAPTURE=
      return 0
      ;;
  esac

  # remember only the first command of a prompt, not every part of a pipeline
  [ -n "${COAT_PENDING_COMMAND:-}" ] || COAT_PENDING_COMMAND=$BASH_COMMAND
  COAT_IN_CAPTURE=
}

# log the command remembered by the DEBUG trap, with the status the prompt saw
coat_prompt_log() {
  # the prompt sees the exit status of the last command; capture it first
  local status=$?
  local command=${COAT_PENDING_COMMAND:-}
  COAT_PENDING_COMMAND=
  COAT_IN_PROMPT=1

  # run the prompt command that was there before Coat, if any
  if [ -n "${COAT_USER_PROMPT_COMMAND:-}" ]; then
    eval "$COAT_USER_PROMPT_COMMAND"
  fi
  COAT_IN_PROMPT=

  [ -n "$command" ] || return 0
  coat_log_entry "$command" "$status"
}

# the old name still works for callers that log the pending command by hand
coat_log_command() {
  coat_prompt_log
}

# show everything that can be earned
achievements() {
  local entry id rest name hint date
  local -A earned=()
  while IFS=$'\t' read -r id date; do
    [ -n "$id" ] && earned[$id]=$date
  done < "$ACHIEVEMENTS_FILE"

  for entry in "${COAT_ACHIEVEMENTS[@]}"; do
    id=${entry%%|*}; rest=${entry#*|}; name=${rest%%|*}; hint=${rest#*|}
    if [ -n "${earned[$id]:-}" ]; then
      printf '🏆 %-12s %s\n' "$name" "$hint"
    else
      printf '   %-12s %s\n' "$name" "$hint"
    fi
  done
}

# the character sheet: level, experience, habits and the current quest
character() {
  local xp level count progress bar top quest branch session done_quests
  xp=$(<"$XP_FILE"); xp=${xp:-0}
  level=$(coat_level "$xp")
  count=$(<"$XP_COUNT"); count=${count:-0}

  # twenty marks, one for every five points of the current level
  progress=$(( xp % 100 ))
  bar=$(printf '%*s' $(( progress / 5 )) '' | tr ' ' '#')
  bar=$(printf '%-20s' "$bar" | tr ' ' '.')

  # the spells you reach for most often
  top=$(awk -F'\t' '{ split($4, word, " "); if (word[1] != "") print word[1] }' "$XP_LOG" \
    | sort | uniq -c | sort -rn | head -5 | awk '{ printf "%s(%s) ", $2, $1 }')

  # where you are and what you are doing
  quest=$(awk -F'\t' '$2 == "active" { print $5; exit }' "$QUEST_FILE" 2>/dev/null)
  branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
  session=''
  [ -n "$TMUX" ] && session=$(tmux display-message -p '#S' 2>/dev/null)
  done_quests=$(awk -F'\t' '$2 == "done"' "$QUEST_FILE" 2>/dev/null | wc -l)

  printf 'Lv %s   [%s] %s/100 xp\n' "$level" "$bar" "$progress"
  printf 'Commands: %s   Quests done: %s   Achievements: %s/%s\n' \
    "$count" "$done_quests" "${#COAT_ACHIEVED[@]}" "${#COAT_ACHIEVEMENTS[@]}"
  printf 'Folder: %s%s\n' "$PWD" "${branch:+  (branch $branch)}"
  printf 'Quest: %s\n' "${quest:-none, use 'quest list'}"
  [ -n "$session" ] && printf 'Room: %s\n' "$session"
  printf 'Top spells: %s\n' "${top:-nothing yet}"
}

# show the heads-up display right away, before the first command
coat_hud_update

# interactive shells: capture the command, then log it when the prompt returns
if [[ $- == *i* ]]; then
  trap 'coat_capture_command' DEBUG
  # keep the user's prompt command and run it inside our logger
  COAT_USER_PROMPT_COMMAND=${PROMPT_COMMAND:-}
  PROMPT_COMMAND=coat_prompt_log
fi
