#!/usr/bin/env bash
# ghostty terminal. x86 has it in the official repos, so just install it.
# Apple silicon has no prebuilt ghostty, so there we build the AUR package
# pinned to the latest stable git tag — its ghostty-git tracks master,
# which regressed on us once (broken background rendering after a commit).
# Re-running picks up a newer stable tag automatically.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$TOOLS/machine.sh"

if is_apple_silicon; then
  bash "$TOOLS/install-yay.sh"

  REPO=https://github.com/ghostty-org/ghostty.git
  LATEST_TAG=$(git ls-remote --tags --refs "$REPO" \
    | awk '{print $2}' \
    | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+$' \
    | sort -V | tail -1)
  if [ -z "$LATEST_TAG" ]; then
    echo "ghostty: could not determine latest stable tag" >&2
    exit 1
  fi

  INSTALLED_VER=$(pacman -Qi ghostty-git 2>/dev/null | awk '/^Version/ {print $3}')
  if [[ "$INSTALLED_VER" != "${LATEST_TAG#v}.r0."* ]]; then
    WORK=$(mktemp -d)
    trap 'rm -rf "$WORK"' EXIT
    cd "$WORK"

    git clone --depth 1 https://aur.archlinux.org/ghostty-git.git
    cd ghostty-git

    if ! grep -q 'source=("git+\$url.git")' PKGBUILD; then
      echo "ghostty: PKGBUILD's source line shape changed; sed needs updating" >&2
      exit 1
    fi
    sed -i 's|^source=("git+\$url.git")|source=("git+$url.git#tag='"$LATEST_TAG"'")|' PKGBUILD

    makepkg -fi --noconfirm

    cd "$HERE"
  fi

  # Keep a system update from dragging ghostty-git back to master; re-runs
  # of this script are how it moves forward.
  if ! grep -qE '^[[:space:]]*IgnorePkg.*ghostty-git' /etc/pacman.conf; then
    if grep -qE '^[[:space:]]*#[[:space:]]*IgnorePkg' /etc/pacman.conf; then
      sudo sed -i 's|^[[:space:]]*#[[:space:]]*IgnorePkg.*|IgnorePkg = ghostty-git ghostty-shell-integration-git ghostty-terminfo-git|' /etc/pacman.conf
    else
      echo 'IgnorePkg = ghostty-git ghostty-shell-integration-git ghostty-terminfo-git' \
        | sudo tee -a /etc/pacman.conf >/dev/null
    fi
  fi
else
  sudo pacman -S --needed --noconfirm ghostty
fi

bash "$TOOLS/link.sh" "$HERE/config" "$HOME/.config/ghostty"
bash "$TOOLS/link.sh" "$HERE/bin" "$HOME/.local/bin"
