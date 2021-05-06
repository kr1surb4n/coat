#!/bin/bash

# set system wide makefiles
export MAKEFILES="$PATH_TO_COAT/paczki/git/Makefile \
                  $PATH_TO_COAT/paczki/docker/Makefile \
                  $PATH_TO_COAT/paczki/python/Makefile"


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
        pid=$(ps -ef | sed 1d | fzf -m | awk '{print $2}')
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

