#!/usr/bin/env bash
# PipeWire audio stack. On Apple silicon we additionally install
# asahi-audio (per-model speaker DSP profiles) and speakersafetyd (the
# daemon the kernel driver needs to un-mute the Mac speakers); both are
# Asahi-only packages with no x86 equivalent.
set -euo pipefail

. "$TOOLS/machine.sh"

packages=(wireplumber pipewire-pulse pipewire-alsa)
if is_apple_silicon; then
  packages+=(asahi-audio speakersafetyd)
fi
sudo pacman -S --needed --noconfirm "${packages[@]}"

systemctl --user enable --now wireplumber.service pipewire-pulse.service
if is_apple_silicon; then
  sudo systemctl enable --now speakersafetyd.service
fi
