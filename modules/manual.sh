#!/bin/bash

# Manual -- the Coat manual, one fzf window with every section.
#
# ALT + m opens it.  A word after the command is typed into the search:
#   manual quest

MANUAL_FILE="${MANUAL_FILE:-$PATH_TO_COAT/docs/manual.md}"

# one row per section: title, first line, last line
manual_index() {
  awk '
    /^## / {
      if (start) print title "\t" start "\t" NR - 1
      title = substr($0, 4); start = NR
    }
    END { if (start) print title "\t" start "\t" NR }
  ' "$MANUAL_FILE"
}

# print one section, in the pager when there is a terminal
manual_open() {
  local start=$1 end=$2

  if [ -t 1 ] && command -v less >/dev/null; then
    sed -n "${start},${end}p" "$MANUAL_FILE" | less -R
  else
    sed -n "${start},${end}p" "$MANUAL_FILE"
  fi
}

# the whole manual in the pager
manual_all() {
  if [ -t 1 ] && command -v less >/dev/null; then
    less -R "$MANUAL_FILE"
  else
    cat "$MANUAL_FILE"
  fi
}

# open the manual: pick a section, or the whole thing with an option
manual() {
  local query="${1:-}" pick start end

  if [ ! -f "$MANUAL_FILE" ]; then
    echo "manual: $MANUAL_FILE is missing" >&2
    return 1
  fi

  case "$query" in
    --all|all) manual_all; return ;;
    --path|path) printf '%s\n' "$MANUAL_FILE"; return ;;
  esac

  # without fzf the whole manual is still readable
  if ! command -v fzf >/dev/null; then
    manual_all
    return
  fi

  pick=$(manual_index | fzf --delimiter='\t' --with-nth=1 \
    --prompt='manual> ' --query="$query" \
    --header='Enter: read the section' \
    --preview "sed -n '{2},{3}p' \"$MANUAL_FILE\"" \
    --preview-window='right:65%:wrap') || return 0

  # nothing picked, nothing to do
  [ -n "$pick" ] || return 0

  start=$(printf '%s' "$pick" | cut -f2)
  end=$(printf '%s' "$pick" | cut -f3)
  manual_open "$start" "$end"
}
