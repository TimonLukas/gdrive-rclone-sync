#!/usr/bin/env sh

set -eou pipefail

missing_env_vars=""

if [ -z "${REMOTE_NAME:-}" ]; then
  missing_env_vars="$missing_env_vars \$REMOTE_NAME"
fi

if [ -z "${REMOTE_FILE_NAME:-}" ]; then
  missing_env_vars="$missing_env_vars \$REMOTE_FILE_NAME"
fi

if [ ! -z "$missing_env_vars" ]; then
  echo "Missing env vars:$missing_env_vars"
  exit 1
fi

debug="${DEBUG:-false}"
remote_string="$REMOTE_NAME:$REMOTE_FILE_NAME"
delta_threshold_in_s="${DELTA_THRESHOLD_IN_S:-30}"
sleep_duration_in_s="${SLEEP_IN_S:-60}"

function log_debug {
  if [ "$debug" = "true" ] || [ "$debug" = "script" ]; then
    echo $1
  fi
}

echo "Starting sync with:"
echo " - debug=$debug"
echo " - remote_string=$remote_string"
echo " - delta_threshold_in_s=$delta_threshold_in_s"
echo " - sleep_duration_in_s=$sleep_duration_in_s"

rclone_debug_flags=""
if [ "$debug" = "true" ] || [ "$debug" = "rsync" ]; then
  rclone_debug_flags="-vv"
fi

iteration=0
while true; do
  iteration="$(($iteration + 1))"
  echo ""
  echo "Starting sync attempt #$iteration (time: $(date))"
  
  mtime_local="$(stat -c %Y "/data/$REMOTE_FILE_NAME")"
  log_debug "mtime_local=$mtime_local"
  
  mdate_remote="$(rclone lsf $rclone_debug_flags $remote_string --format t)"
  log_debug "mdate_remote=$mdate_remote"

  mtime_remote="$(date -d "$mdate_remote" +%s)"
  log_debug "mtime_remote=$mtime_remote"

  mtime_delta="$(($mtime_local - $mtime_remote))"
  log_debug "mtime_delta=$mtime_delta"

  if [ "$mtime_delta" -lt "-$delta_threshold_in_s" ]; then
      echo "Remote file is $(($mtime_delta * -1)) seconds newer than local file, downloading..."
      rclone copy -qu $rclone_debug_flags $remote_string /data
  elif [ "$mtime_delta" -gt "$delta_threshold_in_s" ]; then
    echo "Local file is $mtime_delta seconds newer than remote file, uploading..."
    rclone copy -qu $rclone_debug_flags /data "$REMOTE_NAME:/"
  else
    echo "Local and remote file are identical (delta: $mtime_delta seconds)"
  fi

  sleep "$sleep_duration_in_s"
done

