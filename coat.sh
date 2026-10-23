#!/bin/bash
#########################
# import important components
#########################

# load once per shell, the prompt and the key bindings do not need a second run
# the flag is not exported on purpose: every new shell, even after exec, loads coat again
if [ -n "${COAT_SHELL_LOADED:-}" ]; then
  return 0 2>/dev/null || exit 0
fi
COAT_SHELL_LOADED=1

# without the coat folder there is nothing to source, so stop before the noise
if [ -z "${PATH_TO_COAT:-}" ] || [ ! -d "$PATH_TO_COAT" ]; then
  echo "coat: PATH_TO_COAT is not set or does not exist, source ~/.coatrc first" >&2
  return 1 2>/dev/null || exit 1
fi

# fzf
[ -f ~/.fzf.bash ] && source ~/.fzf.bash


#########################
# load modules
#########################

# variables go first
source $PATH_TO_COAT/modules/variables.sh

source $PATH_TO_COAT/modules/aliases.sh
source $PATH_TO_COAT/modules/bash_functions.sh
source $PATH_TO_COAT/modules/organization.sh
source $PATH_TO_COAT/modules/simplifications.sh
source $PATH_TO_COAT/modules/git.sh
source $PATH_TO_COAT/modules/python.sh
source $PATH_TO_COAT/modules/xp.sh
source $PATH_TO_COAT/modules/quest.sh
source $PATH_TO_COAT/modules/dungeon.sh
source $PATH_TO_COAT/modules/spells.sh
source $PATH_TO_COAT/modules/grimoire.sh
source $PATH_TO_COAT/modules/shortcuts.sh
source $PATH_TO_COAT/modules/autocomplete.sh

# prompt is going last
source $PATH_TO_COAT/modules/prompt.sh
