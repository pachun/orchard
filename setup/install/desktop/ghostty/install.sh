#!/usr/bin/env bash
# Build and install ghostty from AUR pinned to its latest stable git tag.
# Avoids the regression risk of tracking master via the AUR's
# ghostty-git package (which bit us once with broken background
# rendering after a master commit).
#
# Re-running this script automatically pulls a newer stable release if
# upstream has tagged one — no manual version bump required. To freeze
# on a specific version, replace the dynamic `LATEST_TAG` lookup below
# with an explicit assignment.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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

  # Pin AUR PKGBUILD's source to the chosen tag instead of master HEAD.
  if ! grep -q 'source=("git+\$url.git")' PKGBUILD; then
    echo "ghostty: PKGBUILD's source line shape changed; sed needs updating" >&2
    exit 1
  fi
  sed -i 's|^source=("git+\$url.git")|source=("git+$url.git#tag='"$LATEST_TAG"'")|' PKGBUILD

  makepkg -fi --noconfirm

  cd "$HERE"
fi

# Tell pacman/yay not to auto-upgrade ghostty-git to master on a system
# update. Re-runs of this script are how we move forward.
if ! grep -qE '^[[:space:]]*IgnorePkg.*ghostty-git' /etc/pacman.conf; then
  if grep -qE '^[[:space:]]*#[[:space:]]*IgnorePkg' /etc/pacman.conf; then
    sudo sed -i 's|^[[:space:]]*#[[:space:]]*IgnorePkg.*|IgnorePkg = ghostty-git ghostty-shell-integration-git ghostty-terminfo-git|' /etc/pacman.conf
  else
    echo 'IgnorePkg = ghostty-git ghostty-shell-integration-git ghostty-terminfo-git' \
      | sudo tee -a /etc/pacman.conf >/dev/null
  fi
fi

bash "$TOOLS/link.sh" "$HERE/config" "$HOME/.config/ghostty"
bash "$TOOLS/link.sh" "$HERE/bin" "$HOME/.local/bin"
