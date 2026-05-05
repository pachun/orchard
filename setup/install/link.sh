#!/usr/bin/env bash
# Symlink every file under dotfiles/ into $HOME, prepending '.' to the first
# path component. So:
#   dotfiles/zshrc                    -> $HOME/.zshrc
#   dotfiles/config/hypr/hyprland.conf -> $HOME/.config/hypr/hyprland.conf
#
# Idempotent. If a real file is already at the target, it's renamed to
# <target>.bak.<timestamp> before the symlink replaces it.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
TS="$(date +%Y%m%d-%H%M%S)"

cd "$ROOT/dotfiles"
while IFS= read -r -d '' rel; do
  rel="${rel#./}"

  # Prepend '.' to the first path component.
  first="${rel%%/*}"
  rest="${rel#"$first"}"
  target="$HOME/.${first}${rest}"

  src="$ROOT/dotfiles/$rel"

  # Already correctly symlinked?
  if [ -L "$target" ] && [ "$(readlink "$target")" = "$src" ]; then
    echo "ok    $target"
    continue
  fi

  mkdir -p "$(dirname "$target")"

  if [ -e "$target" ] || [ -L "$target" ]; then
    backup="$target.bak.$TS"
    echo "back  $target -> $backup"
    mv "$target" "$backup"
  fi

  ln -s "$src" "$target"
  echo "link  $target -> $src"
done < <(find . -type f -print0)

# Garbage-collect orphans: symlinks under $HOME that point into our
# dotfiles tree but whose source no longer exists. Without this, deleting
# a file from dotfiles/ leaves a dangling symlink at the old target —
# nvim's plugin loader (and similar tools) choke on those.
#
# Scoped to ~/.<top-level-dir> for each entry in dotfiles/ rather than
# scanning all of $HOME so we don't traverse npm/cargo/mise caches.
for entry in "$ROOT/dotfiles"/*; do
  scan="$HOME/.$(basename "$entry")"
  [ -e "$scan" ] || continue
  while IFS= read -r -d '' link; do
    tgt="$(readlink "$link")"
    case "$tgt" in
      "$ROOT/dotfiles/"*)
        if [ ! -e "$tgt" ]; then
          echo "gc    $link"
          rm "$link"
        fi
        ;;
    esac
  done < <(find "$scan" -type l -print0 2>/dev/null)
done
