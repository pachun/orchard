#!/usr/bin/env bash
# Install gitspine — a TUI git client. The official installer at
# https://gitspine.com/install.sh detects OS + arch and drops the
# binary at /usr/local/bin/gitspine (or ~/.local/bin/gitspine if the
# system path isn't writable). Idempotent — skips if already on PATH.
set -euo pipefail

if command -v gitspine >/dev/null 2>&1; then
    exit 0
fi

curl -fsSL https://gitspine.com/install.sh | bash
