#!/usr/bin/env python3
"""Claude Code hook — surface a finished turn as a waybar notification.

Wired to two events in settings.json, both pointing here with a different
argument so the script knows which fired:

  UserPromptSubmit -> `notify-when-done.py start`  (stamp turn start)
  Stop             -> `notify-when-done.py stop`   (notify if it was long)

A long task lets your attention wander, so when it finishes we raise a
notification naming the tmux session it ran in. Clicking it in the bar jumps you
back to that session — see the orchard-notifications daemon, which reads the
session off a hint, and open-tmux-session, which does the switch. A quick reply
stays silent; you were almost certainly still watching the screen.

The notification is deliberately soundless (the x-orchard-silent hint). It
stands in for the finish chime this hook used to play, rather than adding a
second noise on top of the bar's own notification ding.

State is a per-session stamp file under $XDG_RUNTIME_DIR (or /tmp). `stop`
deletes it after reading, so a second Stop with no prompt in between (resume,
/clear, compaction) can't replay a stale notification.
"""
import json
import os
import subprocess
import sys
import time
from pathlib import Path

# Turns shorter than this finish silently. Raise it if quick tasks notify when
# you didn't need them; lower it if you miss the ones you wanted.
THRESHOLD_SECONDS = 10


def hook_input():
    try:
        return json.load(sys.stdin)
    except (json.JSONDecodeError, ValueError, OSError):
        return {}


def stamp_path(session_id):
    runtime = os.environ.get("XDG_RUNTIME_DIR") or "/tmp"
    safe = "".join(c for c in session_id if c.isalnum() or c in "-_") or "default"
    return Path(runtime) / f"claude-turn-start-{safe}"


def tmux_session():
    """The tmux session this turn ran in, or "" if Claude isn't inside tmux.
    Hooks inherit Claude's environment, so $TMUX_PANE points at the right pane."""
    if not os.environ.get("TMUX"):
        return ""
    pane = os.environ.get("TMUX_PANE")
    target = ["-t", pane] if pane else []
    try:
        shown = subprocess.run(
            ["tmux", "display-message", "-p", *target, "#S"],
            capture_output=True,
            text=True,
        )
        return shown.stdout.strip()
    except OSError:
        return ""


def announce_finished(cwd):
    session = tmux_session()
    where = session or (Path(cwd).name if cwd else "Claude")
    hints = ["--hint=string:x-orchard-silent:1"]
    if session:
        hints.append(f"--hint=string:x-orchard-tmux-session:{session}")
    try:
        subprocess.Popen(
            ["notify-send", "--app-name=Claude", *hints, where, "Claude finished"],
            stdin=subprocess.DEVNULL,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            start_new_session=True,
        )
    except OSError:
        pass


def main():
    mode = sys.argv[1] if len(sys.argv) > 1 else ""
    hook = hook_input()
    path = stamp_path(str(hook.get("session_id") or ""))

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
            announce_finished(str(hook.get("cwd") or ""))


if __name__ == "__main__":
    main()
