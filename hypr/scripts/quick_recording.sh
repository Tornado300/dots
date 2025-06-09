#!/bin/zsh

PID=$(pgrep wf-recorder)
rm /tmp/recording.mp4

if [ -z "$PID" ]; then
	wf-recorder -y -a -g "$(slurp -c 00ff00 -o)" -f "/tmp/recording.mp4" 
else
	kill "$PID"
fi

echo "file:///tmp/recording.mp4" | wl-copy --type text/uri-list
