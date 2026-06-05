# mise is the asdf successor (Rust rewrite, in extra/ on Arch).
# `mise activate zsh` emits the shim-PATH export, the cd hook that
# auto-swaps versions when entering a project with .tool-versions or
# .mise.toml, and the completion bindings — one line replaces asdf's
# separate setup + completion functions.
if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate zsh)"
fi
