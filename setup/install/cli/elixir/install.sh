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

bash "$HERE/../mise/install.sh"

mise use --global erlang@latest elixir@latest
