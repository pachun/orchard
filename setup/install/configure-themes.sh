#!/usr/bin/env bash
# Set the orchard-themes default on a fresh machine, only if the user
# hasn't picked one yet. Idempotent — re-running setup/install.sh
# leaves your chosen theme alone.
#
# The `active` symlink is runtime state, not part of dotfiles, so it
# doesn't appear on a fresh checkout. set-theme creates it on first
# call. We pick `catppuccin-frappe` as the seeded default to match
# the rest of the system's existing palette.
set -euo pipefail

themes_dir=$HOME/.config/orchard-themes
default_theme=catppuccin-frappe

if [ -L "$themes_dir/active" ]; then
    # User has already chosen a theme — leave it.
    exit 0
fi

"$HOME/.local/bin/set-theme" "$default_theme"
