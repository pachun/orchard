#!/usr/bin/env bash
# Install gitspine by cloning the source into ~/code/gitspine and
# building a release binary. ~/.local/bin/gitspine symlinks to the build
# output, so local edits + `cargo build --release` from ~/code/gitspine
# show up on the next `gitspine` invocation without re-running this
# script.
#
# Idempotent:
#   - Clones if ~/code/gitspine doesn't exist; otherwise leaves the
#     working tree alone (no auto-pull, so local uncommitted edits stay
#     safe).
#   - cargo build is incremental — first run compiles fresh, subsequent
#     runs are no-ops when nothing changed.
#   - Symlink is refreshed unconditionally so it always points at the
#     latest build output.
#
# Clone URL is HTTPS so a fresh install works without SSH keys
# configured. After the script, switch the remote to SSH manually if
# you want push access:
#   git -C ~/code/gitspine remote set-url origin git@github.com:pachun/gitspine.git
set -euo pipefail

REPO_URL="https://github.com/pachun/gitspine.git"
SRC_DIR="$HOME/code/gitspine"
BIN_TARGET="$HOME/.local/bin/gitspine"

if [ ! -d "$SRC_DIR" ]; then
    mkdir -p "$(dirname "$SRC_DIR")"
    git clone "$REPO_URL" "$SRC_DIR"
fi

(cd "$SRC_DIR" && cargo build --release)

mkdir -p "$(dirname "$BIN_TARGET")"
ln -sfn "$SRC_DIR/target/release/gitspine" "$BIN_TARGET"
