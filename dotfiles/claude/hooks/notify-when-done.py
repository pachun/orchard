#!/usr/bin/env python3
"""Claude Code hook — chime when a long turn finishes.

Wired to two events in settings.json, both pointing at this file but
with a different argument so the script knows which fired:

  UserPromptSubmit -> `notify-when-done.py start`  (stamp turn start)
  Stop             -> `notify-when-done.py stop`   (chime if it was long)

Rationale: a long task lets your attention wander, so a chime calls
you back. A quick reply stays silent — you were almost certainly
still watching the screen anyway.

State is a per-session stamp file under $XDG_RUNTIME_DIR (or /tmp).
`stop` deletes it after reading, so a second Stop with no prompt in
between (resume, /clear, compaction) can't replay a stale chime.
"""
import json
import os
import shutil
import subprocess
import sys
import time
from pathlib import Path

# Turns shorter than this finish silently. Raise it if quick tasks
# chime when you didn't need them; lower it if you miss notifications.
THRESHOLD_SECONDS = 60


def stamp_path(session_id: str) -> Path:
    runtime = os.environ.get("XDG_RUNTIME_DIR") or "/tmp"
    safe = "".join(c for c in session_id if c.isalnum() or c in "-_") or "default"
    return Path(runtime) / f"claude-turn-start-{safe}"


def play_chime() -> None:
    sound = Path(__file__).resolve().parent / "done.wav"
    if not sound.exists():
        return
    player = shutil.which("pw-play") or shutil.which("paplay")
    if not player:
        return
    # Detach so the hook returns immediately instead of blocking until
    # playback finishes.
    try:
        subprocess.Popen(
            [player, str(sound)],
            stdin=subprocess.DEVNULL,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            start_new_session=True,
        )
    except OSError:
        pass


def session_id_from_stdin() -> str:
    """Best-effort: key the stamp file per session so concurrent Claude
    sessions don't clobber each other. Falls back to a shared file."""
    try:
        return str(json.load(sys.stdin).get("session_id") or "")
    except (json.JSONDecodeError, ValueError, OSError):
        return ""


def main() -> None:
    mode = sys.argv[1] if len(sys.argv) > 1 else ""
    path = stamp_path(session_id_from_stdin())

    if mode == "start":
        try:
            path.write_text(str(time.time()))
        except OSError:
            pass
    elif mode == "stop":
        try:
            started = float(path.read_text().strip())
        except (OSError, ValueError):
            return  # no fresh turn recorded — stay silent
        try:
            path.unlink()
        except OSError:
            pass
        if time.time() - started >= THRESHOLD_SECONDS:
            play_chime()


if __name__ == "__main__":
    main()
