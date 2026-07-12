#!/usr/bin/env bash
# AirPlay output. Makes AirPlay speakers (HomePod, Apple TV, AirPort
# Express, most AV receivers) appear as ordinary PipeWire sinks, so
# anything that plays audio can be sent to them from the normal output
# picker — including the Spotify web player, which has no Linux client and
# no AirPlay support of its own.
#
# Three halves, and all of them were missing:
#   1. pipewire-zeroconf. Arch splits the RAOP module out of the main
#      pipewire package, so a stock install has no
#      libpipewire-module-raop-discover at all and the drop-in below
#      silently loads nothing.
#   2. avahi-daemon, for mDNS. AirPlay speakers announce themselves over
#      mDNS and there is no other way to find them. Installed on this box
#      but never enabled.
#   3. The drop-in under config/, which actually loads the module.
#
# Miss any one and the symptom is identical and unhelpful: no AirPlay
# devices in the output picker, with nothing logged to say why.
#
# Caveat worth knowing: this speaks AirPlay 1. Most speakers accept it.
# Some AirPlay-2-only devices (notably newer HomePods on recent firmware)
# won't appear, and that's an upstream PipeWire limitation rather than a
# config error here.
# Idempotent.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

sudo pacman -S --needed --noconfirm pipewire-zeroconf avahi
sudo systemctl enable --now avahi-daemon.service

bash "$TOOLS/link.sh" "$HERE/config" "$HOME/.config"

# PipeWire reads its module list at startup, so the drop-in above does
# nothing until it restarts. Restarting the user services is enough — no
# logout — but it does briefly cut audio.
systemctl --user restart pipewire.service pipewire-pulse.service wireplumber.service
