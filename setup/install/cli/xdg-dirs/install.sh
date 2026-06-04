#!/usr/bin/env bash
# Set the XDG user directories to lowercase paths. Default Arch ships
# Capitalized ones (Downloads/, Documents/, …) — we override per-user
# via ~/.config/user-dirs.dirs and create the lowercase folders to match.
# Idempotent — re-runs overwrite the config and `mkdir -p` is a no-op
# for existing folders.
set -euo pipefail

mkdir -p "$HOME/.config"

cat > "$HOME/.config/user-dirs.dirs" <<'EOF'
# Lowercase XDG user dirs. Vendored by orchard's xdg-dirs install.
# xdg-user-dirs-update may rewrite this on locale change; re-running
# install.sh restores it.
XDG_DESKTOP_DIR="$HOME/desktop"
XDG_DOWNLOAD_DIR="$HOME/downloads"
XDG_TEMPLATES_DIR="$HOME/templates"
XDG_PUBLICSHARE_DIR="$HOME/public"
XDG_DOCUMENTS_DIR="$HOME/documents"
XDG_MUSIC_DIR="$HOME/music"
XDG_PICTURES_DIR="$HOME/pictures"
XDG_VIDEOS_DIR="$HOME/videos"
EOF

mkdir -p \
    "$HOME/desktop" \
    "$HOME/downloads" \
    "$HOME/documents" \
    "$HOME/pictures" \
    "$HOME/music" \
    "$HOME/videos"
