#!/usr/bin/env python3
import getpass
import inspect
import json
import re
import subprocess
from pathlib import Path

NETWORK_TIMEOUT_SECONDS = 30
SSH_CONNECT_TIMEOUT_SECONDS = 5
SSH_EXIT_GRACE_SECONDS = 10


def git(directory, *arguments):
    return subprocess.check_output(
        ["git", "-C", str(directory), *arguments],
        text=True,
        stderr=subprocess.DEVNULL,
        timeout=NETWORK_TIMEOUT_SECONDS,
    ).strip()


def sync_checkout(directory, branch, commit, origin):
    if git(directory, "remote", "get-url", "origin") != origin:
        return "blocked: different origin"
    elif git(directory, "branch", "--show-current") != branch:
        return "blocked: different branch"
    elif git(directory, "rev-parse", "HEAD") == commit:
        return "current"
    elif git(directory, "status", "--porcelain"):
        return "blocked: local changes"
    else:
        try:
            git(directory, "pull", "--ff-only", "origin", branch)
            git(directory, "merge-base", "--is-ancestor", commit, "HEAD")
        except (subprocess.CalledProcessError, subprocess.TimeoutExpired):
            return "blocked: fast-forward pull did not complete"
        else:
            return "updated"


def sync_host(host, status, branch, commit, origin):
    current_host = status["Self"]["DNSName"].rstrip(".")
    peers = {
        peer["DNSName"].rstrip("."): peer for peer in status.get("Peer", {}).values()
    }
    if host == current_host:
        return sync_checkout(Path.home() / "code/orchard", branch, commit, origin)
    elif not peers.get(host, {}).get("Online", False):
        return "offline"
    else:
        remote_code = "\n".join(
            [
                "import json, subprocess",
                "from pathlib import Path",
                f"NETWORK_TIMEOUT_SECONDS = {NETWORK_TIMEOUT_SECONDS}",
                inspect.getsource(git),
                inspect.getsource(sync_checkout),
                f"print(sync_checkout(Path.home() / 'code/orchard', {branch!r}, {commit!r}, {origin!r}))",
            ]
        )
        try:
            result = subprocess.run(
                [
                    "ssh",
                    "-o",
                    "BatchMode=yes",
                    "-o",
                    f"ConnectTimeout={SSH_CONNECT_TIMEOUT_SECONDS}",
                    f"{getpass.getuser()}@{host}",
                    "python3 -",
                ],
                check=False,
                input=remote_code,
                text=True,
                capture_output=True,
                timeout=NETWORK_TIMEOUT_SECONDS + SSH_EXIT_GRACE_SECONDS,
            )
        except (OSError, subprocess.TimeoutExpired):
            return "blocked: remote pull failed"
        else:
            return (
                result.stdout.strip()
                if result.returncode == 0
                else "blocked: remote pull failed"
            )


def main():
    configuration = Path.home() / ".config/orchard-private/orchard-machines.json"
    if configuration.is_file():
        hosts = json.loads(configuration.read_text())["hosts"]
        if not isinstance(hosts, list) or not all(
            isinstance(host, str) and re.fullmatch(r"[a-zA-Z0-9.-]+", host)
            for host in hosts
        ):
            raise ValueError("Invalid Orchard machine configuration")
        directory = Path(__file__).resolve().parents[1]
        branch = git(directory, "branch", "--show-current")
        commit = git(directory, "rev-parse", "HEAD")
        origin = git(directory, "remote", "get-url", "origin")
        published = git(
            directory, "ls-remote", "origin", f"refs/heads/{branch}"
        ).split()
        if not published or published[0] != commit:
            raise ValueError(
                "Push the current branch successfully before synchronizing."
            )
        status = json.loads(
            subprocess.check_output(
                ["tailscale", "status", "--json"],
                text=True,
                timeout=NETWORK_TIMEOUT_SECONDS,
            )
        )
        results = tuple(
            (host, sync_host(host, status, branch, commit, origin)) for host in hosts
        )
        for host, result in results:
            print(f"{host}: {result}")
        return int(any(result.startswith("blocked:") for _, result in results))
    else:
        print("No private Orchard machines configured; no remote checkouts changed.")
        return 0


if __name__ == "__main__":
    raise SystemExit(main())
