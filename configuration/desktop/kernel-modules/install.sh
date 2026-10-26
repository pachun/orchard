#!/usr/bin/env bash
# Keep running-kernel drivers available after package updates.
# Added after the MX Master 3S stayed paired but stopped working: a kernel
# update removed the running kernel's unloaded uhid driver before a reboot.
# Idempotent.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

restore_running_kernel_modules() {
    local running_kernel module_directory package
    running_kernel=$(uname -r)
    module_directory="usr/lib/modules/$running_kernel"

    if [[ -d "/$module_directory/kernel" ]]; then
        return
    fi

    shopt -s nullglob
    for package in /var/cache/pacman/pkg/linux-*.pkg.tar.*; do
        [[ "$package" == *.sig ]] && continue
        if tar -tf "$package" "$module_directory/" >/dev/null 2>&1; then
            printf 'Restoring drivers for running kernel %s from %s\n' "$running_kernel" "$package"
            sudo tar -xpf "$package" -C / "$module_directory/"
            sudo depmod "$running_kernel"
            sudo modprobe uhid
            printf 'Drivers restored without rebooting. Turn the mouse off and on to reconnect.\n'
            return
        fi
    done

    printf 'No cached drivers match running kernel %s. Reboot to use the installed kernel.\n' "$running_kernel" >&2
    return 1
}

sudo pacman -S --needed --noconfirm kernel-modules-hook
sudo systemctl enable linux-modules-cleanup.service
restore_running_kernel_modules
