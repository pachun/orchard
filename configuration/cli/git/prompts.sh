# Sourced — both by the dispatcher at the start of install.sh (so all
# prompts happen up front) and by git/install.sh's own first line (so
# standalone runs of the feature still work). Idempotent: only prompts
# when neither the gitconfig nor the env vars are already in place.
if [ ! -f "$HOME/.gitconfig.local" ] && [ -z "${GIT_COMMIT_NAME:-}" ]; then
  read -rp "Name for git commits: "  GIT_COMMIT_NAME  </dev/tty
  read -rp "Email for git commits: " GIT_COMMIT_EMAIL </dev/tty
  export GIT_COMMIT_NAME GIT_COMMIT_EMAIL
fi
