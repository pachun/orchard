#!/usr/bin/env bash
# The PDF viewer, and the thing you fill in and sign PDFs with — the
# ground macOS's Preview covered: tick checkboxes and type into real form
# fields, drop free-text boxes onto forms that have none, draw with ink in
# any color, and place a visual signature drawn by hand or imported from an
# image. Shapes (rectangles, arrows, ruled lines) are the one Preview tool
# it lacks; freehand ink stands in.
#
# Papers rather than Okular or Xournal++. Okular does everything but pulls
# in the better part of KDE. Xournal++ has shapes but doesn't understand
# form fields — you type over them and export a flattened copy. Papers is
# GTK4, so it wears the same theme as Nautilus and follows the desktop's
# light and dark through set-theme's color-scheme.
#
# Papers is already pulled in by sushi (the file browser's Quick Look).
# It's installed here by name so it stays even if that dependency goes
# away. Without the xdg-mime line Chromium claims PDFs, and Chromium can
# fill forms but not sign or mark them up.
# Idempotent.
set -euo pipefail
TOOLS="${TOOLS:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)/tools}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

sudo pacman -S --needed --noconfirm papers
xdg-mime default org.gnome.Papers.desktop application/pdf

bash "$TOOLS/link.sh" "$HERE/launcher" "$HOME/.config/launcher"
