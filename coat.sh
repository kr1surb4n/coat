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

# the load order is explicit; a later module may override an earlier alias or function
COAT_MODULE_ORDER=(
  variables
  aliases
  bash_functions
  organization
  simplifications
  git
  python
  xp
  quest
  dungeon
  spells
  grimoire
  manual
  shortcuts
  autocomplete
  prompt
)

for _coat_module in "${COAT_MODULE_ORDER[@]}"; do
  source "$PATH_TO_COAT/modules/${_coat_module}.sh"
done
unset _coat_module

# the command log starts after every module is loaded, so loading itself is not counted
COAT_XP_READY=1
