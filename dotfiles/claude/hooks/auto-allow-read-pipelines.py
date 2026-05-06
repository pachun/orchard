#!/usr/bin/env python3
# PreToolUse hook for Bash: auto-allow pipelines/sequences whose every segment
# is a read-only command. Bails (silent exit) on any sign of writes, command
# substitution, subshells, or unknown commands — letting the default permission
# flow run.

import json
import shlex
import sys

# First word of each pipeline segment must be in here.
ALLOWLIST = {
    # core file/dir reads
    "ls", "pwd", "cat", "head", "tail", "tac", "rev", "wc", "file", "stat",
    "du", "df", "tree", "which", "type", "command", "basename", "dirname",
    "realpath", "readlink", "less", "more",
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

# `git <subcmd>` allowed only when subcmd is in here.
GIT_READ_SUBCMDS = {
    "log", "status", "show", "diff", "blame", "remote", "rev-parse",
    "ls-files", "ls-tree", "reflog", "describe", "tag", "branch",
    "shortlog", "for-each-ref", "name-rev", "show-ref", "cat-file",
    "config",  # only --list/--get tolerated; we further restrict below
}

# `git config` requires one of these flags (read-only forms).
GIT_CONFIG_READ_FLAGS = {"--list", "-l", "--get", "--get-all",
                         "--get-regexp", "--get-urlmatch"}

# Disallow sed in-place edit and similar.
SED_BAD_FLAGS = {"-i", "--in-place"}

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
        return True

    if cmd == "sed":
        # Reject in-place edits.
        return not any(t in SED_BAD_FLAGS or t.startswith("-i")
                       for t in tokens[1:])

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
