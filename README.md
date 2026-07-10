# Orchard

My Arch configuration for Apple silicon Macs (Asahi Linux) and the
Dell XPS 14 (x86_64).

# Install

## Asahi (on an M1 or M2 Mac)

```
curl https://asahi-alarm.org/installer-bootstrap.sh | sh
```

After rebooting into arch, connect to wifi and run the base bringup:

```
nmtui
pacman -Sy --noconfirm git
git clone https://github.com/pachun/orchard /tmp/orchard
/tmp/orchard/install-arch/asahi
```

It reboots when done. After reboot, sign in and configure:

```
~/code/orchard/configure
```

## Dell XPS 14 (9440)

First, in the BIOS (press F2 at boot):

- **SATA Operation → AHCI** — the factory default (RAID) hides the NVMe
  from Linux, so the installer won't find a disk.
- **Secure Boot → Off**

Flash an [Arch ISO](https://archlinux.org/download/) to a USB drive and boot
from it.

```
pacman -Sy --noconfirm git
git clone https://github.com/pachun/orchard /tmp/orchard
/tmp/orchard/install-arch/dell-xps-14
```

After reboot, sign in, connect wifi, and install the shell + dev tools:

```
nmtui
~/code/orchard/configure cli
```

# Install modes

`configure` takes an optional mode: `desktop` (default — the full
graphical setup) or `cli` (a server subset: shell, editor, multiplexer,
mise, claude, and core CLI tools, no graphical environment):

```
./configure          # desktop (default)
./configure cli      # headless
```

The active mode is persisted to `~/.config/orchard/mode` so zsh sources
the right zshrc.d subset on every startup.

# Connect accounts

`configure` is fully unattended — anything that needs you to log in or
paste credentials lives under `connections/` instead, run on demand:

```
./connect                # list what's available
./connect <name>         # run a specific one
```

Each connection is idempotent: re-running detects the already-connected
state and skips. Currently:

- **gcalcli** — Google Calendar CLI. Walks you through creating an OAuth
  client in Google Cloud Console (about 3 minutes of clicks across 4 pages
  — the script opens each in chromium and waits between steps), then runs
  `gcalcli init` to complete the OAuth flow.

- **tailscale** — joins this machine to your tailnet. Runs `tailscale up`,
  which opens a browser to authenticate; sign in with the same account the
  Mac mini uses so both devices share one tailnet. The `tailscaled` daemon
  itself is enabled unattended by `configuration/desktop/tailscale/install.sh`;
  this just logs in.

- **icloud** — mounts the Mac mini's iCloud Drive at `~/icloud` over sshfs.
  Run the **tailscale** connect first, and enable Remote Login on the Mac
  (System Settings → General → Sharing). Installs this machine's SSH key on
  the Mac (one password prompt the first time), then sets up a `systemd
--user` service that keeps `~/icloud` mounted and reconnecting across
  reboots. Prompts for the Mac's tailnet hostname / username (defaults
  `mac-mini` / `nick`).
