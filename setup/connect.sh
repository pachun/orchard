#!/usr/bin/env bash
# Guided post-install account hookups — anything that needs the user to
# log in or paste credentials and so doesn't belong in the unattended
# install.sh flow.
#
# Each subscript under setup/connect/ is standalone and idempotent
# (re-running detects the already-connected state). Run this orchestrator
# to see what's available; or invoke a specific subscript directly:
#
#     bash setup/connect/gcalcli.sh
#
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cat <<EOF
──────────────────────────────────────────────────────────────────────
Available connect scripts (run each individually):
──────────────────────────────────────────────────────────────────────

EOF

for script in "$HERE/connect/"*.sh; do
    [ -f "$script" ] || continue
    name="$(basename "$script" .sh)"
    # Pull the first comment line as a one-line description.
    desc="$(awk '/^# / { sub(/^# /, ""); print; exit } !/^#/ { exit }' "$script")"
    printf "  %-20s — %s\n" "$name" "$desc"
    printf "  %-20s   bash %s\n\n" "" "setup/connect/$(basename "$script")"
done
