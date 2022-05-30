#!/bin/bash

# This script is pushing a specified directory to a CDN77 storage via rsync
# and purges the files afterwards via CDN77-API.
# The purge requests are executed in chunks so that the CDN77-API limits can be respected.

CDN77_BASE_PATH="/www"
DESTINATION="$INPUT_CDN77_USER@$INPUT_CDN77_HOST:$CDN77_BASE_PATH/$INPUT_DESTINATION_PATH"

# start ssh agent and add key
eval "$(ssh-agent)"
echo "$INPUT_CDN77_PRIVATE_KEY" | ssh-add -

# sync files to CDN77
FILES_TO_PURGE=($(rsync -arzO --out-format="%o %n" --delete -e "ssh -o StrictHostKeyChecking=no" "$INPUT_SOURCE_PATH" "$DESTINATION" | cut -d ' ' -f 2))

# close ssh agent
eval "$(ssh-agent -k)"

# process files in chunks of the defined limit
for((i=0; i < ${#FILES_TO_PURGE[@]}; i+=INPUT_CDN77_PURGE_LIMIT))
do
  echo "Purge next $INPUT_CDN77_PURGE_LIMIT files."
  chunk=( "${FILES_TO_PURGE[@]:i:INPUT_CDN77_PURGE_LIMIT}" )

  # use jq to create JSON array
  JSON_FILE_ARRAY=$(printf "$INPUT_DESTINATION_PATH%s\n" "${chunk[@]}" | jq -R . | jq -s .)
  JSON_PAYLOAD="{\"paths\":$JSON_FILE_ARRAY}"

  # send purge request to CDN77 API
  curl "https://api.cdn77.com/v3/cdn/${INPUT_CDN77_RESOURCE_ID}/job/purge" -sS --header "Authorization: Bearer ${INPUT_CDN77_API_TOKEN}" --data "${JSON_PAYLOAD}"
done