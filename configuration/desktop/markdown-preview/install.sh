#!/usr/bin/env bash
# Markdown preview. `markdown-preview <file>` — or :md in nvim — puts a
# GitHub-rendered, live-updating copy of the file in a window beside the editor.
#
# grip does the rendering, and the reason it's grip rather than any of the
# lighter local renderers is that grip doesn't imitate GitHub: it POSTs the file
# to GitHub's own Markdown API and shows what comes back. Alerts, task lists,
# autolinks and the table quirks are therefore exactly what the repo page will
# show, and they stay exact when GitHub changes its engine. For files whose
# whole purpose is to be read on GitHub, that fidelity is the feature.
#
# The price is honest: it needs the network. grip's offline renderer is a
# work-in-progress branch that never landed in the CLI, so with no connection
# there is no preview.
#
# The token that lifts GitHub's 60-render/hour anonymous cap is not configured
# here and is not in this repo — settings.py asks the gh CLI for one at startup.
# Idempotent.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

bash "$TOOLS/install-yay.sh"
bash "$TOOLS/aur-install.sh" python-grip

bash "$TOOLS/link.sh" "$HERE/bin" "$HOME/.local/bin"
bash "$TOOLS/link.sh" "$HERE/config" "$HOME/.grip"
