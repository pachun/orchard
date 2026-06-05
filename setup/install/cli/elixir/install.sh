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

# Skip the rest if there's already a working elixir + mix pair. The
# whole reason we install erlang+elixir is so Mason can compile
# elixir-ls (`mix do deps.get, elixir_ls.release2`) — any working pair
# satisfies that, whatever versions they are. Don't churn the user's
# setup just to chase @latest. Probe via mise shims since this script
# runs in bash with the caller's PATH.
export PATH="${MISE_DATA_DIR:-$HOME/.local/share/mise}/shims:$PATH"
if elixir --version >/dev/null 2>&1 && mix --version >/dev/null 2>&1; then
    exit 0
fi

# Erlang's kerl build (the mise erlang installer) compiles OTP from
# source — needs the GNU build toolchain (make, gcc, autoconf, perl,
# etc.). base-devel is the Arch meta-group bundling those. Not on the
# Minimal archinstall profile, so we install it explicitly here.
sudo pacman -S --needed --noconfirm base-devel

# Sequential — install erlang and make it the global default first, so
# elixir's install/verification step (which actually runs `elixir`)
# resolves erlang to the new version. Combined into a single
# `mise use --global erlang@latest elixir@latest` call, elixir's
# verification can still load against a stale previously-installed
# erlang and fail with "you are running Erlang/OTP <old>".
mise use --global erlang@latest
mise use --global elixir@latest
