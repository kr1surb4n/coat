# Coat issues

Things that are wrong, broken or fragile in Coat, found while writing the
test suite and running `shellcheck`. Each entry says how to see it, what it
costs, and how it should be fixed.

Status: **open**, **fixed**, or **environment** (not a code bug).
Severity: **high** (data loss or a broken common path), **medium** (a
feature gives a wrong result), **low** (cosmetic, fragile or unused).

The automated pins live in `tests/cases/`; a fixed issue should flip its
`xfail` test to an unexpected pass, which is your signal to remove the
mark.

```bash
make test                 # includes the expected failures
make shellcheck           # the static findings below
```

## Summary

| ID | Status | Severity | Issue |
|----|--------|----------|-------|
| ISS-01 | open | medium | `command_exists` always returns 2 |
| ISS-02 | open | medium | `spot`, `goto`, `cdg` break folder names with spaces |
| ISS-03 | open | medium | `cd ...` lists the folder twice |
| ISS-04 | open | low | `os-info` checks a literal string, never prints those files |
| ISS-05 | open | medium | `squashcurrent` expands `$1` in the shell, not in awk |
| ISS-06 | open | low | `dec2hex`, `gnb`, `gdv` are aliases that use shell `$1`/`$@` |
| ISS-07 | open | low | `cdo` uses an unquoted `$OLDPWD` |
| ISS-08 | open | low | `install.sh` ignores a failed `git submodule update` |
| ISS-09 | open | low | `QUICK_STATUS` ignores `COAT_STORAGE` |
| ISS-10 | open | low | `spellforge` / ALT+w is unfinished |
| ISS-11 | environment | — | `z` needs `fasd`, not installed |
| ISS-12 | environment | — | `dungeon` has no `TMUXP_CONFIGDIR` folder yet |
| ISS-13 | environment | — | `o` expects macOS `open` |
| ISS-14 | open | low | 17 `shellcheck` findings (details below) |
| FIX-01 | fixed | high | `paczek` copied the `cd` listing (coloured folders) |
| FIX-02 | fixed | high | `paczek` overwrote existing files silently |
| FIX-03 | fixed | low | stale `._push_*` scripts with a missing key |
| FIX-04 | fixed | high | a nested shell did not load Coat |
| FIX-05 | fixed | low | the grimoire read comments from far above |

---

## Open

### ISS-01 — `command_exists` always returns 2

**File:** `modules/bash_functions.sh:658-661`

```bash
command_exists()
{
    return type "$1" &> /dev/null ;
}
```

`return` expects a number; `type` is treated as the number and fails.
Every call returns 2, whether the command exists or not. It is unused
today, which is why nothing visibly breaks, but any future guard built on
it will be wrong.

**Repro**

```bash
bash -ic 'command_exists ls; echo $?'    # 2
bash -ic 'command_exists nope_xyz; echo $?'  # 2
```

**Fix**

```bash
command_exists() { type "$1" &>/dev/null; }
```

**Pin:** `tests/cases/70-known.sh` (`command_exists_is_broken`, xfail).

### ISS-02 — paths with spaces break `spot`, `goto` and `cdg`

**Files:** `modules/organization.sh:34-35`, `:63-64`, `:69-72`

```bash
alias spot='cat $SPOT_FILE'
alias goto='cd `spot`'
alias cdg='cat $FOLDER_BOOKMARK_FILE | fzf'
```

The variables are unquoted and `goto` uses an unquoted command
substitution. A marked folder such as `/tmp/project space` is split into
two words.

**Repro**

```bash
mkdir -p "/tmp/coat space"; cd "/tmp/coat space"; mark; cd /; goto
# cat: /tmp/coat: No such file or directory
# cd goes HOME instead
```

**Fix:** make them functions with quotes, for example
`spot() { cat "$SPOT_FILE"; }` and `goto() { cd "$(spot)"; }`, and quote
`$FOLDER_BOOKMARK_FILE` in `cdg`.

**Pin:** `tests/cases/30-nav.sh` (`goto_folder_with_space`, xfail).

### ISS-03 — `cd ...` runs the wrapper twice

**File:** `modules/bash_functions.sh:69-96`

The wrapper handles dots by calling `cd` again:

```bash
if [[ "x$*" == "x..." ]]; then
  cd ../..
```

That is the function, not the builtin, so the inner call already writes
the current-folder file, the trail and the listing; the outer call then
does the trail and listing again. The trail usually hides it because the
second line is a duplicate and `trail_add` skips it, but the folder is
listed twice.

**Repro**

```bash
mkdir -p /tmp/a/b && cd /tmp/a/b && cd ...
# two listings of /tmp/a
```

**Fix:** use `builtin cd ../..` in every dot branch (the main branch
already uses `builtin`). A separate `oldcd() { builtin cd "$@"; }`
defined before the wrapper works too; a plain variable holding `cd`
does **not**, because after the override it resolves to the function
again.

**Pin:** `tests/cases/30-nav.sh` (`cd_dots_double_listing`, xfail).

### ISS-04 — `os-info` never prints the release files

**File:** `modules/bash_functions.sh:638-654`

```bash
if [ -z /etc/lsb-release ]; then
  cat /etc/lsb-release;
fi
```

`-z` tests whether the literal string is empty, which is always false.
The intent was probably `-f` (file exists).

**Fix:** `[ -f /etc/lsb-release ]` (and the same for `/etc/issue` and
`/proc/version`), or drop the block because `lsb_release -a` and
`uname -a` already ran.

### ISS-05 — `squashcurrent` expands `$1` in the shell

**File:** `modules/git.sh:35`

```bash
alias squashcurrent='git rebase -i $(shortlogs | fzf | awk "{print $1}")'
```

The double-quoted awk program is expanded by bash when the alias runs, so
`awk "{print $1}"` becomes `awk "{print }"` and the whole log line is
returned to `git rebase -i`. It should be a function with single quotes
around the awk program:

```bash
squashcurrent() {
  git rebase -i "$(shortlogs | fzf | awk '{print $1}')"
}
```

### ISS-06 — aliases that use `$1` or `$@`

**Files:** `modules/aliases.sh:459`, `modules/git.sh:41`, `modules/git.sh:129`

- `dec2hex='printf "%x\n" $1'` appends the number after `$1`, which is
  whatever positional parameter the shell happens to have.
- `gnb='git checkout -b $1'` only works while the shell has no `$1`;
  otherwise the branch name is built from it.
- `gdv='git diff -w "$@" | vim -R -'` leaves the file argument on the
  `vim` side of the pipe, so it never reaches `git diff`.

Aliases cannot take arguments; these should be functions.

### ISS-07 — `cdo` uses an unquoted `$OLDPWD`

**File:** `modules/bash_functions.sh:104-107`

```bash
cdo()
{
  cd $OLDPWD
}
```

Same class as ISS-02: a previous folder with a space is split.

**Fix:** `cd "$OLDPWD"`.

### ISS-08 — `install.sh` ignores a failed submodule update

**File:** `install.sh:41`

```bash
git submodule update --init
```

If git is missing, the checkout is not a git repository, or the network is
down, the script continues with empty `lib/` folders. Paczek then copies
from an empty library and the error appears much later.

**Fix:** check the result and print a warning (or fail) with a clear
message; a separate `command -v git` check documents the requirement.

### ISS-09 — `QUICK_STATUS` does not follow `COAT_STORAGE`

**File:** `modules/variables.sh:4`

```bash
export QUICK_STATUS=$PATH_TO_COAT/storage/status
```

Every other runtime path uses `$COAT_STORAGE`; if storage is moved, this
one still points at the repository. The variable is currently unused, so
this is low priority.

**Fix:** `export QUICK_STATUS=$COAT_STORAGE/status` or remove it.

### ISS-10 — `spellforge` / ALT+w is unfinished

**File:** `modules/spells.sh:89`, `modules/shortcuts.sh:21`

The alias runs `type_line_with_fzf $MAGI_BOOK`, but the key is described
as “not working” in the shortcut and as unfinished in the manual. Decide
what it should do (edit or insert) and either finish it or remove the
binding so it does not look broken.

### ISS-11 — `z` needs `fasd`

`z` (`modules/spells.sh:207`) calls `fasd`, which is not installed on this
machine. The manual says so. Either install `fasd` or replace the backend
with the trail file that Coat already keeps.

### ISS-12 — `dungeon` has no layout folder

`TMUXP_CONFIGDIR=~/.dotfiles/tmux` (in `.coatrc`) does not exist, so
`dungeon` always reports “does not exist”. Create the folder or point the
variable at an existing one; `save_the_workshop` will then fill it.

### ISS-13 — `o` expects macOS `open`

`o` is a thin wrapper around the macOS `open` command. On Linux it fails
unless something provides `open`; use `xdg-open`. The manual already
mentions it.

### ISS-14 — the `shellcheck` findings

`make shellcheck` (severity error) reports 17 findings:

| Count | Code | Where | What |
|-------|------|-------|------|
| 5 | SC2142 | `alias.*` in `aliases.sh`, `git.sh` | aliases using `$1`/`$@` (ISS-05, ISS-06) |
| 5 | SC1xxx | `modules/autocomplete.sh` | a stray shebang in the middle of the file (cosmetic) |
| 3 | SC2157 | `os-info` | `-z` on a literal string (ISS-04) |
| 2 | SC2145 | `unidecode`, `codepoint` | string and array mixed in perl arguments |
| 1 | SC2151 | `command_exists` | `return type ...` (ISS-01) |
| 1 | SC2199 | `duh` | `[[ -n "$@" ]]` |

The autocomplete shebang is just noise in a sourced file. The rest are
real or worth cleaning before turning `make shellcheck` into a blocking
gate.

---

## Fixed

### FIX-01 — paczek copied the `cd` listing

**Commit:** `541b2a9 Keep the folder listing out of paczek`

`paczek` listed the library with `(cd "$PACZEK_FILLINGS" && find ...)`.
`cd` is the Coat wrapper, which prints the folder listing to stdout, and
that output landed in the same array as the fzf picks. Every paczek then
tried to copy coloured folder names:

```
cp: cannot stat '…/templates/': No such file or directory
```

The library is now read with `find` on its absolute path, and the `cd`
listing goes to stderr so no command substitution can capture it.

**Pin:** `paczek_leaves_trail_alone`.

### FIX-02 — paczek overwrote existing files silently

**Commit:** `b728ae1 Ask before paczek overwrites a file`

Same-name files were replaced without a word. The copy loop now asks
`overwrite? [y/N]` and skips on anything but `y`; without a terminal it
skips and says so.

**Pin:** `paczek_skips_existing_without_tty` (the `y` path is manual).

### FIX-03 — stale `._push_*` scripts

`._push_to_main_as_kris` (and paczki's `._push_to_master`) were untracked
helpers that called `ssh -i ~/.ssh/id_rp_coat_github_kris` (a key that
does not exist) and force-pushed. The SSH config and the normal remotes
make them unnecessary, so they were removed.

### FIX-04 — a nested shell did not load Coat

**Commit:** `540b198` (loading guard)

The guard was exported, so a child shell thought Coat was already loaded
and skipped the aliases. `COAT_SHELL_LOADED` is now a normal shell
variable and every new shell loads Coat again.

**Pin:** `load_flag_is_not_exported`.

### FIX-05 — the grimoire read comments from far above

**Commit:** `583ea4c Stop reading comments from far above`

The index now resets the description on a blank line and uses only the
comment directly above a definition.

**Pin:** `grimoire_comment`.

---

## Not a bug

- `map` is already an alias for `xargs -n1`, which is why the tmux
  window map is called `sessionmap`.
- `.coatrc` sets `COAT_STORAGE` unconditionally on purpose: the paths are
  machine specific and should all derive from `PATH_TO_COAT`. Tests build
  a separate `.coatrc` instead of exporting over it.
- The `cd` listing goes to stderr. It is decoration; keeping it out of
  stdout is what makes `$(...)` safe.
