#!/usr/bin/env bash
# AI usage in the bar. A robot glyph sits next to the battery; clicking it
# (or Cmd+Shift+U) drops a panel under the bar with one section per AI CLI
# you're signed in to: Claude Code's rate-limit windows as claude.ai's Usage
# page shows them, and Codex's 5-hour and weekly windows for the ChatGPT plan
# GPT-6 Astra runs on — each with its percentage and when it resets.
#
# Claude's numbers come straight from Anthropic's usage endpoint using the
# login Claude Code keeps in ~/.claude; Codex's come from `codex app-server`,
# which reads the login Codex keeps and refreshes it itself. Nothing here
# signs in. The panel is an eww window on its own daemon and config dir,
# themed from the active orchard palette by render-ai-usage-theme, which
# set-theme re-runs on every switch. Waybar wires the module in from its own
# config; this feature only provides the fetchers and the panel.
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

"$HOME/.local/bin/render-ai-usage-theme"
"$HOME/.local/bin/restart-ai-usage"
