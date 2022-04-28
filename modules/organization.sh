#!/bin/bash

__watson_prompt() {

	if [[ "$(watson status)" != "No project started." ]]; then
		# watson_project=`watson status | awk '{ print $2 }'`
		echo -e "🚧 $(watson status | awk '{ print $2 }')"
	else
		echo -e ""
	fi
}

# Spot File a.k.a Teleport Back
# 
# Mark a spot, or a location. Use 
# current location copy&paste
[ ! -a $SPOT_FILE ] && eval "touch ${SPOT_FILE}"

alias mark='pwd > $SPOT_FILE'
alias spot='cat $SPOT_FILE'
alias goto='cd `spot`'

# folder bookmarks with fzf
# 
# ALT + g - open the bookmarks
# see shourtcuts.sh
[ ! -a $FOLDER_BOOKMARK_FILE ] && eval "touch ${FOLDER_BOOKMARK_FILE}"
alias bookmarkfolder='pwd >> $FOLDER_BOOKMARK_FILE'

# look for list of files
#
# this is binded to the alt + g
alias cdg='cat $FOLDER_BOOKMARK_FILE | fzf'
unalias cdg 2> /dev/null
cdg() {
   local dest_dir=$(cat $FOLDER_BOOKMARK_FILE | fzf )
   if [[ $dest_dir != '' ]]; then
      cd "$dest_dir"
   fi
}
export -f cdg > /dev/null