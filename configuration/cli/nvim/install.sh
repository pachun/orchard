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
TOOLS="${TOOLS:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)/tools}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Deps for Mason's downstream installers (run via the pre-warm
# below):
#   - mise provides node for npm-installed LSPs (typescript-,
#     bash-language-server, etc.)
#   - elixir feature provides elixir+erlang via mise so Mason can
#     compile elixir-ls from source
#   - unzip is needed by Mason to extract zip-distributed binaries
#     (stylua and similar) — silently failing without it. Not on
#     Arch's Minimal profile, so we install it explicitly.
#   - tree-sitter-cli is the parser compiler.
#   - ripgrep backs telescope's live_grep.
bash "$HERE/../mise/install.sh"
bash "$HERE/../elixir/install.sh"
sudo pacman -S --needed --noconfirm neovim tree-sitter-cli ripgrep unzip

bash "$TOOLS/link.sh" "$HERE/config" "$HOME/.config/nvim"

export PATH="${MISE_DATA_DIR:-$HOME/.local/share/mise}/shims:$PATH"

nvim --headless \
    "+Lazy! sync" \
    "+MasonToolsInstallSync" \
    "+lua require('nvim-treesitter').install(require('tools.treesitter_parsers')):wait(300000)" \
    +qa
