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
TS="$(date +%Y%m%d-%H%M%S)"

cd "$HERE"
# All regular files under here, excluding this script itself.
while IFS= read -r -d '' rel; do
  rel="${rel#./}"
  [ "$rel" = "link.sh" ] && continue

  # Prepend '.' to the first path component.
  first="${rel%%/*}"
  rest="${rel#"$first"}"
  target="$HOME/.${first}${rest}"

  src="$HERE/$rel"

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
