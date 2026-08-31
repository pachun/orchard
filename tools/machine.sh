#!/usr/bin/env bash
# Sourced by feature installers that diverge by hardware. Three axes:
# Apple silicon (device-tree; x86 laptops have none), the machine's maker
# (DMI, for hardware that only one laptop carries), and the CPU vendor
# (for Intel-vs-AMD userspace like VA-API and thermal daemons).
is_apple_silicon() {
  grep -qa apple /proc/device-tree/compatible 2>/dev/null
}

is_dell() {
  grep -qi '^Dell' /sys/class/dmi/id/sys_vendor 2>/dev/null
}

is_framework() {
  grep -qi '^Framework' /sys/class/dmi/id/sys_vendor 2>/dev/null
}

is_amd_cpu() {
  grep -q AuthenticAMD /proc/cpuinfo
}
