#!/usr/bin/env bash
# Pre-warm the nvim plugin set + every tool declared in lua/tools/* so
# the first interactive launch lands on a styled buffer with LSPs,
# formatters, and linters already installed — no lazy.nvim installer UI,
# no Mason install spinner.
#
# Three blocking steps in one nvim invocation:
#   1. `Lazy! sync` downloads/updates plugins (the `!` skips prompts and
#      blocks until done).
#   2. `MasonToolsInstallSync` blocks on every tool listed in
#      lua/tools/{language_servers,formatters,linters}.lua. Without
#      this, Mason kicks installs off async and headless nvim would
#      exit before they completed.
#   3. nvim-treesitter's `install()` is async by default. Chain `:wait`
#      so headless nvim doesn't quit before parsers finish downloading.
#      300s is the upper bound from the plugin's own README example.
#
# lazy.nvim self-bootstraps on first run via the clone block in
# init.lua, so this works on a fresh machine where ~/.local/share/nvim/
# is empty.
#
# Idempotent — both commands are no-ops when nothing is out of date.
set -euo pipefail

if ! command -v nvim >/dev/null 2>&1; then
    echo "nvim not on PATH; skipping plugin sync" >&2
    exit 0
fi

if [ ! -f "$HOME/.config/nvim/init.lua" ]; then
    echo "no nvim config at ~/.config/nvim/init.lua; skipping (link.sh probably hasn't run yet)" >&2
    exit 0
fi

nvim --headless \
    "+Lazy! sync" \
    "+MasonToolsInstallSync" \
    "+lua require('nvim-treesitter').install(require('tools.treesitter_parsers')):wait(300000)" \
    +qa
