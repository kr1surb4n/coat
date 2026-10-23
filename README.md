Coat
====

Coat is an overlay over the command line, that groups several
tools together, in an attempt to change the experience
of working with shell.

The philosophy:

I don't want to work, I want to have fun without an interuption every 10 seconds.

Coat uses/binds:
- bash
- bash-completion
- fzf
- tmux
- git
- python
- python watchdog
- ansible
- foxer
- paczki
- cookiecuter
- GNU make

It is not inteded as a framework like Bash-it. Although,
it is intended to be easily modified and explored.

Dotfiles you have to provide by yourself.

Features
========

- out of the box fzf
- a collection of Bash aliases (all described in Spells)
- a collcetion of usefull Bash functions (all described in Spells)
- loading the bash completion files
- git aliases and helpers
- mark folder & jump back to folder
- folder bookmarks
- scaffold for Bash shourtcuts, with few useful already defined
- bind hack to start interactive commands through bash shortcuts 
- browser profile manager (foxer) 
- template files (paczki), ready for use with paczekfiller (ALT + n); files ending in `.tpl` ask for their `{{ variable }}` values before landing in the current folder
- Spells 
  - a list of commands that you can run, or use to build bigger chained CLI commands
  - open the Spellbook using ALT + s
  - fzf helps you to find the right command
  - connect to other hosts using SSH
  - and more
- Grimoire (ALT + h)
  - every function and alias Coat defines, with the comment above it
  - fzf preview shows the definition, Enter types the name into the prompt
  - the fastest way to find a spell you forgot the name of

Installation
============

Useful order of reading:
- .gitmodules
- .coatrc.example
- coat.sh
- install.sh
- modules/variables.sh
- modules/shortcuts.sh
- modules/prompt.sh
- modules/organizations.sh
- modules/simplifications.sh
- modules/spells.sh
- modules/grimoire.sh

### Warning

This package is ment mostly for Ubuntu/Debian.

### Requirements

tmux
bash
bash-completion
fzf
tmux
tmuxp
git
python3

### Installation

1. clone this repo
2. modify the .coatrc.example file and save it in your home folder under the name .coatrc
3. run git submodules update --init --recursive
4. source .coatrc file at the end of your .bashrc file
5. have fun

or

use the install.sh script.
It will link this folder as ~/.coat, pull the submodules and source your ~/.coatrc.
It will create the runtime files in $COAT_STORAGE, the ~/temp folder with the
file used by the cd function, and an empty ~/.env for the machine specific settings.


Code that influenced Coat
=========================

https://github.com/mathiasbynens/dotfiles.git
https://github.com/Bash-it/bash-it.git 

and many more which I have stumbled upon
through all my years of work.
