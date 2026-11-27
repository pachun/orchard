#!/usr/bin/env bash
# Dictation: speak, and the words are typed into the focused window. Hold
# Right Alt to talk, or press Alt+Space to start and again to stop (both
# bound in hyprland.lua). While it listens, a glow traces the bottom edge
# of the window being dictated into.
#
# Superwhisper does the listening. It is the dictation app Omarchy ships,
# published in Omarchy's package repository, so the omarchy-apps feature
# builds it from that repository's recipe and system-update keeps it
# current. Speech goes to Superwhisper's cloud by default, free up to a
# word limit counted over 30 days; `superwhisper models select offline`
# keeps it on this machine with no limit.
#
# The package's own per-user setup script is written for Omarchy's shell
# and stops at the first Omarchy command, so the steps that matter are
# done here instead.
#
# The microphone in the bar, or Cmd+Shift+D, drops a panel under the bar
# with the cloud words used, cloud or offline, the indicator's look and the
# tone, and a way into Superwhisper's full settings. The panel is an eww
# window on its own daemon and config dir, themed from the active orchard
# palette by render-dictation-theme, which set-theme re-runs on every
# switch. The bar module belongs to this feature too: waybar/ holds the
# module and its styles, and the bar draws whatever features leave in
# ~/.config/waybar/feature-modules.
# Idempotent.
set -euo pipefail
TOOLS="${TOOLS:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)/tools}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

PREFERENCES="${XDG_CONFIG_HOME:-$HOME/.config}/superwhisper/preferences.json"
INSTALLED_APP=/opt/superwhisper
WHERE_THE_APP_LOOKS_FOR_ITSELF="${XDG_DATA_HOME:-$HOME/.local/share}/superwhisper/app/current"

bash "$TOOLS/install-packages.sh" \
  python python-gobject python-cairo gtk4 gtk4-layer-shell at-spi2-core \
  pipewire-pulse libnotify wl-clipboard ffmpeg vulkan-icd-loader librsvg \
  fontconfig hicolor-icon-theme foot

# The panel's colors are rendered from the active orchard theme, so the
# theme system has to be in place before its daemon starts.
bash "$HERE/../themes/install.sh"
bash "$TOOLS/install-yay.sh"
bash "$TOOLS/aur-install.sh" eww

bash "$HERE/../omarchy-apps/install.sh"
bash "$TOOLS/link.sh" "$HERE/omarchy-recipe" "$HOME/.config/omarchy-recipes"
"$HOME/.local/bin/omarchy-apps" install superwhisper-bin

# Superwhisper's settings window and its own guides run the command from
# ~/.local/bin, and the app finds its assets through the link below.
point_the_app_at_the_installed_package() {
  mkdir -p "$HOME/.local/bin" "$(dirname "$WHERE_THE_APP_LOOKS_FOR_ITSELF")"
  ln -sfn /usr/bin/superwhisper "$HOME/.local/bin/superwhisper"
  ln -sfn "$INSTALLED_APP" "$WHERE_THE_APP_LOOKS_FOR_ITSELF"
}

has_never_run_here() {
  [ ! -e "$PREFERENCES" ]
}

# hyprland.lua owns Right Alt and Alt+Space and calls superwhisper for
# them. Superwhisper insists on one shortcut of its own, so it gets a
# chord nothing else uses; left at its defaults it would claim Right Alt
# too, and the two would start and stop each other.
keep_its_own_shortcuts_off_the_dictation_keys() {
  mkdir -p "$(dirname "$PREFERENCES")"
  (
    umask 077
    printf '%s\n' '{"toggleRecordingShortcut":"Ctrl+Alt+Space","pushToTalkShortcut":"","cancelRecordingShortcut":"Escape"}' > "$PREFERENCES"
  )
}

start_listening_for_dictation() {
  systemctl --user daemon-reload
  systemctl --user enable --now superwhisper.service
}

wait_until_it_answers() {
  local attempts_left=100
  until superwhisper status >/dev/null 2>&1; do
    attempts_left=$((attempts_left - 1))
    if [ "$attempts_left" -eq 0 ]; then
      echo "dictation: Superwhisper did not become ready; see systemctl --user status superwhisper" >&2
      return 1
    fi
    sleep 0.1
  done
}

glow_along_the_window_while_listening() {
  superwhisper audio set recordingIndicatorStyle '"edgeGlow"' >/dev/null
}

point_the_app_at_the_installed_package
if has_never_run_here; then
  is_first_setup=true
  keep_its_own_shortcuts_off_the_dictation_keys
else
  is_first_setup=false
fi
start_listening_for_dictation
wait_until_it_answers
if "$is_first_setup"; then
  glow_along_the_window_while_listening
fi

bash "$TOOLS/link.sh" "$HERE/bin" "$HOME/.local/bin"
bash "$TOOLS/link.sh" "$HERE/config" "$HOME/.config"
bash "$TOOLS/link.sh" "$HERE/launcher" "$HOME/.config/launcher"
"$HOME/.local/bin/render-dictation-theme"
"$HOME/.local/bin/restart-dictation-panel"
bash "$TOOLS/link.sh" "$HERE/waybar" "$HOME/.config/waybar/feature-modules"
if [ -x "$HOME/.local/bin/restart-waybar" ]; then
  "$HOME/.local/bin/restart-waybar"
fi

# hyprland.lua binds the dictation keys only once Superwhisper is installed.
if [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
  hyprctl reload >/dev/null
fi
