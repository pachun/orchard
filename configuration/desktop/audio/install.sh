#!/usr/bin/env bash
# PipeWire audio stack. On Apple silicon we additionally install
# asahi-audio (per-model speaker DSP profiles) and speakersafetyd (the
# daemon the kernel driver needs to un-mute the Mac speakers); both are
# Asahi-only packages with no x86 equivalent.
#
# Also owns audio-menu, the output picker (Cmd+O). It's what routes sound to
# an AirPlay speaker: those arrive as ordinary PipeWire sinks via the airplay
# feature, and no application picker can see them — the Spotify web player's
# device list only knows about Spotify Connect and Google Cast — so choosing
# an output has to happen at the OS.
set -euo pipefail
TOOLS="${TOOLS:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)/tools}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

. "$TOOLS/machine.sh"

packages=(wireplumber pipewire-pulse pipewire-alsa)
if is_apple_silicon; then
  packages+=(asahi-audio speakersafetyd)
fi
sudo pacman -S --needed --noconfirm "${packages[@]}"

bash "$TOOLS/link.sh" "$HERE/bin" "$HOME/.local/bin"
bash "$TOOLS/link.sh" "$HERE/config" "$HOME/.config"

systemctl --user enable --now wireplumber.service pipewire-pulse.service
# Re-runs must apply wireplumber.conf.d changes; a restart of the session
# manager alone leaves pipewire and active streams running.
systemctl --user try-restart wireplumber.service
if is_apple_silicon; then
  sudo systemctl enable --now speakersafetyd.service
fi
