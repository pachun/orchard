<p align="center">
  <img src="orchard.png" alt="Orchard" width="200">
</p>

<p align="center"><em>There's a garden outside Apple's</em></p>

<h1 align="center">Orchard</h1>

My Arch configuration for the [2026 Dell XPS 14](https://www.dell.com/en-us/shop/dell-laptops/new-xps-14-laptop-2026/spd/xps-da14260-laptop) and M1/M2 Silicon Macs.

<p align="center">
  <img src="everforest-orchard.png" alt="Orchard" width="100%">
</p>

# Install

**On a 2026 Dell XPS 14**

1. Flash an [Arch ISO](https://archlinux.org/download/) to a USB drive
1. Boot into the XPS's BIOS by pressing F2 during boot
   - Turn off secure boot
   - Adjust the boot order to prioritize booting from the USB drive
   - Boot into the USB drive
1. Connect to wifi `iwctl --passphrase "PASS" station wlan0 connect "SSID"`
1. Install git `pacman -Sy --noconfirm git`
1. Clone orchard `git clone https://github.com/pachun/orchard /tmp/orchard`
1. Install Arch `/tmp/orchard/install-arch/dell-xps-14`
1. After the automatic reboot, sign in
1. Connect to wifi `nmcli device wifi connect "SSID" password "PASS"`
1. Install orchard `~/code/orchard/install desktop`
1. Run `~/code/orchard/connect` to connect your google calendar, github, icloud files, and tailscale

**On an M1/M2 Mac**

1. Install [Asahi](https://asahi-alarm.org/) `curl https://asahi-alarm.org/installer-bootstrap.sh | sh`
1. After rebooting into Arch, connect to wifi `nmcli device wifi connect "SSID" password "PASS"`
1. Download git `pacman -Sy --noconfirm git`
1. Clone orchard `git clone https://github.com/pachun/orchard /tmp/orchard`
1. Setup Arch `/tmp/orchard/install-arch/asahi`
1. After the reboot, sign in
1. Connect to wifi `nmcli device wifi connect "SSID" password "PASS"`
1. Install orchard `~/code/orchard/install desktop`
1. Run `~/code/orchard/connect` to connect your google calendar, github, icloud files, and tailscale
