#!/bin/bash

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

# kill processes
show_process_id () {
  ps -ef | grep $1 | awk '{print $2}'
}

alias processids='show_process_id'
alias kknd='kill -s KILL'

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

# run servers
alias runserver='python -m http.server 8000'
alias phpserver='php -S 127.0.0.1:8000'

# switch mouse layout
alias lefthandmouse='xmodmap -e "pointer = 3 2 1"'
alias righthandmouse='xmodmap -e "pointer = 1 2 3"'


# TODO add more keys or automatic key search
# add ssh-key to ssh-agent when key exist
if [ "$SSH_AUTH_SOCK" != "" ] && [ -f ~/.ssh/id_rsa ] && [ -x /usr/bin/ssh-add  ]; then
  ssh-add -l >/dev/null || alias ssh='(ssh-add -l >/dev/null || ssh-add) && unalias ssh; ssh'
fi

function fill() {
	read -ep "$1" variable
	echo $variable
}

