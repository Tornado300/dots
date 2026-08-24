#!/usr/bin/env sh
multiple="$1"
directory="$2"
save="$3"
path="$4"
out="$5"
debug="$6"
set -e
if [ "$debug" = 1 ]; then
    set -x
fi
echo "=== $(date) ===" >> /tmp/wrapper-debug.log
echo "multiple=$1 directory=$2 save=$3 path=$4 out=$5" >> /tmp/wrapper-debug.log
cmd="yazi"
termcmd="${TERMCMD:-kitty --title 'termfilechooser'}"
if [ "$save" = "1" ]; then
    default_name=$(basename -- "$path")
    default_dir=$(dirname -- "$path")
    cmd="env YAZI_SAVE_MODE=1 YAZI_CHOOSER_FILE=\"$out\" YAZI_SAVE_DEFAULT_NAME=\"$default_name\" yazi"
    set -- "$default_dir"
elif [ "$directory" = "1" ]; then
    set -- --chooser-file="$out" --cwd-file="$out"".1" "$path"
elif [ "$multiple" = "1" ]; then
    set -- --chooser-file="$out" "$path"
else
    set -- --chooser-file="$out" "$path"
fi
command="$termcmd $cmd"
for arg in "$@"; do
    escaped=$(printf "%s" "$arg" | sed 's/"/\\"/g')
    command="$command \"$escaped\""
done
echo "command=$command" >> /tmp/wrapper-debug.log
sh -c "$command"
if [ "$directory" = "1" ]; then
    if [ ! -s "$out" ] && [ -s "$out"".1" ]; then
        cat "$out"".1" > "$out"
        rm "$out"".1"
    else
        rm "$out"".1"
    fi
fi
