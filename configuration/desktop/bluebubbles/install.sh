#!/usr/bin/env bash
# BlueBubbles desktop client — pairs with BlueBubbles Server running on an
# always-on Mac (the Mac handles iMessage; this is the Linux UI).
#
# Preferred client settings: the app defaults a couple of Private API options
# off that we want on. They live in the app's own shared_preferences file —
# alongside the server address and password, which are per-machine secrets, so
# we can't ship the file; we patch just these two keys into it and leave the
# rest untouched. That file only exists once BlueBubbles has been run and
# paired, so on a fresh machine these take hold after you've set it up and
# re-run configure. They apply on the next BlueBubbles launch (it reads prefs
# at startup).
#   privateAPIAttachmentSend — send images/files over the Private API; the
#     legacy AppleScript attachment send times out on macOS Tahoe.
#   privateMarkChatAsRead — reading a chat here marks it read on the Mac, so
#     the phone's unread count clears the way it would on a real Mac.
# Idempotent.
set -euo pipefail

bash "$TOOLS/install-yay.sh"
yay -S --needed --noconfirm bluebubbles-bin

prefs="$HOME/.local/share/app.bluebubbles.BlueBubbles/shared_preferences.json"
if [ -f "$prefs" ]; then
  python3 - "$prefs" <<'PY'
import json, os, sys
f = sys.argv[1]
d = json.load(open(f))
changed = False
for k in ("flutter.privateAPIAttachmentSend", "flutter.privateMarkChatAsRead"):
    if d.get(k) is not True:
        d[k] = True
        changed = True
if changed:
    tmp = f + ".tmp"
    json.dump(d, open(tmp, "w"), separators=(",", ":"), ensure_ascii=False)
    os.replace(tmp, f)
PY
fi
