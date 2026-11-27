#!/usr/bin/env bash
# Thunderbolt displays and docks. The Dell's firmware leaves Thunderbolt at
# the "user" security level, where a device does nothing until something
# authorizes it. bolt is the daemon that does, and that remembers a device
# authorized once (the LG UltraFine) so it comes up by itself from then on.
#
# GNOME's settings panel used to bring bolt along as a dependency. Named
# here so removing that panel doesn't leave the monitor dark.
# `boltctl list` shows what is connected; `boltctl enroll <uuid>`
# authorizes a new device for good.
# Idempotent.
set -euo pipefail
TOOLS="${TOOLS:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)/tools}"

bash "$TOOLS/install-packages.sh" bolt
