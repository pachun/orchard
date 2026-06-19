#!/usr/bin/env bash
# Language version manager. Installs mise and sets latest LTS Node and
# latest Ruby as the global defaults. Node is for Mason (via nvim)
# which needs it on PATH to fetch typescript-language-server,
# bash-language-server, etc. Ruby is for depot's entry-point script,
# which uses #!/usr/bin/env ruby. Idempotent — `mise use --global`
# rewrites a config file; the version is skipped on subsequent runs.
set -euo pipefail

sudo pacman -S --needed --noconfirm mise

mise use --global node@lts
mise use --global ruby@latest
