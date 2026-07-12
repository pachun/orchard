<p align="center">
  <img src="orchard.png" alt="Orchard" width="200">
</p>

<p align="center"><em>There's a garden outside Apple's</em></p>

<h1 align="center">Orchard</h1>

My Arch configuration for the Dell XPS (2026) and M1/M2 Macs.

# Install

## On a Dell XPS 14 (DA14260)

Flash an [Arch ISO](https://archlinux.org/download/) to a USB drive.

Boot into the XPS's BIOS by pressing F2 during boot.

- Turn off secure boot
- Adjust the boot order to prioritize booting from the USB drive
- Boot into the USB drive and connect to wifi `iwctl --passphrase "PASS" station wlan0 connect "SSID"`
- Install Arch:

```
pacman -Sy --noconfirm git
git clone https://github.com/pachun/orchard /tmp/orchard
/tmp/orchard/install-arch/dell-xps-14
```

After reboot:

- Sign in
- Connect to wifi `nmtui`
- Install orchard `~/code/orchard/install desktop`
- Run `~/code/orchard/connect` to connect your google calendar, github, icloud files, and tailscale

## On an M1 or M2 Mac

```
curl https://asahi-alarm.org/installer-bootstrap.sh | sh
```

After rebooting into arch, connect to wifi and setup the arch installation:

```
nmtui
pacman -Sy --noconfirm git
git clone https://github.com/pachun/orchard /tmp/orchard
/tmp/orchard/install-arch/asahi
```

After reboot:

- Sign in
- Connect to wifi `nmtui`
- Install orchard `~/code/orchard/install desktop`
- Run `~/code/orchard/connect` to connect your google calendar, github, icloud files, and tailscale
