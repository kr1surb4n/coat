#!/bin/bash
set -o pipefail

# IMPORTANT!
# 
# the variables are defined inside the ~/.coatrc file


# # Spells
#
# A spell is a function cast by the User.
# You will find here functions that allow you to cast
# many spells.
#
# # A spell is written in a text file in the format:
# 
# echo "The spell description"; the command ...
#
# # To ask user for values use this way:
#
# read -ep "The Prompt: " the_variable_with_the_value && echo $the_variable_with_the_value
# 
# # Grouping of the spells
#
# Group the spells in files. One spell per line. 
# The spell casting command uses `cat` to read the files with the spells. 
# You can use it to concatente the spells like this: 
# 
# export MAGIC_BOOK="$PATH_TO_BASH_COMMANDS \
#                    $PATH_TO_GIT_COMMANDS \
#                    ... \ 
#                   "
# 
# # List of functions
# 
# eval_line_with_fzf     -- will cast spells written in the variable $MAGIC_BOOKS
#                           default shortcut: ALT + s 
#
# insert_line_with_fzf   -- will type in the spell in the command line, for tmux
#                           default shortcut: ALT + w 
# 
# type_line_with_fzf     -- will type in the spell in the command line, for xdotool
#
# connect_with_ssh       -- will connect you to the a selected host through ssh
#
# call_a_workshop        -- will ask you which tmuxp configuration to load 
#
# save_the_workshop      -- will save you the current tmux session, you will be asked for the name

function eval_line_with_fzf {
    command=$(cat $MAGIC_BOOKS | fzf)
    eval "${command/echo*\";/}"
    # source "${command/echo*\";/}"
}

function insert_line_with_fzf {
    command=$(cat $MAGIC_BOOKS | fzf)
    # TODO save to history what you paste
    tmux send-keys "${command/echo*\";/}"
}

function type_line_with_fzf {
    command=$(cat $MAGIC_BOOKS | fzf)
	  xdotool type "${command/echo*\";/}"
}

function connect_with_ssh {
	exec $(cat $TELEPORTS | fzf)
}

function watchmedo_command {
   watchmedo shell-command -W --patterns="${1}" --recursive --command="${2}" $3
}

function call_a_workshop {
   tmuxp load $(tmuxp ls | fzf)
}

function save_the_workshop {
   read -p "Name of the workshop: " workshop_name && tmuxp freeze -f yaml -o "${TMUXP_CONFIGDIR}/${workshop_name}.yaml"
}

# choose host to go
alias teleports='exec $(cat $TELEPORTS|fzf)'

# cast a spell
alias spellcast='eval_line_with_fzf'  # ALT + s

# modify a spell
alias spellforge='type_line_with_fzf $MAGI_BOOK' # ALT + w

fman() {
    man -k . | fzf --prompt='Man> ' | awk '{print $1}' | xargs -r man
}

z() {
  local dir
  dir="$(fasd -Rdl "$1" | fzf -1 -0 --no-sort +m)" && cd "${dir}" || return 1
}

spellsave () {
    history | fzf | awk -e '{ $1=""; print $0 }' >> $MAGI_BOOK
}

dirtynotes() {
    history | fzf | awk -e '{ $1=""; print $0 }' >> $DIRTY_NOTES
}

cleardirtynotes() {
    > $DIRTY_NOTES
}

export ANSIBLE_PLAYS=~/docs/systems/playbooks
ansible_command() {
    #host=$(ansible-inventory -y --list | while read -r line; do echo $line; done | sed -e 's/:.*//g'|fzf)	
    playbook=$(find $ANSIBLE_PLAYS -type f -name "*.yml" | fzf)
    ansible-playbook --ask-become-pass $playbook
}
export ansible_command

export COOKIES_LIST="$HOME/.coat/storage/cookies"

makecookie() {
    exec $(cat ${COOKIES_LIST} | fzf)
}

fkill() {
    local pid 
    if [ "$UID" != "0" ]; then
        pid=$(ps -f -u $UID | sed 1d | fzf -m | awk '{print $2}')
    else
        pid=$(ps ax | sed 1d | fzf -m | awk '{print $2}')
    fi  

    if [ "x$pid" != "x" ]
    then
        echo $pid | xargs kill -${1:-9}
    fi  
}

alias linkdocs='find ~/docs/ -path *.git -prune -o -type f -print | fzf | xargs ln -s'
alias edocs='find ~/docs/ -path *.git -prune -o -type f -print | fzf | xargs emacs'
alias putgitignore='find ~/libraly/gitignores -path *.git -prune -o -type f -print | fzf | xargs -I{} cp "{}" . '
alias fmans='fman'


