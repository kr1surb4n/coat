Coat
====

Coat is a small overlay over bash: aliases, functions and fzf menus that
make the shell feel more like a game and less like a chore.

It loads from `~/.coatrc`, keeps everything it remembers in plain text
under `~/.coat/storage`, and never edits your `.bashrc` behind your back.

Coat is currently one profile: everything is loaded.  The overrides are
**not being split now**; `cd` and `grep` are explicitly kept.  A future
**core + extras** option is described in `docs/tasks/core-extras.md`, but
it is not current work.  Until then, read `docs/overrides.md` to see which
basic commands Coat redefines.

The complete manual is [docs/manual.md](docs/manual.md).  Once Coat is
loaded, run `manual` or press `ALT + m`.

What you get
============

**Find things**

- `grimoire` (`ALT + h`) -- every function and alias, with the source in
  the preview and how often you used it. Enter types the name.
- `manual` (`ALT + m`) -- this project's manual, section by section.
- `history_top_used`, `lman`, `fman` -- your habits, the last man page,
  any man page.

**Places**

- `mark`, `spot`, `goto` -- the "where I stopped working" save point.
- `trail` (`ALT + l`) -- every folder you visited or marked, newest first.
- `bookmarkfolder`, `cdg` (`ALT + g`) -- a folder bookmark list with fzf.
- `cd` prints the folder after moving and records the visit; `cdo`, `..`,
  `...`, `mkd` work the way you expect.

**Spells**

- A spell is one line: `echo "description"; the command`.
- `ALT + s` casts a spell in the current tmux pane, `ALT + i` types it into
  the prompt so you can edit it first, `spellsave` saves a history line as
  a new spell.

**Templates**

- `paczek` (`ALT + n`) -- copy ready files from the paczki library into the
  current folder; `.tpl` files ask for their `{{ variables }}` first.
- `loot` -- the same, limited to the kind of project you are standing in.

**Work**

- `quest add`, `quest list` (`ALT + q`), `quest done`, `quest log` -- what
  you are doing right now.
- `character` -- level, experience bar, top spells, folder, branch, quest.
- `achievements` -- eight badges, from Apprentice to Veteran.
- The tmux status line shows your level and the active quest.

**Sessions**

- `dungeon` -- enter a saved tmuxp layout with a preview.
- `save_the_workshop` -- save the current session as a layout.
- `sessionmap` -- list the windows of the current session.

**The usual**

- git aliases and helpers (`gs`, `gc`, `gp`, `fbr`, `fco`, the `working`
  branch flow).
- python virtualenv helpers (`makevenv`, `makeactive`, `makeactiver`).
- notes (`dirtynotes`, `note`), clipboard, archive helpers, network and
  system tools.
- 100+ functions and 200+ aliases in total; `grimoire` lists all of them.

The manual has a section for every feature, with examples.

Keys
====

These work in an interactive bash shell, not inside scripts.

| Key     | What it does |
|---------|--------------|
| ALT + g | folder bookmarks |
| ALT + h | grimoire: every function and alias |
| ALT + i | type a spell into the prompt |
| ALT + l | trail: folders you have visited |
| ALT + m | the manual |
| ALT + n | take a paczek template |
| ALT + q | pick the active quest |
| ALT + s | cast a spell in the current tmux pane |
| ALT + t | ssh to a host from your teleports |
| ALT + w | spellforge, unfinished |

Installation
============

Requirements: Debian or Ubuntu, bash 4.2 or newer, git, fzf.
Optional but expected: tmux (the `ALT + s`, `ALT + i` and `ALT + t` keys),
tmuxp (dungeons), direnv, xclip (clipboard), python3 + virtualenv, fasd
(`z`).

1. Copy `.coatrc.example` to `~/.coatrc` and edit the paths.
2. Run `bash install.sh` from this folder.
3. Add `source ~/.coatrc` at the end of your `~/.bashrc`.
4. Open a new shell.

`install.sh` links this folder as `~/.coat`, stops if `~/.coatrc` is
missing, pulls the submodules, creates the runtime files in
`$COAT_STORAGE`, creates `~/temp/current_dir` and an empty `~/.env`.  It
keeps existing data and never truncates a bookmark, a mark or a quest.

To update, `git pull` and run `install.sh` again.  Open a new shell after
changing a module: the load guard ignores a second `source ~/.coatrc` in
the same shell on purpose.

Layout
======

```
coat.sh              loads the modules, in the explicit COAT_MODULE_ORDER
install.sh           links ~/.coat and creates the runtime files
.coatrc.example      template for the machine specific config
modules/
  variables.sh       environment basics (paths, pager, colours)
  aliases.sh         the plain aliases
  bash_functions.sh  the plain functions
  organization.sh    marks, bookmarks, the trail
  simplifications.sh clipboard helpers
  git.sh             git aliases and helpers
  python.sh          virtualenv helpers
  xp.sh              command log, levels, achievements, the hud
  quest.sh           the quest log
  dungeon.sh         tmuxp layouts as dungeons
  spells.sh          spellbook, paczki, ssh, loot
  grimoire.sh        the searchable list of functions and aliases
  manual.sh          the manual window
  shortcuts.sh       every key binding
  autocomplete.sh    loads the completion files
  prompt.sh          the prompt
docs/manual.md       the long form manual
docs/alias-audit.md  duplicate aliases and synonym groups
docs/overrides.md    every ordinary command Coat changes
docs/issues.md       the issue list
docs/tasks/          larger work for the next session
lib/                 submodules: foxer, paczki
storage/             runtime data, all plain text, all git ignored
```

Load order
==========

`coat.sh` has one explicit `COAT_MODULE_ORDER`:

```
variables -> aliases -> bash_functions -> organization -> simplifications ->
git -> python -> xp -> quest -> dungeon -> spells -> grimoire -> manual ->
shortcuts -> autocomplete -> prompt
```

A later module wins.  Inside one file, the last definition wins.  `prompt`
is always last.  The command log is enabled after every module is loaded,
so loading does not count as a command.  The duplicate and synonym audit
is in [docs/alias-audit.md](docs/alias-audit.md).

Where your data lives
=====================

`~/.coat/storage`, unless `COAT_STORAGE` says otherwise:

| File | What it holds |
|------|---------------|
| `spot`, `bookmarks`, `trail` | where you have been |
| `teleports` | ssh destinations |
| `quests`, `quest_hud` | the quest log and the status line |
| `xp`, `xp_count`, `xp.log`, `achievements` | the game |
| `dirty_notes`, `cookies`, `status` | notes and scratch data |

Delete `xp`, `xp_count`, `xp.log`, `achievements` and `quests` to start a
new character.  Delete `trail` to forget where you have been.  Nothing
else depends on them.

Customising
===========

- A new function or alias: add it to a module, or make a new module and
  add it to `COAT_MODULE_ORDER` in `coat.sh`; `prompt` stays last.
- A new key: one `bind -x` line in `modules/shortcuts.sh`.
- A new spell: edit a file listed in `MAGIC_BOOKS`, or save a history line
  with `spellsave`.
- A new template: drop a file into `lib/paczki/<section>/`.
- A new dungeon: `save_the_workshop`.

Reading order
=============

- `.coatrc.example`
- `coat.sh`
- `install.sh`
- `modules/variables.sh`
- `modules/organization.sh`
- `modules/xp.sh`, `modules/quest.sh`, `modules/dungeon.sh`
- `modules/spells.sh`
- `modules/grimoire.sh`, `modules/manual.sh`
- `modules/shortcuts.sh`
- `modules/prompt.sh`

Known limits
============

- Ordinary commands change meaning: `cd`, `ls`, `grep`, `mkdir`, `man`,
  `vi`, `top`, `tmux` and others.  See `docs/overrides.md`; use
  `command`, `builtin` or an absolute path to bypass them.
- The Python helpers still assume a global `python`/`pip` and one
  `$VENV_FOLDER`.  The agreed target is the new interface in
  `docs/tasks/python-environments.md`; the old names will become wrappers,
  not get more aliases.
- `ALT + w` (spellforge) is unfinished; edit the spell files directly.
- `z` needs `fasd`, which is not installed by default.
- `dungeon` needs `TMUXP_CONFIGDIR` with at least one yaml layout; the
  path in `.coatrc.example` may not exist on a fresh machine.
- Key bindings only exist in interactive shells.
- `ALT + s`, `ALT + i` and `ALT + t` only work inside tmux.

Credits
=======

Influenced by [mathiasbynens/dotfiles](https://github.com/mathiasbynens/dotfiles)
and [Bash-it](https://github.com/Bash-it/bash-it), and by many snippets
collected over the years.

MIT licensed, see [LICENSE](LICENSE).
