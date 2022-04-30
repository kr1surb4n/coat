#!/bin/bash
#########################
# import important components
#########################

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
source $PATH_TO_COAT/modules/git.sh
source $PATH_TO_COAT/modules/python.sh
source $PATH_TO_COAT/modules/spells.sh
source $PATH_TO_COAT/modules/shortcuts.sh
source $PATH_TO_COAT/modules/autocomplete.sh

# prompt is going last
source $PATH_TO_COAT/modules/prompt.sh
