# Task: core plus optional extras (option B)

Status: **next-session product task**. This is the target shape of Coat,
not a quick patch.

Issue: **ISS-18** in `docs/issues.md`.

## Current decision

- **Do not split overrides now.** This document is a design option, not the
  current change. The single profile stays.
- **Keep `cd` and `grep`.** They are deliberate overrides, not pending
  removals.
- **Python moves to its own interface** in
  `docs/tasks/python-environments.md`; it is not part of the first
  core/extras cut.
- The rest of the split below is still a future direction. Nothing here is
  implemented by this decision.

## The problem

Right now Coat is one pile. `source ~/.coatrc` loads every module, and every
module is allowed to redefine an ordinary command. A user who wants quests
and the manual also gets `cd` printing a listing, `ls`/`grep` colour wrappers,
Polish clipboard aliases and a global Python helper. That is why the layer
feels invasive even when the game part is welcome.

Option B separates the product into:

- **core** — the game, the manual, the index, the safe helpers, and the
  prompt. It does not change what `ls`, `cd`, `grep`, `mkdir`, `man`, `vi`,
  `python` or any other ordinary command means.
- **extras** — the optional aliases, old functions, git shortcuts, Python
  helpers, clipboard spellings and standard-command overrides.
- **full** — core plus extras, kept for existing users and for people who
  want the old behaviour.

The default for a new install **in that future option** should be **core**.
The old behaviour stays available with one line in `.coatrc`.

## Principles

1. **No hidden overrides in core.** If a command exists in POSIX/bash, core
   does not give it a different meaning.
2. **Opt in by name.** A profile or a list in `.coatrc` says what is loaded.
3. **One load order.** The order is explicit and tested for every profile.
4. **Small dependencies.** A core module may not call a function that only
   exists in extras.
5. **Honest docs.** The manual says what is core, what is extra and how to
   turn an extra off.
6. **No deletion by surprise.** Existing users keep `full` during the
   migration; removal happens after a deprecation note.

## Profiles

Start with three profiles:

| Profile | What loads | Who it is for |
|---------|------------|---------------|
| `core` | game, manual, index, prompt, safe helpers | new users; people who want Coat without a changed shell |
| `extras` | core + aliases/functions/git/python/clipboard/overrides | people who want the old toolbox |
| `full` | same as `extras` for now; kept as the compatibility name | existing `.coatrc` files |

`core` is the default when `COAT_PROFILE` is unset. `full` is the migration
value for current users. Later `extras` and `full` can diverge if needed,
but two names are enough for the first release.

A finer list is useful for power users:

```bash
# .coatrc
export COAT_PROFILE=core
export COAT_EXTRAS="git python"   # only these extras, on top of core
```

If both are set, `COAT_EXTRAS` wins for the extra list; `COAT_PROFILE` still
controls the core.

## Proposed module split

The current files are a mix of policies. The split should follow behaviour,
not just file names.

### Core

| Module | Why it is core |
|--------|----------------|
| `variables.sh` | environment, pager, colours; no history or `TERM` (those are in `.coatrc`) |
| `core.sh` (new) | small safe helpers that do not shadow a standard command; the shared prompt helpers |
| `organization.sh` | `mark`, `spot`, `goto`, `trail`, bookmarks; these are new names |
| `xp.sh` | command log, XP, achievements, HUD |
| `quest.sh` | quests |
| `dungeon.sh` | tmuxp layouts |
| `spells.sh` | spellbook, paczek, loot, ssh helpers |
| `grimoire.sh` | the searchable index |
| `manual.sh` | the manual picker |
| `shortcuts.sh` | key bindings; every binding must check that its function exists |
| `autocomplete.sh` | completion files |
| `prompt.sh` | `PS1`; needs the prompt helpers from `core.sh` |

Core must not include:

- `aliases.sh`;
- the old `bash_functions.sh` aliases and the `cd`/`man` wrappers;
- `git.sh` aliases (the prompt helper can live in `core.sh`);
- `python.sh`;
- `simplifications.sh` and the Polish clipboard names.

`organization.sh` currently calls `cd`, and `trail`/`cdg` use it. In core
that is the builtin; in extras the `cd` wrapper is loaded, so the listing
appears. That is acceptable, but the task must decide whether `trail` should
call `builtin cd` to stay quiet even in `full`. Recommendation: use
`builtin cd` inside core helpers, so the core behaviour does not depend on
extras.

### Extras

| Module | What it brings | Risk |
|--------|----------------|------|
| `aliases.sh` | the big alias file, colours, listing, system shortcuts | shadows `ls`, `grep`, `mkdir`, `du`, `df`, `dir`, `vdir`, `tree`, `vi`, `top`, `tmux`, `chown`, `chmod`, `chgrp`, `dmesg`, etc. |
| `bash_functions.sh` | old functions and a few aliases; the `cd`/`man` wrappers | the `cd` wrapper prints a listing and writes files; old Python 2 helpers |
| `git.sh` | git aliases and helpers | hundreds of short names; mostly new names, but `g`/`get` duplicate |
| `python.sh` | Python/venv helpers | global `pip`, `sudo update-alternatives`; see `docs/tasks/python-environments.md` |
| `simplifications.sh` | clipboard aliases, including Polish names | shadows no standard command; safe but language-specific |
| `overrides.sh` (new, optional) | any standard-command override that survives the audit | must be explicit and documented |

The old `bash_functions.sh` should eventually be split:

- `core.sh`: `command_exists`, `err`, prompt helpers, `history_top_used`,
  and other functions that do not shadow a standard command;
- `extras/functions.sh`: old convenience functions;
- `extras/overrides.sh`: `cd`, `man`, and any other standard-name wrapper.

This task does not require the split on day one. It does require that the
profile boundary is real: if `COAT_PROFILE=core`, `type cd` is the builtin
and `type ll` fails.

## Load order with profiles

The existing `COAT_MODULE_ORDER` becomes two arrays:

```bash
# always loaded, in this order
COAT_CORE_ORDER=(
  variables
  core
  organization
  quest
  dungeon
  spells
  grimoire
  manual
  shortcuts
  autocomplete
)

# loaded only when the profile includes extras
COAT_EXTRAS_ORDER=(
  aliases
  bash_functions
  git
  python
  simplifications
  overrides
)

# xp and prompt are always last; xp needs the other modules, prompt needs all
COAT_CORE_ORDER+=(xp prompt)
```

The real load loop:

```
core modules
  -> extras modules (if selected)
  -> xp
  -> prompt
  -> COAT_XP_READY=1
```

That keeps the command log from counting the loading itself and keeps the
prompt last. `xp` must load after extras so a command captured during
loading is not counted, but before `prompt` so its hook is installed.

## What `core` looks like to the user

```
$ type ll
bash: type: ll: not found
$ type cd
cd is a shell builtin
$ type grep
grep is /usr/bin/grep
$ quest add "try core"
$ manual
$ paczek
$ mark
$ trail
```

`quest`, `manual`, `paczek`, `mark`, `trail`, `grimoire` are new names, so
they are safe in core. `cd` is the builtin. The prompt still shows the git
branch and the virtualenv, but the prompt helpers live in core.

## Migration

1. Add `COAT_PROFILE` and `COAT_EXTRAS` parsing to `coat.sh`, with `core`
   as the default.
2. Put `COAT_PROFILE=full` in the current `.coatrc.example` and in the live
   `.coatrc` for one release. Add a comment: "remove this to try core".
3. Move the prompt helpers out of `bash_functions.sh` into `core.sh`.
4. **Deferred:** move the standard-command overrides behind the extras
   boundary. Start with `cd` and `man` only after the decision changes;
   today `cd` and `grep` are explicitly kept in the default profile.
5. Make `shortcuts.sh` skip a binding when its function is absent, so core
   does not print "command not found" on a key press.
6. Make `grimoire` show the loaded profile and mark extras that are not
   loaded, or scan only loaded modules.
7. Update `README.md`, `docs/manual.md`, `docs/overrides.md`,
   `docs/alias-audit.md` and the issue list.
8. After one release, switch the default in `.coatrc.example` to core and
   remove the compatibility note from new installs.

## Tests

Add to `tests/cases/10-load.sh` or a new `15-profiles.sh`:

- `COAT_PROFILE=core`:
  - `type -t ll` is empty;
  - `type -t cd` is `builtin`;
  - `type -t grep` is `file` (not `alias`/`function`);
  - `type -t quest` is `function`;
  - `type -t manual` is `function`;
  - `type -t paczek` is `function`;
  - `type -t py` is empty;
  - the prompt hook is installed exactly once.
- `COAT_PROFILE=extras` and `COAT_PROFILE=full`:
  - `type -t ll` is `alias`;
  - `type -t cd` is `function`;
  - `type -t grep` is `alias`;
  - the extra modules are loaded.
- `COAT_EXTRAS="git"`:
  - git aliases exist;
  - `ll` and `py` do not.
- The load order arrays are explicit, prompt is last, and double source is
  still a no-op.
- Core does not call a function that only exists in extras. A simple test:
  source core, then run `type -t` for every function called by core modules,
  or run a small smoke script with `set -u`.

## Acceptance criteria

- A new install defaults to core.
- `COAT_PROFILE=full` gives the current behaviour.
- Core does not redefine `cd`, `ls`, `grep`, `mkdir`, `du`, `df`, `man`,
  `vi`, `top`, `tmux`, `python` or any other ordinary command.
- The game, manual, grimoire, paczek and prompt work in core.
- The load order is explicit, documented and tested for all profiles.
- The manual and README explain the profile switch in one short section.
- Existing users can migrate by adding one line, not by reading the source.
- `make test`, `make syntax` and `make shellcheck` pass.

## Open questions

- Should the default be `core` immediately, or after one release of
  `full`? Recommendation: `full` in existing `.coatrc`, `core` in the
  example, then flip the example after one release.
- Is `organization` core? It adds no standard-name override, but it calls
  `cd` and writes a trail on every folder change. Recommendation: core, but
  use `builtin cd` inside it.
- Are the git aliases extras or a separate `git` extra? Recommendation:
  separate `git` extra, because many users want the prompt but not 100
  short names.
- Does `shortcuts.sh` belong in core? Recommendation: yes, but every
  binding must be guarded by `type -t`.
- Should `overrides.sh` exist at all, or should every override move to an
  alias file that is clearly named `overrides`? Recommendation: a distinct
  file makes the audit and the test easy.
