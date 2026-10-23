#!/bin/bash
# Loading, aliases and the guards around coat.sh.

# every part of coat is available after one source
test_load_core_functions() {
  new_case_sandbox
  local out name

  out=$(run_coat 'for f in mark trail cdg quest character achievements grimoire manual paczek loot eval_line_with_fzf; do printf "%s=%s\n" "$f" "$(type -t "$f")"; done')
  for name in mark trail cdg quest character achievements grimoire manual paczek loot eval_line_with_fzf; do
    assert_contains "$out" "$name=function"
  done

  # a few aliases that come from the modules
  out=$(run_coat 'for a in ll gs clip-in spot goto spellcast; do printf "%s=%s\n" "$a" "$(type -t "$a")"; done')
  for name in ll gs clip-in spot goto spellcast; do
    assert_contains "$out" "$name=alias"
  done
}

# the load flag is not exported, so a child shell loads coat again
test_load_flag_is_not_exported() {
  new_case_sandbox
  local out
  out=$(run_coat 'declare -p COAT_SHELL_LOADED; bash -c "echo \${COAT_SHELL_LOADED:-unset}"')

  assert_contains "$out" "declare -- COAT_SHELL_LOADED"
  assert_contains "$out" "unset"
}

# sourcing .coatrc twice must not add a second prompt hook
test_double_source_is_a_noop() {
  new_case_sandbox
  local out
  out=$(run_coat 'source "$HOME/.coatrc"; grep -o coat_log_command <<<"$PROMPT_COMMAND" | wc -l')

  assert_eq "$out" "1"
}

# without PATH_TO_COAT coat stops with a readable message
test_missing_path_to_coat() {
  new_case_sandbox
  local out status
  out=$(PATH_TO_COAT= HOME="$HOME" bash --noprofile --norc -c 'source "$1/coat.sh"' _ "$REPO_DIR" 2>&1)
  status=$?

  assert_status "$status" 1
  assert_contains "$out" "PATH_TO_COAT"
}

# the manual and the grimoire both index the real files
test_indexes_are_complete() {
  new_case_sandbox
  local sections rows
  sections=$(run_coat 'manual_index | wc -l')
  rows=$(run_coat 'coat_index | wc -l')

  assert_eq "$sections" "24"
  [ "$rows" -ge 300 ] || fail "expected at least 300 grimoire rows, got $rows"

  # every row has six tab separated fields
  out=$(run_coat 'coat_index | awk -F"\t" "NF != 6" | wc -l')
  assert_eq "$out" "0"
}

# a known function has the comment that sits directly above it
test_grimoire_comment() {
  new_case_sandbox
  local out
  out=$(run_coat 'coat_index | awk -F"\t" "\$1 == \"mark\" { print \$4 }"')

  assert_contains "$out" "mark the folder where you stopped"
}

# PATH_TO_COAT has to be a folder before anything is sourced
test_path_to_coat_must_be_a_folder() {
  new_case_sandbox
  local out status
  out=$(PATH_TO_COAT=/does/not/exist HOME="$HOME" bash --noprofile --norc -c 'source "$1/coat.sh"' _ "$REPO_DIR" 2>&1)
  status=$?

  assert_status "$status" 1
  assert_contains "$out" "does not exist"
}
