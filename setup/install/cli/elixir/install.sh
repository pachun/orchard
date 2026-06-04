#!/usr/bin/env bash
# Elixir + Erlang via mise. Matches how they're managed on the desktop
# dev machine: tool-versions are pinned by mise, shims put `elixir` /
# `mix` / `erl` on PATH for both interactive use and Mason's
# elixir-ls build (orchard's nvim pre-warm needs this to succeed).
# Idempotent — `mise use --global` is a config-file write that
# resolves on the next shim invocation; already-installed versions
# skip the download.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Erlang's kerl build (the mise erlang installer) compiles OTP from
# source — needs the GNU build toolchain (make, gcc, autoconf, perl,
# etc.). base-devel is the Arch meta-group bundling those. Not on the
# Minimal archinstall profile, so we install it explicitly here.
sudo pacman -S --needed --noconfirm base-devel

bash "$HERE/../mise/install.sh"

mise use --global erlang@latest elixir@latest
