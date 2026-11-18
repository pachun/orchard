# Power management

The installer normally selects power-saver on battery and balanced on AC.
The Dell XPS 14 DA14260 instead selects balanced for both, including on
fresh setups. This is an experimental mitigation for abrupt power loss
followed by a repeating 1 amber / 6 white power-button code. It can increase
battery consumption. It does not establish that power-saver causes the
fault, and reports include failures in balanced mode too. Manual profile
changes remain possible until the next power-supply event.

Run `bash configuration/desktop/battery/install.sh` from the repository
root to install the policy. It installs packages, enables power-management
services, replaces the existing Orchard udev rule, reloads udev, and checks
the resulting profile. `powerprofilesctl get` should report `balanced` on
this model on either power source. Other models keep their existing policy.

## XPS 14 incident, November 17, 2026

The affected boot was `e70b036998664699a6e05cddef095795`, on kernel
7.2.10-arch1-1 and BIOS 1.12.0. It resumed at 04:19:23 EST after approximately
7.5 hours of sleep. The journal ends at 04:19:46 with ordinary service
messages and no orderly shutdown sequence. The next boot begins at
04:20:38. The later manual reboots do have shutdown records.

No thermal shutdown, kernel panic, or out-of-memory kill was found at the
incident. Resume did log an unexpected IRQ trap and camera runtime-PM
errors; their proximity alone does not prove causation. The battery was
99% and discharging during inspection, not a measurement at failure time.
Thermald, intel-lpmd, UPower, and power-profiles-daemon were running.
The active PPD profile was power-saver, with CPU EPP `power`; the ACPI
platform profile was already balanced. These are distinct settings.

Dell defines 1,6 as an embedded-controller code-flow error. Combined with
the abrupt journal ending, a controller/firmware/platform fault is the
leading explanation, but neither its exact trigger nor a watchdog event
has been confirmed on this machine. An abrupt loss can prevent the last
kernel messages from reaching disk. The archived pstore directory was
empty; direct access to firmware pstore was unavailable during inspection.

fwupd metadata was current during inspection and offered no newer system
firmware. The successful 1.12.0 update was recorded on October 29. This
does not rule out a newer release appearing later or directly on Dell's
support site. Orchard already installs fwupd and its refresh timer, and
the system update command includes firmware updates.

## Clearing the indicator and investigating recurrence

1. Save work. At the next planned shutdown, use `systemctl poweroff`, wait
   until the machine is fully off, and then turn it on. Reports for this
   model say a full shutdown clears the latched blink code when warm
   reboots do not. Clearing the indicator is not a repair.
2. Enter F2 BIOS Setup and inspect the Power, Thermal, and BIOS event logs.
   Record entries around the failure, especially `Power Off - WDT` if
   present. Do this before repeated reboots can displace older entries;
   do not clear the logs. A WDT entry would support a watchdog timeout,
   but would not identify what stalled the controller.
3. Use F12 → Diagnostics and record any error and validation codes.
   Passing diagnostics does not exclude an intermittent fault.
4. If the light persists after a full shutdown, or power loss recurs,
   contact Dell with the blink code, event logs, firmware version, and
   timestamps. Ask for investigation of the EC/platform power fault.
   A durable repair may require Dell firmware or hardware service.

No automatic shutdown, EC reset, diagnostic-light suppression, watchdog
disabling, or global CPU idle-state restriction is installed. Those do
not establish a repair. Community CPU-latency workarounds are experimental;
idle restrictions can affect power consumption and suspend behavior.
Likewise, community insulation/tape modifications are not a verified fix.

To inspect this incident even after more reboots:

```sh
journalctl -b e70b036998664699a6e05cddef095795 -n 100 --no-pager
```

For a new incident, use `journalctl --list-boots` to identify the affected
boot rather than assuming it is `-1`. Preserve its journal before rotation.
Record AC/battery state, power profile, whether it followed resume, and
any peripherals in use. Compare recurrence after the balanced policy;
an isolated successful boot does not validate prevention.

## Sources

- [Dell DA14260 diagnostic codes](https://www.dell.com/support/manuals/en-us/xps-da14260-laptop/xps-14-da14260-service-manual/system-diagnostic-lights?guid=guid-924845d7-957f-49d6-8494-0d7d6b10e34d&lang=en-us)
- [Dell pre-boot diagnostics](https://www.dell.com/support/manuals/en-us/xps-da14260-laptop/xps-14-da14260-service-manual/running-the-supportassist-pre-boot-system-performance-check?guid=guid-0b893eed-efbc-4831-a9c4-7298a7a9f619&lang=en-us)
- [Owners' incident reports and experimental mitigations](https://github.com/omacom/omarchy/issues/5953)
- [Dell community follow-ups, including recurrences after proposed fixes](https://www.dell.com/community/en/conversations/xps/xps-1416-2026-abrupt-crashshutdown-while-on-battery-da14260-da16260/6a41380230ba7b5c1c724a29?page=6)
