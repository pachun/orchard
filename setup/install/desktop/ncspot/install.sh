#!/usr/bin/env bash
# ncspot — Rust-based Spotify TUI. Bound to Cmd+S in hyprland.conf.
# Cargo install — installs into ~/.cargo/bin/ which is exported to
# PATH from the desktop zshrc additions.
# Idempotent (cargo skips re-install for the same version).
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

bash "$HERE/../../cli/rust/install.sh"
cargo install --locked ncspot
