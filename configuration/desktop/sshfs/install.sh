#!/usr/bin/env bash
# sshfs — FUSE client for mounting a remote directory over SSH. Used by
# the icloud script to mount the Mac mini's iCloud Drive folder over
# the Tailscale link. Idempotent.
set -euo pipefail

sudo pacman -S --needed --noconfirm sshfs
