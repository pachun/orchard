#!/usr/bin/env bash
# Symlink every file under SRC into DST, preserving subdirectory
# structure. Each feature's install.sh calls this with its own
# `config/` dir and the corresponding $HOME location.
#
# Idempotent:
#   - existing symlinks (correct or dangling) get replaced via ln -sfn
#   - existing real files get backed up to <path>.bak.<timestamp> first,
#     so we never silently destroy a user-edited config
# Real directories at DST are preserved (we walk into them); only
# files inside are symlinks. That way DST can also hold runtime state
# (e.g. ~/.claude/projects/) without conflict.
set -euo pipefail

SRC="$1"
DST="$2"
TS="$(date +%Y%m%d-%H%M%S)"

mkdir -p "$DST"
find "$SRC" -type f -print0 | while IFS= read -r -d '' src; do
  rel="${src#$SRC/}"
  dst="$DST/$rel"
  mkdir -p "$(dirname "$dst")"
  if [ -e "$dst" ] && [ ! -L "$dst" ]; then
    mv "$dst" "$dst.bak.$TS"
  fi
  ln -sfn "$src" "$dst"
done
