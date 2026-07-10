#!/usr/bin/env python3
# PreToolUse hook for Bash: auto-allow pipelines/sequences whose every segment
# is a read-only command. Bails (silent exit) on any sign of writes, command
# substitution, subshells, or unknown commands — letting the default permission
# flow run.
#
# Evaluation order Claude Code uses for each tool call (verbatim from docs:
# "Rules are evaluated in order: deny -> ask -> allow. The first matching
# rule wins, so deny rules always take precedence."):
#
#   1. settings.json  permissions.deny   — hard block, can't be overridden
#   2. settings.json  permissions.ask    — forces a prompt even if hook says allow
#   3. THIS HOOK                         — can output {permissionDecision: allow}
#                                           to skip the prompt for safe commands
#   4. settings.json  permissions.allow  — pattern-match for whole-string allow
#   5. Default                           — prompt the user
#
# Lifecycle: settings.json is read once at session start, so changes need a
# session restart (or `claude --resume`) to take effect. This hook is a
# subprocess spawned per tool call, so edits land immediately — no restart.
#
# Practical implications:
# - A hook that outputs "allow" wins over settings.json's allow (step 4 isn't
#   reached) but loses to deny/ask (steps 1–2 fire first regardless).
# - Anything this hook auto-allows makes the equivalent settings.json allow
#   pattern dead code. settings.json allow patterns only matter for commands
#   the hook stays silent on.
# - settings.json deny is the only true hard block. Hooks cannot circumvent it.

import json
import shlex
import sys

# First word of each pipeline segment must be in here.
ALLOWLIST = {
    # core file/dir reads
    "ls", "pwd", "cd", "cat", "head", "tail", "tac", "rev", "wc", "file",
    "stat", "du", "df", "tree", "which", "type", "command", "basename",
    "dirname", "realpath", "readlink", "less", "more",
    # search
    "grep", "rg", "egrep", "fgrep", "find", "fd", "ack", "pcregrep", "ag",
    # text shuffling/transform (read-only)
    "echo", "printf", "diff", "cmp", "colordiff", "jq", "yq", "sort", "uniq",
    "cut", "tr", "awk", "sed", "paste", "join", "comm", "pr", "nl", "fold",
    "fmt", "expand", "unexpand", "column", "shuf", "seq",
    # binary inspection
    "xxd", "od", "hexdump", "strings", "ldd", "nm", "objdump", "readelf",
    # checksums
    "md5sum", "sha1sum", "sha256sum", "sha512sum", "b2sum", "cksum",
    # math / logic
    "true", "false", "test", "[", "expr", "bc", "factor",
    # system info (no network, no writes)
    "whoami", "id", "hostname", "uname", "groups", "tty", "uptime", "w",
    "who", "users", "printenv", "date", "cal", "free", "vmstat", "iostat",
    "ps", "lsof", "ss", "netstat", "pgrep", "pidof",
    # code stats
    "tokei", "scc", "cloc",
}

# `git <subcmd>` allowed only when subcmd is in here. `config` and
# `stash` need further nested checks (see segment_allowed below).
GIT_READ_SUBCMDS = {
    "log", "status", "show", "diff", "blame", "remote", "rev-parse",
    "ls-files", "ls-tree", "reflog", "describe", "tag", "branch",
    "shortlog", "for-each-ref", "name-rev", "show-ref", "cat-file",
    "config", "stash",
}

# `git config` requires one of these flags (read-only forms).
GIT_CONFIG_READ_FLAGS = {"--list", "-l", "--get", "--get-all",
                         "--get-regexp", "--get-urlmatch"}

# `git stash` is mostly destructive (push, pop, drop, apply, clear,
# bare `stash` saves a new entry). Only `list` and `show` read.
GIT_STASH_READ_SUBCMDS = {"list", "show"}

# Commands that mix read/auto-allow subcommands with write/dangerous
# ones — they can't go in the simple ALLOWLIST because, e.g., `pacman
# -S <pkg>` installs (write). Each entry maps command → (set of
# allowed first-args after any leading flags, skip_leading_flags).
#
# Most entries here are pure-read (pacman -Q, systemctl status, etc).
# A few are not strictly read-only but trusted enough to chain
# (`cargo build`, `bluetoothctl scan`) — these also live in
# settings.json's permissions.allow as the auditable record. The hook
# entry exists so the same trust applies inside pipelines/sequences.
# Standalone forms with flag-values the hook can't express (e.g.
# `bluetoothctl --timeout 5 scan on`) rely on settings.allow alone.
#
# skip_leading_flags=True walks past tokens that start with "-" before
# checking the subcommand position. Used by tools like `hyprctl -j
# clients` where -j is a global flag and `clients` is the actual
# subcommand. Set False for pacman-style tools where the operation
# itself starts with "-" (`pacman -Q`). Note: this skips dash-prefixed
# tokens but NOT the *values* that follow them — so it can't match
# `cmd --flag value sub` patterns.
SUBCMD_READ_OPS = {
    "pacman": ({
        # query installed
        "-Q", "-Qi", "-Ql", "-Qm", "-Qe", "-Qd", "-Qn", "-Qq",
        "-Qk", "-Qo", "-Qp", "-Qs", "-Qg", "-Qt", "-Qu",
        # sync repo reads (info, search, list, groups)
        "-Si", "-Ss", "-Sl", "-Sg",
        # file database reads (list, owner, search, regex). -Fy/-Fyy
        # download/refresh the file db (mutation) — kept out.
        "-Fl", "-Fo", "-Fs", "-Fx",
        # version / help
        "-V", "--version", "-h", "--help",
    }, False),
    # yay shares pacman's flag set for its read ops.
    "yay": (None, False),  # filled in below to alias pacman
    "hyprctl": ({
        "version", "monitors", "workspaces", "activeworkspace",
        "workspacerules", "clients", "devices", "decorations", "binds",
        "layers", "splash", "getoption", "cursorpos", "animations",
        "instances", "layouts", "configerrors", "rollinglog",
        "globalshortcuts", "systeminfo", "activewindow",
    }, True),
    "xdg-mime": ({"query", "--help", "-h"}, False),
    # fuzzel without args opens the launcher (a UI mutation), so only
    # the inspection flags get the auto-allow.
    "fuzzel": ({"--version", "-v", "--help", "-h"}, False),
    # systemctl: status/is-* commands and various list/show forms are
    # all read-only; start/stop/restart/enable/disable mutate.
    # skip_flags=True so `systemctl --user status X` works (--user/
    # --system/--no-pager are global flags before the operation).
    "systemctl": ({
        "status", "is-active", "is-enabled", "is-failed",
        "list-units", "list-unit-files", "list-jobs", "list-timers",
        "list-sockets", "list-dependencies", "list-machines",
        "show", "cat", "get-default", "show-environment",
        "--version", "-V", "--help", "-h",
    }, True),
    # gh has many top-level subcommands. We allow only `search` here
    # (always read). Other reads (`pr view`, `repo view`, etc.) need
    # second-level checks; add when actually needed.
    "gh": ({"search", "--version", "--help", "-h"}, False),
    # bluetoothctl: inspection plus `scan` (which flips the adapter
    # into discovery mode — not strictly read, but trusted enough to
    # chain with `; bluetoothctl devices`). `pair`/`connect`/
    # `disconnect`/`power`/`trust`/`untrust` change persistent state
    # and stay out. `--timeout N scan on` can't be expressed here (the
    # hook can't skip flag-values), so the bounded form lives in
    # settings.allow.
    "bluetoothctl": ({
        "show", "devices", "info", "list", "scan",
        "--version", "-v", "--help", "-h",
    }, False),
    # cargo: `build` writes to target/, so it's not read-only — but
    # the user has blessed it as auto-runnable in settings.allow, and
    # we want the same trust inside pipelines (e.g. `cargo build 2>&1
    # | grep error`). Other subcommands (run, install, publish, etc.)
    # are intentionally excluded — extend deliberately, not blanket.
    "cargo": ({"build", "--version", "-V", "--help", "-h"}, True),
}
SUBCMD_READ_OPS["yay"] = (SUBCMD_READ_OPS["pacman"][0], False)

# Disallow sed in-place edit and similar.
SED_BAD_FLAGS = {"-i", "--in-place"}

# journalctl is mostly read, but a handful of flags mutate the journal
# (vacuum/rotate/flush) or write to disk (--update-catalog,
# --setup-keys). Reject these; allow all other invocations.
JOURNALCTL_BAD_FLAGS = {
    "--rotate", "--flush", "--sync", "--relinquish-var",
    "--smart-relinquish-var", "--update-catalog", "--setup-keys",
    "--vacuum-size", "--vacuum-time", "--vacuum-files",
}

# Substrings that, if present in the unquoted portion of the command,
# disqualify auto-allow. Covers subshells, command substitution, process
# substitution, and backgrounding. Redirects are checked separately (we
# tolerate stderr-to-/dev/null and fd-to-fd merges).
DANGER_SUBSTRINGS = (
    "$(", "`", "<(", ">(", "(", ")", "&", "\n",
)


def strip_quotes(cmd: str) -> str:
    """Return the command with single/double-quoted regions removed."""
    out = []
    in_s = in_d = False
    i = 0
    n = len(cmd)
    while i < n:
        c = cmd[i]
        if in_s:
            if c == "'":
                in_s = False
        elif in_d:
            if c == '"':
                in_d = False
            elif c == "\\" and i + 1 < n:
                i += 1
        elif c == "'":
            in_s = True
        elif c == '"':
            in_d = True
        elif c == "\\" and i + 1 < n:
            i += 1  # skip escaped char
        else:
            out.append(c)
        i += 1
    return "".join(out)


def scrub_redirects(s: str):
    """Walk s, blank out each redirect (op + target) with spaces. Returns
    (cleaned_string, unsafe_redirect_found). A redirect is unsafe if its
    target isn't /dev/null or a numeric fd, or if it's a heredoc."""
    out = list(s)
    unsafe = False
    i = 0
    n = len(s)
    while i < n:
        c = s[i]
        if c not in "<>":
            i += 1
            continue
        start = i
        is_heredoc = c == "<" and i + 1 < n and s[i + 1] == "<"
        j = i
        while j < n and s[j] in "<>":
            j += 1
        if j < n and s[j] == "&":
            j += 1
        while j < n and s[j] in " \t":
            j += 1
        tgt_start = j
        while j < n and s[j] not in " \t|&;<>":
            j += 1
        target = s[tgt_start:j]
        if is_heredoc:
            unsafe = True
        elif target and target != "/dev/null" and not target.isdigit():
            unsafe = True
        for k in range(start, j):
            out[k] = " "
        i = j
    return "".join(out), unsafe


def has_danger(cmd: str) -> bool:
    s = strip_quotes(cmd)
    # `&&` and `||` are safe sequencers; remove before scanning for `&` and `|`.
    s = s.replace("&&", "  ").replace("||", "  ")
    s, unsafe_redir = scrub_redirects(s)
    if unsafe_redir:
        return True
    return any(d in s for d in DANGER_SUBSTRINGS)


def split_pipeline(cmd: str):
    """Split on |, ||, &&, ; respecting quotes/escapes. Pure pipelines only —
    we've already rejected things like (, ), &, redirects in has_danger."""
    segs = []
    buf = []
    in_s = in_d = False
    i = 0
    n = len(cmd)
    while i < n:
        c = cmd[i]
        nxt = cmd[i + 1] if i + 1 < n else ""
        if in_s:
            buf.append(c)
            if c == "'":
                in_s = False
        elif in_d:
            buf.append(c)
            if c == '"':
                in_d = False
            elif c == "\\" and i + 1 < n:
                buf.append(cmd[i + 1])
                i += 1
        elif c == "'":
            buf.append(c); in_s = True
        elif c == '"':
            buf.append(c); in_d = True
        elif c == "\\" and i + 1 < n:
            buf.append(c); buf.append(cmd[i + 1]); i += 1
        elif c == "|" and nxt == "|":
            segs.append("".join(buf)); buf = []; i += 1
        elif c == "|":
            segs.append("".join(buf)); buf = []
        elif c == "&" and nxt == "&":
            segs.append("".join(buf)); buf = []; i += 1
        elif c == ";":
            segs.append("".join(buf)); buf = []
        else:
            buf.append(c)
        i += 1
    if buf:
        segs.append("".join(buf))
    return [s.strip() for s in segs if s.strip()]


def is_env_assignment(tok: str) -> bool:
    eq = tok.find("=")
    if eq <= 0:
        return False
    name = tok[:eq]
    return name[0].isalpha() and all(ch.isalnum() or ch == "_" for ch in name)


def segment_allowed(seg: str) -> bool:
    try:
        tokens = shlex.split(seg)
    except ValueError:
        return False
    # Skip leading env var assignments: FOO=bar BAZ=qux cmd ...
    while tokens and is_env_assignment(tokens[0]):
        tokens.pop(0)
    if not tokens:
        return False

    cmd = tokens[0]

    if cmd == "git":
        if len(tokens) < 2:
            return False
        sub = tokens[1]
        if sub not in GIT_READ_SUBCMDS:
            return False
        if sub == "config":
            # Require at least one read-only flag.
            return any(t in GIT_CONFIG_READ_FLAGS for t in tokens[2:])
        if sub == "stash":
            # `git stash` (no further args) saves a new stash — write.
            # Only allow when an explicit read-only subsubcmd follows.
            return len(tokens) >= 3 and tokens[2] in GIT_STASH_READ_SUBCMDS
        return True

    if cmd == "sed":
        # Reject in-place edits.
        return not any(t in SED_BAD_FLAGS or t.startswith("-i")
                       for t in tokens[1:])

    if cmd == "journalctl":
        # Reject the mutating flags; everything else is read.
        # Match exact tokens and `--vacuum-*=N` forms.
        for t in tokens[1:]:
            if t in JOURNALCTL_BAD_FLAGS:
                return False
            if t.startswith("--vacuum-") and "=" in t:
                return False
        return True

    if cmd in SUBCMD_READ_OPS:
        allowed, skip_flags = SUBCMD_READ_OPS[cmd]
        i = 1
        if skip_flags:
            while i < len(tokens) and tokens[i].startswith("-"):
                i += 1
        return i < len(tokens) and tokens[i] in allowed

    return cmd in ALLOWLIST


def main() -> None:
    try:
        data = json.load(sys.stdin)
    except Exception:
        return
    if data.get("tool_name") != "Bash":
        return
    cmd = data.get("tool_input", {}).get("command", "") or ""
    if not cmd or has_danger(cmd):
        return
    segs = split_pipeline(cmd)
    if not segs:
        return
    if not all(segment_allowed(s) for s in segs):
        return

    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "allow",
            "permissionDecisionReason": "All pipeline segments are read-only.",
        }
    }))


if __name__ == "__main__":
    try:
        main()
    except Exception:
        # Never block the user's normal flow on a hook bug.
        pass
