#!/bin/bash
# paczek: copying, prefixes, loot detection and the overwrite guard.

# a small library used by the paczek tests
make_library() {
  mkdir -p "$SB/paczki/python" "$SB/paczki/other"
  printf 'print("hello")\n' > "$SB/paczki/python/hello.py"
  printf 'other\n' > "$SB/paczki/other/thing.txt"
}

# the chosen file lands in the current folder, xp goes up and Looter is earned
test_paczek_copies_pick() {
  new_case_sandbox
  make_library
  mkdir -p "$HOME/project"
  local out
  out=$(FZF_PICK='^python/hello.py$' run_coat 'cd "$HOME/project"; paczek; cat "$COAT_STORAGE/xp"')

  assert_file "$HOME/project/hello.py"
  assert_contains "$out" "3"
  assert_contains "$(cat "$SB/storage/achievements")" "looter"
}

# paczek must not add a line to the trail by itself (the old cd bug)
test_paczek_leaves_trail_alone() {
  new_case_sandbox
  make_library
  mkdir -p "$HOME/project"
  local out
  out=$(FZF_PICK='^python/hello.py$' run_coat 'cd "$HOME/project"; before=$(wc -l < "$COAT_STORAGE/trail"); paczek; after=$(wc -l < "$COAT_STORAGE/trail"); printf "%s:%s\n" "$before" "$after"' | tail -n 1)

  assert_eq "$out" "1:1"
}

# an existing file is skipped when there is no terminal to ask on
test_paczek_skips_existing_without_tty() {
  new_case_sandbox
  make_library
  mkdir -p "$HOME/project"
  printf 'OLD\n' > "$HOME/project/hello.py"
  FZF_PICK='^python/hello.py$' run_coat 'cd "$HOME/project"; paczek' >/dev/null

  assert_eq "$(cat "$HOME/project/hello.py")" "OLD"
  assert_contains "$(last_stderr)" "skipped hello.py"
}

# the optional prefix limits the fzf list to one section
test_paczek_prefix() {
  new_case_sandbox
  make_library
  mkdir -p "$HOME/project"
  FZF_PICK='^other/' run_coat 'cd "$HOME/project"; paczek python' >/dev/null

  [ -e "$HOME/project/thing.txt" ] && fail "the python prefix offered another section"
}

# missing library is a readable error, not a broken copy
test_paczek_missing_library() {
  new_case_sandbox
  local status
  PACZEK_FILLINGS=/nope run_coat 'PACZEK_FILLINGS=/nope paczek'
  status=$?

  assert_status "$status" 1
  assert_contains "$(last_stderr)" "PACZEK_FILLINGS"
}

# loot recognises the common project kinds
test_loot_detection() {
  new_case_sandbox
  local kind
  mkdir -p "$HOME/py" "$HOME/js" "$HOME/docker" "$HOME/tf" "$HOME/make" "$HOME/git" "$HOME/none"

  : > "$HOME/py/pyproject.toml"
  : > "$HOME/js/package.json"
  : > "$HOME/docker/Dockerfile"
  : > "$HOME/tf/main.tf"
  : > "$HOME/make/Makefile"
  mkdir -p "$HOME/git/.git"

  kind=$(run_coat 'cd "$HOME/py"; coat_loot_type')
  assert_eq "$kind" "python"
  kind=$(run_coat 'cd "$HOME/js"; coat_loot_type')
  assert_eq "$kind" "js"
  kind=$(run_coat 'cd "$HOME/docker"; coat_loot_type')
  assert_eq "$kind" "docker"
  kind=$(run_coat 'cd "$HOME/tf"; coat_loot_type')
  assert_eq "$kind" "terraform"
  kind=$(run_coat 'cd "$HOME/make"; coat_loot_type')
  assert_eq "$kind" "makefiles"
  kind=$(run_coat 'cd "$HOME/git"; coat_loot_type')
  assert_eq "$kind" "git"
  kind=$(run_coat 'cd "$HOME/none"; coat_loot_type')
  assert_eq "$kind" ""
}
