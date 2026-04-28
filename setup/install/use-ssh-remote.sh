#!/usr/bin/env bash
# Convert this repo's origin remote from https://github.com/... to
# git@github.com:... so subsequent push/fetch uses the SSH key registered
# by configure-github-auth.sh. Idempotent — no-op if already SSH, no remote,
# or github auth was skipped (in which case https stays so push still works).
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"

# If github auth was skipped, leave the remote alone.
gh auth status >/dev/null 2>&1 || exit 0

url="$(git -C "$REPO" remote get-url origin 2>/dev/null || true)"
case "$url" in
  https://github.com/*)
    new_url="git@github.com:${url#https://github.com/}"
    git -C "$REPO" remote set-url origin "$new_url"
    ;;
  *)
    : # already SSH, or no origin
    ;;
esac
