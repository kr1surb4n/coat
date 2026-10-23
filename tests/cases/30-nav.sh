#!/bin/bash
# cd, the trail, marks and bookmarks.

# cd changes folder, updates the state file and lists the folder on stderr
test_cd_updates_state() {
  new_case_sandbox
  mkdir -p "$HOME/project"
  local out
  out=$(run_coat 'cd "$HOME/project"')

  assert_eq "$out" ""
  assert_eq "$(cat "$HOME/temp/current_dir")" "$HOME/project"
  assert_contains "$(last_stderr)" "."

  # the last trail line is a cd to the new folder
  assert_eq "$(cut -f2,3 "$SB/storage/trail" | tail -1)" "cd	$HOME/project"
}

# cd to the folder you are already in does not write the trail twice
test_trail_deduplicates() {
  new_case_sandbox
  mkdir -p "$HOME/project"
  local lines
  lines=$(run_coat 'cd "$HOME/project"; cd "$HOME/project"; wc -l < "$COAT_STORAGE/trail"')

  assert_eq "$lines" "1"
}

# mark remembers the folder, writes the trail and pays two xp
test_mark_and_spot() {
  new_case_sandbox
  mkdir -p "$HOME/project"
  local out
  out=$(run_coat 'cd "$HOME/project"; mark; cat "$SPOT_FILE"; cat "$COAT_STORAGE/xp"')

  assert_contains "$out" "$HOME/project"
  assert_contains "$out" "2"
  assert_file "$SB/storage/spot"
  assert_eq "$(cut -f2 "$SB/storage/trail" | tail -1)" "mark"
  assert_contains "$(cat "$SB/storage/achievements")" "camper"
}

# goto returns to the marked folder
test_goto() {
  new_case_sandbox
  mkdir -p "$HOME/project"
  local out
  out=$(run_coat 'cd "$HOME/project"; mark; cd /; goto; pwd' 2>/dev/null | tail -n 1)

  assert_eq "$out" "$HOME/project"
}

# cdo returns to the previous folder
test_cdo() {
  new_case_sandbox
  mkdir -p "$HOME/one" "$HOME/two"
  local out
  out=$(run_coat 'cd "$HOME/one"; cd "$HOME/two"; cdo; pwd')

  assert_eq "$out" "$HOME/one"
}

# bookmarkfolder adds a line and cdg returns to it
test_bookmarks() {
  new_case_sandbox
  mkdir -p "$HOME/project"
  local out
  out=$(FZF_PICK="^$HOME/project\$" run_coat 'cd "$HOME/project"; bookmarkfolder; cd /; cdg; pwd')

  assert_eq "$out" "$HOME/project"
  assert_contains "$(cat "$SB/storage/bookmarks")" "$HOME/project"
}

# known issue: the ... branches call the wrapper again, so the folder is listed twice
test_cd_dots_double_listing() {
  new_case_sandbox
  xfail "ISS-03: cd ... recurses through the wrapper"
  run_coat 'mkdir -p "$HOME/a/b"; cd "$HOME/a/b"; cd ...' >/dev/null

  # .coatrc is in HOME, so a second listing of HOME is easy to count
  local count
  count=$(grep -c '\.coatrc' "$SB/stderr")
  assert_eq "$count" "1"
}

# known issue: spot and goto do not quote the folder name
test_goto_folder_with_space() {
  new_case_sandbox
  xfail "ISS-02: spot/goto split a folder name with a space"
  mkdir -p "$HOME/project space"
  local out
  out=$(run_coat 'cd "$HOME/project space"; mark; cd /; goto; pwd' 2>/dev/null | tail -n 1)

  assert_eq "$out" "$HOME/project space"
}
