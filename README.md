# Orchard

My Arch configuration for Apple silicon Macs (Asahi Linux).

# Install

On an M1/M2 machine:

```
curl https://asahi-alarm.org/installer-bootstrap.sh | sh
```

After rebooting into arch, connect to wifi and install:

```
nmtui
pacman -Sy --noconfirm git
git clone https://github.com/pachun/orchard /tmp/orchard
bash /tmp/orchard/setup/bootstrap.sh
```

# Install modes

`setup/install.sh` accepts a mode argument: `desktop` (default — the full
graphical setup the Asahi bootstrap flow produces) or `cli` (a server
subset with just the shell, editor, multiplexer, mise, claude, and core
CLI tools — no graphical environment). The Asahi bootstrap above runs
`desktop`; pass `cli` explicitly for a headless install:

```
bash setup/install.sh cli
```

The active mode is persisted to `~/.config/orchard/mode` so zsh sources
the right zshrc.d subset on every startup.

# Connect accounts

`setup/install.sh` is fully unattended — anything that needs you to log in
or paste credentials lives under `setup/connect/` instead, run on demand:

```
bash setup/connect.sh                # list what's available
bash setup/connect/<name>.sh         # run a specific one
```

Each subscript is idempotent: re-running detects the already-connected
state and skips. Currently:

- **gcalcli** — Google Calendar CLI. Walks you through creating an OAuth
  client in Google Cloud Console (about 3 minutes of clicks across 4 pages
  — the script opens each in chromium and waits between steps), then runs
  `gcalcli init` to complete the OAuth flow.

- **tailscale** — joins this machine to your tailnet. Runs `tailscale up`,
  which opens a browser to authenticate; sign in with the same account the
  Mac mini uses so both devices share one tailnet. The `tailscaled` daemon
  itself is enabled unattended by `setup/install/desktop/tailscale/install.sh`;
  this just logs in.

- **icloud** — mounts the Mac mini's iCloud Drive at `~/icloud` over sshfs.
  Run the **tailscale** connect first, and enable Remote Login on the Mac
  (System Settings → General → Sharing). Installs this machine's SSH key on
  the Mac (one password prompt the first time), then sets up a `systemd
  --user` service that keeps `~/icloud` mounted and reconnecting across
  reboots. Prompts for the Mac's tailnet hostname / username (defaults
  `mac-mini` / `nick`).
