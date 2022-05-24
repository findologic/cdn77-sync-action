#!/bin/bash

DESTINATION="$CDN77_USER@$CDN77_HOST:$DESTINATION_PATH"
rsync --dry-run -arzO --out-format="%o %n" --delete $SOURCE_PATH $DESTINATION