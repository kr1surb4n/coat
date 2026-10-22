#!/bin/bash
source $HOME/.coatrc

# pull submodules
git submodule update --init

# create coat files
> $COAT_STORAGE/status
> $COAT_STORAGE/teleports
> $COAT_STORAGE/spot
> $COAT_STORAGE/bookmarks
