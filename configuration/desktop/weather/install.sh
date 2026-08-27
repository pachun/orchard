#!/usr/bin/env bash
# Weather. Owns the `weather` launcher — Cmd+Shift+W, and a click on the bar's
# temperature — which opens Google's weather card for wherever you currently
# are. The script explains why it has to resolve the town itself rather than
# letting the browser do it.
#
# The bar's weather glyph is a waybar module (waybar-weather) and lives with
# the other bar modules, in the waybar feature.
# Idempotent.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

bash "$TOOLS/link.sh" "$HERE/bin" "$HOME/.local/bin"
