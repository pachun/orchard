# grip renders by calling GitHub's Markdown API, and GitHub rate-limits
# anonymous callers to 60 requests an hour. Each save spends one, so an
# afternoon's editing runs out. A token raises the ceiling to 5000.
#
# Ask gh for that token at startup rather than storing it. A credential belongs
# in exactly one place and gh already keeps it in the keyring; copying it here
# would put a repo-scoped token in a dotfiles repo, and handing it to grip on
# the command line would publish it to `ps` for every process on the machine.
#
# Having no token is not an error. gh missing, or logged out, just means the
# anonymous cap applies — which still previews a file perfectly well, right up
# until you've saved sixty times in an hour.
import subprocess


def token_from_gh():
    try:
        gh = subprocess.run(
            ["gh", "auth", "token"], capture_output=True, text=True, timeout=5
        )
    except (OSError, subprocess.TimeoutExpired):
        return None
    return gh.stdout.strip() or None


PASSWORD = token_from_gh()
QUIET = True
