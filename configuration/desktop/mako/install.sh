#!/usr/bin/env bash
# mako — notification daemon (implements org.freedesktop.Notifications
# over D-Bus). Without one, apps that emit toasts (chromium, electron,
# libnotify-using CLIs) can freeze waiting for the D-Bus interface.
# libnotify provides `notify-send` for shell scripts and is what most
# CLI/GUI apps link against to emit notifications.
# Idempotent.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

sudo pacman -S --needed --noconfirm mako libnotify

bash "$TOOLS/link.sh" "$HERE/config" "$HOME/.config/mako"
bash "$TOOLS/link.sh" "$HERE/bin" "$HOME/.local/bin"
