#!/usr/bin/env bash
# Install Claude Code, symlink the orchard-managed config (CLAUDE.md,
# settings.json, hooks/) into ~/.claude/, and pre-install plugins so a
# fresh machine comes up with the same marketplaces registered and
# plugins enabled.
#
# Both `claude plugin marketplace add` and `claude plugin install` are
# idempotent: re-adding a marketplace or re-installing a plugin prints
# an "already …" notice and exits 0, so this script is safe to re-run.
#
# To add a plugin: append its marketplace's GitHub repo to MARKETPLACES
# and the plugin's <name>@<marketplace> to PLUGINS. The marketplace
# name is the repo's basename
# (anthropics/claude-plugins-official → claude-plugins-official).
# Enabling is also recorded in enabledPlugins in settings.json.
set -euo pipefail
TOOLS="${TOOLS:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)/tools}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# claude installs to ~/.local/bin/claude. zshrc adds that to PATH at
# shell startup, but this script runs in bash with whatever PATH the
# install dispatcher had — which doesn't include ~/.local/bin. Add it
# BEFORE the `command -v` check below so re-runs detect an existing
# claude and skip the installer.
export PATH="$HOME/.local/bin:$PATH"

if ! command -v claude >/dev/null 2>&1; then
    curl -fsSL https://claude.ai/install.sh | bash
fi

bash "$TOOLS/link.sh" "$HERE/config" "$HOME/.claude"

MARKETPLACES=(
    anthropics/claude-plugins-official
)

PLUGINS=(
    frontend-design@claude-plugins-official
    expo@claude-plugins-official
)

for repo in "${MARKETPLACES[@]}"; do
    claude plugin marketplace add "$repo"
done

for plugin in "${PLUGINS[@]}"; do
    claude plugin install "$plugin" --scope user
done
