#!/bin/bash
DELTA=$1

NODE_ID=$(pw-dump 2>/dev/null | python3 -c "
import json, sys
data = json.load(sys.stdin)

# find pipewire client IDs belonging to spotify
client_ids = {
    str(n.get('id'))
    for n in data
    if n.get('info', {}).get('props', {}).get('application.process.binary') == 'spotify'
}

# find the audio output node for those clients
for n in data:
    props = n.get('info', {}).get('props', {})
    if str(props.get('client.id')) in client_ids and props.get('media.class') == 'Stream/Output/Audio':
        print(n.get('id'))
        break
")

[[ -z "$NODE_ID" ]] && exit 1
wpctl set-volume "$NODE_ID" "${DELTA}"
