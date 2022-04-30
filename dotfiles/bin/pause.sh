#!/bin/bash

export DISPLAY=":0.0"
[ -z $USER ] && USER=$( who | awk '{ print $1 }' | sort | uniq >/tmp/test )
for I in /var/run/gdm3/*; do
    AUTHUSER="`echo $I | awk -F '-' '{ print $3 }'`"
    for J in $USER; do
        [ "${AUTHUSER}" = "${J}" ] || continue
        USER="$J"
        export XAUTHORITY="${I}/database" && break
    done
done
feh /home/kris/bin/crons/alerts/pause.png
