# gdrive-rclone-sync

Periodically sync a local file with an `rclone` remote (tested with Google Drive, but should work with others as well)

## Setup

1. Clone this repository
2. `cd` into config directory & create `rclone` config:
    ```shell
    RCLONE_CONFIG="$(pwd)/rclone.conf" rclone config
    ```
3. Create `.env` from template:
    ```shell
    cp .env.template .env
    ```
4. Add values to `.env` file:
    - `REMOTE_NAME`: Name of your configured `rclone` remote
    - `REMOTE_FILE_NAME`: Name of file (on remote) that will be synced
5. Start container:
    ```shell
    podman compose up
    ```

### Configuration

There are more values you can set in your `.env` file:
 - `DELTA_THRESHOLD_IN_S` (default=`30`): Local/remote file has to be at least this many seconds newer than the other to sync
 - `SLEEP_IN_S` (default=`60`): Duration to wait after every loop (lower value = more frequent sync)
 - `DEBUG` (default=`false`): Print debug information in logs. Possible values:
     - `true`: Print all debug information
     - `script`: Print debug information from the sync script itself
     - `rclone`: Make rclone output verbose

