#!/usr/bin/env bash
# Language version manager. Installs mise and sets latest LTS Node and
# latest Ruby as the global defaults. Node is for Mason (via nvim)
# which needs it on PATH to fetch typescript-language-server,
# bash-language-server, etc. Ruby is for depot's entry-point script,
# which uses #!/usr/bin/env ruby. Idempotent — `mise use --global`
# rewrites a config file; the version is skipped on subsequent runs.
set -euo pipefail

sudo pacman -S --needed --noconfirm mise

# Use precompiled binaries for Ruby instead of building from source.
# Source builds need libyaml / openssl / readline headers + a full C
# toolchain (none of which are in Arch's `base`), and Arch doesn't
# ship libyaml-dev as a separate package the way Debian does.
# Precompiled will be mise's default in 2026.8.0; setting it
# explicitly so older mise versions don't try to compile.
mise settings ruby.compile=false

mise use --global node@lts
mise use --global ruby@latest
