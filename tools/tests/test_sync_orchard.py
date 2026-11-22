import contextlib
import subprocess
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from tools.sync_orchard import sync_checkout, sync_host


def git(directory, *arguments):
    return subprocess.check_output(
        ["git", "-C", str(directory), *arguments], text=True, stderr=subprocess.DEVNULL
    ).strip()


@contextlib.contextmanager
def published_change():
    with tempfile.TemporaryDirectory() as directory:
        root = Path(directory)
        origin = root / "origin.git"
        origin.mkdir()
        git(origin, "init", "--bare", "--initial-branch=main")
        author = root / "author"
        git(root, "clone", str(origin), str(author))
        git(author, "config", "user.name", "Example")
        git(author, "config", "user.email", "example@example.invalid")
        (author / "setting").write_text("old\n")
        git(author, "add", "setting")
        git(author, "commit", "-m", "Initial")
        git(author, "push", "origin", "main")
        peer = root / "peer"
        git(root, "clone", str(origin), str(peer))
        (author / "setting").write_text("new\n")
        git(author, "commit", "-am", "Update")
        git(author, "push", "origin", "main")
        yield peer, str(origin), git(author, "rev-parse", "HEAD")


class OrchardSynchronization(unittest.TestCase):
    def test_an_offline_machine_is_reported_without_attempting_ssh(self):
        status = {
            "Self": {"DNSName": "runner.example."},
            "Peer": {"peer": {"DNSName": "laptop.example.", "Online": False}},
        }
        with patch("subprocess.run") as ssh:
            self.assertEqual(
                sync_host("laptop.example", status, "main", "commit", "origin"),
                "offline",
            )
            ssh.assert_not_called()

    def test_an_unresponsive_online_machine_is_reported_as_blocked(self):
        status = {
            "Self": {"DNSName": "runner.example."},
            "Peer": {"peer": {"DNSName": "laptop.example.", "Online": True}},
        }
        with patch("subprocess.run", side_effect=subprocess.TimeoutExpired("ssh", 40)):
            self.assertEqual(
                sync_host("laptop.example", status, "main", "commit", "origin"),
                "blocked: remote pull failed",
            )

    def test_local_commits_are_not_rebased_or_reset(self):
        with published_change() as (peer, origin, commit):
            git(peer, "config", "user.name", "Example")
            git(peer, "config", "user.email", "example@example.invalid")
            (peer / "local-work").write_text("keep me\n")
            git(peer, "add", "local-work")
            git(peer, "commit", "-m", "Local work")
            before = git(peer, "rev-parse", "HEAD")
            self.assertEqual(
                sync_checkout(peer, "main", commit, origin),
                "blocked: fast-forward pull did not complete",
            )
            self.assertEqual(git(peer, "rev-parse", "HEAD"), before)

    def test_an_online_clean_checkout_receives_the_pushed_change(self):
        with published_change() as (peer, origin, commit):
            self.assertEqual(sync_checkout(peer, "main", commit, origin), "updated")
            self.assertEqual((peer / "setting").read_text(), "new\n")
            self.assertEqual(git(peer, "rev-parse", "HEAD"), commit)

    def test_preserves_local_work_and_reports_a_blocked_pull(self):
        with published_change() as (peer, origin, commit):
            (peer / "setting").write_text("my work\n")
            before = git(peer, "rev-parse", "HEAD")
            self.assertEqual(
                sync_checkout(peer, "main", commit, origin), "blocked: local changes"
            )
            self.assertEqual((peer / "setting").read_text(), "my work\n")
            self.assertEqual(git(peer, "rev-parse", "HEAD"), before)

    def test_does_not_switch_a_peer_off_its_working_branch(self):
        with published_change() as (peer, origin, commit):
            git(peer, "switch", "-c", "work")
            self.assertEqual(
                sync_checkout(peer, "main", commit, origin), "blocked: different branch"
            )
            self.assertEqual(git(peer, "branch", "--show-current"), "work")

    def test_an_up_to_date_checkout_can_keep_uncommitted_work(self):
        with published_change() as (peer, origin, commit):
            sync_checkout(peer, "main", commit, origin)
            (peer / "local-notes").write_text("keep me\n")
            self.assertEqual(sync_checkout(peer, "main", commit, origin), "current")
            self.assertTrue((peer / "local-notes").exists())
