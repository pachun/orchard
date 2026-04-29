#!/usr/bin/env bash
# Install Rust crates listed in cargo.txt via `cargo install --locked`.
# --locked uses each crate's bundled Cargo.lock so dependency-resolver bugs
# (vergen-lib version skew, etc.) don't sink the build. Idempotent: cargo
# skips re-install when the same version is already present.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
mapfile -t crates < <(grep -v '^\s*\(#\|$\)' "$HERE/cargo.txt")
for crate in "${crates[@]}"; do
  cargo install --locked "$crate"
done
