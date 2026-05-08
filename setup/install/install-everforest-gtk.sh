#!/usr/bin/env bash
# Install Fausto-Korpsvart's Everforest GTK theme system-wide. We
# bypass the AUR package (everforest-gtk-theme-git) because it pulls
# in gtk-engine-murrine, whose autotools-era `configure` script can't
# auto-detect aarch64 and fails to build on Asahi. murrine is a GTK2
# runtime engine — chromium's file picker (the main consumer here)
# uses GTK3, so skipping it is fine.
#
# `--tweaks medium` matches the medium variant used by neanias/
# everforest-nvim and our ghostty palette, keeping the dark family
# consistent across apps. Idempotent — re-runs do a fresh clone +
# reinstall.
set -euo pipefail

if ! command -v sassc >/dev/null 2>&1; then
    echo "sassc not installed; expected as a system package" >&2
    exit 1
fi

WORK_DIR=/tmp/everforest-gtk-build
rm -rf "$WORK_DIR"
git clone --depth=1 https://github.com/Fausto-Korpsvart/Everforest-GTK-Theme.git "$WORK_DIR"

cd "$WORK_DIR/themes"
sudo bash install.sh \
    --dest /usr/share/themes \
    --color dark \
    --tweaks medium
