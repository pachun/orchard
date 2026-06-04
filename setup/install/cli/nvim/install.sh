#!/usr/bin/env bash
# Install Neovim, symlink the orchard-managed config into place, and
# pre-warm plugins + LSPs so the first interactive launch lands on a
# styled buffer instead of the Lazy installer UI. Idempotent.
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
# Node-LSPs (typescript-language-server, etc.) need `node` on PATH at
# install time — mise provides it, hence the prerequisite + PATH export.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# mise gives us node for Mason; tree-sitter-cli is the parser compiler.
bash "$HERE/../mise/install.sh"
sudo pacman -S --needed --noconfirm neovim tree-sitter-cli ripgrep

bash "$TOOLS/link.sh" "$HERE/config" "$HOME/.config/nvim"

export PATH="${MISE_DATA_DIR:-$HOME/.local/share/mise}/shims:$PATH"

nvim --headless \
    "+Lazy! sync" \
    "+MasonToolsInstallSync" \
    "+lua require('nvim-treesitter').install(require('tools.treesitter_parsers')):wait(300000)" \
    +qa
