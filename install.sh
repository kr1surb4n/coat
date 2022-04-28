#!/bin/bash
source $HOME/.coatrc

# TODO add additional repositories with software
# install ubuntu packages
cat $COAT_PACKAGES/apt_packages | xargs sudo apt -mfy install

# install python packages
pip3 install -r $COAT_PACKAGES/python3_packages

# make folders
mkdir ~/archive ~/bin ~/docs ~/range ~/workshops ~/library ~/temp ~/Portal ~/sync

# pull submodules
git submodule update --init

# run fzf install
sh lib/fzf/install

# create coat files
> $COAT_STORAGE/status
> $COAT_STORAGE/teleports
> $COAT_STORAGE/spot
> $COAT_STORAGE/bookmarks

# add coat to .bashrc
echo "source $HOME/.coatrc" >> ~/.bashrc
source ~/.bashrc