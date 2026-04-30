#!/usr/bin/env bash
# Build aquamarine from upstream v0.11.0 + PR #289 patch and install via
# pacman. Pin via IgnorePkg so `pacman -Syu` doesn't replace our patched
# build with the broken upstream release.
#
# Why: aquamarine 0.11+ regressed render device detection on Apple Silicon
# (Asahi). Hyprland falls back to llvmpipe software rendering, which kills
# ghostty's background colors, hides the cursor, and breaks tmux bar /
# anything driven by GL_FRAMEBUFFER_SRGB. PR #289 restores the fallback.
#
# When PR #289 merges and a new aquamarine release ships in extra, this
# whole script can be deleted (and the `aquamarine` IgnorePkg entry
# stripped) — see todos.md for the cleanup checklist.
#
# Tracker: https://github.com/hyprwm/aquamarine/pull/289

set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PKGDIR="$HERE/aquamarine"

# Skip the build if the patched aquamarine is already installed. The
# orchard build embeds the literal string "orchard" in pkgver, so a
# simple substring check is enough to distinguish it from upstream.
INSTALLED_VER=$(pacman -Qi aquamarine 2>/dev/null | awk '/^Version/ {print $3}')
if [[ "$INSTALLED_VER" != *orchard* ]]; then
    ( cd "$PKGDIR" && makepkg -si --noconfirm )
fi

# Pin: keep the IgnorePkg entry inside [options]. We append after the
# section header rather than at end-of-file because pacman.conf can have
# trailing repo sections (e.g. [aur]) and IgnorePkg outside [options] is
# silently ignored.
if ! grep -qE "^[[:space:]]*IgnorePkg.*\baquamarine\b" /etc/pacman.conf; then
    sudo sed -i '/^\[options\]/a IgnorePkg = aquamarine' /etc/pacman.conf
fi
