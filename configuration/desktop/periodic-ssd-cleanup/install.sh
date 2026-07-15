#!/usr/bin/env bash
# Weekly SSD upkeep. fstrim.timer runs `fstrim` on a schedule to tell the
# drive which blocks are free, so the controller can erase and recycle
# them and writes stay fast. It's a timer (cron-like), not a daemon, and
# it's independent of reboots — the free-block bookkeeping lives on the
# disk, so restarting never does this job for you. fstrim ships with
# util-linux (already present); this just enables the timer.
# Idempotent.
set -euo pipefail

sudo systemctl enable --now fstrim.timer
