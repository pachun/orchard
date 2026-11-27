#!/usr/bin/env bash
# A graphical client for looking through databases and running queries:
# Beekeeper Studio, which speaks Postgres, MySQL, SQLite and SQL Server.
#
# It comes from the AUR and is built from source, which takes several
# minutes the first time. The launcher announces it while it opens,
# because its first window takes about five seconds to appear.
# Idempotent.
set -euo pipefail
TOOLS="${TOOLS:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)/tools}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

bash "$TOOLS/install-yay.sh"
bash "$TOOLS/aur-install.sh" beekeeper-studio

bash "$TOOLS/link.sh" "$HERE/launcher" "$HOME/.config/launcher"
