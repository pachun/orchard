#!/usr/bin/env bash
# Make vendored fonts visible to fontconfig by symlinking the fonts/
# directory under ~/.local/share/fonts/, then refreshing the font cache.
# Idempotent — re-runs do nothing if the symlink is already correct.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$HERE/fonts"
DEST="$HOME/.local/share/fonts/orchard"

mkdir -p "$(dirname "$DEST")"

if [ -L "$DEST" ] && [ "$(readlink -f "$DEST")" = "$(readlink -f "$SRC")" ]; then
  exit 0
fi

rm -rf "$DEST"
ln -s "$SRC" "$DEST"
fc-cache -f >/dev/null
