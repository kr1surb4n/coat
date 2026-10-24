# Coat manual

Coat is a layer of aliases, functions and small helpers that sits on top
of bash.  It is loaded by `~/.coatrc` and it is meant to make the shell
feel like a game you enjoy, not like a tool you fight.

This manual uses plain language.  Every section is short and has examples.

## Reading this manual

- `manual` opens the table of contents in fzf.  Pick a section and it opens
  in the pager (`q` closes it).
- `manual quest` opens the same list with "quest" already typed, so you only
  see the matching sections.
- `manual --all` opens the whole manual.
- `manual --path` prints where the manual file is, so you can open it in
  your editor.
- `ALT + m` does the same as `manual` while you are working.

The manual is `docs/manual.md` in the Coat folder.  Edit it like any text
file; the list of sections is built from the `##` headings, so a new
heading shows up on the next `manual`.

## Finding a command

Two tools answer "what was that thing called?":

`grimoire` (`ALT + h`) lists every function and alias Coat defines.

```
name        uses  kind   module      description
paczek      12    func   spells.sh   pick a filling from the paczki library...
ll          40    alias  aliases.sh  displays files and directories in detail
```

- Type to filter, the right pane shows the real definition.
- Enter types the name into your prompt, ready for arguments.
- The `uses` column comes from your own history, so your habits show up.

`manual` (`ALT + m`) does the same for this text.

If you only remember a word, `history_top_used` shows the commands you use
most, and `lman` opens the man page of the last command you ran.

## Keys

These work in an interactive bash shell.  They do not work inside scripts.

| Key     | What it does                                      |
|---------|---------------------------------------------------|
| ALT + g | Folder bookmarks (`cdg`)                          |
| ALT + h | Grimoire: every function and alias (`grimoire`)   |
| ALT + i | Type a spell into the prompt (`insert_line_with_fzf`) |
| ALT + l | Trail: folders you have visited (`trail`)         |
| ALT + m | This manual (`manual`)                            |
| ALT + n | Take a paczek template (`paczek`)                 |
| ALT + q | Pick the active quest (`quest list`)              |
| ALT + s | Cast a spell in the current tmux pane (`eval_line_with_fzf`) |
| ALT + t | SSH to a host from your teleports (`connect_with_ssh`) |
| ALT + w | Spellforge, unfinished, do not rely on it         |

`ALT + s`, `ALT + i` and `ALT + t` use `tmux send-keys`, so they need tmux.
The rest work in any terminal.

Every binding is one line in `modules/shortcuts.sh`.  Change the key there
and open a new shell.

## Where things live

Coat reads paths from `~/.coatrc`.  The important ones:

| Variable                 | Usual value                     | What it is |
|--------------------------|---------------------------------|------------|
| `PATH_TO_COAT`           | `~/.coat`                       | the Coat folder |
| `COAT_STORAGE`           | `~/.coat/storage`               | all runtime data |
| `SPOT_FILE`              | `storage/spot`                  | the folder saved by `mark` |
| `FOLDER_BOOKMARK_FILE`   | `storage/bookmarks`             | the bookmark list |
| `TELEPORTS`              | `storage/teleports`             | ssh destinations |
| `MAGIC_BOOKS`            | several files under `~/.dotfiles/spells` | your spell files |
| `PACZEK_FILLINGS`        | `~/.coat/lib/paczki`            | the template library |
| `TMUXP_CONFIGDIR`        | `~/.dotfiles/tmux`              | saved dungeon layouts |

All runtime files are plain text.  You can read them, edit them, or delete
them.  See "Where your data lives" for the full list.

## Moving around

`cd` is replaced by a small function.  It does what you expect, and then:

- prints the contents of the new folder,
- writes the folder to `~/temp/current_dir`,
- adds a line to the trail.

```
cd /etc        # change folder, then list it
cdo            # go back to the previous folder
..             # one folder up
...            # two folders up
-              # the folder you came from
mkd new/place  # create the folder and enter it
```

Handy aliases next to `cd`: `mkdir` creates parents, `pu` and `po` push and
pop folders, `d` lists the folder stack, and `1` to `9` jump to an entry of
that stack (the stack needs `pushd` first).

### Marks: where you stopped working

```
mark            # remember this folder
spot            # print the remembered folder
goto            # go back to it
```

`mark` also adds a line to the trail and earns 2 xp.  This is the "save
point" of the shell: mark the folder before you leave, `goto` when you
come back.

### Bookmarks

```
bookmarkfolder  # add the current folder to the list
cdg             # pick one with fzf and go there (ALT + g)
```

`bookmarkfolder` only adds; it never removes.  Edit `storage/bookmarks`
with any editor to clean the list.

### The trail

Every `cd` and every `mark` is written to `storage/trail`:

```
2026-10-23 04:19   cd     /usr
2026-10-23 04:19   mark   /etc
```

`trail` (`ALT + l`) shows the folders newest first, one line per folder.
Enter takes you back to the chosen one.  If a folder no longer exists,
`trail` says so instead of moving.

### Jumping by name

`z <part of a name>` jumps to a folder you visited before.  It needs
`fasd`, which is not installed on this machine right now, so it will not
work until you install it.

## Looking at files

```
l       # long list
ll      # long list, folders first
la      # all files, including hidden
lr      # newest last
lt      # the ten files changed most recently
lsd     # only folders
l.      # hidden files only
tree    # tree view (tre pipes it through less)
ff name # find files by part of the name
fs path # size of a file or folder
duh     # disk usage, sorted, human readable
fstr -i word   # find a word inside files
sgrep word     # recursive grep with context
```

`extract file.zip` unpacks almost any archive.  `targz folder` makes a
`.tar.gz`.  `gz file.html` gzips a copy.

## Spells

A spell is one line of text that you can run.  Spell files live in
`~/.dotfiles/spells` and are listed in `MAGIC_BOOKS`.  A line looks like:

```
echo "show the open ports"; ss -tulpn
```

The part between quotes is the description, the rest is the command.

```
ALT + s        # pick a spell with fzf and run it in this pane
spellcast      # the same without the key
ALT + i        # pick a spell and type it into the prompt, without running it
spellsave      # pick a line from your history and append it to MAGI_BOOK
```

`ALT + i` is the safe one: you get the command in the prompt, you edit it,
you press Enter yourself.  `ALT + w` (spellforge) is not finished; edit the
spell files directly for now.

`eval_line_with_fzf`, `insert_line_with_fzf` and `type_line_with_fzf` are
the functions behind the keys.  `type_line_with_fzf` uses `xdotool` and is
the alternative for terminals where tmux is not available.

## SSH and teleports

`storage/teleports` holds one ssh command per line, for example:

```
ssh user@server.example
```

```
teleports      # pick a line with fzf and run it
ALT + t        # the same from a key
```

`connect_with_ssh` is the function behind them.  It `exec`s the chosen
line, so the shell is replaced by ssh (exit the connection and you are
gone from that pane).

Related helpers:

- `logssh` opens an ssh session and keeps a log file.
- `makecookie` runs a line from `storage/cookies`; use it for login
  commands you do not want in your history.
- `ansible_command` picks a playbook from `~/docs/systems/playbooks` and
  runs it with `--ask-become-pass`.

## Paczki: templates you drop into a folder

`lib/paczki` is a library of ready files: `.gitignore`, `Dockerfile`,
`Makefile`, configs, scripts, and so on, grouped in folders.

```
paczek          # pick one or more files and copy them into this folder (ALT + n)
paczekfiller    # the same thing under the name used in the paczki README
loot            # pick only the files that fit this kind of project
```

`paczek` lets you select several files with Tab before Enter.  A file
ending in `.tpl` is a template: Coat asks for every `{{ variable }}` in it
and writes the filled copy into the current folder.

If a file with the same name is already in the folder, `paczek` asks
before overwriting it.  Answer `n` and that file is skipped.  Without a
terminal it skips the file instead of guessing.

`loot` looks at the current folder and chooses a section of the library:
Python, JS, Docker, Terraform, Makefiles, or Git.  If it does not
recognise the project it shows the whole library.

To add your own template, drop a file into `lib/paczki/<section>/`.
Nothing else is needed.

## Quests

A quest is one thing you want to get done.  The active quest follows you
around: it shows in the tmux status line and in `character`.

```
quest add "fix the installer"   # add a quest
quest list                      # pick the active quest (ALT + q)
quest                           # show the active quest
quest done                      # pick a quest and finish it
quest done 3                    # finish quest number 3
quest log                       # finished quests, newest first
```

Rules:

- only one quest is active at a time; starting another sets the old one
  back to `open`,
- finishing a quest gives 25 xp and the "Quest Taker" badge,
- the file `storage/quests` is a tab separated text file, so you can fix a
  typo with any editor.

The tmux status line shows the level and the active quest, for example:

```
Lv3 ⚔ fix the installer   14:20 23-Oct-26
```

## Experience and levels

Every command you run is written to `storage/xp.log` and earns experience.
The log is a work diary: when, how the command ended, where you were, and
what you ran.

What a command pays:

| Action                | XP |
|-----------------------|----|
| any command           | 1  |
| `git commit`, `git push` | 10 |
| a test run (`pytest`, `make test`, `npm test`, ...) | 5 |
| `mark`                | 2  |
| `paczek`              | 3  |
| `dungeon`             | 5  |
| `quest done`          | 25 |

100 xp is one level.  `character` shows where you are:

```
Lv 1   [#######.............] 36/100 xp
Commands: 9   Quests done: 1   Achievements: 4/8
Folder: /usr  (branch main)
Quest: check the game layer
Room: work
Top spells: quest(4) cd(2) mark(1) echo(1)
```

`achievements` lists all badges, earned or not:

| Badge        | How to earn it |
|--------------|----------------|
| Apprentice   | run your first command |
| Centurion    | run 100 commands |
| Veteran      | run 1000 commands |
| Night Owl    | work between midnight and five |
| Quest Taker  | finish a quest |
| Dungeoneer   | enter a dungeon |
| Looter       | take a paczek |
| Camper       | mark a spot |

The logging is done by a `DEBUG` trap that remembers the command and a
`PROMPT_COMMAND` hook that writes it after the command finishes.  It does
not read `history`, so `HISTCONTROL`, `HISTIGNORE` and the history file do
not change what is counted.  Loading modules is not counted.

## Dungeons

A dungeon is a tmuxp layout: a session with windows and panes, saved as a
yaml file.  Entering it puts you back in the same rooms as last time.

```
dungeon              # pick a saved layout with a preview and load it
save_the_workshop    # save the current tmux session under a name
sessionmap           # show the windows of the current session
```

`dungeon` reads `$TMUXP_CONFIGDIR`.  On this machine that path points to
`~/.dotfiles/tmux`, and the folder does not exist yet, so `dungeon` will
tell you to save a workshop first.  Create the folder, or point
`TMUXP_CONFIGDIR` somewhere else in `~/.coatrc`.

`sessionmap` is named that way because `map` is already an alias for
`xargs -n1`.

## Git

The most used aliases:

```
gs      git status          gss    git status --short
gd      git diff            gds    git diff --staged
gc      git commit -v       gcm    git commit -v -m
gp      git push            gl     git pull
gup     fetch and rebase    gf     fetch and prune
gcl     git clone           gsu    update submodules
```

`gitlogs` and `shortlogs` are one-line history views.  `choose_commit`,
`choose_branch` and `choose_remote` pick an item with fzf and print it.

Branch work has its own flow:

```
setcurrentbranch   # remember the branch you are on
newwork            # remember it, delete "working", create a fresh "working"
squashcurrent      # interactive rebase from a commit you pick
mergeworking       # go back to the remembered branch and rebase "working" onto it
removeworking      # delete the "working" branch
```

`fbr` checks out a recent branch with fzf.  `fco` checks out a branch or a
tag with fzf.  `branch` prints the current branch name.

## Python

> **Work in progress.** This section documents the old helpers so they are
> not a surprise.  They are being redesigned in
> `docs/tasks/python-environments.md`; the new interface will prefer a
> project `.venv`, keep `virtualenv` as one alternative, use `pipx` or
> `uv tool` for command-line tools, and never silently install into the
> system Python.

```
switchpython          # choose the global python (update-alternatives, sudo)
makevenv              # virtualenv $VENV_FOLDER
makeactive            # source $VENV_FOLDER/bin/activate
makeactiver           # mark, walk up to .venv, activate, go back
installrequirements   # pip install -r requirements.txt (global pip)
black                 # black -Sq
```

The current helpers assume one `$VENV_FOLDER` (or a `.venv` somewhere up
the tree) and a global `pip`.  On Debian/Ubuntu with PEP 668, a global
`pip install` is refused; use a project virtualenv.  `makeactiver` also
moves you with `mark`/`goto`, so it has side effects.  The task document
lists the alternatives (`venv`, `virtualenv`, `pipx`, `uv`, `poetry`,
`pdm`, `hatch`, `conda`, `pyenv`) and the migration plan.

## Notes

```
dirtynotes        # pick lines from your history and save them as notes
cleardirtynotes   # empty the notes file
note "title" "body"   # append a note to ~/notes.txt
echo "body" | note "title"   # the same, body from stdin
note_show             # print ~/notes.txt
```

`dirtynotes` saves the commands, not just the ideas, so a note can be run
later.

## Files, processes, network

```
fman              # search man pages with fzf
fkill             # pick a process and kill it (fkill 15 for TERM)
psgrep word       # grep the process list
server            # serve the current folder over http (still Python 2)
ips               # local addresses
digga example.org # dns lookup
t file pattern    # follow the last 50 lines of a file, marking the pattern
```

Network and security helpers: `sniff`, `httpdump`, `iptablesBlockIP`,
`netstat_used_local_ports`, `netstat_free_local_port`,
`netstat_connection_overview`, `testConnection`, `getcertnames`,
`shellShockCheck`.

`linkdocs` symlinks files from `~/docs` into the current folder.
`edocs` opens one of them in Emacs, `emacs-read` opens a file in the
running Emacs and returns at once.

## Clipboard

```
clip-in     # copy stdin to the clipboard
clip-out    # print the clipboard
wez         # same as clip-in
pusc        # same as clip-out
kopjuj      # same as clip-in
wklej       # same as clip-out
```

## Small utilities

```
calc 3+3              # quick arithmetic
passwdgen 8            # random password
rand_int 8             # random number
json '{"a":1}'         # pretty print json
box 'text'             # draw a box around text
dataurl file           # turn a file into a data URL
unidecode '\x{41}'     # decode unicode escapes
codepoint a            # unicode code point of a character
whenis "next friday"   # date arithmetic
stripspace file        # remove trailing whitespace
history_top_used       # your most used commands
```

System helpers: `battery_life`, `battery_indicator`, `cpuinfo`,
`mount_info`, `print_all_colors`, `cleanTheSystem`.

`o path` opens a path with the `open` command.  That command is normal on
macOS; on Linux you probably want `xdg-open`, and `o` may fail.

## Completion

Coat sources every file in `$BASH_COMPLETION_USER_DIR` (normally
`~/.config/bash-completion`).  To add completion for a program, drop its
completion file there.  Too many files can slow the shell down; keep only
the ones you need.

## Installing and updating

`install.sh` does one job: make this folder usable.

1. It goes to its own folder.
2. It stops if `~/.coatrc` is missing.
3. It links this folder as `~/.coat` (and refuses if `~/.coat` points
   somewhere else).
4. It sources `~/.coatrc` to learn your paths.
5. It pulls the submodules.
6. It creates the runtime files in `$COAT_STORAGE`, `~/temp/current_dir`
   and an empty `~/.env`.

It never edits `.bashrc`.  Add this line to your `.bashrc` yourself:

```
source ~/.coatrc
```

To update: `git pull`, then run `install.sh` again.  The runtime files are
kept, never truncated.

## Customising

- **A new alias or function**: put it in a module, or in
  `modules/aliases.sh` / `modules/bash_functions.sh`.  A new file needs an
  entry in `COAT_MODULE_ORDER` in `coat.sh`; `prompt` stays last.
- **A new key**: add a `bind -x` line in `modules/shortcuts.sh`.
- **A new spell**: edit a spell file listed in `MAGIC_BOOKS`, or pick a
  history line with `spellsave`.
- **A new template**: drop a file into `lib/paczki/<section>/`.
- **A new dungeon**: save it with `save_the_workshop`.

After changing a module, open a new shell.  The load guard makes a second
`source ~/.coatrc` in the same shell do nothing on purpose.

## Where your data lives

All of this is under `$COAT_STORAGE` (`~/.coat/storage`) unless noted.

| File            | What it holds |
|-----------------|---------------|
| `spot`          | the folder saved by `mark` |
| `bookmarks`     | folder bookmarks |
| `teleports`     | ssh destinations |
| `trail`         | every folder visit and mark |
| `quests`        | the quest log |
| `quest_hud`     | the one line tmux shows |
| `xp`            | total experience |
| `xp_count`      | number of commands run |
| `xp.log`        | one line per command |
| `achievements`  | badges and when you earned them |
| `dirty_notes`   | notes saved by `dirtynotes` |
| `cookies`       | login commands for `makecookie` |
| `status`        | free scratch file |
| `marks/`        | file markers from file manager scripts |

To start a new character, delete `xp`, `xp_count`, `xp.log`,
`achievements` and `quests`.  To forget where you have been, delete
`trail`.  Nothing else depends on them.

## Load order

`coat.sh` loads one explicit list, `COAT_MODULE_ORDER`:

```
variables -> aliases -> bash_functions -> organization -> simplifications ->
git -> python -> xp -> quest -> dungeon -> spells -> grimoire -> manual ->
shortcuts -> autocomplete -> prompt
```

A later module wins over an earlier one.  Inside one file, the last
definition wins.  `prompt` is always last.  The command log starts after
every module is loaded, so loading does not earn XP.

This order is also why some aliases do not mean what their first
definition says.  The detailed list is in `docs/alias-audit.md`.

## Commands Coat changes

These are ordinary commands with a new meaning.  The full table, with the
file, the line, the condition and the difference, is in
`docs/overrides.md`.  This is a work in progress: the audit is complete,
but the decision to keep, remove or move each one is still open.

| Command | What Coat does |
|---------|----------------|
| `cd` | a function that saves the folder, writes the trail and prints a listing |
| `man` | adds colour variables to the pager |
| `sudo` | enables alias expansion after `sudo` |
| `chown`, `chmod`, `chgrp` | adds `--preserve-root` |
| `dmesg` | adds `-T` |
| `grep`, `egrep`, `fgrep` | adds `--color`; the later `grep` alias drops `GREP_OPTIONS` |
| `ls`, `dir`, `vdir` | uses `ls -F --color` (and `ls` formats) |
| `mkdir` | adds `-p` |
| `du`, `df` | human sizes; `df` also adds the filesystem type |
| `vi` | uses `nvim` when `vim` is installed |
| `tmux` | adds `-u` |
| `black` | adds `-Sq` |
| `top` | uses `htop` when installed; `top_orig` keeps the old one |
| `tree` | `tree -Csu`, or a `find` fallback |
| `ack` | `ack-grep` when installed |
| `as`, `configure`, `diff`, `dig`, `g++`, `gas`, `gcc`, `head`, `ifconfig`, `ld`, `make`, `mount`, `netstat`, `ping`, `ps`, `tail`, `traceroute`, `syslog` | `grc` colour wrappers, only when `grc` exists and `TERM` is not `dumb` |
| `runserver`, `server`, `json`, `lc`, `uc`, `urldecode`, `urlencode` | Python helpers; several are still Python 2 |

Use `command ls`, `\ls`, `builtin cd` or `/bin/ls` to get the original
behaviour.  The difference between an alias and a function matters:
`\ls` skips an alias, `command ls` skips both, and `builtin cd` skips the
`cd` function.

## Terminal and history

Coat no longer forces `TERM`.  Your terminal, tmux or ssh should set it.
If the value is wrong, uncomment one line in `~/.coatrc`:

```
# export TERM="xterm-256color"      # normal 256-colour xterm
# export TERM="tmux-256color"       # inside tmux
# export TERM="screen-256color"     # inside screen, or a tmux that reports screen
# export TERM="linux"               # the Linux console
# export TERM="dumb"                # no escape sequences, plain logs
```

Check a value with `infocmp xterm-256color`.

History is also yours.  The example uses:

```
export HISTSIZE=-1          # no Bash limit in memory
export HISTFILESIZE=-1      # no truncation of the history file
export HISTCONTROL=ignoredups
export HISTIGNORE=          # collect everything, including ls, pwd and cd
shopt -s histappend
```

Bash treats a negative size as unlimited; the real limit is memory and
disk.  If you want a cap, use a large positive number, for example
`100000` in memory and `200000` on disk.  `ignoredups` still drops
consecutive repeats; remove it if you want those too.

## Core and extras (work in progress)

The target is a **core** profile that does not change ordinary commands,
plus an optional **extras** profile with the aliases, old functions, git
shortcuts, Python helpers and overrides.  `full` keeps today's behaviour
for existing users.

This is not implemented yet.  The design, module split, migration and
tests are in `docs/tasks/core-extras.md`; the issue is ISS-18.  Until it
lands, `source ~/.coatrc` loads everything, so the table above is the
honest description of the current shell.

## Troubleshooting

**Nothing loads.** `~/.bashrc` must end with `source ~/.coatrc`, and
`~/.coatrc` must set `PATH_TO_COAT`.  A new shell should then know
`grimoire`.

**I changed a module and nothing happened.** Open a new shell.  Sourcing
`~/.coatrc` again in the same shell is ignored on purpose, so prompts and
keys are not set twice.

**A child shell has no aliases.** It should not happen any more.  If it
does, check that `COAT_SHELL_LOADED` is not exported in your environment:
`export -p | grep COAT_SHELL`.

**`ALT + s`, `ALT + i` or `ALT + t` do nothing.** They use `tmux
send-keys`, so they only work inside tmux.

**No key bindings at all.** They are only set in interactive shells; a
script does not get them.

**`dungeon` says there are no layouts.** Save one with
`save_the_workshop`, or fix `TMUXP_CONFIGDIR`.

**`z` does not work.** It needs `fasd`.

**A spell does not show up in the grimoire.** The grimoire lists the
functions and aliases Coat defines, not the spells.  Use `spellcast` for
spells.

**Something in a script fails.** Run `bash -n yourscript.sh` to check the
syntax, and run `bash -x yourscript.sh` to see each line.

## The full command list

`grimoire` (`ALT + h`) is the live list: every function and alias, the
module it lives in, the comment above it, how often you used it, and the
source code in the preview.

For a plain list in the terminal:

```
coat_index | cut -f1,2,3
```
