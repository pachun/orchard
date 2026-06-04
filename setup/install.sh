#!/usr/bin/env bash
# User-mode setup. Walks install/cli (always) and install/desktop (if
# MODE=desktop or unset). Each subdirectory under those is one feature
# with its own install.sh — adding/removing a feature is just create or
# delete the folder. Idempotent — re-run any time.
set -euo pipefail
shopt -s nullglob

MODE="${1:-desktop}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Available to every feature script — zsh's installer writes it into
# the generated ~/.zshrc, others can branch on it if they need to.
export ORCHARD_MODE="$MODE"
export TOOLS="$HERE/tools"

for d in "$HERE/install/cli"/*/; do
  bash "$d/install.sh"
done

if [[ "$MODE" == "desktop" ]]; then
  for d in "$HERE/install/desktop"/*/; do
    bash "$d/install.sh"
  done
fi
