#!/usr/bin/env bash
# Keeps the machine responsive under memory pressure, and lets a job that
# needs more memory than the machine has finish slowly instead of taking
# the desktop down. A jest run (19 workers at over 1 GB each, jest's
# default on 16 threads) filled 32 GB and the swap in 36 s; the same suite
# on a MacBook Air runs 7 workers and spills the rest to its SSD. Four
# parts:
#   - zram: a compressed swap device that lives inside RAM. When memory
#     fills, the coldest pages are compressed in place rather than paged
#     out to the slow SSD, so far more fits before anything gives.
#   - A RAM-sized swap file behind it (lower priority, so zram fills
#     first). It is the overflow the Air has: a job past what RAM and
#     zram hold pages to the NVMe and finishes, slower, instead of
#     hitting the OOM killer.
#   - A memory ceiling on app.slice, where every terminal and app lives:
#     at 90% of RAM the apps as a group are reclaimed and throttled,
#     which keeps the last 10% for the compositor, the user services and
#     the kernel, so the desktop stays usable while a job swaps.
#   - systemd-oomd: NOT used to kill on swap. On zram, swap filling is
#     normal, and oomd's swap-kill picks the cgroup with the largest swap
#     footprint - a long-lived tmux/desktop session - rather than the
#     transient hog, so it logged us out mid-build. It still watches
#     memory pressure per app scope (ghostty puts every terminal in one)
#     and kills a scope that has been stalled for 30 s, the last resort
#     for a job that is thrashing without progressing.
#   - OOM scores that make the kernel kill the hog, not the desktop. The
#     kernel OOM killer is the backstop, and it picks by badness, which is
#     memory size plus oom_score_adj, where each 100 points counts like
#     10% of RAM. systemd starts the user manager at 100 and every user
#     service at 200, so on 32 GB a 1 GB test worker (0) lost to a 500 kB
#     PAM helper (100) and to pipewire and the portals (200): the kernel
#     took the session apart and left the workers running. The drop-ins
#     below put the manager at -100 and its services at 0, so the kill
#     order is by size and the session outlives whatever filled memory.
# Idempotent.
set -euo pipefail
TOOLS="${TOOLS:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)/tools}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

sudo pacman -S --needed --noconfirm zram-generator

# zram sized at half of RAM (capped at 8 GiB), zstd for a good
# compression-ratio / CPU balance.
sudo tee /etc/systemd/zram-generator.conf >/dev/null <<'EOF'
[zram0]
zram-size = min(ram / 2, 8192)
compression-algorithm = zstd
EOF

# Disarm oomd's swap-based killing (see above): keep the drop-in for a
# documented, easily-reverted limit pinned at 100%, and ManagedOOMSwap=auto
# on the root slice so nothing under it is ever swap-killed.
sudo mkdir -p /etc/systemd/oomd.conf.d /etc/systemd/system/-.slice.d
sudo tee /etc/systemd/oomd.conf.d/orchard.conf >/dev/null <<'EOF'
[OOM]
SwapUsedLimit=100%
EOF
sudo tee /etc/systemd/system/-.slice.d/10-oomd.conf >/dev/null <<'EOF'
[Slice]
ManagedOOMSwap=auto
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now systemd-oomd.service
sudo systemctl restart systemd-oomd.service
# Bring the zram device up now; the generator otherwise creates it at boot.
sudo systemctl start systemd-zram-setup@zram0.service

swap_file=/swapfile
swap_file_priority=10
ram_size_in_mebibytes() { awk '/MemTotal/ {printf "%d", $2 / 1024}' /proc/meminfo; }

create_swap_file_if_missing() {
  [ -f "$swap_file" ] && return 0
  sudo mkswap -U clear --size "$(ram_size_in_mebibytes)M" --file "$swap_file" >/dev/null
}

register_swap_file_in_fstab() {
  grep -q "^$swap_file " /etc/fstab && return 0
  echo "$swap_file none swap defaults,pri=$swap_file_priority 0 0" | sudo tee -a /etc/fstab >/dev/null
}

create_swap_file_if_missing
register_swap_file_in_fstab
sudo swapon --all

# The app.slice memory ceiling is a user unit drop-in; a daemon-reload
# applies it to the running slice.
bash "$TOOLS/link.sh" "$HERE/systemd" "$HOME/.config/systemd/user"
systemctl --user daemon-reload

# OOM scores (see above). The manager's own score applies at its next
# start; the default for services applies to services started after the
# user manager re-executes. Both are also applied to the running session
# so the fix is live without a logout.
sudo mkdir -p /etc/systemd/system/user@.service.d /etc/systemd/user.conf.d
sudo tee /etc/systemd/system/user@.service.d/orchard-oom.conf >/dev/null <<'EOF'
[Service]
OOMScoreAdjust=-100
EOF
sudo tee /etc/systemd/user.conf.d/orchard-oom.conf >/dev/null <<'EOF'
[Manager]
DefaultOOMScoreAdjust=0
EOF
sudo systemctl daemon-reload
systemctl --user daemon-reexec

# The user manager and its PAM helper share init.scope; the PAM helper is
# what took the whole session down when the kernel killed it.
user_manager_processes() {
  for cgroup in /proc/[0-9]*/cgroup; do
    pid=${cgroup#/proc/}; pid=${pid%/cgroup}
    grep -q -E "/user@$(id -u)\.service/init\.scope$" "$cgroup" 2>/dev/null && echo "$pid"
  done
}

# Only processes of user services are rescored (their cgroup ends in
# .service under the user manager). Apps in scopes keep their own scores:
# Chromium, for one, scores its tabs itself.
user_service_processes_still_preferred_by_the_oom_killer() {
  for cgroup in /proc/[0-9]*/cgroup; do
    pid=${cgroup#/proc/}; pid=${pid%/cgroup}
    grep -q -E "/user@$(id -u)\.service(/.*)?\.service$" "$cgroup" 2>/dev/null || continue
    [ "$(cat "/proc/$pid/oom_score_adj" 2>/dev/null)" -gt 0 ] 2>/dev/null && echo "$pid"
  done
}

apply_oom_scores_to_running_session() {
  for pid in $(user_manager_processes); do
    sudo choom -n -100 -p "$pid" >/dev/null 2>&1 || true
  done
  for pid in $(user_service_processes_still_preferred_by_the_oom_killer); do
    sudo choom -n 0 -p "$pid" >/dev/null 2>&1 || true
  done
}
apply_oom_scores_to_running_session
