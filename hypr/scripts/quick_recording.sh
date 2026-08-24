#!/bin/zsh


PID=$(pgrep wf-recorder)

if [ -z "$PID" ]; then
	rm /tmp/recording.mp4
	notify-send "Start RECORD"
	wf-recorder -y -a -g "$(slurp -c 00ff00 -o)" -f "/tmp/recording.mp4" 
else
	kill "$PID"
	notify-send "Stoped RECORD"
fi

echo "file:///tmp/recording.mp4" | wl-copy --type text/uri-list
