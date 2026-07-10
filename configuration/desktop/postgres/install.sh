#!/usr/bin/env bash
# PostgreSQL server + initial cluster bootstrap. Three steps the package
# itself doesn't handle:
#   1. Initialize the data directory at /var/lib/postgres/data via
#      `initdb`. Without this, postgresql.service refuses to start.
#   2. Enable + start postgresql.service so the daemon is up at boot
#      and right now.
#   3. Create a superuser matching the current login name, so apps
#      (Phoenix/Ecto, etc.) that connect with no explicit username
#      authenticate as $USER and can create per-project DBs.
# Idempotent — each step is a no-op when its work is already done.
set -euo pipefail

sudo pacman -S --needed --noconfirm postgresql

DATA_DIR="/var/lib/postgres/data"

# initdb writes PG_VERSION into the data dir on success — its presence
# is the canonical "this cluster is initialized" marker. /var/lib/postgres
# is mode 700 owned by the postgres user, so we have to `sudo test` for
# the file rather than testing as the invoking user. `sudo -u` (not -iu)
# runs as postgres without spawning a login shell, which would otherwise
# stall on profile scripts.
if ! sudo test -f "$DATA_DIR/PG_VERSION"; then
    sudo -u postgres initdb -D "$DATA_DIR"
fi

sudo systemctl enable --now postgresql.service

# Wait up to 15s for the listening socket to come up. systemctl returns
# as soon as the unit forks, but the daemon may need a moment beyond
# that.
ready=0
for _ in $(seq 1 15); do
    if sudo -u postgres pg_isready -q; then
        ready=1
        break
    fi
    sleep 1
done
if [ "$ready" -ne 1 ]; then
    echo "postgresql.service started but is not accepting connections after 15s" >&2
    echo "check: systemctl status postgresql; journalctl -xeu postgresql" >&2
    exit 1
fi

# Create a $USER superuser if missing.
if [ "$(sudo -u postgres psql -tAc "SELECT 1 FROM pg_roles WHERE rolname='$USER'")" != "1" ]; then
    sudo -u postgres createuser --superuser "$USER"
fi
