#!/usr/bin/env python3
import os
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

UPDATE_ORCHARD = Path(__file__).resolve().parent.parent / "bin" / "update-orchard"
UPDATE_ORCHARD_IN_CHECKOUT = "configuration/cli/orchard-update/bin/update-orchard"

INSTALLER_THAT_LOGS_ITS_FEATURE = """#!/usr/bin/env bash
feature="$(basename "$(dirname "$(dirname "${BASH_SOURCE[0]}")")")/$(basename "$(dirname "${BASH_SOURCE[0]}")")"
echo "$feature" >> "$HOME/installers-run"
"""

INSTALLER_THAT_FAILS = INSTALLER_THAT_LOGS_ITS_FEATURE + "exit 1\n"


class UpdateOrchardTest(unittest.TestCase):
    def setUp(self):
        self.sandbox = Path(tempfile.mkdtemp(prefix="update-orchard-test-"))
        self.addCleanup(shutil.rmtree, self.sandbox)
        self.home = self.sandbox / "home"
        self.home.mkdir()
        self.origin = self.sandbox / "origin.git"
        self.another_machine = self.sandbox / "another-machine"
        self.this_machine = self.home / "code" / "orchard"

        self.run_command("git", "init", "--quiet", "--bare", "--initial-branch=main", self.origin)
        self.run_command("git", "clone", "--quiet", self.origin, self.another_machine)
        installed_script = self.another_machine / UPDATE_ORCHARD_IN_CHECKOUT
        installed_script.parent.mkdir(parents=True)
        shutil.copy(UPDATE_ORCHARD, installed_script)
        self.write_feature("cli/shell")
        self.write_feature("desktop/bar")
        self.push_from_another_machine("Set up the shell and the bar")
        self.run_command("git", "clone", "--quiet", self.origin, self.this_machine)

    def environment(self):
        return {
            **os.environ,
            "HOME": str(self.home),
            "XDG_STATE_HOME": str(self.home / ".local/state"),
            "XDG_CONFIG_HOME": str(self.home / ".config"),
            "GIT_AUTHOR_NAME": "Test",
            "GIT_AUTHOR_EMAIL": "test@example.com",
            "GIT_COMMITTER_NAME": "Test",
            "GIT_COMMITTER_EMAIL": "test@example.com",
        }

    def run_command(self, *command, directory=None, check=True):
        return subprocess.run(
            [str(part) for part in command],
            cwd=directory,
            env=self.environment(),
            capture_output=True,
            text=True,
            check=check,
        )

    def write_feature(self, feature, installer=INSTALLER_THAT_LOGS_ITS_FEATURE, note="first"):
        folder = self.another_machine / "configuration" / feature
        folder.mkdir(parents=True, exist_ok=True)
        (folder / "install.sh").write_text(installer)
        (folder / "note").write_text(note)

    def push_from_another_machine(self, subject):
        self.run_command("git", "add", "--all", directory=self.another_machine)
        self.run_command("git", "commit", "--quiet", "-m", subject, directory=self.another_machine)
        self.run_command("git", "push", "--quiet", "origin", "main", directory=self.another_machine)

    def update_orchard(self, *arguments, check=True):
        return self.run_command(
            "bash", self.this_machine / UPDATE_ORCHARD_IN_CHECKOUT, *arguments, check=check
        )

    def installers_run(self):
        log = self.home / "installers-run"
        return log.read_text().split() if log.exists() else []

    def test_applies_only_the_features_new_commits_touched(self):
        self.update_orchard("mark-applied")
        self.write_feature("cli/shell", note="changed")
        self.push_from_another_machine("Change the shell")

        self.update_orchard()

        self.assertEqual(self.installers_run(), ["cli/shell"])

    def test_applies_commits_that_were_pulled_but_never_applied(self):
        self.update_orchard("mark-applied")
        self.write_feature("desktop/bar", note="changed")
        self.push_from_another_machine("Change the bar")
        self.run_command("git", "pull", "--quiet", "--ff-only", directory=self.this_machine)

        self.update_orchard()

        self.assertEqual(self.installers_run(), ["desktop/bar"])

    def test_applies_nothing_when_nothing_changed(self):
        self.update_orchard()

        self.assertEqual(self.installers_run(), [])

    def test_leaves_desktop_features_alone_on_a_machine_without_a_desktop(self):
        self.update_orchard("mark-applied")
        mode = self.home / ".config/orchard/mode"
        mode.parent.mkdir(parents=True)
        mode.write_text("cli\n")
        self.write_feature("cli/shell", note="changed")
        self.write_feature("desktop/bar", note="changed")
        self.push_from_another_machine("Change the shell and the bar")

        self.update_orchard()

        self.assertEqual(self.installers_run(), ["cli/shell"])

    def test_retries_a_feature_whose_installer_failed(self):
        self.update_orchard("mark-applied")
        self.write_feature("cli/shell", installer=INSTALLER_THAT_FAILS)
        self.push_from_another_machine("Break the shell installer")

        first_update = self.update_orchard(check=False)
        self.update_orchard(check=False)

        self.assertNotEqual(first_update.returncode, 0)
        self.assertEqual(self.installers_run(), ["cli/shell", "cli/shell"])

    def test_retries_only_the_feature_whose_installer_failed(self):
        self.update_orchard("mark-applied")
        self.write_feature("cli/shell", installer=INSTALLER_THAT_FAILS)
        self.write_feature("desktop/bar", note="changed")
        self.push_from_another_machine("Break the shell installer and change the bar")

        self.update_orchard(check=False)
        self.update_orchard(check=False)

        self.assertEqual(
            self.installers_run(), ["cli/shell", "desktop/bar", "cli/shell"]
        )

    def test_pending_lists_only_the_feature_to_retry_after_a_failure(self):
        self.update_orchard("mark-applied")
        self.write_feature("cli/shell", installer=INSTALLER_THAT_FAILS)
        self.write_feature("desktop/bar", note="changed")
        self.push_from_another_machine("Break the shell installer and change the bar")

        self.update_orchard(check=False)
        pending = self.update_orchard("pending").stdout.splitlines()

        self.assertEqual(pending, ["Retry cli/shell, whose installer failed"])

    def test_stops_retrying_a_feature_once_its_installer_succeeds(self):
        self.update_orchard("mark-applied")
        self.write_feature("cli/shell", installer=INSTALLER_THAT_FAILS)
        self.push_from_another_machine("Break the shell installer")
        self.update_orchard(check=False)
        self.write_feature("cli/shell")
        self.push_from_another_machine("Mend the shell installer")

        self.update_orchard()
        self.update_orchard()
        pending = self.update_orchard("pending").stdout.splitlines()

        self.assertEqual(self.installers_run(), ["cli/shell", "cli/shell"])
        self.assertEqual(pending, [])

    def test_keeps_uncommitted_work_in_the_checkout(self):
        self.update_orchard("mark-applied")
        unfinished = self.this_machine / "configuration/desktop/bar/note"
        unfinished.write_text("unfinished local work")
        self.write_feature("cli/shell", note="changed")
        self.push_from_another_machine("Change the shell")

        self.update_orchard()

        self.assertEqual(unfinished.read_text(), "unfinished local work")
        self.assertEqual(self.installers_run(), ["cli/shell"])

    def test_pending_lists_feature_commits_not_yet_pulled(self):
        self.update_orchard("mark-applied")
        self.write_feature("cli/shell", note="changed")
        self.push_from_another_machine("Change the shell")

        pending = self.update_orchard("pending").stdout.splitlines()

        self.assertEqual(pending, ["Change the shell"])

    def test_pending_lists_feature_commits_pulled_but_not_applied(self):
        self.update_orchard("mark-applied")
        self.write_feature("cli/shell", note="changed")
        self.push_from_another_machine("Change the shell")
        self.run_command("git", "pull", "--quiet", "--ff-only", directory=self.this_machine)

        pending = self.update_orchard("pending").stdout.splitlines()

        self.assertEqual(pending, ["Change the shell"])

    def test_pending_ignores_commits_that_change_no_feature(self):
        self.update_orchard("mark-applied")
        (self.another_machine / "README.md").write_text("orchard")
        self.push_from_another_machine("Describe orchard")

        pending = self.update_orchard("pending").stdout.splitlines()

        self.assertEqual(pending, [])

    def test_pending_is_empty_after_updating(self):
        self.update_orchard("mark-applied")
        self.write_feature("cli/shell", note="changed")
        self.push_from_another_machine("Change the shell")

        self.update_orchard()
        pending = self.update_orchard("pending").stdout.splitlines()

        self.assertEqual(pending, [])


if __name__ == "__main__":
    unittest.main()
