#!/usr/bin/env bash
# Sourced by feature installers that diverge by hardware. The only
# aarch64 target orchard runs on is an Apple-silicon Mac under Asahi, and
# Apple machines expose a device-tree; x86 laptops don't.
is_apple_silicon() {
  grep -qa apple /proc/device-tree/compatible 2>/dev/null
}
