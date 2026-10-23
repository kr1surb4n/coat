#!/bin/bash
# install.sh in a throwaway home: link, runtime files, refusals.

# build a small copy of coat and a matching .coatrc, never the real home
sandbox_install() {
  SB=$(mktemp -d "${TMPDIR:-/tmp}/coat-install.XXXXXX")
  export SB
  export HOME="$SB/home"
  mkdir -p "$HOME" "$SB/src" "$SB/bin" "$SB/paczki" "$SB/tmuxp" "$SB/completion"
  cp "$REPO_DIR/coat.sh" "$REPO_DIR/install.sh" "$SB/src/"
  cp -a "$REPO_DIR/modules" "$SB/src/"

  cat > "$HOME/.coatrc" <<EOF
export PATH_TO_COAT="$SB/src"
export COAT_STORAGE="$SB/src/storage"
export SPOT_FILE="$SB/src/storage/spot"
export FOLDER_BOOKMARK_FILE="$SB/src/storage/bookmarks"
export TELEPORTS="$SB/src/storage/teleports"
export DIRTY_NOTES="$SB/src/storage/dirty_notes"
export FILE_MARKERS="$SB/src/storage/marks"
export PACZEK_FILLINGS="$SB/paczki"
export TMUXP_CONFIGDIR="$SB/tmuxp"
export BASH_COMPLETION_USER_DIR="$SB/completion"
source "\$PATH_TO_COAT/coat.sh"
EOF

  # no git work in a test: record the submodule call and pretend it worked
  cat > "$SB/bin/git" <<'EOF'
#!/bin/sh
printf 'git %s\n' "$*" >> "$SB/git.log"
EOF
  chmod +x "$SB/bin/git"

  unset COAT_STORAGE FZF_PICK FZF_N FZF_ALL
}

# run install.sh with the sandbox git and home
run_install() {
  HOME="$HOME" PATH="$SB/bin:$PATH" bash "$SB/src/install.sh" >"$SB/install.out" 2>"$SB/stderr"
}

# a normal run links ~/.coat and creates every runtime file
test_install_creates_everything() {
  sandbox_install
  run_install
  local status=$?

  assert_status "$status" 0
  assert_eq "$(readlink -f "$HOME/.coat")" "$SB/src"

  local file
  for file in status teleports spot bookmarks trail quests quest_hud achievements xp xp.log xp_count; do
    assert_file "$SB/src/storage/$file"
  done
  assert_file "$HOME/temp/current_dir"
  assert_file "$HOME/.env"
  assert_contains "$(cat "$SB/git.log")" "submodule update"
}

# a second run keeps the existing numbers
test_install_preserves_runtime() {
  sandbox_install
  run_install
  printf '42\n' > "$SB/src/storage/xp"
  run_install

  assert_eq "$(cat "$SB/src/storage/xp")" "42"
  assert_eq "$(readlink -f "$HOME/.coat")" "$SB/src"
}

# install never edits the shell startup file
test_install_does_not_touch_bashrc() {
  sandbox_install
  printf '# my own bashrc\n' > "$HOME/.bashrc"
  run_install

  assert_eq "$(cat "$HOME/.bashrc")" "# my own bashrc"
}

# missing .coatrc stops before anything else
test_install_needs_coatrc() {
  sandbox_install
  mv "$HOME/.coatrc" "$SB/coatrc.gone"
  run_install
  local status=$?

  assert_status "$status" 1
  assert_contains "$(last_stderr)" "~/.coatrc is missing"
}

# a foreign ~/.coat is refused instead of replaced
test_install_refuses_foreign_link() {
  sandbox_install
  ln -s /tmp "$HOME/.coat"
  run_install
  local status=$?

  assert_status "$status" 1
  assert_contains "$(last_stderr)" "links to"
}

# without COAT_STORAGE the runtime files would land in /
test_install_needs_storage() {
  sandbox_install
  cat > "$HOME/.coatrc" <<EOF
export PATH_TO_COAT="$SB/src"
source "\$PATH_TO_COAT/coat.sh"
EOF
  run_install
  local status=$?

  assert_status "$status" 1
  assert_contains "$(last_stderr)" "COAT_STORAGE"
}
