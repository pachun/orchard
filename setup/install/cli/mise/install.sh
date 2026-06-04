#!/usr/bin/env bash
# Language version manager. Installs mise and sets latest LTS Node as
# the global default — Mason (via nvim) needs node on PATH to fetch
# typescript-language-server, bash-language-server, etc. Idempotent —
# `mise use --global` rewrites a config file; the version is skipped on
# subsequent runs.
set -euo pipefail

sudo pacman -S --needed --noconfirm mise

mise use --global node@lts
