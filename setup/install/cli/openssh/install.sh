#!/usr/bin/env bash
# OpenSSH client + server. Idempotent.
set -euo pipefail

sudo pacman -S --needed --noconfirm openssh
