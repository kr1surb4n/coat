#!/bin/bash

# install ubuntu packages
cat packages/apt_packages | xargs sudo apt -mfy install

# install python packages
pip3 install -r packages/python3_packages

source packages/npm_packages

cp -fr .* ~/
cp -fr bin ~/

# make folders
mkdir ~/archive ~/docs ~/workshops ~/library ~/temp ~/Portal ~/sync
