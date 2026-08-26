#!/usr/bin/env bash
# Bootstrap yay (AUR helper) from the AUR's git repo. Idempotent — skipped
# if already installed. Called by any install script that needs AUR
# packages.
set -euo pipefail

# Persist `--ignorearch` as yay's default makepkg flag. Many AUR
# PKGBUILDs hardcode arch=('x86_64') even when the source builds fine
# on aarch64; --ignorearch tells makepkg to attempt the build anyway.
# Source packages that genuinely need x86 still fail at compile time,
# so the worst case stays a noisy error rather than a silent breakage.
mkdir -p "$HOME/.config/yay"
printf '%s\n' '{"mflags": "--ignorearch"}' > "$HOME/.config/yay/config.json"

# Point gpg at a keyserver that actually serves PKGBUILD signing keys.
# gpg's default, keys.openpgp.org, strips UIDs whose owner has not
# verified their email with it, and gpg refuses a UID-less key. Most
# kernel and upstream signers have not, so makepkg's import comes back
# "No data" and yay aborts the entire AUR batch. pgpkeys.eu (Hockeypuck)
# serves them with UIDs intact. Idempotent: rewrite the line in place.
mkdir -p "$HOME/.gnupg"
chmod 700 "$HOME/.gnupg"
gpg_conf="$HOME/.gnupg/gpg.conf"
touch "$gpg_conf"
sed -i '/^keyserver /d' "$gpg_conf"
printf 'keyserver hkps://pgpkeys.eu\n' >> "$gpg_conf"

if command -v yay >/dev/null 2>&1; then
  exit 0
fi

sudo pacman -S --needed --noconfirm base-devel git

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
git clone https://aur.archlinux.org/yay-bin.git "$tmp/yay-bin"
( cd "$tmp/yay-bin" && makepkg -si --noconfirm )
