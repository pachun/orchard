---
name: orchard
description: How this repo (orchard, Nick's Arch/Hyprland dotfiles for the Dell XPS 14, the Framework Laptop 13, and Apple-silicon Macs) is laid out and how to add or change a feature — feature folders, install.sh conventions, symlinking, the theme system, waybar modules, Hyprland wiring, eww panels, fuzzel menus, and how to verify a change live. Invoke before adding or modifying anything in orchard so the work lands in the right place without re-explaining the setup.
---

# Orchard

Arch + Hyprland desktop configuration. Two phases on a machine:
`install-arch/<machine>` (base OS, run once from the ISO / Asahi live
system) and `./configure` (dotfiles + desktop, idempotent, re-run any
time). Everything below is about the second phase.

## The unit of work is a feature folder

`configuration/cli/<feature>/` (every machine) and
`configuration/desktop/<feature>/` (desktop machines). `configure` walks
them **alphabetically** and runs each `install.sh`. Adding a feature is
creating the folder; removing one is deleting it. A feature folder holds:

- `install.sh` — required. Installs packages, links config, applies
  state. Header comment says what the feature is and why the choices
  were made; ends with `# Idempotent.` Starts with
  `set -euo pipefail` and `HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"`.
- `bin/` — scripts, linked into `~/.local/bin`. Named the way you'd say
  them (`set-theme`, `system-update`, `claude-usage-panel`). Waybar
  module scripts are `waybar-<module>`; theme renderers are
  `render-<thing>-theme`; daemon restarters are `restart-<thing>`.
- `config/` — files linked into `~/.config`, preserving subdirectories
  (`config/eww/eww.yuck` → `~/.config/eww/eww.yuck`).
- `prompts.sh` — optional; interactive questions, sourced up front by
  `configure` so all prompts happen before any install.

### install.sh conventions

- Packages: `sudo pacman -S --needed --noconfirm …` for repo packages.
  AUR: `bash "$TOOLS/install-yay.sh"` first, then
  `bash "$TOOLS/aur-install.sh" …` (never bare `yay -S`: the helper
  fetches each PKGBUILD's signing keys from whichever keyserver has
  them before yay runs, since no single keyserver serves them all).
  `install-yay.sh` also owns the
  per-user gpg keyserver and `MAKEFLAGS` — don't duplicate those.
- Linking: `bash "$TOOLS/link.sh" "$HERE/bin" "$HOME/.local/bin"` and
  `bash "$TOOLS/link.sh" "$HERE/config" "$HOME/.config"`. `link.sh`
  symlinks **per file** (real directories at the destination are kept,
  so generated files can sit beside linked ones), backs up real files it
  would clobber, and garbage-collects dangling links. A new file in
  `bin/` or `config/` is not live until `link.sh` runs again.
- Dependencies between features: call the other feature's installer
  explicitly — `bash "$HERE/../themes/install.sh"` — rather than relying
  on alphabetical order. Installers are idempotent, so this is cheap.
- Hardware divergence: `source "$TOOLS/machine.sh"` and branch on
  `is_apple_silicon`, `is_dell`, `is_framework`, or `is_amd_cpu` — pick
  the axis the hardware actually varies on (the camera relay is Dell-only,
  the GPU userspace is Intel-vs-AMD). Anything a laptop either has or
  doesn't (a fingerprint reader) is gated on the device being present,
  not the machine. Per-device Hyprland tuning (touchpad sensitivity) is
  a `device {}` block keyed by device name, one per laptop.
- Per-machine variants of a config (e.g. waybar's bar layout) live
  outside `config/` in their own directory and `install.sh` links only
  the chosen one.
- `$TOOLS` is exported by `configure`, and every install.sh defaults
  it from its own location, so a standalone
  `./configuration/desktop/<feature>/install.sh` run just works. Users run install scripts
  themselves (they contain `sudo`); Claude never runs `sudo`.
- No comments explaining *what* — names do that. Comments carry *why*:
  the constraint, the upstream bug, the "this looks wrong, here's why it
  isn't."

## Consumers vs owners

A feature owns its scripts and config; other features carry only the
wiring lines that reference it, in their own files. E.g. the Claude usage
widget: `claude-usage/` owns the scripts and the eww panel; `waybar`
holds the module block, style rule, and layout entry; `hyprland` holds
the keybind, `exec-once`, and layer rules; `themes/bin/set-theme` holds
the re-theme block. When adding something, put each line in the file
whose feature it belongs to, guarded so a machine without the owning
feature still works (`[ -x "$HOME/.local/bin/render-x-theme" ] && …`,
`command -v eww >/dev/null && …`).

## Theme system (`configuration/desktop/themes/`)

`config/orchard-themes/<theme>/` holds one partial per app;
`~/.config/orchard-themes/active` is a symlink to the current one and
apps read through it. `set-theme <name>` repoints the link and then
reloads every consumer (nvim over its socket, ghostty SIGUSR2, `hyprctl
reload`, waybar via a byte rewrite of style.css, eww daemons via
`render-*-theme` + `restart-*`, chromium policy refresh, gsettings GTK
theme + color-scheme, tmux `source-file`, wallpaper). `theme-menu` is the
fuzzel picker; `ghostty.conf` marks a directory as a real theme.

A theme directory needs all of: `palette` (Ghostty-format
`palette = N=#hex`, `background`, `foreground`, `cursor-color`,
`selection-*`; read by `render-*-theme` scripts — ANSI slot 4 is the
accent every theme agrees on), `ghostty.conf` (bundled `theme = "…"` +
`background-opacity`, or the palette inlined), `nvim.lua` (plugin
`setup()` with `require("theme_opacity").transparent()`, then
`vim.opt.background` — the source of truth for light/dark — and
`colorscheme`), `hyprland.conf` (active/inactive border colors),
`fuzzel.ini`, `tmux.conf`, `waybar.css` (bar background sampled from the
wallpaper's top edge: `magick wallpaper.png -crop 100%x2%+0+0 +repage
-resize '1x1!' -format '%[hex:u.p{0,0}]' info:`), `chromium.json`
(`BrowserThemeColor`), `gtk-theme-name` (one line; `Adwaita` when no GTK
port exists), `wallpaper.png`. The nvim colorscheme plugin is declared
bare in `configuration/cli/nvim/config/lua/plugins/<name>.lua` with
`priority = 1000`; per-theme options live in the partial. After adding a
theme: `link.sh` both config dirs, `nvim --headless "+Lazy! sync" +qa`,
verify with `nvim --headless -c 'luafile ~/.config/orchard-themes/<t>/nvim.lua' -c 'lua print(vim.g.colors_name)' +qa`,
then `set-theme <t>`. A README screenshot at `screenshots/<theme>.png` +
`tools/update-readme-screenshots` is the user's step.

Anything drawn outside those apps (eww panels, the OSD) gets its colors
from a `render-<thing>-theme` script that reads `active/palette` and
writes a `colors.scss`; `set-theme` re-runs it and restarts the daemon.

## Waybar (`configuration/desktop/waybar/`)

A module is: a `bin/waybar-<name>` script printing one JSON line
(`{"text","tooltip","class"}`), a `"custom/<name>": {…}` block in
`config/config.jsonc` (`exec`, `return-type: json`, `interval` or
continuous, a dedicated `signal` number — 7 dnd, 9 network, 11
bluetooth, 12 claude-usage — and `on-click`), a padding rule
plus any state classes in `config/style.css` (icon modules join the
`Phosphor-Fill` font-family list), and an entry in **both**
`layouts/with-notch.jsonc` and `layouts/without-notch.jsonc` (the Mac's
notch owns the center, so the clock lives on the right there; the XPS
has the clock + weather glyph dead center). Icons are Phosphor glyphs
by codepoint, listed in the script header as `name  U+XXXX`; look
codepoints up in
`https://raw.githubusercontent.com/phosphor-icons/web/master/src/fill/style.css`.
Scripts must never block on the network — cache and serve stale.
Anything that sits in the centre beside the clock (weather glyph, updates
badge) runs through `waybar-hidden-during-notifications <command>
<seconds>`, which polls the command and fades the module out while a
notification holds the clock's slot; the command itself is a one-shot
`<thing>-now` script. **Never give a continuous module a `signal` key**:
waybar reads signal-without-interval as "run the command once per signal
and wait for it to exit", so a looping script never draws. Continuous
modules that need a nudge get signalled directly by process
(`refresh-updates-badge`). Apply live: `pkill -SIGUSR2 -x waybar` for
config/layout changes; `pkill -RTMIN+<n> waybar` to refresh a polled
module.

## Hyprland (`configuration/desktop/hyprland/config/hyprland.conf`)

`$modifier = SUPER` (the key the user calls Cmd; the XPS keycap says
Alt). App binds are `bind = $modifier [SHIFT], <key>, exec,
$HOME/.local/bin/focus-or-launch <class> <command>` — one window you
bring forward or hide; things you open several of (Nautilus) use plain
`exec` plus `windowrule = match:class …, workspace unset`. A global
`windowrule = match:class .*, workspace empty` sends every new window to
the lowest empty workspace; anything that should stay put (dialogs,
file manager, calculator, Quick Look) needs the `workspace unset`
override. Layer surfaces (eww, fuzzel) get `layerrule = no_anim on` and,
for frosted panels, `blur on` + `ignore_alpha 0.3`, keyed by namespace.
Daemons start from `exec-once`. Apply live with `hyprctl reload` (does
not re-run exec-once).

## Panels and menus

- **eww** for anything drawn (OSD square, Claude usage dropdown). Each
  feature runs **its own daemon on its own config dir**
  (`eww --config ~/.config/<feature>/eww`), restarted by kill + `daemon`
  + ping loop, never `eww reload` (strands surfaces on wlr-layer-shell).
  Window geometry that should line up with tiled windows uses
  `gaps_out` (10px) offsets and `rounding` (10px) radius; hyprland.conf
  `general`/`decoration` are the source. No drop shadows anywhere.
- **fuzzel** for pickers/menus (`system-menu`, `wifi-menu`,
  `bluetooth-menu`, `theme-menu`, `audio-menu`): `. "$HOME/.local/bin/_fuzzel-menu-toggle"`,
  build rows as `<phosphor glyph>  <label>`, pipe to
  `fuzzel --dmenu --prompt=… --width=… --lines=…`.
- Notifications don't toast; they take the clock's slot in the bar
  (`waybar-clock` + `orchard-notifications`).

## Verifying a change

Link it (`link.sh`), apply live (the reload command for that consumer),
then look: `grim -g "X,Y WxH" file.png` (logical pixels; screen is
1440×900 logical at scale 2 on the XPS) and read the image. `hyprctl
layers` / `hyprctl clients -j` give exact geometry. Screenshots the user
takes land in `~/pictures/screenshots/`. When a feature installs a
package, the user runs the feature's `install.sh` — don't hand them a
bare pacman line.

## Commits

Subject = outcome for the person using the desktop, ≤50 chars,
imperative, no period ("Show Claude Code usage in the bar", "Speed up
system updates that build from source"). Body optional. No AI
attribution anywhere. Only commit when asked. Report git state only
after running `git status` in the same turn.
