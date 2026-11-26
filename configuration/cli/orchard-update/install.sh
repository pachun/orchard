#!/usr/bin/env bash
# Orchard updating itself. `update-orchard` pulls new commits and runs
# the installer of each feature they touched, so a change made on one
# machine reaches the others without a full `configure`. Its header
# explains why it tracks the last applied commit instead of how far the
# checkout is behind. The desktop's updates badge and system-update call
# it when it is present.
# Idempotent.
set -euo pipefail
TOOLS="${TOOLS:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)/tools}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

bash "$TOOLS/link.sh" "$HERE/bin" "$HOME/.local/bin"
