#!/usr/bin/env bash
# Full-screen music visualizer — projectM, the open-source MilkDrop engine:
# thousands of presets that actually track the beat, in the lineage of the
# old iTunes/Winamp visualizers. projectm-sdl is the SDL front end
# (projectMSDL); projectm carries the preset pack it plays. Launched by
# `music-visualizer`, which is what clicking the bar's music levels does.
# Idempotent.
set -euo pipefail
TOOLS="${TOOLS:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)/tools}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

sudo pacman -S --needed --noconfirm projectm projectm-sdl

bash "$TOOLS/link.sh" "$HERE/bin" "$HOME/.local/bin"
