#!/usr/bin/env bash
# Intel laptop power + thermal management. Three daemons and an AC/battery
# profile switch:
#   - thermald: watches CPU temperature and steers Intel's power limits
#     so the chip backs off smoothly under sustained load instead of
#     relying on the firmware's blunt trip points — more sustained
#     performance, a cooler chassis. Fully automatic, no modes.
#   - power-profiles-daemon: the battery / balanced / performance switch
#     (the Mac-style "low power mode"). Defaults to balanced and needs no
#     interaction; it just makes the modes available if ever wanted.
#   - intel-lpmd: on hybrid Intel chips (Alder Lake and newer) it steers
#     light background load onto the low-power efficiency cores when the
#     system is mostly idle, letting the compute tile power-gate for
#     deeper idle and fewer wakeups. Automatic; a no-op on non-hybrid CPUs.
# The udev rule then makes power-profiles-daemon follow the wall plug —
# power-saver on battery (which biases the CPU to its efficient EPP), balanced
# on AC — because PPD ships without that behaviour. The rule file carries the
# measured reasoning.
# The Apple-silicon Mac manages its own power and thermals and skips all
# of this.
set -euo pipefail
TOOLS="${TOOLS:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)/tools}"

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$TOOLS/machine.sh"

# The charger chime (bin/charge-chime, started from hyprland.conf) is for
# every laptop, Macs included; the freedesktop sound theme provides the
# sound. Everything past this is x86 power management.
sudo pacman -S --needed --noconfirm sound-theme-freedesktop
bash "$TOOLS/link.sh" "$HERE/bin" "$HOME/.local/bin"

is_apple_silicon && exit 0

# thermald and intel-lpmd are Intel-only; AMD's amd-pstate driver and
# firmware handle the same jobs, so an AMD machine gets just the profile
# switch and the AC/battery udev rule.
packages=(power-profiles-daemon)
services=(power-profiles-daemon.service)
if ! is_amd_cpu; then
  packages+=(thermald intel-lpmd)
  services+=(thermald.service intel_lpmd.service)
fi
sudo pacman -S --needed --noconfirm "${packages[@]}"
sudo systemctl enable --now "${services[@]}"

sudo install -Dm644 "$HERE/99-orchard-power-profile.rules" \
    /etc/udev/rules.d/99-orchard-power-profile.rules
sudo udevadm control --reload
sudo udevadm trigger --subsystem-match=power_supply

# Confirm the profile actually followed the power state. The one silent failure
# is polkit refusing powerprofilesctl from udev's root context; catch it here
# rather than as a fan that never quiets on battery.
on_battery() {
    local type
    for type in /sys/class/power_supply/*/type; do
        [ "$(cat "$type" 2>/dev/null)" = Mains ] && { [ "$(cat "${type%type}online")" = 0 ]; return; }
    done
    return 1
}
sleep 1
on_battery && wanted=power-saver || wanted=balanced
got="$(powerprofilesctl get 2>/dev/null || true)"
[ "$got" = "$wanted" ] \
    || echo "battery: power-profile auto-switch didn't take (got '$got', wanted '$wanted') — udev may be blocked from setting it" >&2
