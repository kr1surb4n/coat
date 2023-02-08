#!/bin/bash
source $HOME/.coatrc

# pull submodules
git submodule update --init

# run fzf install
sh lib/fzf/install

# create coat files
> $COAT_STORAGE/status
> $COAT_STORAGE/teleports
> $COAT_STORAGE/spot
> $COAT_STORAGE/bookmarks
