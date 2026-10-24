# Coat test cases

This is the checklist for checking Coat by hand. The automated part is in
`tests/` and runs through `make test`; everything marked **manual** needs a
terminal, fzf or tmux and is not covered by the suite.

The tests never touch your real `~/.coat/storage`. Every case builds its own
temporary `HOME`, storage, spell files and paczek library, and cleans up
afterwards.

## Legend

| Mark | Meaning |
|------|---------|
| auto | covered by `make test` |
| manual | follow the steps in a normal interactive shell |
| xfail | known bug, kept in the suite as an expected failure |
| — | not automated yet |

## Running

```bash
make test                      # syntax check + all automated cases
make test TEST_FILTER=paczek   # only test names containing "paczek"
make syntax                    # bash -n on every script
make shellcheck                # static analysis, should report nothing
make cases                     # this file
make issues                    # docs/issues.md
```

For manual testing use a scratch folder:

```bash
mkdir -p /tmp/coat-test && cd /tmp/coat-test
```

Optional clean character (back up first):

```bash
cp -a ~/.coat/storage /tmp/coat-storage-backup
rm -f ~/.coat/storage/{xp,xp_count,xp.log,achievements,quests,quest_hud,trail}
```

Remember that in an interactive shell every command earns 1 xp, so a step
that pays 2 xp shows +3 if you count the command itself.

---

## A. Loading the shell

| ID | Test | Steps | Expected | Auto |
|----|------|-------|----------|------|
| A1 | Core is loaded | `type grimoire`, `type mark`, `type quest` | `function` for all | auto (`load_core_functions`) |
| A2 | Aliases exist | `type ll`, `type gs`, `type spot` | `alias` | auto (`load_core_functions`) |
| A3 | The guard is not exported | `bash` then `echo "${COAT_SHELL_LOADED:-unset}"` | `unset` in the child shell | auto (`load_flag_is_not_exported`) |
| A4 | Double source is a no-op | `source ~/.coatrc`, then `grep -o coat_prompt_log <<<"$PROMPT_COMMAND" \| wc -l` | `1` | auto (`double_source_is_a_noop`) |
| A5 | Missing `PATH_TO_COAT` | `env -u PATH_TO_COAT bash --noprofile --norc -c 'source ~/.coat/coat.sh'` | readable error, exit 1 | auto (`missing_path_to_coat`) |
| A6 | `PATH_TO_COAT` is not a folder | `PATH_TO_COAT=/nope bash --noprofile --norc -c 'source ~/.coat/coat.sh'` | readable error, exit 1 | auto (`path_to_coat_must_be_a_folder`) |
| A7 | Scripts do not get bindings | `bash -c 'source ~/.coatrc; bind -X'` | no Coat bindings | manual |
| A8 | `.bashrc` only sources `.coatrc` | `grep -n coatrc ~/.bashrc` | one `source` line | auto (`install_does_not_touch_bashrc` covers the installer) |
| A9 | Indexes are complete | `manual_index \| wc -l`, `coat_index \| wc -l` | `28`, at least 300 | auto (`indexes_are_complete`) |
| A10 | Grimoire comments are close | `coat_index \| awk -F'\t' '$1=="mark"{print $4}'` | the `mark the folder…` comment | auto (`grimoire_comment`) |
| A11 | Load order is explicit | `printf '%s\n' "${COAT_MODULE_ORDER[@]}"` | `prompt` is last | auto (`module_order_is_explicit`) |
| A12 | `TERM` is not forced | `TERM=xterm-256color`, source `.coatrc`, print `$TERM` | `xterm-256color` | auto (`term_is_not_forced`) |
| A13 | XP does not use history | set `HISTIGNORE='*'`, log a pending command | the command is in `xp.log` | auto (`xp_log_ignores_history`) |

## B. `install.sh` (throwaway home)

All of these run against a copy under `/tmp`, never the real home. The
matching automated cases create the copy themselves.

| ID | Test | Steps | Expected | Auto |
|----|------|-------|----------|------|
| B1 | Normal install | run `install.sh` with a test `.coatrc` | exit 0; `~/.coat` → copy; runtime files; `~/temp/current_dir`; `~/.env` | auto (`install_creates_everything`) |
| B2 | Runtime is preserved | write `42` to `storage/xp`, run again | still `42` | auto (`install_preserves_runtime`) |
| B3 | `.bashrc` is untouched | write a marker into the test `.bashrc`, run | unchanged | auto (`install_does_not_touch_bashrc`) |
| B4 | Missing `.coatrc` | rename it, run | exit 1, clear message | auto (`install_needs_coatrc`) |
| B5 | Foreign `~/.coat` | `ln -s /tmp ~/.coat`, run | exit 1, says where it points | auto (`install_refuses_foreign_link`) |
| B6 | Missing `COAT_STORAGE` | remove it from the test `.coatrc`, run | exit 1, clear message | auto (`install_needs_storage`) |
| B7 | Re-run | run twice | idempotent, no duplicate link | auto (`install_preserves_runtime`) |
| B8 | Submodule update | check the git call | `git submodule update` attempted | auto (git stubbed in the installer case) |

## C. Moving around

| ID | Test | Steps | Expected | Auto |
|----|------|-------|----------|------|
| C1 | `cd` state | `cd /tmp`; `cat ~/temp/current_dir`; `tail -1 ~/.coat/storage/trail` | `/tmp`; line ends `cd<TAB>/tmp`; listing on stderr | auto (`cd_updates_state`) |
| C2 | No duplicate trail | `cd /tmp` twice; `wc -l < ~/.coat/storage/trail` | one new line | auto (`trail_deduplicates`) |
| C3 | `mark` / `spot` | `cd /tmp/coat-test; mark; spot` | spot prints the folder; `storage/spot` written; trail gets `mark`; +2 xp; Camper | auto (`mark_and_spot`) |
| C4 | `goto` | `mark`, `cd /`, `goto` | back in the marked folder | auto (`goto`) |
| C5 | `cdo` | `cd one; cd two; cdo` | in `one` | auto (`cdo`) |
| C6 | Bookmarks | `bookmarkfolder`, `cd /`, `cdg` | pick returns to the folder | auto (`bookmarks`) |
| C7 | `trail` | open ALT+l, pick an entry | newest first, one row per folder, jumps there | manual |
| C8 | Missing trail folder | delete a listed folder, pick it | clear “is gone”, no cd | manual |
| C9 | `z` | `z part-of-name` | needs `fasd` (not installed) | manual |
| C10 | `cd ...` | from `a/b`, `cd ...` | one listing | xfail (`cd_dots_double_listing`, ISS-03) |
| C11 | Folder with a space | `cd "a b"; mark; goto` | returns to `a b` | xfail (`goto_folder_with_space`, ISS-02) |
| C12 | Stack helpers | `pushd`, `popd`, `d`, `1`…`9` | moves through the stack | manual |

## D. Spells and paczki

| ID | Test | Steps | Expected | Auto |
|----|------|-------|----------|------|
| D1 | Copy one file | in a scratch folder, `paczek`, pick `python/hello.py` | file copied; +3 xp; Looter | auto (`paczek_copies_pick`) |
| D2 | No trail side effect | `wc -l trail` before/after `paczek` | unchanged | auto (`paczek_leaves_trail_alone`) |
| D3 | Existing file, no tty | pre-create the target file, run `paczek` | `skipped`, old content kept | auto (`paczek_skips_existing_without_tty`) |
| D4 | Existing file, answer `n`/`y` | run `paczek`, answer at the prompt | `n` skips, `y` replaces | manual |
| D5 | Prefix | `paczek python` | only the `python/` section | auto (`paczek_prefix`) |
| D6 | Missing library | `PACZEK_FILLINGS=/nope paczek` | clear error, exit 1 | auto (`paczek_missing_library`) |
| D7 | Loot detection | `pyproject.toml`, `package.json`, `Dockerfile`, `*.tf`, `Makefile`, `.git` | python / js / docker / terraform / makefiles / git | auto (`loot_detection`) |
| D8 | Template | pick a `.tpl`, answer the variables | asks each `{{ var }}`, writes without `.tpl` | manual (needs a tty) |
| D9 | Multi-select | pick several files with Tab | all copied | manual |
| D10 | Spellcast | `spellcast`, pick a spell | command runs in this pane | manual |
| D11 | Spell insert | ALT+i, pick a spell | text appears in the prompt, not run | manual |
| D12 | Spell save | `spellsave`, pick a history line | appended to `$MAGI_BOOK` | manual |

## E. Quests, XP, achievements

| ID | Test | Steps | Expected | Auto |
|----|------|-------|----------|------|
| E1 | Activate a quest | add two, `quest list`, pick the second | it becomes `active`, the first goes back to `open` | auto (`quest_activate`) |
| E2 | Finish a quest | `quest done 1` | 25 xp, Quest Taker, HUD clears the quest | auto (`quest_done`) |
| E3 | Bad id | `quest done 99` | exit 1, `no quest 99` | auto (`quest_missing_id`) |
| E4 | Level boundary | `echo 99 > storage/xp`, run a command | 100 xp, Lv 2, bar `0/100` | auto (`xp_levels`) |
| E5 | Character sheet | `character` | level, bar, command count, quests, achievements, folder, branch | auto (`character_sheet`) |
| E6 | Achievement list | `achievements` | 8 entries, earned ones marked | auto (`achievements_list`) |
| E7 | HUD truncation | activate a 50-character quest | HUD keeps the first 40 characters | auto (`hud_truncates_long_quest`) |
| E8 | XP rates | measure before/after: normal, `git commit`, `pytest`, `mark`, `paczek`, `quest done` | +1, +11, +6, +3, +4, +26 (including the command itself) | manual |
| E9 | History is not double counted | open a new shell and press Enter | no new `xp.log` line for old history | manual |
| E10 | 100/1000 commands | set `xp_count` to 99/999, run one command | Centurion / Veteran | manual |

## F. Dungeons and the tmux HUD

| ID | Test | Steps | Expected | Auto |
|----|------|-------|----------|------|
| F1 | Missing layout folder | `dungeon` | clear message about `TMUXP_CONFIGDIR` | manual |
| F2 | Empty folder | create `$TMUXP_CONFIGDIR`, run | “no layouts”, suggests `save_the_workshop` | manual |
| F3 | Enter a dungeon | put a yaml there, run `dungeon` | preview, tmuxp loads it, +5 xp, Dungeoneer | manual |
| F4 | Save a workshop | inside tmux, `save_the_workshop` | yaml written under `$TMUXP_CONFIGDIR` | manual |
| F5 | Session map | inside/outside tmux | lists windows / clear error | manual |
| F6 | HUD | `cat ~/.coat/storage/quest_hud`; look at tmux status | `LvN` and `⚔ quest` | manual (the unit writes it; rendering is tmux) |

## G. Grimoire and manual

| ID | Test | Steps | Expected | Auto |
|----|------|-------|----------|------|
| G1 | Manual path | `manual --path` | `…/docs/manual.md` | auto (`manual_path`) |
| G2 | Whole manual | `manual --all` | starts with `# Coat manual` | auto (`manual_all`) |
| G3 | Pick a section | `manual`, type `Quests` | preview and the Quests section | auto (`manual_section`) |
| G4 | Missing manual | `MANUAL_FILE=/nope manual` | exit 1, `is missing` | auto (`manual_missing_file`) |
| G5 | Grimoire pick | `grimoire`, pick `mark` | `mark` typed into the prompt | auto (`grimoire_pick`) |
| G6 | ALT+h / ALT+m | press them in a terminal | same as `grimoire` / `manual` | manual |

## H. Aliases, git, python, utilities (sample)

| ID | Test | Steps | Expected | Auto |
|----|------|-------|----------|------|
| H1 | Listing aliases | `ll`, `la`, `lsd`, `tree`, `ff`, `fs`, `duh` | normal listings | manual |
| H2 | Archives | `extract file.zip`, `targz folder` | unpack / create archive | manual |
| H3 | Git flow | temp repo: `gss`, `gitlogs`, `setcurrentbranch`, `newwork`, `mergeworking`, `removeworking` | branch dance works | manual |
| H4 | Git pickers | `fbr`, `fco`, `choose_branch` | fzf lists branches and switches | manual |
| H5 | Python | `makevenv`, `makeactive`, `makeactiver` | venv created/activated, returns to the start folder | manual |
| H6 | Notes | `note "t" "b"`, `note_show`, `dirtynotes` | note appended/shown | manual |
| H7 | Small utilities | `calc 3+3`, `passwdgen 8`, `json`, `box`, `whenis "next friday"` | sensible output | manual |
| H8 | Clipboard | `echo hi \| clip-in; clip-out` | xclip round trip | manual |
| H9 | Completion | drop a file into `~/.config/bash-completion` and open a shell | completion available | manual |

## I. Robustness and known issues

| ID | Test | Steps | Expected | Auto |
|----|------|-------|----------|------|
| I1 | Syntax | `make syntax` | all scripts parse | auto |
| I2 | Static analysis | `make shellcheck` | no findings | auto |
| I3 | `command_exists` | `command_exists ls; echo $?` / `command_exists nope; echo $?` | 0 / 1 | auto (`command_exists`) |
| I4 | Missing runtime file | delete `storage/trail`, open a shell | recreated, other files kept | auto (source of `organization.sh`) |
| I5 | Real install | run `install.sh` on the real account | link and runtime files only, no `.bashrc` edit | manual |

## Not automated, by design

- real key presses (ALT+g/h/i/l/m/n/q/s/t/w)
- fzf's interface, previews and multi-select
- `tmux send-keys`, tmux status rendering
- templates that read answers from `/dev/tty`
- ssh, sudo, `switchpython`, a real browser
- installation on a fresh machine
