#!/usr/bin/env bash
set -euo pipefail

minimum_hyprland_version=0.57.0
available_hyprland_version=$(LC_ALL=C pacman -Si hyprland 2>/dev/null | awk '$1 == "Version" { print $3; exit }') || available_hyprland_version=

if [ -z "$available_hyprland_version" ]; then
  echo "Orchard: cannot find Hyprland in the local package indexes." >&2
  echo "Complete a full system update, then run configure again." >&2
  exit 1
fi

if [ "$(vercmp "$available_hyprland_version" "$minimum_hyprland_version")" -lt 0 ]; then
  echo "Orchard requires Hyprland $minimum_hyprland_version or newer for its Lua configuration." >&2
  echo "Your package indexes offer $available_hyprland_version on $(uname -m)." >&2
  echo "If a full system update still offers this version, wait for compatible repository packages before applying current Orchard." >&2
  exit 1
fi
