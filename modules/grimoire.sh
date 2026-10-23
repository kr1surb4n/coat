#!/bin/bash

# Grimoire
#
# The list of every function and alias Coat defines. Pick one and its name
# is typed into the command line, ready for arguments.
#
# ALT + h -- open the grimoire

# Print one tab separated row per function and alias:
# name, kind, module, the comment above it, file:line
coat_index() {
  local module_file
  for module_file in "${COAT_MODULES:-$PATH_TO_COAT/modules}"/*.sh; do
    awk -v module="${module_file##*/}" -v path="$module_file" '
      # remember the comment above, it describes the next definition
      /^#/ { desc = $0; sub(/^#[[:space:]]*/, "", desc); next }
      /^[[:space:]]*$/ { next }
      # spell() { ... }
      /^[A-Za-z_][A-Za-z0-9_]*\(\)/ {
        name = $0; sub(/\(.*/, "", name)
        print name "\tfunc\t" module "\t" desc "\t" path ":" NR
        desc = ""; next
      }
      # function spell { ... }
      /^function[[:space:]]+[A-Za-z_][A-Za-z0-9_]*/ {
        name = $0; sub(/^function[[:space:]]+/, "", name); sub(/[[:space:](].*/, "", name)
        print name "\tfunc\t" module "\t" desc "\t" path ":" NR
        desc = ""; next
      }
      # alias spell=... (names like .. or l. count too)
      /^alias[[:space:]]+[^[:space:]=]+=/ {
        name = $0; sub(/^alias[[:space:]]+/, "", name); sub(/=.*/, "", name)
        print name "\talias\t" module "\t" desc "\t" path ":" NR
        desc = ""; next
      }
      { desc = "" }
    ' "$module_file"
  done | sort -s -t $'\t' -k1,1 -u
}

# Open the grimoire and type the chosen spell into the prompt
grimoire() {
  local pick name

  pick=$(coat_index | fzf --delimiter='\t' --with-nth=1..4 \
    --prompt='grimoire> ' \
    --header='Enter: type the spell | Ctrl-/: preview' \
    --preview 'p={5}; sed -n "${p##*:},$(( ${p##*:} + 20 ))p" "${p%:*}"' \
    --preview-window='right:60%:wrap') || return 0

  # nothing picked, nothing to do
  [ -n "$pick" ] || return 0

  name=${pick%%$'\t'*}

  # called from ALT + h, put the spell in the command line
  if [ -n "${READLINE_LINE+x}" ]; then
    READLINE_LINE="${READLINE_LINE:0:READLINE_POINT}${name}${READLINE_LINE:READLINE_POINT}"
    READLINE_POINT=$(( READLINE_POINT + ${#name} ))
  else
    printf '%s\n' "$name"
  fi
}
