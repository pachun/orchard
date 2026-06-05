#!/usr/bin/env bash
# Move the cloned repo into the new user's ~/code/orchard. Reads USERNAME
# and ROOT (= the current repo path) from the env exported by the
# dispatcher. Idempotent: if the repo is already at the destination,
# leave it alone.
set -euo pipefail
DEST="/home/$USERNAME/code/orchard"

mkdir -p "/home/$USERNAME/code"

if [ -d "$DEST" ]; then
  if [ "$(realpath "$DEST")" != "$(realpath "$ROOT")" ]; then
    echo "$DEST exists but is not the source repo; refusing to overwrite" >&2
    exit 1
  fi
else
  mv "$ROOT" "$DEST"
fi

chown -R "$USERNAME:$USERNAME" "/home/$USERNAME/code"
