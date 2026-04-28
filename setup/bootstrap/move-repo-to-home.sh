#!/usr/bin/env bash
# Move the cloned repo into the new user's ~/code/orchard. Idempotent: if
# the repo is already there, leave it alone.
set -euo pipefail
USERNAME="$1"
SRC="$2"
DEST="/home/$USERNAME/code/orchard"

mkdir -p "/home/$USERNAME/code"

if [ -d "$DEST" ]; then
  if [ "$(realpath "$DEST")" != "$(realpath "$SRC")" ]; then
    echo "$DEST exists but is not the source repo; refusing to overwrite" >&2
    exit 1
  fi
else
  mv "$SRC" "$DEST"
fi

chown -R "$USERNAME:$USERNAME" "/home/$USERNAME/code"
