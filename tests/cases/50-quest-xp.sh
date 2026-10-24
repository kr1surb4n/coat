#!/bin/bash
# Quests, experience, levels, achievements and the HUD.

# add two quests and make the second one active
test_quest_activate() {
  new_case_sandbox
  local out state
  out=$(FZF_PICK='^2' run_coat 'quest add "first"; quest add "second"; quest list; cat "$COAT_STORAGE/quests"; cat "$COAT_STORAGE/quest_hud"')

  assert_contains "$out" "active quest: second"
  assert_contains "$out" "Lv1 ⚔ second"
  state=$(awk -F'\t' '$1 == 2 { print $2 }' "$SB/storage/quests")
  assert_eq "$state" "active"
  state=$(awk -F'\t' '$1 == 1 { print $2 }' "$SB/storage/quests")
  assert_eq "$state" "open"
}

# finishing a quest pays 25 xp, earns the badge and clears the HUD
test_quest_done() {
  new_case_sandbox
  local out
  out=$(FZF_PICK='^1' run_coat 'quest add "finish me"; quest list; quest done 1; quest log; cat "$COAT_STORAGE/xp"; cat "$COAT_STORAGE/quest_hud"; cat "$COAT_STORAGE/achievements"')

  assert_contains "$out" "quest 1 done: finish me"
  assert_contains "$out" "25"
  assert_contains "$out" "Lv1"
  assert_contains "$out" "first_quest"
  assert_eq "$(awk -F'\t' '$1 == 1 { print $2 }' "$SB/storage/quests")" "done"
}

# a missing quest is an error and does not change the file
test_quest_missing_id() {
  new_case_sandbox
  local status
  run_coat 'quest done 99' >/dev/null
  status=$?

  assert_status "$status" 1
  assert_contains "$(last_stderr)" "no quest 99"
}

# one level per 100 xp, and the HUD follows the new level
test_xp_levels() {
  new_case_sandbox
  local out
  out=$(run_coat 'printf "99\n" > "$COAT_STORAGE/xp"; coat_award 1; coat_level "$(cat "$COAT_STORAGE/xp")"; cat "$COAT_STORAGE/quest_hud"')

  assert_contains "$out" "2"
  assert_contains "$out" "Lv2"
}

# the character sheet shows the level, the bar and the counters
test_character_sheet() {
  new_case_sandbox
  local out
  out=$(run_coat 'printf "100\n" > "$COAT_STORAGE/xp"; printf "7\n" > "$COAT_STORAGE/xp_count"; character')

  assert_contains "$out" "Lv 2"
  assert_contains "$out" "0/100 xp"
  assert_contains "$out" "Commands: 7"
}

# achievements are listed whether they are earned or not
test_achievements_list() {
  new_case_sandbox
  local out
  out=$(run_coat 'coat_achievement first_spell; achievements')

  assert_contains "$out" "Apprentice"
  assert_contains "$out" "Centurion"
  assert_contains "$out" "Looter"
  assert_contains "$(cat "$SB/storage/achievements")" "first_spell"
}

# the command log does not depend on history settings
test_xp_log_ignores_history() {
  new_case_sandbox
  local out
  out=$(run_coat 'HISTIGNORE="*"; COAT_XP_READY=1; COAT_PENDING_COMMAND="echo hidden"; coat_prompt_log; cat "$COAT_STORAGE/xp.log"; cat "$COAT_STORAGE/xp_count"')

  assert_contains "$out" "echo hidden"
  assert_contains "$out" "1"

  # the status comes from the command, not from a history entry
  out=$(run_coat 'COAT_XP_READY=1; COAT_PENDING_COMMAND="false"; false; coat_prompt_log; cat "$COAT_STORAGE/xp.log"')
  assert_contains "$out" $'\t1\t'
}

# a quest longer than 40 characters is cut in the HUD
test_hud_truncates_long_quest() {
  new_case_sandbox
  local out
  out=$(run_coat 'quest add "12345678901234567890123456789012345678901234567890"; quest_activate 1; coat_hud_update; cat "$COAT_STORAGE/quest_hud"')

  assert_contains "$out" "Lv1 ⚔ 1234567890123456789012345678901234567890"
}
