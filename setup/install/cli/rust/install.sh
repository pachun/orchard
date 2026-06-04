#!/usr/bin/env bash
# Rust toolchain. Idempotent.
set -euo pipefail

sudo pacman -S --needed --noconfirm rust
