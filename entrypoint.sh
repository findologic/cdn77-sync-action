#!/bin/bash

DESTINATION="$INPUT_CDN77_USER@$INPUT_CDN77_HOST:$INPUT_DESTINATION_PATH"

echo $DESTINATION

eval `ssh-agent`
echo "$INPUT_CDN77_PRIVATE_KEY" | ssh-add -

rsync --dry-run -arzO --out-format="%o %n" --delete -e "ssh -o StrictHostKeyChecking=no" $INPUT_SOURCE_PATH $DESTINATION

eval `ssh-agent -k`