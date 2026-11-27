#!/usr/bin/env bash
# sshfs — FUSE client for mounting a remote directory over SSH. Used by
# the icloud script to mount the Mac mini's iCloud Drive folder over
# the Tailscale link. Idempotent.
set -euo pipefail
TOOLS="${TOOLS:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)/tools}"

bash "$TOOLS/install-packages.sh" sshfs
