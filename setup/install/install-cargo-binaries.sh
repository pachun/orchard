#!/usr/bin/env bash
# Install Rust crates listed in cargo.txt via `cargo install --locked`.
# --locked uses each crate's bundled Cargo.lock so dependency-resolver bugs
# (vergen-lib version skew, etc.) don't sink the build. Idempotent: cargo
# skips re-install when the same version is already present.
#
# Each line in cargo.txt is appended verbatim to the install command, so
# extra args (like "xremap --features wlroots") work without a parser.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
mapfile -t entries < <(grep -v '^\s*\(#\|$\)' "$HERE/cargo.txt")
for entry in "${entries[@]}"; do
  # shellcheck disable=SC2086  # word-splitting is intentional here
  cargo install --locked $entry
done
