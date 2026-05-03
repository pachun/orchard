#!/usr/bin/env bash
# Pre-warm the nvim plugin set so the first interactive launch lands
# straight on a styled buffer instead of lazy.nvim's installer UI.
#
# `nvim --headless "+Lazy! sync" +qa` runs nvim with no TTY, asks
# lazy.nvim to install/update everything declared under lua/plugins/
# (the `!` skips prompts), then quits. lazy.nvim itself bootstraps on
# first run via the clone block in init.lua, so this works on a fresh
# machine where ~/.local/share/nvim/lazy/lazy.nvim doesn't exist yet.
#
# Idempotent — sync is a no-op when every plugin is already at its
# pinned version.
set -euo pipefail

if ! command -v nvim >/dev/null 2>&1; then
    echo "nvim not on PATH; skipping plugin sync" >&2
    exit 0
fi

if [ ! -f "$HOME/.config/nvim/init.lua" ]; then
    echo "no nvim config at ~/.config/nvim/init.lua; skipping (link.sh probably hasn't run yet)" >&2
    exit 0
fi

nvim --headless "+Lazy! sync" +qa
