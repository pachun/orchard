#!/usr/bin/env bash
set -euo pipefail
sudo pacman -Syu --needed --noconfirm \
  zsh zsh-syntax-highlighting neovim tmux direnv hyprland chromium \
  base-devel git
