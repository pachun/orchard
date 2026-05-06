#!/usr/bin/env bash
# Pre-stage Claude Code plugins so a fresh machine can use them
# without manually running `/plugin install` inside Claude Code.
#
# Mechanics, reverse-engineered from ~/.claude/plugins/ layout:
#   - marketplaces/<name>/      git clone of the plugin source repo
#   - known_marketplaces.json   registry pointing at each marketplace
#   - settings.json (dotfile)   enabledPlugins.<plugin>@<marketplace>=true
#
# This script handles the marketplace clone + registry. Claude Code on
# next launch sees the marketplace, sees enabledPlugins in settings,
# and finishes the install (populating ~/.claude/plugins/cache/).
#
# Caveat: this depends on Claude Code's plugin internal format which
# isn't a stable public contract. If `/plugin install` ever stops
# working from the registry alone, we'd need to also pre-populate
# the cache/ directory and installed_plugins.json. Add new
# marketplaces/plugins to the lists below as needed.
set -euo pipefail

if ! command -v claude >/dev/null 2>&1; then
    echo "claude not on PATH; skipping plugin pre-stage" >&2
    exit 0
fi

PLUGINS_DIR="$HOME/.claude/plugins"
MARKETPLACES_DIR="$PLUGINS_DIR/marketplaces"
REGISTRY="$PLUGINS_DIR/known_marketplaces.json"

mkdir -p "$MARKETPLACES_DIR"

# Marketplace git sources, name → github repo. Add more entries here
# if you start using plugins from additional marketplaces.
declare -A MARKETPLACES=(
    [claude-plugins-official]="anthropics/claude-plugins-official"
)

for name in "${!MARKETPLACES[@]}"; do
    repo="${MARKETPLACES[$name]}"
    target="$MARKETPLACES_DIR/$name"
    if [ ! -d "$target/.git" ]; then
        git clone "https://github.com/$repo" "$target"
    fi
done

# Rewrite known_marketplaces.json from scratch — small file, idempotent,
# avoids the brittleness of merging into existing JSON.
python3 - "$REGISTRY" "$MARKETPLACES_DIR" <<'PY'
import json, os, sys
from datetime import datetime, timezone

registry_path, marketplaces_dir = sys.argv[1], sys.argv[2]
now = datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%S.000Z')

entries = {}
for name in os.listdir(marketplaces_dir):
    install_path = os.path.join(marketplaces_dir, name)
    if not os.path.isdir(os.path.join(install_path, '.git')):
        continue
    # Read the git remote to recover the github repo identifier.
    import subprocess
    url = subprocess.check_output(
        ['git', '-C', install_path, 'remote', 'get-url', 'origin'],
        text=True,
    ).strip()
    # Normalize https://github.com/owner/repo(.git) → owner/repo
    repo = url.replace('https://github.com/', '').removesuffix('.git')
    entries[name] = {
        'source': {'source': 'github', 'repo': repo},
        'installLocation': install_path,
        'lastUpdated': now,
    }

with open(registry_path, 'w') as f:
    json.dump(entries, f, indent=2)
PY
