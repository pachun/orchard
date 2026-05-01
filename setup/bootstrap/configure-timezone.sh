#!/usr/bin/env bash
# Set the system timezone if it's still UTC. Walks the user through
# `tzselect` (numbered menus: continent → country → region → confirm) so
# nobody has to know the IANA string format. Idempotent — skips entirely
# if the timezone is already set to something other than UTC.
set -euo pipefail

current=$(timedatectl show --value -p Timezone 2>/dev/null || echo UTC)

if [[ "$current" != "UTC" && "$current" != "Etc/UTC" ]]; then
    exit 0
fi

echo
echo "Timezone is currently UTC. Walking through tzselect to pick yours…"
echo

# tzselect prints menus on stderr and the chosen TZ (plus some prose) on
# stdout. The final stdout line is the bare zone name.
if ! tz=$(tzselect | tail -1); then
    echo "tzselect aborted; leaving as UTC. Re-run this script later."
    exit 0
fi

if [[ -z "$tz" ]]; then
    echo "No selection; leaving as UTC."
    exit 0
fi

sudo timedatectl set-timezone "$tz"
echo "Timezone set to $tz."
