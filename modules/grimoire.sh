#!/bin/bash

# Grimoire
#
# The list of every function and alias Coat defines. Pick one and its name
# is typed into the command line, ready for arguments.
#
# ALT + h -- open the grimoire

# how often each command was used, from the experience log
coat_spell_uses() {
  [ -s "${XP_LOG:-}" ] || return 0
  awk -F'\t' '{ split($4, word, " "); if (word[1] != "") print word[1] }' "$XP_LOG" \
    | sort | uniq -c | awk '{ print $2 "\t" $1 }'
}

# Print one tab separated row per function and alias:
# name, kind, module, the comment above it, file:line, times it was used
coat_index() {
  local module_file rows uses

  rows=$(
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
  )

  uses=$(coat_spell_uses)

  # no modules, or the modules are empty
  [ -n "$rows" ] || return 0

  printf '%s\n' "$rows" | awk -F'\t' -v OFS='\t' -v uses="$uses" '
    # count the uses first, keyed by the command name
    BEGIN {
      n = split(uses, lines, "\n")
      for (i = 1; i <= n; i++) {
        if (split(lines[i], part, "\t") == 2) u[part[1]] = part[2]
      }
    }
    { print $0, (u[$1] + 0) }
  '
}

# Open the grimoire and type the chosen spell into the prompt
grimoire() {
  local pick name

  pick=$(coat_index | fzf --delimiter='\t' --with-nth=1,6,2,3,4 \
    --prompt='grimoire> ' \
    --header='name uses kind module description | Enter: type the spell' \
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
