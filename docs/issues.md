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
make shellcheck           # static analysis, should report nothing
```

## Summary

| ID | Status | Severity | Issue |
|----|--------|----------|-------|
| ISS-01 | fixed | medium | `command_exists` always returns 2 |
| ISS-02 | open | medium | `spot`, `goto`, `cdg` break folder names with spaces |
| ISS-03 | open | medium | `cd ...` lists the folder twice |
| ISS-04 | fixed | low | `os-info` checks a literal string, never prints those files |
| ISS-05 | fixed | medium | `squashcurrent` expands `$1` in the shell, not in awk |
| ISS-06 | fixed | low | `dec2hex`, `gnb`, `gdv` are aliases that use shell `$1`/`$@` |
| ISS-07 | open | low | `cdo` uses an unquoted `$OLDPWD` |
| ISS-08 | open | low | `install.sh` ignores a failed `git submodule update` |
| ISS-09 | open | low | `QUICK_STATUS` ignores `COAT_STORAGE` |
| ISS-10 | open | low | `spellforge` / ALT+w is unfinished |
| ISS-11 | environment | — | `z` needs `fasd`, not installed |
| ISS-12 | environment | — | `dungeon` has no `TMUXP_CONFIGDIR` folder yet |
| ISS-13 | environment | — | `o` expects macOS `open` |
| ISS-14 | fixed | low | `shellcheck` findings (details below) |
| ISS-15 | open | medium | duplicate aliases; the load order is now explicit |
| ISS-16 | open | high | ordinary commands mean something else |
| ISS-17 | open | high | Python helpers assume a global Python and `pip` |
| ISS-18 | open | high | no core/extras boundary; every module is invasive |
| FIX-01 | fixed | high | `paczek` copied the `cd` listing (coloured folders) |
| FIX-02 | fixed | high | `paczek` overwrote existing files silently |
| FIX-03 | fixed | low | stale `._push_*` scripts with a missing key |
| FIX-04 | fixed | high | a nested shell did not load Coat |
| FIX-05 | fixed | low | the grimoire read comments from far above |
| FIX-06 | fixed | low | load order was implicit; `TERM` and history were forced |
| FIX-07 | fixed | low | XP logging depended on history settings |
| FIX-08 | fixed | low | `autocomplete.sh` had a stray shebang in the middle |

---

## Open

Some entries below are kept with their original detail even after a fix;
the summary says `fixed` and the section starts with `**Status:** fixed.`

### ISS-01 — `command_exists` always returned 2

**Status:** fixed.

**File:** `modules/bash_functions.sh`

```bash
command_exists()
{
    type "$1" &> /dev/null
}
```

`return type ...` made every call return 2, whether the command existed or
not. It now returns the status of `type`.

**Pin:** `tests/cases/70-known.sh` (`command_exists`), plus the existing
`load_core_functions` coverage.

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

### ISS-04 — `os-info` never printed the release files

**Status:** fixed.

**File:** `modules/bash_functions.sh`

The three checks used `-z` on a literal path, which is always false, so
the release files were never printed. They now use `-f`, which is the
file-exists test the block intended.

### ISS-05 — `squashcurrent` expanded `$1` in the shell

**Status:** fixed.

**File:** `modules/git.sh`

```bash
squashcurrent() {
  local commit
  commit=$(shortlogs | fzf | awk '{print $1}') || return 0
  [ -n "$commit" ] || return 0
  git rebase -i "$commit"
}
```

The alias expanded the double-quoted awk program before `awk` saw it, so
the commit hash was lost. It is now a function with a single-quoted awk
program and a guard for an empty pick.

### ISS-06 — aliases that used `$1` or `$@`

**Status:** fixed.

**Files:** `modules/aliases.sh`, `modules/git.sh`

- `dec2hex` is now a function with `printf '%x\n' "$1"`;
- `gnb` is now a function that requires a branch name;
- `gdv` is now a function, so the file argument reaches `git diff`;
- `inf` is now a function, which also keeps ShellCheck quiet.

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

**Status:** fixed. `make shellcheck` now reports no findings.

The pass cleaned:

| Code | Where | What |
|------|-------|------|
| SC2142 | `aliases.sh`, `git.sh` | aliases using `$1`/`$@`; now functions (ISS-05, ISS-06) |
| SC1xxx | `modules/autocomplete.sh` | the `# !!` line looked like a shebang; now a normal warning |
| SC2157 | `os-info` | `-z` on a literal string; now `-f` (ISS-04) |
| SC2145 | `unidecode`, `codepoint` | `$@` mixed into a string; now `$*` |
| SC2151 | `command_exists` | `return type ...`; now `type` (ISS-01) |
| SC2199 | `duh` | `[[ -n "$@" ]]`; now `$*` |

`make shellcheck` is now a clean gate, not an informational target.

### ISS-15 — duplicate aliases; the load order is now explicit

**Files:** `coat.sh`, `modules/aliases.sh`, `modules/bash_functions.sh`,
`modules/git.sh`

The load order used to be a comment and a list of `source` lines. It is now
an explicit `COAT_MODULE_ORDER` array in `coat.sh`, and
`test_module_order_is_explicit` checks that `prompt` is last. The order is:

```
variables -> aliases -> bash_functions -> organization -> simplifications ->
git -> python -> xp -> quest -> dungeon -> spells -> grimoire -> manual ->
shortcuts -> autocomplete -> prompt
```

The audit still has real duplicate names. The visible one is `ll`:

- `aliases.sh:264` defines `ls -lFh --group-directories-first --color`;
- `bash_functions.sh:2` defines `ls -AlFctr`;
- `bash_functions.sh` loads later, so the plain version wins.

`la` and `l` have the same problem. `grep` is defined twice in
`aliases.sh` (`:56` and `:230`); the later colour alias wins and
`GREP_OPTIONS` is lost. `ls` is defined at `:204` (`grc ls`) and `:249`
(plain `ls -F --color`); line 249 wins. `..`, `...`, `....`, `g`, and the
OS/tool branches are duplicates too, but some are harmless or mutually
exclusive.

**Full table, definitions, differences and the synonym groups:**
`docs/alias-audit.md`.

**Fix:** decide, row by row, whether to keep the later definition, remove
the earlier one, or move the whole group to extras. Then make the audit and
the code agree. This is a task, not a one-line deletion.

### ISS-16 — ordinary commands mean something else

This is the issue behind the quote: "you have to remember that basic
commands mean something else, and some behaviour is hidden." The complete
list and the load-order effect are in `docs/overrides.md`; the manual gets
a work-in-progress section.

The list of names is:

| Name | Kind / where | What changed |
|------|--------------|--------------|
| `sudo` | alias `aliases.sh:22` | trailing space, so `sudo ll` expands |
| `chown`, `chmod`, `chgrp` | aliases `aliases.sh:48-50` | `--preserve-root` |
| `dmesg` | alias `aliases.sh:53` | `-T` |
| `grep` | aliases `aliases.sh:56`, `:230` | `--color`; `GREP_OPTIONS` lost |
| `mkdir` | alias `aliases.sh:118` | `-p` |
| `du` | alias `aliases.sh:401` | `-kh` |
| `df` | alias `aliases.sh:407` | `-kTh` |
| `ls` | aliases `aliases.sh:204`, `:249` | `-F --color`; grc lost |
| `dir`, `vdir` | aliases `aliases.sh:272`, `:274` | use `ls` with a format |
| `vi` | alias `bash_functions.sh:20` | `nvim` when `vim` exists |
| `tmux` | alias `aliases.sh:13` | `-u` |
| `black` | alias `python.sh:15` | `-Sq` |
| `cd` | function `bash_functions.sh:69` | saves state, writes trail, prints a listing |
| `man` | function `bash_functions.sh:420` | colour pager variables |
| `t` | function `bash_functions.sh:1276` | tail helper; short name |
| `o` | function `bash_functions.sh:1316` | open helper; still expects macOS `open` |
| `z` | function `spells.sh:207` | fzf+fasd helper; short name |
| `as`, `configure`, `diff`, `dig`, `g++`, `gas`, `gcc`, `head`, `ifconfig`, `ld`, `make`, `mount`, `netstat`, `ping`, `ps`, `tail`, `traceroute`, `syslog` | aliases `aliases.sh:194-212` | grc wrappers, only with `grc` and a non-dumb `TERM` |
| `egrep`, `fgrep` | aliases `aliases.sh:231-232` | colour |
| `top` | alias `aliases.sh:224` | `htop` when installed; `top_orig` saved |
| `tree` | alias `aliases.sh:281` | `tree -Csu` or a `find` fallback |
| `ack` | alias `aliases.sh:298` | `ack-grep` when installed |
| `runserver`, `server`, `json`, `lc`, `uc`, `urldecode`, `urlencode` | aliases/functions | Python helpers, several still Python 2 |

All of these load in the order at the top of this entry. A later module wins:
`aliases.sh` runs before `bash_functions.sh`, so the `cd`/`man` functions
win over any alias; `git.sh`, `python.sh` and `spells.sh` run later and can
add or replace names. The conditional `grc`, `htop`, `tree` and `ack`
aliases only exist when the listed tool is installed and `TERM` is not
`dumb`. The detailed per-row condition is in `docs/overrides.md`.

**Fix:** understand which of these are wanted, which move to extras, and
which are removed. Add the final table to the manual and keep
`docs/overrides.md` as the detailed reference. This is deliberately a
work-in-progress: the audit is complete, the decisions are not.

### ISS-17 — Python helpers assume a global Python and `pip`

**Files:** `modules/python.sh`, `modules/aliases.sh`,
`modules/bash_functions.sh`, `.coatrc.example`

`switchpython` calls `sudo update-alternatives`; `makevenv` needs a global
`virtualenv` and `$VENV_FOLDER`; `installrequirements` calls the global
`pip`; `server`, `lc`, `uc`, `urldecode` and `urlencode` still use Python 2
syntax. On a modern Debian/Ubuntu, PEP 668 blocks the global install, and
the helper either fails or asks the user to do the wrong thing.

**Task:** `docs/tasks/python-environments.md`. It records the current
state, the options (`venv`, `virtualenv`, `pipx`, `uv`, `poetry`, `pdm`,
`hatch`, `conda`, `pyenv`, system packages, per-user and per-project), the
recommended model, the migration and the acceptance criteria. `virtualenv`
stays as one supported alternative.

### ISS-18 — no core/extras boundary

**Files:** `coat.sh`, every module

Every module is loaded and every module may redefine an ordinary command.
There is no way to ask for the game and the manual without also getting the
`cd` wrapper, `ll`, `grep --color`, the old functions and the Python
helpers.

**Task:** `docs/tasks/core-extras.md`. It develops option B: a core profile
that does not change ordinary commands, an extras profile with the old
toolbox, and a full profile for existing users. It lists the module split,
the `COAT_PROFILE` / `COAT_EXTRAS` settings, the migration, the tests and
the open questions.

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

### FIX-06 — load order was implicit, `TERM` and history were forced

**Files:** `coat.sh`, `modules/variables.sh`, `.coatrc.example`

`coat.sh` now has one explicit `COAT_MODULE_ORDER` array and one load loop.
`TERM` and all history settings moved to `.coatrc.example` (and the live
`.coatrc`), where the user can choose them. `HISTSIZE=-1` and
`HISTFILESIZE=-1` mean no Bash limit; the real limit is memory and disk.
`HISTCONTROL=ignoredups` remains, `ignorespace` is gone, and `HISTIGNORE`
is empty so `ls`, `pwd` and `cd` are collected.

**Pins:** `module_order_is_explicit`, `term_is_not_forced`.

### FIX-07 — XP logging depended on history settings

**File:** `modules/xp.sh`

XP used to read `history 1` and skip the first prompt entry. That coupled
the game to `HISTCONTROL`/`HISTIGNORE` and to the user's history file. It
now uses a `DEBUG` trap to remember the command and a `PROMPT_COMMAND` hook
to log it with the status. History and XP are independent.

**Pin:** `xp_log_ignores_history`.

### FIX-08 — `autocomplete.sh` had a stray shebang

The file starts with a `# shellcheck shell=bash` directive and one plain
comment, so ShellCheck no longer treats a sourced file as a script with a
shebang in the middle.

---

## Not a bug

- `map` is already an alias for `xargs -n1`, which is why the tmux
  window map is called `sessionmap`.
- `.coatrc` sets `COAT_STORAGE` unconditionally on purpose: the paths are
  machine specific and should all derive from `PATH_TO_COAT`. Tests build
  a separate `.coatrc` instead of exporting over it.
- The `cd` listing goes to stderr. It is decoration; keeping it out of
  stdout is what makes `$(...)` safe.
