# Commands that Coat changes

This is the full list of ordinary shell commands whose meaning changes after
`source ~/.coatrc`. It is the audit behind the issue about hidden behaviour.
It is allowed to be work in progress: every row should end up as *keep*,
*remove*, *rename* or *extras*.

Issue: **ISS-16** in `docs/issues.md`.

## Current decision

- **No overrides split now.** The single profile stays; `cd`, `grep` and the
  rest are not moved into a separate extras module in this pass.
- **`cd` stays.** The wrapper keeps its current behaviour; this is a
  deliberate choice, not an oversight.
- **`grep` stays.** The colour override stays. The earlier
  `grep $GREP_OPTIONS` definition is still a duplicate tracked by ISS-15;
  the final `grep --color` definition is the one that wins.
- **Python helpers move to the new interface** described in
  `docs/tasks/python-environments.md`. The old names stay for now and will
  become thin wrappers when that task is implemented.

The load order in `coat.sh` is:

```
variables -> aliases -> bash_functions -> organization -> simplifications ->
git -> python -> xp -> quest -> dungeon -> spells -> grimoire -> manual ->
shortcuts -> autocomplete -> prompt
```

Aliases and functions from a later module win. Inside one file, the last
definition wins. A function beats an alias of the same name; an alias beats
an external command of the same name.

## How to get the original command back

- `command ls` bypasses an alias and a function.
- `\ls` bypasses an alias only.
- `builtin cd` bypasses the `cd` function.
- `command cd` also bypasses the function and uses the builtin.
- `/bin/ls` always runs the real binary.

## Always active

These are defined without a test (apart from `vi`, which needs `vim`).

| Name | Where | Without Coat | With Coat | Difference |
|------|-------|--------------|-----------|------------|
| `sudo` | `aliases.sh:22` | `sudo` | `sudo ` (trailing space) | The next word is also alias-expanded, so `sudo ll` works. |
| `chown` | `aliases.sh:48` | `chown` | `chown --preserve-root` | Refuses `/` as the target. |
| `chmod` | `aliases.sh:49` | `chmod` | `chmod --preserve-root` | Refuses `/` as the target. |
| `chgrp` | `aliases.sh:50` | `chgrp` | `chgrp --preserve-root` | Refuses `/` as the target. |
| `dmesg` | `aliases.sh:53` | `dmesg` | `dmesg -T` | Human-readable timestamps. |
| `grep` | `aliases.sh:56` and `:230` | `grep` | `grep --color` | Colour. The first definition uses `$GREP_OPTIONS`; the later one replaces it, so `GREP_OPTIONS` is effectively lost when colour is on. **Decision: keep.** |
| `mkdir` | `aliases.sh:118` | `mkdir` | `mkdir -p` | Creates missing parents, never fails when the folder exists. |
| `du` | `aliases.sh:401` | `du` | `du -kh` | Human sizes, 1024-byte blocks. |
| `df` | `aliases.sh:407` | `df` | `df -kTh` | Filesystem type and human sizes. |
| `ls` | `aliases.sh:249` | `ls` | `ls -F --color` | Classify entries and colour. If `grc` is installed, `aliases.sh:204` first sets `ls="colour ls"` and line 249 overwrites it. |
| `dir` | `aliases.sh:272` | `dir` | `ls --format=vertical --color` | Uses `ls`, not the original `dir` binary. |
| `vdir` | `aliases.sh:274` | `vdir` | `ls --format=long --color` | Uses `ls`, not the original `vdir` binary. |
| `vi` | `bash_functions.sh:20` | `vi` | `nvim` | Only when `vim` is in `PATH`; the check is `which vim`, not `which nvim`. |
| `tmux` | `aliases.sh:13` | `tmux` | `tmux -u` | Forces UTF-8. |
| `black` | `python.sh:15` | `black` | `black -Sq` | Skips string normalisation and is quiet. |
| `cd` | `bash_functions.sh:69` | `cd` | a function | Saves `$BACK`, writes `~/temp/current_dir`, feeds the trail, handles `cd ...`, sources `~/.autoenv` if present, and prints a coloured `ls` listing to stderr after every change. **Decision: keep.** |
| `man` | `bash_functions.sh:420` | `man` | a function | Sets `LESS_TERMCAP_*` colour variables. |
| `t` | `bash_functions.sh:1276` | (no standard `t`) | a tail helper | Not an override of a standard command, but it occupies the short name. |
| `o` | `bash_functions.sh:1316` | (no standard `o`) | open helper | On Linux it still prefers `open`; the detection for `xdg-open` is commented out. |
| `z` | `spells.sh:207` | (a possible `fasd` helper) | fzf+fasd helper | Needs `fasd`; prints an error when it is missing. |

## Conditional: colour and optional tools

These only exist when the test passes. They are shown because "sometimes the
command means something else" is exactly the hidden behaviour this audit is
about.

| Name | Where | Condition | With Coat |
|------|-------|-----------|-----------|
| `as` | `aliases.sh:194` | `grc` installed, `TERM != dumb` | `grc as` |
| `configure` | `aliases.sh:195` | same | `grc ./configure` |
| `diff` | `aliases.sh:196` | same | `grc diff` |
| `dig` | `aliases.sh:197` | same | `grc dig` |
| `g++` | `aliases.sh:198` | same | `grc g++` |
| `gas` | `aliases.sh:199` | same | `grc gas` |
| `gcc` | `aliases.sh:200` | same | `grc gcc` |
| `head` | `aliases.sh:201` | same | `grc head` |
| `ifconfig` | `aliases.sh:202` | same | `grc ifconfig` |
| `ld` | `aliases.sh:203` | same | `grc ld` |
| `make` | `aliases.sh:205` | same | `grc make` |
| `mount` | `aliases.sh:206` | same | `grc mount` |
| `netstat` | `aliases.sh:207` | same | `grc netstat` |
| `ping` | `aliases.sh:208` | same | `grc ping` |
| `ps` | `aliases.sh:209` | same | `grc ps` |
| `tail` | `aliases.sh:210` | same | `grc tail` |
| `traceroute` | `aliases.sh:211` | same | `grc traceroute` |
| `syslog` | `aliases.sh:212` | same | `sudo grc tail -f -n 100 /var/log/syslog` |
| `egrep` | `aliases.sh:231` | `TERM != dumb` | `egrep --color` |
| `fgrep` | `aliases.sh:232` | `TERM != dumb` | `fgrep --color` |
| `top` | `aliases.sh:224` | `htop` installed | `htop`; `top_orig` keeps the original. |
| `tree` | `aliases.sh:281` | `tree` installed | `tree -Csu`; otherwise a `find`-based fallback. |
| `ack` | `aliases.sh:298` | `ack-grep` installed | `ack-grep`. |
| `ls` | `aliases.sh:204` | `grc` installed | `grc ls`, but overwritten by line 249. |
| `diff` (again) | `aliases.sh:180` | `colordiff`/`highlight` | `difflight` is the colour pager; `diff` itself is only changed by `grc`. |

## Functions that look like commands

The Python helpers in this table — including `server`, `json`, `lc`, `uc` and
`runserver` — are moving to the new interface in
`docs/tasks/python-environments.md`. They stay in place until that task is
implemented, then become wrappers or are removed. The other functions below
are not part of that move.

| Name | Where | What it does | Why it matters |
|------|-------|--------------|----------------|
| `cd` | `bash_functions.sh:69` | wraps the builtin and prints a listing | The extra output and the `~/temp/current_dir` / trail writes are visible side effects. Use `builtin cd` to avoid them. |
| `man` | `bash_functions.sh:420` | wraps `man` with `LESS_TERMCAP_*` | Colour only; the same pager. |
| `t` | `bash_functions.sh:1276` | `tail -n 50 -f` with optional highlight | Short name; no standard `t`. |
| `o` | `bash_functions.sh:1316` | open a file/URL | On Linux the `xdg-open` branch is commented out, so it may call a missing `open`. |
| `server` | `bash_functions.sh:1040` | Python HTTP server | Uses Python 2 `SimpleHTTPServer`; broken on a Python 3-only system. |
| `json` | `bash_functions.sh:1132` | `python -mjson.tool` | Uses `python`, not `python3`. |
| `lc`, `uc` | `bash_functions.sh:111`, `:124` | lower/upper case | Python 2 `print` syntax; broken on Python 3. |
| `runserver` | `bash_functions.sh:40` | `python -m http.server 8000` | Alias; needs `python` on `PATH`. |
| `switchpython` | `python.sh:4` | `sudo update-alternatives --config python` | Global, sudo, Debian-specific. **Decision: move to `pyversion`.** |
| `makevenv` | `python.sh:6` | `virtualenv $VENV_FOLDER` | Needs `virtualenv`; ignores `.venv`. **Decision: move to `pyvenv`.** |
| `makeactive` | `python.sh:8` | `source $VENV_FOLDER/bin/activate` | Needs `VENV_FOLDER`. **Decision: move to `pyactivate`.** |
| `makeactiver` | `python.sh:11` | find `.venv` upward and activate | Uses `mark`/`goto` and hardcodes `.venv`. **Decision: move to `pyactivate`.** |
| `installrequirements` | `python.sh:13` | `pip install -r requirements.txt` | Global `pip`; no venv check. **Decision: move to `pyrequirements`.** |

## Things that are *not* overrides

These are new short names, not changes to an existing command. They are in
the list so nobody mistakes them for a standard behaviour:

`g`, `h`, `j`, `py`, `ipy`, `rb`, `_`, `please`, `clr`, `pu`, `po`, `..`,
`...`, `....`, `.....`, `~`, `-`, `cd..`, `md`, `d`, `rd`, `l`, `la`, `ll`,
`ldir`, `l.`, `ldot`, `l1`, `lA`, `lsa`, `lr`, `lt`, `lf`, `llr`, `lsd`,
`lS`, `sgrep`, `afind`, `apt-*`, `myip_*`, `dnsInfo`, `speedtest`, `gurl`,
`lsport`, `llport`, `netlisteners`, `date_*`, `timer`, `meminfo`, `psmem*`,
`pscpu*`, `psx`, `pst`, `psmy`, `loadavg`, `partitions`, `du_overview`,
`getclip`, `putclip`, `pc`, `badge`, `dec2hex`, `urldecode`, `urlencode`,
`rot13`, `map`, `chromekill`, `composer-install`, `yt-*`, `starwars`.

The full duplicate and synonym list is in `docs/alias-audit.md`.

## Decisions

- **Overrides stay in the default profile for now.** There is no extras
  split in this pass.
- **`cd` keeps its listing and trail behaviour.** This is intentional.
- **`grep` keeps the colour override.** The earlier `GREP_OPTIONS`
  definition is still a duplicate for ISS-15.
- **Python moves to the new interface** in
  `docs/tasks/python-environments.md`; the old names will become wrappers.

## Still open

- Which of the remaining overrides (beyond `cd` and `grep`) should be kept,
  removed or renamed in a later cleanup?
- Should the duplicate `GREP_OPTIONS` alias be removed, or documented as
  the first attempt that the final alias replaces?
- Should `man`, `vi`, `top`, `tmux` and the `grc` wrappers stay in the
  default profile when the future core/extras work is picked up?
