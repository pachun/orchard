#!/usr/bin/env bash
# Install the optional build notification command without personal settings.
# Idempotent.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLS="${TOOLS:-$(cd "$HERE/../../../tools" && pwd)}"
bash "$TOOLS/link.sh" "$HERE/bin" "$HOME/.local/bin"
