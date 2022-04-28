
#!/bin/bash
set -o pipefail

export SPELLS=~/.coat/storage/spells
export MAGI_BOOK=$SPELLS/magi_book

export BASH_SPELLS=$SPELLS/bash
export DIAGNOSTICS_SPELLS=$SPELLS/diagnostics
export PROGRAMS_SPELLS=$SPELLS/programs
export NET_SPELLS=$SPELLS/network
export DOCKER_SPELLS=$SPELLS/docker
export PGSQL_SPELLS=$SPELLS/postgresql
export GIT_COMMANDS_FILE=$SPELLS/git_commands

export MAGIC_BOOKS="$MAGI_BOOK \
                    $BASH_SPELLS \
                    $DIAGNOSTICS_SPELLS \
                    $PROGRAMS_SPELLS \
                    $NET_SPELLS \
                    $GIT_COMMANDS_FILE \
                    $DOCKER_SPELLS \
                    $PGSQL_SPELLS"

export DIRTY_NOTES=~/.coat/storage/dirty_notes
export TELEPORTS=$PATH_TO_COAT/storage/teleports

unalias spell_find 2>/dev/null


function eval_line_with_fzf {
    command=$(cat $MAGIC_BOOKS | fzf)
    eval "${command/echo*\";/}"
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

function watchmedo_command() {
   watchmedo shell-command -W --patterns="${1}" --recursive --command="${2}" $3
}

# choose host to go
alias teleports='exec $(cat $TELEPORTS|fzf)'

# cast a spell
alias spellcast='eval_line_with_fzf'  # ALT + s
alias sp='spellcast'

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


