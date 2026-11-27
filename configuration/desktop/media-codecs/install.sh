#!/usr/bin/env bash
# Format support for every media app that isn't Chromium — mpv, GTK apps,
# anything GStreamer-backed. Adds the codecs a bare install lacks so files
# actually play:
#   - gst-libav: the ffmpeg-backed catch-all (H.264, AAC, and most of
#     what you hit day to day).
#   - gst-plugins-good: the containers nearly every file comes in (MP4,
#     Matroska) and the audio and webcam outputs. GNOME's settings panel
#     used to bring it along; nothing else here names it.
#   - gst-plugins-bad / gst-plugins-ugly: the rest of the codec set,
#     split upstream by licence / patent status, not by media type — each
#     holds a mix of audio, video, and container handlers.
#   - gst-plugin-va: routes video decode to the GPU via VA-API. Driver-
#     agnostic — it uses whatever decode driver graphics/ set up, which is
#     why the driver itself lives there (hardware-specific) and not here.
# Idempotent.
set -euo pipefail
TOOLS="${TOOLS:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)/tools}"

. "$TOOLS/machine.sh"

packages=(gst-libav gst-plugins-good gst-plugins-bad gst-plugins-ugly)
if ! is_apple_silicon; then
  packages+=(gst-plugin-va)
fi
sudo pacman -S --needed --noconfirm "${packages[@]}"

# On a machine where gst-plugins-good arrived as some other package's
# dependency, installing it again leaves it marked as one, and removing
# that other package would take it away. Marking it explicit keeps it.
sudo pacman -D --asexplicit gst-plugins-good >/dev/null
