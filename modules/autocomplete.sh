#########################
# autocomplete
#########################

for _complete__file in $BASH_COMPLETION_USER_DIR/*
do
  [[ -f "$_complete__file" ]] && source "$_complete__file"
done