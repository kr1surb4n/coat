#!/bin/bash
source $HOME/.coatrc

# pull submodules
git submodule update --init

# fzf comes from the system, install it with: sudo apt install fzf

# create coat files
> $COAT_STORAGE/status
> $COAT_STORAGE/teleports
> $COAT_STORAGE/spot
> $COAT_STORAGE/bookmarks
