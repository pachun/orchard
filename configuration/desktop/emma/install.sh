#!/usr/bin/env bash
# Emma, my email client (emmaemail.app). Installed once from the site's
# installer, which puts the AppImage under ~/.local/share/emma, links it
# as `emma` on the PATH, and adds it to the app menu. Emma keeps itself
# up to date after that, so a re-run leaves an installed copy alone.
set -euo pipefail
TOOLS="${TOOLS:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)/tools}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

EMMA="${XDG_DATA_HOME:-$HOME/.local/share}/emma/Emma.AppImage"

if [ ! -x "$EMMA" ]; then
  curl -fsSL https://emmaemail.app/install.sh | sh
fi

bash "$TOOLS/link.sh" "$HERE/launcher" "$HOME/.config/launcher"
