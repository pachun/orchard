#!/usr/bin/env bash
# Enable the audio stack services. Idempotent — `enable --now` is a no-op
# on already-enabled-and-running services.
#
#   wireplumber + pipewire-pulse: per-user PipeWire session bits
#   speakersafetyd: system-level DSP daemon required for Mac speakers
#                   (kernel driver mutes them until this is running)
set -euo pipefail

systemctl --user enable --now wireplumber.service pipewire-pulse.service
sudo systemctl enable --now speakersafetyd.service
