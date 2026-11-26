#!/usr/bin/env bash
# Launch coding agents on another machine over SSH. Idempotent.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLS="${TOOLS:-$(cd "$HERE/../../../tools" && pwd)}"

bash "$TOOLS/link.sh" "$HERE/bin" "$HOME/.local/bin"
