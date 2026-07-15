#!/usr/bin/env bash
# Format support for every media app that isn't Chromium — mpv, GTK apps,
# anything GStreamer-backed. Adds the codecs a bare install lacks so files
# actually play:
#   - gst-libav: the ffmpeg-backed catch-all (H.264, AAC, and most of
#     what you hit day to day).
#   - gst-plugins-bad / gst-plugins-ugly: the rest of the codec set,
#     split upstream by licence / patent status, not by media type — each
#     holds a mix of audio, video, and container handlers.
#   - gst-plugin-va: routes video decode to the GPU via VA-API. Driver-
#     agnostic — it uses whatever decode driver graphics/ set up, which is
#     why the driver itself lives there (hardware-specific) and not here.
# Idempotent.
set -euo pipefail

. "$TOOLS/machine.sh"

packages=(gst-libav gst-plugins-bad gst-plugins-ugly)
if ! is_apple_silicon; then
  packages+=(gst-plugin-va)
fi
sudo pacman -S --needed --noconfirm "${packages[@]}"
