# Task: Python environments and packages

Status: **decision recorded; implementation pending**. Do not solve it by
adding one more alias. The current Python module is a 2016-era wrapper
around a global `python`, global `pip` and a single `virtualenv` folder.
The rest of the world moved to per-project and per-user environments.

Decision: the old helpers move to the new interface described below. They
stay in place until the implementation lands, then become thin wrappers or
are removed. No code changes were made in this pass.

Issue: **ISS-17** in `docs/issues.md`.

This document is the input for the next session. It records the current
state, the options, a recommended model, and the acceptance criteria.

## Goal

Replace the hidden, global Python helpers with a small, explicit and
general interface that:

- keeps `virtualenv` as one supported alternative;
- prefers per-project `.venv` for projects;
- prefers `pipx` (or an equivalent) for command-line tools;
- never silently installs into the system Python;
- works on a PEP 668 "externally managed" system;
- supports `venv`, `virtualenv`, `uv`, `poetry`, `pdm`, `hatch`, `conda`
  and plain `pip` where the user chooses them;
- uses `python3`, not `python`, unless the user explicitly asks;
- does not change global alternatives with `sudo`;
- can be tested without touching the real `$HOME` or the real Python.

## Current state (still in the code)

### `modules/python.sh`

```bash
alias switchpython='sudo update-alternatives --config python'
alias makevenv='virtualenv $VENV_FOLDER'
alias makeactive='source $VENV_FOLDER/bin/activate'
alias makeactiver='mark; current_dir=`pwd`; while ...; do source $current_dir/.venv/bin/activate ...; done; goto'
alias installrequirements='pip install -r requirements.txt'
alias black='black -Sq'
```

Problems:

- `switchpython` is Debian/Ubuntu-only, global, needs `sudo`, and changes
  the system interpreter. It is not a project tool.
- `makevenv` needs an external `virtualenv` and uses `$VENV_FOLDER`; there
  is no `.venv` default, no `python3 -m venv` fallback and no check that
  the target already exists.
- `makeactive` assumes `$VENV_FOLDER`; `makeactiver` assumes `.venv`,
  changes directory, calls `mark` and `goto`, and can leave the shell in a
  different folder. Activation is a shell state change, not a command.
- `installrequirements` calls the global `pip`; on Debian/Ubuntu with PEP
  668 this fails or, worse, installs into the user site or the system.
- `black` is a tool alias, not an environment operation; it belongs with
  the tool runner, not with venv management.
- All are aliases, so they cannot validate arguments, choose a backend or
  print a useful error.

### Other Python uses

| Place | What it does | Problem |
|-------|--------------|---------|
| `aliases.sh:458` `py='python'` | short name | Many systems only have `python3`. |
| `aliases.sh:459` `ipy='ipython'` | short name | Fine as a shortcut. |
| `aliases.sh:476` `urldecode` | Python 2 `urllib` | `print` statement; broken on Python 3. |
| `aliases.sh:479` `urlencode` | Python 2 `urllib` | Same. |
| `bash_functions.sh:40` `runserver` | `python -m http.server` | Uses `python`, fixed port 8000. |
| `bash_functions.sh:111` `lc` | lower-case with Python | Python 2 syntax. |
| `bash_functions.sh:124` `uc` | upper-case with Python | Python 2 syntax. |
| `bash_functions.sh:1040` `server` | Python 2 `SimpleHTTPServer` | Broken on Python 3. |
| `bash_functions.sh:1132` `json` | `python -mjson.tool` | Uses `python`; no `python3` fallback. |
| `prompt.sh` | shows `$VIRTUAL_ENV` | Only display; no management. |
| `.coatrc.example` | `VENV_FOLDER`, `pyenv` paths | Assumes one global venv folder. |

The `spells.sh` `makecookie` function is **not** Python; it is a login-cookie
picker. Do not include it in this task.

## The options

### Scope and system

| Option | Scope | What it is good for | Cost / risk |
|--------|-------|---------------------|-------------|
| Debian/Ubuntu `apt` | system | distro Python, system libraries, services | old versions; `sudo`; not for project packages |
| `pip install --user` | per-user | small scripts when no venv is needed | shared between projects; can still conflict; PEP 668 may block it |
| `pipx` | per-user | command-line tools (`black`, `ruff`, `poetry`, `httpie`) | one venv per tool; not for libraries imported by a project |
| `python3 -m venv .venv` | project | the standard library baseline | no lockfile; needs activation or explicit interpreter path |
| `virtualenv` | project | faster/older Python support; **must stay as an alternative** | external dependency; still no lockfile |
| `uv` | project + tools + interpreters | fast venv, `uv pip`, `uv add`, `uv tool`, `.python-version` | newer tool; teams must agree on it |
| `poetry` | project | dependency resolution + lockfile + packaging | its own env model; slower; opinionated |
| `pdm` | project | PEP 582 / lockfile alternative | less common |
| `hatch` | project | environments + build + scripts | another config file |
| `conda` / `mamba` | project or user | binary packages, data science, non-Python deps | large; separate ecosystem |
| `pyenv` | per-user | several Python versions | builds interpreters; shims; slower |
| `direnv` | per-project | automatic activation when entering a folder | another shell hook; not a package manager |
| `nix` / devcontainers | project or system | fully reproducible environments | large conceptual and disk cost |

### What "global" means today

There is no single global Python state that is safe to modify:

- **System Python** (`/usr/bin/python3`) is owned by the distribution.
  Debian and Ubuntu mark it `EXTERNALLY-MANAGED` (PEP 668). `pip install`
  into it is refused by default, and forcing it can break `apt`.
- **User site** (`~/.local/lib/python3.X/site-packages`) is global to the
  user, not to a project. It is where `pip install --user` goes. It is a
  reasonable place for a tiny script, not for project dependencies.
- **`pipx`** gives each CLI tool its own venv under `~/.local/pipx`. That
  is the modern replacement for "install this tool globally".
- **Project venv** (`.venv`) is local to the checkout. The project should
  record its dependencies in `pyproject.toml` (and a lock file), not in a
  global list.
- **Conda base** is global to the conda installation. Treat it like system
  Python: do not install project packages into `base`.

### Recommended default model

Start with the smallest model that covers almost everything:

1. **Project libraries and applications:** a project-local `.venv`,
   created with `uv venv` when `uv` is available, otherwise
   `python3 -m venv`. Keep `virtualenv` as an explicit fallback:
   `COAT_PYTHON_VENV_BACKEND=virtualenv`.
2. **Command-line tools:** `pipx install <tool>` (or `uv tool install` when
   the user chooses `uv`). Never `pip install` a CLI tool into the system.
3. **System packages:** only through `apt` (or the distro package manager),
   and only when the tool is part of the system. Do not use `sudo pip`.
4. **Interpreter versions:** prefer the distro `python3`, `uv python`, or
   `pyenv`; do not use `update-alternatives` as the default.
5. **Activation:** support both explicit activation
   (`source .venv/bin/activate`) and direct interpreter use
   (`.venv/bin/python`, `.venv/bin/pip`, `uv run`). The helper must not
   force a directory change.
6. **Locking:** prefer `uv.lock`, `poetry.lock`, `pdm.lock` or
   `requirements.txt` with hashes. The helper should detect the file and
   tell the user what it will use.

`virtualenv` remains fully supported. It is not the default only because
`python3 -m venv` is already there; the user can set it as the backend.

## Proposed interface

Names are provisional; the next session can rename them after a short
review. Prefer functions over aliases, because functions can validate.

| Command | Meaning |
|---------|---------|
| `pyvenv [dir]` | create `.venv` (or `dir`) with the selected backend; print the activation command |
| `pyactivate [dir]` | `source <dir>/bin/activate`; no `cd` |
| `pydeactivate` | `deactivate` if active |
| `pystatus` | show interpreter, venv, backend, `sys.path`, `.venv` presence |
| `pyinstall <pkg...>` | install into the active/project venv; refuse outside a venv |
| `pyrequirements [file]` | `pip install -r` into the active/project venv |
| `pysync` | install from the detected lock/requirements file |
| `pytool <tool>` | `pipx install` / `uv tool install`; never system pip |
| `pyrun <cmd...>` | run with the project interpreter (`uv run`, `poetry run`, or `.venv/bin/...`) |
| `pyversion` | show/select an interpreter (no `sudo update-alternatives`) |
| `pyclean` | remove `.venv` after confirmation; never remove a global env |
| `pylock` | create/update the lock file with the chosen backend |

Configuration in `.coatrc` (not in the module):

```bash
# project venv backend: auto | venv | virtualenv | uv | poetry | pdm | conda
export COAT_PYTHON_VENV_BACKEND=auto
# default folder for a new project venv
export COAT_PYTHON_VENV_DIR=.venv
# where pipx keeps its tools (default is fine)
# export PIPX_HOME="$HOME/.local/pipx"
# export PIPX_BIN_DIR="$HOME/.local/bin"
# prefer this interpreter for new venvs
# export COAT_PYTHON="python3"
```

Detection order for `auto`:

1. `uv.lock` or `pyproject.toml` with `[tool.uv]` -> `uv`;
2. `poetry.lock` -> `poetry`;
3. `pdm.lock` -> `pdm`;
4. `requirements.txt` -> `.venv` + `pip` (or `uv pip` if selected);
5. no project file -> create `.venv` with `python3 -m venv`;
6. `virtualenv` only when the user set it explicitly or `python3 -m venv`
   is unavailable.

The helper must never guess "the global Python" and must never run `sudo`.

## Migration plan

1. **Inventory and classify** every current Python use (`python`, `pip`,
   `python3`, `virtualenv`, `venv`, `pipx`, `uv`, `poetry`, `pyenv`,
   `conda`). Keep the table in this document up to date.
2. **Decide the default backend** with the user. Recommendation: `auto`,
   with `venv` then `virtualenv` as the fallback, and `uv` when its files
   are present.
3. **Write the new `modules/python.sh`** as functions. Keep the old names
   only as thin, documented wrappers for one release:
   - `makevenv` -> `pyvenv`
   - `makeactive` -> `pyactivate`
   - `makeactiver` -> `pyactivate` with an upward search, no `cd`
   - `installrequirements` -> `pyrequirements`
   - `switchpython` -> `pyversion` (no sudo by default)
4. **Move all knobs to `.coatrc`** (backend, folder, interpreter, pipx
   paths). The module should have safe defaults.
5. **Fix the old Python 2 helpers** (`lc`, `uc`, `urldecode`, `urlencode`,
   `server`, `json`) or move them to a text/HTTP module. Use `python3`
   with `-c` and `sys.stdin`/`sys.argv`.
6. **Tests**: add cases that stub `python3`, `virtualenv`, `uv`, `pipx`
   and assert:
   - no `sudo` and no system pip in any path;
   - `pyvenv` creates the requested directory and does not `cd`;
   - `pyactivate` changes `VIRTUAL_ENV` and `PATH`;
   - `pyinstall` refuses outside a venv;
   - `pytool` calls `pipx`/`uv tool`, not `pip`;
   - `pystatus` reports the detected backend.
7. **Docs**: update `docs/manual.md`, `README.md`, the grimoire description
   and the `.coatrc.example` comments.
8. **Remove** the old aliases only after the wrappers and tests pass.

## Acceptance criteria

- A fresh shell on Debian/Ubuntu with PEP 668 can create a project venv,
  activate it, install from `requirements.txt`, and run the project without
  `sudo` and without touching the system Python.
- `virtualenv` is selectable and works.
- `uv`, `poetry`, `pdm`, `conda` and plain `venv` are detected or
  selectable; none is silently assumed.
- `pipx` is the documented way to install CLI tools; no helper installs a
  CLI tool into the global Python.
- Every helper prints what it is about to do and fails with a clear message
  when it cannot.
- No helper changes the current directory as a side effect.
- The old names still work through documented wrappers during migration.
- `make test`, `make syntax` and `make shellcheck` pass; the Python tests
  do not need network access.

## Decisions already made

- The old names (`makevenv`, `makeactive`, `makeactiver`,
  `installrequirements`, `switchpython`) stay as documented wrappers
  during the migration.
- `virtualenv` remains one supported alternative; it is not removed.
- No helper calls `sudo update-alternatives` or installs into the system
  Python.

## Open questions for the user

- Default backend: `auto`, `venv`, `virtualenv`, or `uv`?
- Should `uv` be a hard dependency for the fast path, or only an optional
  accelerator?
- Is `pipx` acceptable as the default for CLI tools, or is `uv tool`
  preferred?
- Should the helper support `conda`/`mamba`, or is that a separate task?
- Should activation be automatic via `direnv`, or explicit only?
- Do we need a per-project `.python-version` file, and which tool owns it?

## References

- Python Packaging User Guide: virtual environments and `pipx`.
- PEP 668: Marking Python base environments as "externally managed".
- `python3 -m venv` documentation.
- `virtualenv` documentation.
- `pipx` documentation.
- `uv` documentation (`uv venv`, `uv pip`, `uv tool`, `uv run`).
- `poetry`, `pdm`, `hatch`, `conda`/`mamba` documentation, if chosen.
