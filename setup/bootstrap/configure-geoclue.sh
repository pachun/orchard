#!/usr/bin/env bash
# Point geoclue's WiFi-positioning backend at BeaconDB instead of the
# default (Mozilla Location Service, which Mozilla shut down mid-2024).
# BeaconDB is the community-run replacement, same Ichnaea API, no key.
# Geoclue's `ichnaea` IP method also uses this URL, so a single setting
# covers both wifi-based and IP-based fallback paths.
#
# Idempotent — re-runs are no-ops if the BeaconDB URL is already set.
set -euo pipefail

CONF=/etc/geoclue/geoclue.conf
BEACON_URL='https://api.beacondb.net/v1/geolocate'

if grep -qE "^[[:space:]]*url=${BEACON_URL}" "$CONF"; then
    exit 0
fi

# If a [wifi] section already exists, drop a url= line into it; otherwise
# append a fresh section. The sed first removes any prior url=… line in
# [wifi] so re-runs don't accumulate stale entries.
if grep -qE '^\[wifi\]' "$CONF"; then
    sudo sed -i -E '/^\[wifi\]/,/^\[/{ /^[[:space:]]*url=/d; }' "$CONF"
    sudo sed -i -E "/^\[wifi\]/a url=${BEACON_URL}" "$CONF"
else
    printf '\n[wifi]\nurl=%s\n' "$BEACON_URL" | sudo tee -a "$CONF" >/dev/null
fi

sudo systemctl restart geoclue.service
