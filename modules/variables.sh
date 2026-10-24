#!/bin/bash

export QUICK_STATUS=$PATH_TO_COAT/storage/status

export GREP_OPTIONS=""

# batcat  fails without it
export BAT_PAGER="less -RF"

# colored GCC warnings and errors
export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'
