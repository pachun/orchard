#!/usr/bin/env bash
# Pre-install Claude Code plugins so a fresh machine comes up with the
# same marketplaces registered and plugins enabled, without anyone
# running `/plugin install` by hand inside Claude Code.
#
# Uses Claude Code's own `claude plugin` CLI — the supported, headless
# path — instead of reverse-engineering ~/.claude/plugins/ on disk.
# Claude Code moved marketplaces from git clones to opaque fetched
# snapshots (a .gcs-sha file, no .git), so hand-cloning the repo and
# writing known_marketplaces.json no longer produces a marketplace it
# recognizes.
#
# Both commands are idempotent: re-adding a marketplace or re-installing
# a plugin that's already present prints an "already …" notice and exits
# 0, so this is safe to re-run.
#
# To add more: append the marketplace's GitHub repo to MARKETPLACES and
# the plugin's <plugin>@<marketplace> to PLUGINS. The marketplace name is
# the repo's basename (anthropics/claude-plugins-official →
# claude-plugins-official), which is what a plugin references after the @.
# Enabling is also recorded in enabledPlugins in the committed
# settings.json dotfile.
set -euo pipefail

if ! command -v claude >/dev/null 2>&1; then
    echo "claude not on PATH; skipping plugin pre-install" >&2
    exit 0
fi

# Marketplaces to register, by GitHub repo (owner/name).
MARKETPLACES=(
    anthropics/claude-plugins-official
)

# Plugins to install, as <plugin>@<marketplace-name>. Installed at user
# scope so they're available across every project.
PLUGINS=(
    frontend-design@claude-plugins-official
)

for repo in "${MARKETPLACES[@]}"; do
    claude plugin marketplace add "$repo"
done

for plugin in "${PLUGINS[@]}"; do
    claude plugin install "$plugin" --scope user
done
