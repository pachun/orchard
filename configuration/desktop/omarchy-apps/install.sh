#!/usr/bin/env bash
# The apps Omarchy publishes only in its own package repository, built
# from its recipes and kept current. This feature is the `omarchy-apps`
# command (see its header) and the tools every such build needs. The apps
# themselves are their own features (presentations, video-trimmer,
# folio), each of which links a file into ~/.config/omarchy-recipes to
# put its app under this command's care.
#
# It also dresses those apps in orchard's themes: see
# bin/render-omarchy-apps-theme, which set-theme runs on every switch.
# Idempotent.
set -euo pipefail
TOOLS="${TOOLS:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)/tools}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

sudo pacman -S --needed --noconfirm base-devel cmake curl pkgconf

bash "$TOOLS/link.sh" "$HERE/bin" "$HOME/.local/bin"

"$HOME/.local/bin/render-omarchy-apps-theme"
