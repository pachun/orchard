#!/usr/bin/env bash
# AirPlay output, including AirPlay-2-only receivers that demand device
# verification — modern Apple TVs, HomePods, Macs, all of which answer an
# unauthenticated AirPlay 1 sender with RTSP 403 and can't be reached by
# PipeWire's raop module at all (it used to be loaded here; picking such a
# device killed the sink and audio fell back to the speakers).
#
# The shape now: one PipeWire sink called "AirPlay" (a pipe-tunnel writing
# PCM16 into a named pipe), and OwnTone reading that pipe and doing the
# actual AirPlay — it implements the AirPlay 2 pairing dance, so a device
# that requires verification shows a PIN on screen, you type it once (in
# audio-menu, or the web UI at http://localhost:3689 under Settings >
# Remotes & Outputs), and the credential persists. Which speakers actually
# play is OwnTone's output selection; audio-menu drives it over the JSON
# API. Nothing on the receiving Apple device needs its settings changed —
# the point, since not every AirPlay target in your life is yours to
# configure.
#
# Latency caveat: AirPlay buffers ~2s, so this is for music; a video's lips
# won't sync.
# Idempotent.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# The restart at the bottom needs the PipeWire stack present, and audio/
# sorts after this feature alphabetically, so on a fresh machine it would
# not be yet. jq is for audio-menu's OwnTone API calls.
bash "$HERE/../audio/install.sh"
sudo pacman -S --needed --noconfirm avahi jq
sudo systemctl enable --now avahi-daemon.service

bash "$TOOLS/install-yay.sh"
bash "$TOOLS/aur-install.sh" owntone-server
# The AUR PKGBUILD doesn't set options=(!debug), so makepkg builds an empty
# -debug package alongside and yay installs both.
if pacman -Qq owntone-server-debug >/dev/null 2>&1; then
    sudo pacman -R --noconfirm owntone-server-debug
fi

# The pipe is pre-created with deliberate ownership: PipeWire (this user)
# writes it, OwnTone (its own system user) reads it. Left to the pipe-tunnel
# module, it would be created with this user's umask and OwnTone may not be
# able to open it.
sudo install -d -o owntone -g owntone /var/lib/owntone/library
if [ ! -p /var/lib/owntone/library/airplay.fifo ]; then
    sudo mkfifo /var/lib/owntone/library/airplay.fifo
fi
sudo chown "$USER:owntone" /var/lib/owntone/library/airplay.fifo
sudo chmod 640 /var/lib/owntone/library/airplay.fifo

sudo install -Dm644 "$HERE/owntone.conf" /etc/owntone.conf
sudo systemctl enable owntone.service
sudo systemctl restart owntone.service

bash "$TOOLS/link.sh" "$HERE/config" "$HOME/.config"

# PipeWire reads its module list at startup, so the drop-in above does
# nothing until it restarts. Restarting the user services is enough — no
# logout — but it does briefly cut audio.
systemctl --user restart pipewire.service pipewire-pulse.service wireplumber.service
