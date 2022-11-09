#!/usr/bin/bash -xv

# This script is pushing a specified directory to a CDN77 storage via rsync
# and purges the files afterwards via CDN77-API.
# The purge requests are executed in chunks so that the CDN77-API limits can be respected.

set -e

function upload_to_cdn_storage() {
  # start ssh agent and add key
  eval "$(ssh-agent)"
  echo "$INPUT_CDN77_STORAGE_PRIVATE_KEY" | ssh-add -

  CDN77_BASE_PATH="/www"
  CDN77_DESTINATION="$INPUT_CDN77_STORAGE_USER@$INPUT_CDN77_STORAGE_HOST:$CDN77_BASE_PATH/$INPUT_DESTINATION_PATH"

  # sync files to CDN77
  # TODO: Ensure that destination path exists.
  rsync --archive --recursive --compress --progress --from0 --out-format="%o %n" --delete -e "ssh -o StrictHostKeyChecking=no" "$INPUT_SOURCE_PATH" "$CDN77_DESTINATION"

  # close ssh agent
  eval "$(ssh-agent -k)"
}

function upload_to_google_cloud_storage() {
  gsutil -m rsync -r "$INPUT_SOURCE_PATH" "gs://$INPUT_GCS_BUCKET/$INPUT_DESTINATION_PATH"
}

function purge_cdn() {
  # process files in chunks of the defined limit
  (cd "$INPUT_SOURCE_PATH" && find "$INPUT_SOURCE_PATH" -type f) | while readarray -tn "$INPUT_CDN77_API_PURGE_LIMIT" CHUNK && ((${#CHUNK[@]})); do
    echo -e "\nPurge next $INPUT_CDN77_API_PURGE_LIMIT files."

    # use jq to create JSON array
    JSON_FILE_ARRAY=$(printf "$INPUT_DESTINATION_PATH%s\n" "${CHUNK[@]}" | jq -R . | jq -s .)
    JSON_PAYLOAD="{\"paths\":$JSON_FILE_ARRAY}"

    # send purge request to CDN77 API
    curl --silent --show-error --fail "https://api.cdn77.com/v3/cdn/${INPUT_CDN77_RESOURCE_ID}/job/purge" \
      --header "Authorization: Bearer ${INPUT_CDN77_API_TOKEN}" --data "${JSON_PAYLOAD}"
  done
}

function wait_for_pids() {
  local PIDS=("$@")

  for PID in "${PIDS[@]}"; do
    wait "$PID"
    EXIT_CODE="$?"
    if [ $EXIT_CODE -ne 0 ]; then
      exit "$EXIT_CODE"
    fi
  done

  return 0
}

function refresh_configs() {
  echo ""
  # TODO: Call Account Backend to refresh configs
}

PIDS=()
upload_to_cdn_storage &
PIDS+=($!)
upload_to_google_cloud_storage &
PIDS+=($!)

wait_for_pids "${PIDS[@]}"

purge_cdn
refresh_configs
