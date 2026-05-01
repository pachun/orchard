#!/usr/bin/env bash
# Ensure Claude Code's prompt input uses vim mode. Merges `editorMode:
# "vim"` into ~/.claude/settings.json without touching other keys, so:
#   - fresh installs get the file created with editorMode=vim
#   - existing settings (yours or future Claude Code additions) survive
#   - re-runs are no-ops once editorMode is already "vim"
#
# Doesn't symlink the file because `/config` and Claude Code itself
# write to it during normal use; a symlink to the repo would dirty
# the working tree on every preference change.
set -euo pipefail

mkdir -p "$HOME/.claude"
file="$HOME/.claude/settings.json"
existing=$(cat "$file" 2>/dev/null || echo '{}')
printf '%s' "$existing" | jq '. + {"editorMode": "vim"}' > "$file"
