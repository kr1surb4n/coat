#!/bin/bash

# work from the coat folder, no matter where the script is called from
cd "$(dirname "$0")" || exit 1
COAT_DIR=$(pwd)

# .coatrc holds the machine specific paths and loads the aliases, without it we stop
if [ ! -f "$HOME/.coatrc" ]; then
  echo "~/.coatrc is missing: copy $COAT_DIR/.coatrc.example to ~/.coatrc and edit it" >&2
  exit 1
fi

# link the coat folder into the home folder, .coatrc expects it there
if [ -e "$HOME/.coat" ] || [ -L "$HOME/.coat" ]; then
  # a link to another folder would load a different coat, so stop
  if [ "$(readlink -f "$HOME/.coat")" != "$COAT_DIR" ]; then
    if [ -L "$HOME/.coat" ]; then
      echo "~/.coat links to $(readlink -f "$HOME/.coat"), not to $COAT_DIR" >&2
    else
      echo "~/.coat exists and is not a link to $COAT_DIR" >&2
    fi
    echo "fix or remove ~/.coat, then run this script again" >&2
    exit 1
  fi
  echo "~/.coat already points to $COAT_DIR"
else
  ln -s "$COAT_DIR" "$HOME/.coat"
  echo "linked ~/.coat to $COAT_DIR"
fi

# the paths from .coatrc are what the rest of this script works with
source "$HOME/.coatrc"

# without COAT_STORAGE the runtime files would land in /
if [ -z "${COAT_STORAGE:-}" ]; then
  echo "COAT_STORAGE is not set in ~/.coatrc" >&2
  exit 1
fi

# pull the submodules
git submodule update --init

# create the runtime files, keep the ones that already hold something
mkdir -p "$COAT_STORAGE"
for _coat_file in status teleports spot bookmarks; do
  [ -f "$COAT_STORAGE/$_coat_file" ] || : > "$COAT_STORAGE/$_coat_file"
done
unset _coat_file

# the cd function writes the folder we came from into this file
mkdir -p "$HOME/temp"
touch "$HOME/temp/current_dir"

# machine specific settings live here, .coatrc sources it when it exists
touch "$HOME/.env"
