#!/usr/bin/env bash
# Install Claude Code (Anthropic's CLI). The official installer drops a
# binary at ~/.local/share/claude/versions/<ver>/ and a symlink at
# ~/.local/bin/claude. Idempotent — skips if `claude` is already on PATH.
set -euo pipefail

if command -v claude >/dev/null 2>&1; then
    exit 0
fi

curl -fsSL https://claude.ai/install.sh | bash
