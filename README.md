# cdn77-sync-action

This action is pushing a specified directory to a CDN77 storage via rsync
and purges the files afterwards via CDN77-API.
The purge requests are executed in chunks so that the CDN77-API limits can be respected.

## Pre-Requisites
* To use this action you need a CDN77 storage and its credentials.
* Create an ssh key pair
    * The private key should be set in the repository secrets. Check usage section.
    * The public key must be added to the `/.ssh/authorized_keys` file on the CDN77 storage.
* Create an CDN77-API token.


## Inputs

* `source_path`: Directory that should be synced to the CDN77 storage.

* `destination_path`: Destination path on the remote CDN77 storage.

* `cdn77_storage_host`: The CDN77 storage hostname.

* `cdn77_storage_user`: The CDN77 storage username.

* `cdn77_storage_private_key`: A private key that secures communication to the remote storage.

* `cdn77_resource_id`: The ID of the CDN77 resource.

* `cdn77_api_token`: The CDN77 API token.

* `cdn77_api_purge_limit`: The amount of files that should be sent within a single purge request. Default: `1750`.

## Example usage
```yaml
      - name: Sync files to CDN77
        uses: findologic/cdn77-sync-action@1.0.0
        with:
            source_path: /MY/SOURCE/PATH/
            destination_path: /MY/DESTINATION/PATH/
            cdn77_storage_host: xy-host.cdn77.com
            cdn77_storage_user: xy-username
            cdn77_storage_private_key: ${{ secrets.SSH_PRIVATE_KEY }}
            cdn77_resource_id: 1234
            cdn77_api_token: 1234_MY_TOKEN
```