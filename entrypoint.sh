#!/bin/bash

DESTINATION="$INPUT_CDN77_USER@$INPUT_CDN77_HOST:$INPUT_DESTINATION_PATH"

# Start ssh agent and add key
eval "$(ssh-agent)"
echo "$INPUT_CDN77_PRIVATE_KEY" | ssh-add -

# sync files to CDN77
FILES_TO_PURGE=($(rsync -arzO --out-format="%o %n" --delete -e "ssh -o StrictHostKeyChecking=no" "$INPUT_SOURCE_PATH" "$DESTINATION" | cut -d ' ' -f 2))

# Close ssh agent
eval "$(ssh-agent -k)"

# process files in chunks of the defined limit
for((i=0; i < ${#FILES_TO_PURGE[@]}; i+=INPUT_CDN77_PURGE_LIMIT))
do
  part=( "${FILES_TO_PURGE[@]:i:INPUT_CDN77_PURGE_LIMIT}" )

  # use jq to create JSON array
  JSON_FILE_ARRAY=$(printf '/test/%s\n' "${part[@]}" | jq -R . | jq -s .)
  JSON_PAYLOAD="{\"paths\":$JSON_FILE_ARRAY}"

  # Send purge request to CDN77 API
  curl "https://api.cdn77.com/v3/cdn/${INPUT_CDN77_RESOURCE_ID}/job/purge" -sS --header "Authorization: Bearer ${INPUT_CDN77_API_TOKEN}" --data "${JSON_PAYLOAD}"
done