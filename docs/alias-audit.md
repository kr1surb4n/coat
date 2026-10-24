# Alias audit

This is the working list behind the duplicate-alias issue. It has two parts:

1. **Same name, more than one definition** — the load order decides which
   one wins.
2. **Same operation, different names or languages** — the user has to
   choose one spelling, or keep both knowingly.

The goal is not to delete everything. The goal is to make the choice
visible and to know what the shell actually has after `source ~/.coatrc`.

Issue: **ISS-15** in `docs/issues.md`.

## Load order

`coat.sh` now has one explicit list, `COAT_MODULE_ORDER`:

| # | Module | What it adds |
|---|--------|--------------|
| 1 | `variables.sh` | environment, colours, pager |
| 2 | `aliases.sh` | the big alias file, colours, listing, system, language shortcuts |
| 3 | `bash_functions.sh` | functions and a few old aliases |
| 4 | `organization.sh` | `mark`, `spot`, `goto`, `trail`, bookmarks |
| 5 | `simplifications.sh` | clipboard aliases, including the Polish ones |
| 6 | `git.sh` | git aliases and helpers |
| 7 | `python.sh` | Python/venv aliases |
| 8 | `xp.sh` | command log, XP, achievements, HUD |
| 9 | `quest.sh` | quests |
| 10 | `dungeon.sh` | tmuxp layouts |
| 11 | `spells.sh` | spellbook, paczek, ssh, loot |
| 12 | `grimoire.sh` | the searchable index |
| 13 | `manual.sh` | the manual picker |
| 14 | `shortcuts.sh` | key bindings |
| 15 | `autocomplete.sh` | completion files |
| 16 | `prompt.sh` | `PS1` and the git prompt |

Later modules override earlier aliases and functions. Inside one file, the
last definition wins, except for `if/elif/else` branches, where only one
branch runs.

## Same name, more than one definition

These are the real collisions. "Both run" means both definitions are
executed while the file is sourced; the later one wins. "One branch" means
the definitions are alternatives in an `if/elif/else` and only one is
active.

| Name | Definitions (file:line) | Both run? | Difference | What wins |
|------|-------------------------|-----------|------------|-----------|
| `..` | `aliases.sh:88` `cd ..`; `bash_functions.sh:5` `cd ..` | yes | none | `bash_functions.sh` (same) |
| `...` | `aliases.sh:89` `cd ../..`; `bash_functions.sh:6` `cd ../..` | yes | none | `bash_functions.sh` (same) |
| `....` | `aliases.sh:90` `cd ../../..`; `bash_functions.sh:7` `cd ../../..` | yes | none | `bash_functions.sh` (same) |
| `l` | `aliases.sh:242` `ls -lhF $COLORFLAG`; `bash_functions.sh:4` `ls -CF` | yes | colour + long + human + directories first vs columns only | `bash_functions.sh` (plain) |
| `la` | `aliases.sh:253` `ls -laFh $COLORFLAG`; `bash_functions.sh:3` `ls -Al` | yes | colour + human + almost-all vs almost-all only | `bash_functions.sh` (plain) |
| `ll` | `aliases.sh:264` `ls -lFh --group-directories-first $COLORFLAG`; `bash_functions.sh:2` `ls -AlFctr` | yes | colour + human + group-dirs vs hidden + long + reverse ctime | `bash_functions.sh` (plain, unsorted by name) |
| `g` | `aliases.sh:65` `git`; `git.sh:3` `git` | yes | none | `git.sh` (same) |
| `grep` | `aliases.sh:56` `grep $GREP_OPTIONS`; `aliases.sh:230` `grep $COLORFLAG` | yes when `TERM != dumb` | `GREP_OPTIONS` (`-s`) vs `--color` | line 230; `GREP_OPTIONS` is lost |
| `ls` | `aliases.sh:204` `colour ls` (grc); `aliases.sh:249` `ls -F $COLORFLAG` | yes | grc wrapper vs plain colour `ls` | line 249; grc is lost |
| `tree` | `aliases.sh:281` `tree -Csu`; `aliases.sh:285` `find …` | one branch | real tree vs fallback | whichever branch is active |
| `ltree` | `aliases.sh:283` `tree -Csu \| less -R`; `aliases.sh:286` `tree \| less -R` | one branch | same, but the fallback uses the fallback `tree` | whichever branch is active |
| `afind` | `aliases.sh:300` `ack-grep -iH`; `aliases.sh:302` `ack -iH` | one branch | package name differs | whichever branch is active |
| `difflight` | `aliases.sh:180` `colordiff`; `:182` `highlight`; `:188` `less -XFIRd` | one branch | three available backends | whichever branch is active |
| `getclip` | `aliases.sh:430` `pbpaste`; `:433` `xclip … -o`; `:436` `cat /dev/clipboard` | one branch | macOS / X11 / Cygwin | whichever OS branch is active |
| `putclip` | `aliases.sh:431` `pbcopy`; `:434` `xclip … -i`; `:437` `cat > /dev/clipboard` | one branch | macOS / X11 / Cygwin | whichever OS branch is active |

The `ll`/`la`/`l` collision is the one with a visible bug: `aliases.sh`
defines the nice versions, then `bash_functions.sh` overwrites them with
plain `ls` variants. `grep` has a smaller one: the final alias drops
`GREP_OPTIONS`, and `ls` loses the `grc` wrapper.

## Same operation, different names

These are not necessarily bugs. They are the places where two or more
names mean almost the same thing, so the shell has to be learned twice.

### Clipboard

| Names | Operation | Difference |
|-------|-----------|------------|
| `clip-in`, `wez`, `kopjuj` | copy stdin to the clipboard | English / Polish; `wez` and `kopjuj` are synonyms |
| `clip-out`, `pusc`, `wklej` | print/paste the clipboard | English / Polish; `pusc` and `wklej` are synonyms |
| `getclip`, `putclip`, `pc` | OS clipboard read/write | `getclip` reads, `putclip` writes; `pc` is `putclip` |
| `xclip` | the underlying tool | no wrapper; useful when a script needs the real command |

### Moving around

| Names | Operation | Difference |
|-------|-----------|------------|
| `cd`, `cdo`, `-`, `~` | change folder | `cd` is the wrapper (listing + trail); `cdo` uses `$OLDPWD`; `-` and `~` are aliases |
| `..`, `...`, `....`, `.....`, `cd..`, `cd...`, `cd....`, `cd.....` | go up N folders | all aliases; the `cd..` forms are typo fallbacks |
| `goto`, `spot`, `mark` | save/return to one folder | `mark` writes `$SPOT_FILE`; `spot` prints it; `goto` cds there |
| `trail`, `z` | jump to a visited folder | `trail` uses Coat's own trail; `z` needs `fasd` and is not installed |
| `pu`/`pushd`, `po`/`popd`, `d`, `1`…`9` | directory stack | aliases to the builtins / stack entries |
| `mkd`, `md`, `mkdir` | create a folder | `mkdir` is `mkdir -p`; `md` is `mkdir`; `mkd` creates and enters |
| `rd`, `rmdir` | remove an empty folder | `rd` is a short alias |

### Listing and files

| Names | Operation | Difference |
|-------|-----------|------------|
| `ls`, `l`, `la`, `ll`, `ldir`, `l.`, `ldot`, `l1`, `lA`, `lsa`, `lr`, `lt`, `lf`, `llr`, `lsd`, `lS` | list files | different flags: long/short, hidden, human, sort, directories only, recent files |
| `dir`, `vdir`, `tree`, `ltree` | list in another layout | `dir`/`vdir` are aliases to `ls`; `tree` has a fallback; `ltree` pages it |
| `du`, `duh`, `fs` | disk usage | `du` adds `-kh`; `duh` is a quick human total; `fs` is a size helper |
| `df` | free space | adds `-kTh` (1024-byte blocks, type, human) |
| `ff`, `fstr`, `file_information`, `mount_info` | find/show files | different scopes: recursive files, string search, single-file info, mounts |

### Git

| Names | Operation | Difference |
|-------|-----------|------------|
| `g`, `get` | `git` | two names for the same command |
| `gs`, `gss` | status | full vs short |
| `gd`, `gds`, `gdv` | diff | worktree, staged, or `-w` through vim |
| `gc`, `gca`, `gcm`, `gcam`, `gci`, `gcaa`, `gcsam` | commit | verbose, all, message, amend, interactive, signed |
| `gb`, `gba`, `gbt`, `gbm`, `gbd`, `gbD`, `gdel` | branch | list, all, track, move, delete, force-delete |
| `gco`, `gcom`, `gcob`, `gct` | checkout | branch, master, new branch, track |
| `gf`, `gft`, `gfv`, `gftv` | fetch | all/prune, tags, verbose |
| `gl`, `glum`, `gpr`, `gpp`, `gup` | pull | plain, upstream, rebase, pull+push, fetch+rebase |
| `gp`, `gpo`, `gpu`, `gpuo`, `gpuoc`, `gpom` | push | plain, origin, set-upstream, origin+upstream, branch, master |
| `gr`, `grv`, `gra` | remote | list, verbose, add |
| `gitlogs`, `shortlogs`, `gll`, `gg`, `ggs`, `gnew`, `gwc` | log | graph, one-line, decorated, stat, reflog range, whatchanged |
| `gst`, `gstb`, `gstd`, `gstl`, `gstp` | stash | save, branch, drop, list, pop |
| `gt`, `gta`, `gtd`, `gtl`, `gtls`, `gpatch` | tag / patch | tag, annotate, delete, list, version-sort, format-patch |
| `gsu`, `gsa` | submodule | update, add |
| `gcl`, `grm`, `gmv`, `gap`, `gall` | clone/rm/mv/add | plain git subcommands with short names |
| `makeworking`, `removeworking`, `newwork`, `mergeworking`, `setcurrentbranch` | branch workflow | a small workflow around a `working` branch |
| `fbr`, `fco`, `choose_branch`, `choose_commit`, `choose_remote` | pick with fzf | different objects and actions |

### Python

See `docs/tasks/python-environments.md` for the new interface. The decision
is to **move the old helpers to that interface**, not to add more aliases.
The old names stay until the task is implemented.

| Names | Operation | Difference |
|-------|-----------|------------|
| `py`, `python` | run Python | `py` is an alias for `python`; on many systems only `python3` exists |
| `ipy`, `ipython` | run IPython | alias |
| `makevenv`, `virtualenv` | create a virtualenv | alias around `virtualenv $VENV_FOLDER` |
| `makeactive`, `source .venv/bin/activate` | activate | alias |
| `makeactiver` | find and activate a venv upward | uses `mark`/`goto` and hardcodes `.venv` |
| `installrequirements`, `pip install -r requirements.txt` | install project deps | alias |
| `switchpython`, `update-alternatives` | choose the global Python | system-wide, sudo, distro-specific |
| `black`, `black -Sq` | format | alias with fixed flags |
| `runserver`, `python -m http.server` | serve the folder | alias on port 8000 |
| `lc`, `uc`, `json`, `server`, `urldecode`, `urlencode` | text/HTTP helpers | several are still Python 2 syntax and call `python`, not `python3` |

### System, processes, network

| Names | Operation | Difference |
|-------|-----------|------------|
| `apt-update`, `apt-upgrade`, `apt-search`, `apt-install` | apt shortcuts | wrappers around `apt-get`/`apt-cache`; not the `apt` command itself |
| `psmem`, `psmem5`, `psmem10` | memory hogs | full list / last 5 / last 10 |
| `pscpu`, `pscpu5`, `pscpu10` | CPU hogs | full list / last 5 / last 10 |
| `psgrep`, `psx`, `psmy`, `pst` | process search | grep the process list, full tree, current user, tree view |
| `kknd`, `fkill`, `processids` | kill processes | `kknd` sends KILL; `fkill` picks with fzf; `processids` prints PIDs |
| `myip_dns`, `myip_http`, `dnsInfo`, `digga` | IP/DNS | different resolvers |
| `lsport`, `llport`, `netlisteners` | listening ports | lsof vs netstat |
| `sniff`, `httpdump`, `testConnection`, `ips` | network debug | tcpdump/HTTP/connect/addresses |
| `speedtest`, `gurl` | download/speed | wget vs curl |
| `ping`, `traceroute`, `netstat`, `ifconfig`, `mount` | system tools | colour wrappers when `grc` is installed |

### Archives, notes, text

| Names | Operation | Difference |
|-------|-----------|------------|
| `extract`, `targz`, `gz` | archive | unpack / create tar.gz / gzip |
| `file_backup`, `file_backup_compressed` | backup | copy vs compressed |
| `note`, `note_show`, `dirtynotes`, `cleardirtynotes` | notes | append, show, pick from history, clear |
| `spellsave`, `dirtynotes` | save a history line | spellbook vs notes; both use `history` |
| `spellcast`, `spellforge`, `insert_line_with_fzf`, `type_line_with_fzf` | use a spell | run / type / insert / forge |
| `lc`, `uc` | lower/upper case | two directions |
| `unidecode`, `codepoint` | Unicode | decode escapes vs code point |
| `escape`, `rot13`, `dec2hex` | text transforms | different encodings |
| `dataurl`, `gitio`, `shorturl`, `urldecode`, `urlencode` | URLs | data URL / git.io / shortener / percent coding |

### Language shortcuts

| Names | Operation | Difference |
|-------|-----------|------------|
| `py`, `rb`, `g`, `h`, `j` | language/tool shortcuts | Python, Ruby, git, history, jobs |
| `clr`, `please`, `_`, `zzz` | convenience | clear, sudo, sudo, suspend |
| `fman`, `fmans` | man picker | same function, two names |
| `o`, `open`, `xdg-open` | open a file/URL | `o` calls macOS `open`; Linux needs `xdg-open` |

## Decisions (current)

The audit is deliberately a list, not a deletion plan. These decisions are
recorded now; the rest are still open.

| Topic | Decision |
|-------|----------|
| overrides split | **Do not split now.** The single profile stays; the aliases and overrides remain in the default shell. |
| `cd` | **Keep.** The wrapper and its listing/trail behaviour stay. |
| `grep` | **Keep.** The colour override stays; the earlier `grep $GREP_OPTIONS` definition is still a duplicate for ISS-15. |
| Python | **Move to the new interface.** `docs/tasks/python-environments.md` is the target; old names become wrappers during migration. |
| everything else | Still to decide: keep, remove, rename, or future extras. |

The next step for the remaining rows is to mark each one `keep`, `remove`,
`rename` or `future extras`, then make the code and the manual agree. That
is a later task, not part of this pass.
