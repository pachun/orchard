#!/usr/bin/env bash
# Two-factor codes in the bar. A key glyph sits beside the AI usage robot;
# clicking it (or Cmd+Shift+2) drops a panel under the bar with every account
# in Ente Auth, its current code large on the right, and a bar under each
# code draining through its 30 seconds. Clicking a row copies the code.
#
# Ente Auth is the authenticator: open source, exports its secrets on
# request, and syncs phone and laptop end to end encrypted through an
# optional account. The desktop app keeps a local copy of the codes in an
# encrypted database whose key it parks in the GNOME keyring; enteauth-rs
# reads that database through that key and prints the codes, which is what
# lets the panel show them without the app running. The app still has to be
# signed in once on this machine, and it syncs only while it is open, so a
# code added on the phone shows up here after the next time Ente Auth has
# been opened — the panel's last row opens it for that.
#
# enteauth-rs is built from its AUR recipe with LTO turned off. As published
# the recipe fails to link on a current Arch: makepkg compiles the bundled
# SQLite with GCC's LTO, and Rust links with lld, which cannot read GCC's LTO
# objects and reports every sqlite3_* symbol undefined. Built once; a -git
# package is not something `yay -Sua` rebuilds.
#
# The panel is an eww window on its own daemon and config dir, themed from
# the active orchard palette by render-two-factor-theme, which set-theme
# re-runs on every switch. Waybar and Hyprland wire the module and the
# keybind in from their own configs; this feature provides the panel and
# its scripts.
# Idempotent.
set -euo pipefail
TOOLS="${TOOLS:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)/tools}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# The panel's colors are rendered from the active orchard theme, so the
# theme system has to be in place (and a theme active) before the daemon
# starts — configure runs features alphabetically, which puts themes after
# this one.
bash "$HERE/../themes/install.sh"

bash "$TOOLS/install-yay.sh"
bash "$TOOLS/aur-install.sh" ente-auth-bin eww

install_enteauth_rs_without_lto() {
  WORK="$(mktemp -d)"
  trap 'rm -rf "$WORK"' EXIT
  cd "$WORK"

  git clone --depth 1 https://aur.archlinux.org/enteauth-rs-git.git
  cd enteauth-rs-git

  if grep -q '^options=' PKGBUILD; then
    echo "enteauth-rs: PKGBUILD now sets options=; check whether !lto is still needed" >&2
    exit 1
  fi
  sed -i "s/^makedepends=/options=('!lto' '!debug')\nmakedepends=/" PKGBUILD

  makepkg -fi --noconfirm

  cd "$HERE"
}

if ! pacman -Qq enteauth-rs-git >/dev/null 2>&1; then
  install_enteauth_rs_without_lto
fi

bash "$TOOLS/link.sh" "$HERE/bin" "$HOME/.local/bin"
bash "$TOOLS/link.sh" "$HERE/config" "$HOME/.config"

"$HOME/.local/bin/render-two-factor-theme"
"$HOME/.local/bin/restart-two-factor"
