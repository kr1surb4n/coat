#!/bin/bash
# Shared helpers for the Coat test suite: sandbox, stubs and assertions.

REPO_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
TESTS_DIR=$REPO_DIR/tests

# counters are kept by run.sh
: "${PASS:=0}"
: "${FAIL:=0}"
: "${XFAIL:=0}"
: "${XPASS:=0}"

# record a failed assertion, the case keeps running
fail() {
  printf '    FAIL: %s\n' "$*"
  CASE_FAILED=1
}

# mark the current case as a known bug that is expected to fail
xfail() {
  CASE_XFAIL=1
  printf '    xfail: %s\n' "$*"
}

# assert that two strings are equal
assert_eq() {
  [ "$1" = "$2" ] || fail "expected [$2], got [$1]"
}

# assert that a string contains another string
assert_contains() {
  case "$1" in
    *"$2"*) ;;
    *) fail "expected to find [$2] in [$1]" ;;
  esac
}

# assert that a string does not contain another string
assert_not_contains() {
  case "$1" in
    *"$2"*) fail "did not expect [$2] in [$1]" ;;
  esac
}

# assert that a file exists
assert_file() {
  [ -f "$1" ] || fail "missing file $1"
}

# assert that a directory exists
assert_dir() {
  [ -d "$1" ] || fail "missing folder $1"
}

# assert an exit status
assert_status() {
  [ "$1" -eq "$2" ] || fail "expected status $2, got $1"
}

# build an isolated home and storage, and a .coatrc pointing at this checkout
sandbox() {
  SB=$(mktemp -d "${TMPDIR:-/tmp}/coat-test.XXXXXX")
  export SB
  export HOME="$SB/home"
  mkdir -p "$HOME" "$SB/storage" "$SB/bin" "$SB/spells" "$SB/tmuxp" "$SB/paczki" "$SB/completion"
  mkdir -p "$HOME/temp"
  : > "$HOME/.env"
  : > "$HOME/temp/current_dir"

  # every fzf call is answered by the stub, one test at a time
  unset FZF_PICK FZF_N FZF_ALL

  cat > "$HOME/.coatrc" <<EOF
# test configuration, never the real one
export PATH_TO_COAT="$REPO_DIR"
export COAT_MODULES="$REPO_DIR/modules"
export COAT_STORAGE="$SB/storage"
export SPOT_FILE="$SB/storage/spot"
export FOLDER_BOOKMARK_FILE="$SB/storage/bookmarks"
export TELEPORTS="$SB/storage/teleports"
export DIRTY_NOTES="$SB/storage/dirty_notes"
export FILE_MARKERS="$SB/storage/marks"
export TRAIL_FILE="$SB/storage/trail"
export PACZEK_FILLINGS="$SB/paczki"
export TMUXP_CONFIGDIR="$SB/tmuxp"
export BASH_COMPLETION_USER_DIR="$SB/completion"
export SPELLS="$SB/spells"
export MAGI_BOOK="$SB/spells/magi_book"
export MAGIC_BOOKS="$SB/spells/magi_book"
export VENV_FOLDER=.venv
source "\$PATH_TO_COAT/coat.sh"
EOF

  cat > "$SB/bin/fzf" <<'EOF'
#!/usr/bin/env bash
# test stub: choose lines by regex instead of opening the interface
mapfile -t rows
[ "${#rows[@]}" -eq 0 ] && exit 0
if [ -n "${FZF_ALL:-}" ]; then
  printf '%s\n' "${rows[@]}" | grep -E "${FZF_PICK:-.}" || true
else
  printf '%s\n' "${rows[@]}" | grep -E "${FZF_PICK:-.}" | head -n 1 || true
fi
EOF
  chmod +x "$SB/bin/fzf"

  # tmux is only used to type commands; record it and do nothing
  cat > "$SB/bin/tmux" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$SB/tmux.log"
case "$1" in
  display-message) printf 'coat-test\n' ;;
  list-windows) printf '0: shell  <== you are here\n' ;;
esac
EOF
  chmod +x "$SB/bin/tmux"

  cat > "$SB/bin/tmuxp" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$SB/tmuxp.log"
EOF
  chmod +x "$SB/bin/tmuxp"

  export PATH="$SB/bin:$PATH"
}

# start a case with a clean sandbox; run.sh removes it afterwards
new_case_sandbox() {
  sandbox
}

# run one command in a fresh shell with the sandbox .coatrc loaded
run_coat() {
  local command=$1
  HOME="$HOME" bash --noprofile --norc -c 'source "$HOME/.coatrc" >/dev/null; shopt -s expand_aliases; eval "$1"' _ "$command" 2>"$SB/stderr"
}

# the stderr of the last run_coat call
last_stderr() {
  cat "$SB/stderr"
}
