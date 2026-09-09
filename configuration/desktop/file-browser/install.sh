#!/usr/bin/env bash
# The file browser, and Quick Look for it.
#
# Nautilus was only ever here as a dependency of xdg-desktop-portal-gnome, even
# though Cmd+E in hyprland.conf launches it by name — so it's installed on
# purpose now.
#
# sushi is GNOME's Quick Look: Space on a selected file opens a preview window,
# the arrow keys walk the rest of the folder, Space closes it. Images, PDFs,
# text and source, audio and video, and (with libreoffice) office documents.
# Anything it can't render falls back to a name-and-type card.
#
# The sidebar shows Home, then the places listed in ./sidebar-places (one
# `~/path Label` per line), then Trash. Nautilus reads them from GTK's
# bookmarks file, which it rewrites whenever a bookmark is added in-app,
# so the file is rendered from the list rather than symlinked to it.
# Ctrl+j / Ctrl+k (xremap) walk the sidebar rows via bin/nautilus-walk-sidebar,
# which finds the next row over the accessibility bus (python-gobject +
# at-spi2-core) and clicks it with ydotool.
# Idempotent.
set -euo pipefail
TOOLS="${TOOLS:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)/tools}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

sudo pacman -S --needed --noconfirm nautilus sushi ydotool python-gobject at-spi2-core

bash "$TOOLS/link.sh" "$HERE/bin" "$HOME/.local/bin"

render_sidebar_places() {
  local bookmarks="$HOME/.config/gtk-3.0/bookmarks"
  mkdir -p "$(dirname "$bookmarks")"
  python3 - "$HERE/sidebar-places" "$bookmarks" <<'PY'
import sys
from pathlib import Path
from urllib.parse import quote

places, bookmarks = Path(sys.argv[1]), Path(sys.argv[2])
lines = []
for line in places.read_text().splitlines():
    path, label = line.rsplit(" ", 1)
    lines.append(f"file://{quote(str(Path(path).expanduser()))} {label}")
bookmarks.write_text("\n".join(lines) + "\n")
PY
}
render_sidebar_places
