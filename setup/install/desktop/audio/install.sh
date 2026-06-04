#!/usr/bin/env bash
# PipeWire audio stack:
#   wireplumber + pipewire-pulse + pipewire-alsa — per-user PipeWire
#     session bits and the API shims apps talk to.
#   asahi-audio — per-model PipeWire/Wireplumber profiles for Apple
#     silicon speakers.
#   speakersafetyd — system-level DSP daemon required by the kernel
#     driver to actually un-mute the Mac speakers.
# `enable --now` is idempotent for already-enabled-and-running units.
set -euo pipefail

sudo pacman -S --needed --noconfirm \
    wireplumber pipewire-pulse pipewire-alsa asahi-audio speakersafetyd

systemctl --user enable --now wireplumber.service pipewire-pulse.service
sudo systemctl enable --now speakersafetyd.service
