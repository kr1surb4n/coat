#!/bin/bash
# manual and grimoire: the documentation entry points.

# manual knows where its file is
test_manual_path() {
  new_case_sandbox
  local out
  out=$(run_coat 'manual --path')

  assert_eq "$out" "$REPO_DIR/docs/manual.md"
}

# the whole manual starts with its title
test_manual_all() {
  new_case_sandbox
  local out
  out=$(run_coat 'manual --all' | head -n 1)

  assert_eq "$out" "# Coat manual"
}

# a section can be picked with the fzf stub
test_manual_section() {
  new_case_sandbox
  local out
  out=$(FZF_PICK='^Quests' run_coat 'manual')

  assert_contains "$out" "## Quests"
  assert_contains "$out" "quest add"
}

# a missing manual is a readable error
test_manual_missing_file() {
  new_case_sandbox
  local status
  run_coat 'MANUAL_FILE=/nope/manual.md manual' >/dev/null
  status=$?

  assert_status "$status" 1
  assert_contains "$(last_stderr)" "is missing"
}

# the grimoire types the chosen name into the prompt (or prints it)
test_grimoire_pick() {
  new_case_sandbox
  local out
  out=$(FZF_PICK='^mark[[:space:]]' run_coat 'grimoire')

  assert_eq "$out" "mark"
}
