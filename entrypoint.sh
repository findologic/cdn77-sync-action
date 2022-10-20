#!/usr/bin/bash

# This script is pushing a specified directory to a CDN77 storage via rsync
# and purges the files afterwards via CDN77-API.
# The purge requests are executed in chunks so that the CDN77-API limits can be respected.

INPUT_CDN77_STORAGE_PRIVATE_KEY=$(cat ~/.ssh/id_rsa)


set -e

CDN77_BASE_PATH="/www"
CDN77_DESTINATION="$INPUT_CDN77_STORAGE_USER@$INPUT_CDN77_STORAGE_HOST:$CDN77_BASE_PATH/$INPUT_DESTINATION_PATH"

# start ssh agent and add key
eval "$(ssh-agent)"
echo "$INPUT_CDN77_STORAGE_PRIVATE_KEY" | ssh-add -

# sync files to CDN77
# TODO: Ensure that destination path exists.
rsync --archive --recursive --compress --from0 --out-format="%o %n" --delete -e "ssh -o StrictHostKeyChecking=no" "$INPUT_SOURCE_PATH" "$CDN77_DESTINATION"

# close ssh agent
eval "$(ssh-agent -k)"

gsutil -m rsync -r "$INPUT_SOURCE_PATH" "gs://$INPUT_GCS_BUCKET/$INPUT_DESTINATION_PATH"

# process files in chunks of the defined limit
(cd "$INPUT_SOURCE_PATH" && find "$INPUT_SOURCE_PATH" -type f) | while readarray -tn "$INPUT_CDN77_API_PURGE_LIMIT" CHUNK && ((${#CHUNK[@]})); do
  echo "Purge next $INPUT_CDN77_API_PURGE_LIMIT files."

  # use jq to create JSON array
  JSON_FILE_ARRAY=$(printf "$INPUT_DESTINATION_PATH%s\n" "${CHUNK[@]}" | jq -R . | jq -s .)
  JSON_PAYLOAD="{\"paths\":$JSON_FILE_ARRAY}"

  # send purge request to CDN77 API
  curl "https://api.cdn77.com/v3/cdn/${INPUT_CDN77_RESOURCE_ID}/job/purge" -sS \
    --header "Authorization: Bearer ${INPUT_CDN77_API_TOKEN}" --data "${JSON_PAYLOAD}"
done
