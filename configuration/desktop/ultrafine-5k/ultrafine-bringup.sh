#!/usr/bin/env bash
set -uo pipefail

externalConnectors=(/sys/class/drm/card0-DP-1 /sys/class/drm/card0-DP-2 /sys/class/drm/card0-DP-3)
probationSeconds=300
presenceSampleSeconds=2
settleSeconds=15
unpluggedGraceSeconds=90
maxAttempts=180

ultrafinePresent() {
  local deviceIdFile
  for deviceIdFile in /sys/bus/thunderbolt/devices/*/device; do
    [ "$(cat "$deviceIdFile" 2>/dev/null)" = "0x1114" ] && return 0
  done
  return 1
}

suppressExternalOutputs() {
  local connector
  for connector in "${externalConnectors[@]}"; do
    echo off > "$connector/status" 2>/dev/null
  done
}

releaseExternalOutputs() {
  local connector
  for connector in "${externalConnectors[@]}"; do
    echo detect > "$connector/status" 2>/dev/null
  done
}

monitorIsUnplugged() {
  local waited=0
  while [ "$waited" -lt "$unpluggedGraceSeconds" ]; do
    ultrafinePresent && return 1
    sleep "$presenceSampleSeconds"
    waited=$((waited + presenceSampleSeconds))
  done
  return 0
}

linkSurvivesProbation() {
  local watched=0
  while [ "$watched" -lt "$probationSeconds" ]; do
    sleep "$presenceSampleSeconds"
    ultrafinePresent || return 1
    watched=$((watched + presenceSampleSeconds))
  done
  return 0
}

for attempt in $(seq 1 "$maxAttempts"); do
  if ! ultrafinePresent && monitorIsUnplugged; then
    echo "monitor unplugged; exiting"
    releaseExternalOutputs
    exit 0
  fi
  echo "attempt $attempt: enabling video for ${probationSeconds}s probation"
  releaseExternalOutputs
  if linkSurvivesProbation; then
    echo "attempt $attempt: link held probation; leaving display enabled"
    exit 0
  fi
  echo "attempt $attempt: link collapsed; suppressing outputs while it re-trains"
  suppressExternalOutputs
  sleep "$settleSeconds"
done

echo "no stable link after $maxAttempts attempts; leaving outputs enabled"
releaseExternalOutputs
exit 1
