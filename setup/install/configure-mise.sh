#!/usr/bin/env bash
# Provisions mise with the latest LTS Node as the global default. The
# Mason install path that runs later in install.sh
# (configure-nvim.sh) needs `node`/`npm` on PATH to fetch
# typescript-language-server, bash-language-server, etc., so this
# script must run BEFORE configure-nvim.sh.
#
# Idempotent — `mise use --global` is a config-file write that mise
# resolves on the next shim invocation; if the version is already
# installed it skips the download.
set -euo pipefail

if ! command -v mise >/dev/null 2>&1; then
    echo "mise not on PATH; skipping (install-packages.sh hasn't run yet?)" >&2
    exit 0
fi

# `lts` is mise's filter for the latest LTS major. Unlike asdf, no
# separate `plugin add nodejs` step — Node is a built-in core tool in
# mise's plugin registry.
mise use --global node@lts
