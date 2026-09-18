#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_SETUP_HOME="${1:-$HOME}"

link_skill_directory() {
  local source="$1"
  local name="${source##*/}"
  local destination="$CLAUDE_SETUP_HOME/.claude/skills/$name"
  if [ -L "$destination" ] && [ "$(readlink "$destination")" = "$source" ]; then
    return
  fi
  if [ -e "$destination" ] || [ -L "$destination" ]; then
    local backups="$CLAUDE_SETUP_HOME/.claude/skill-backups"
    mkdir -p "$backups"
    local backup
    backup="$(mktemp -d "$backups/$name.XXXXXX")"
    mv "$destination" "$backup/skill"
  fi
  ln -s "$source" "$destination"
}

mkdir -p "$CLAUDE_SETUP_HOME/.claude/skills"
for source in "$HERE/skills"/*; do
  [ -f "$source/SKILL.md" ] || continue
  link_skill_directory "$source"
done
