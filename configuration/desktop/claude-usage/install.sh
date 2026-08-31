#!/usr/bin/env bash
# Claude Code usage in the bar. A sparkle with the current session percentage
# sits next to the update badge; clicking it drops a panel under the bar with
# every rate-limit window Anthropic reports for the signed-in account — the
# 5-hour session, the 7-day all-models window, and any per-model weekly
# window — the same numbers as claude.ai's Usage page, with when each resets.
#
# The numbers come straight from Anthropic's usage endpoint using the login
# Claude Code already keeps in ~/.claude; nothing here signs in or refreshes
# tokens. The panel is an eww window on its own daemon and config dir, themed
# from the active orchard palette by render-claude-usage-theme, which
# set-theme re-runs on every switch. Waybar wires the module in from its own
# config; this feature only provides the scripts and the panel.
# Idempotent.
set -euo pipefail
TOOLS="${TOOLS:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)/tools}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# The panel's colours are rendered from the active orchard theme, so the
# theme system has to be in place (and a theme active) before the daemon
# starts — configure runs features alphabetically, which would put this
# one first.
bash "$HERE/../themes/install.sh"

bash "$TOOLS/install-yay.sh"
bash "$TOOLS/aur-install.sh" eww

bash "$TOOLS/link.sh" "$HERE/bin" "$HOME/.local/bin"
bash "$TOOLS/link.sh" "$HERE/config" "$HOME/.config"

"$HOME/.local/bin/render-claude-usage-theme"
"$HOME/.local/bin/restart-claude-usage"
