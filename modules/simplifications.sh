#!/bin/bash

# Put the clipboard on stdout (paste)
alias clip-out="xclip -o -selection clipboard"

# Read stdin into the clipboard (copy)
alias clip-in="xclip -i -selection clipboard"

# Polish spellings of the two clipboard actions above
alias pusc="clip-out"
alias wez="clip-in"
alias kopjuj="clip-in"
alias wklej="clip-out"

# Open a file in the running Emacs and return to the shell right away
alias emacs-read="emacsclient -nqu"
