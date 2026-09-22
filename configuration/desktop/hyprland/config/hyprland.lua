-- The desktop, in Hyprland's Lua config (the .conf format it replaced is gone
-- in Hyprland 0.57). Everything here is wired to a script or a feature folder
-- elsewhere in orchard; the comments say why each line is the way it is.

local home = os.getenv("HOME")
local function localBin(command) return home .. "/.local/bin/" .. command end
local function runScript(command) return hl.dsp.exec_cmd(localBin(command)) end

-- The key the user calls Cmd (the XPS keycap says Alt).
local modifier = "SUPER"

local terminalApplication = "ghostty"
local browserApplication = "chromium"
local messagesApplication = "bluebubbles"
local emailApplication = localBin("emma")
local emailWindowClass = "emma-desktop"

-- The web apps below all run as `chromium --app`, which strips the browser
-- chrome so each reads as its own application rather than a tab.
--
-- Chromium ignores --class for --app windows: it derives the window class from
-- the app's URL instead, as chrome-<host>__<path>-Default. Passing --class
-- looks like it works and silently does nothing, so focus-or-launch has to
-- match on the derived name — hence a ...WindowClass beside every
-- ...Application. Each one below was read off `hyprctl clients`, not guessed;
-- it holds even for a fresh chromium instance, so it isn't an artifact of
-- attaching to a running one.
local mapsApplication = "chromium --app=https://www.google.com/maps"
local mapsWindowClass = "chrome-www.google.com__maps-Default"

-- Spotify's native Linux client — yes, one exists (spotify-launcher, official
-- extra repo, pulls the real client from Spotify's apt repo). Its audio is an
-- ordinary PipeWire stream, so Cmd+O still routes it to an AirPlay speaker,
-- which is the one thing the web player gave us — but unlike the web player it
-- stays signed in across restarts instead of storing the login in a session
-- cookie that dies on every chrome close. See the spotify feature.
local musicApplication = "spotify-launcher"
-- Lowercase because the spotify feature runs the client on Wayland, where the
-- class is the app id; on X11 it comes off WM_CLASS and is `Spotify`.
local musicWindowClass = "spotify"

local photosApplication = "chromium --app=https://www.icloud.com/photos"
local photosWindowClass = "chrome-www.icloud.com__photos-Default"

-- Claude's native desktop app (installed by the claude-desktop feature). Unlike
-- the chromium --app windows above it has a real reverse-DNS app id, and the
-- packaging keeps the Wayland app id, the X11 WM_CLASS and the .desktop name all
-- equal to com.anthropic.Claude — so this one class matches however it launches.
--
-- --password-store=gnome-libsecret is what keeps you signed in. It's an Electron
-- app, and Chromium picks its credential backend from the desktop environment;
-- it doesn't recognize Hyprland, so it falls back to the plaintext-disabled
-- "basic" store, safeStorage then reports encryption unavailable, and the app
-- refuses to persist the session ("Your sign-in won't be saved on this device").
-- Naming the backend outright routes it to gnome-keyring, which is running and
-- unlocked. The .desktop override in the claude-desktop feature carries the same
-- flag so a claude:// link opens the app the same way this keybind does.
local claudeApplication = "claude-desktop --password-store=gnome-libsecret"
local claudeWindowClass = "com.anthropic.Claude"

-- The calendar that matters is the one the events are actually in.
local calendarApplication = "chromium --app=https://calendar.google.com"
local calendarWindowClass = "chrome-calendar.google.com__-Default"

-- Replaces a ghostty window running `curl wttr.in`. Goes through a script
-- rather than straight to a URL because Google's weather card needs to be told
-- what town you're in — chromium on Arch has no working geolocation to tell it
-- — and the script resolves that from the IP. See ~/.local/bin/weather.
local weatherApplication = localBin("weather")
local weatherWindowClass = "chrome-www.google.com__search-Default"

local quitHyprland = "command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"

local function focusOrLaunch(windowClass, application)
    return runScript("focus-or-launch " .. windowClass .. " " .. application)
end

-- Two families of shortcut, and the shift key is what tells them apart.
--
--   Cmd+<letter>        opens a thing you look at.
--   Cmd+Shift+<letter>  opens one of the bar's menus — the same menu you'd
--                       get by clicking that icon in waybar.
--
-- So the shifted half of the keyboard is "change a setting", the unshifted
-- half is "show me an app", and you never have to remember which is which.
-- The rule also happens to sidestep xremap, which claims a fixed list of bare
-- Cmd+<letter> combos for their macOS meanings (c/v/x/a/z/w/t/f/s/r) and
-- rewrites them at the input layer, before Hyprland ever sees the key. A menu
-- bound to a bare Cmd+S or Cmd+V would simply never fire. xremap's rules set
-- exact_match, so the shifted variants are all free.
--
-- A few apps sit on a shifted key despite not being menus. Weather and
-- Spotify land there because their unshifted letter is one xremap has taken
-- (Cmd+W is close-tab, Cmd+S is save); each keeps its own initial. Maps is
-- the holdover — it moved to Cmd+Shift+M back when music held bare Cmd+M, and
-- stayed after music left for Cmd+Shift+S. Bare Cmd+M is now deliberately
-- unbound.

-- ── Displays ────────────────────────────────────────────────────────────────
-- The Odyssey G8 is a 4K120 panel, but it comes in over a USB-C→HDMI adapter
-- whose DPCD reports `TMDS clock 25000-300000, PCON Max FRL BW 0Gbps` — a pure
-- TMDS converter capped at 300 MHz with no HDMI 2.1 fixed-rate link and no DSC.
-- That ceiling prunes every mode above it (4K60 wants 594 MHz, 1440p120 wants
-- 498 MHz), leaving native 4K available only at 30 Hz, which is bad enough that
-- the pointer visibly steps as it moves. 1440p60 is the best mode that fits.
-- Replacing the adapter with USB-C→DisplayPort bypasses the converter and this
-- line should then go.
-- Both are pinned because pinning only one leaves the other to auto-place,
-- which lands the laptop panel to the right of the external instead of left.
-- eDP-1 is 2880 wide at scale 2, so DP-1 starts at its logical width, 1440.
local internalPanel = "eDP-1"
local externalMonitor = "DP-1"
local rightOfTheLaptopPanel = "1440x0"
hl.monitor({ output = internalPanel, mode = "preferred", position = "0x0", scale = 2 })
hl.monitor({ output = externalMonitor, mode = "2560x1440@59.95", position = rightOfTheLaptopPanel, scale = 1 })

-- The UltraGear is a 3440x1440 ultrawide behind the Insignia USB-C hub, whose
-- HDMI port has the same 300 MHz TMDS ceiling: the kernel prunes every
-- advertised mode above 297 MHz, which takes out the panel's native 85 Hz
-- timing (471 MHz) and leaves 50 Hz as the only listed one at native
-- resolution. The pruning only applies to the monitor's own list, though, and
-- the hub carries more than it admits to: this is `cvt -r 3440 1440 60`, a
-- reduced-blanking 60 Hz timing at 319.75 MHz, which the kernel accepts as a
-- custom mode. Matched by description so the DP-1 rule above can't stretch
-- 16:9 across a 21:9 panel; it comes second because the later matching rule
-- wins.
local ultrawideSixtyHertzReducedBlanking = "modeline 319.75 3440 3488 3520 3600 1440 1443 1453 1481 +hsync -vsync"
hl.monitor({ output = "desc:LG Electronics LG ULTRAGEAR", mode = ultrawideSixtyHertzReducedBlanking, position = rightOfTheLaptopPanel, scale = 1 })

-- The external is the primary screen: the five spaces the bar promises all live
-- on it, so Cmd+1..5 always drives the monitor and closing the lid barely
-- changes anything — the windows are already there.
--
-- Without these rules the five spaces are a single pool shared across both
-- screens, and a newly connected monitor squats on whichever number happens to
-- be free. That number drifts (it took 4, then 5), and the space it lands on
-- stops being reachable from the laptop — you press Cmd+4, focus jumps to a
-- screen you weren't looking at, and the space you wanted never appears.
--
-- monitor rules are skipped when the named output is absent, so undocked all
-- five fall back to the laptop panel on their own. The laptop takes the lowest
-- space these rules leave free while docked.
--
-- `external-spaces on|off` decides whether the rules are made at all, so they
-- can be switched off while a monitor's link is being coaxed up (a flapping
-- monitor would otherwise sweep your windows across to it on every
-- appearance). It records the choice in a state file and reloads; no file
-- means on.
local spaceCount = 5

local function externalSpacesArePinned()
    local state = io.open(home .. "/.local/state/orchard/external-spaces")
    if not state then return true end
    local choice = state:read("l")
    state:close()
    return choice ~= "off"
end

if externalSpacesArePinned() then
    for space = 1, spaceCount do
        hl.workspace_rule({ workspace = tostring(space), monitor = externalMonitor, default = space == 1 })
    end
end

-- ── Apps ────────────────────────────────────────────────────────────────────
hl.bind(modifier .. " + Return", focusOrLaunch("com.mitchellh.ghostty", terminalApplication))
hl.bind(modifier .. " + N", focusOrLaunch("chromium", browserApplication))
-- Incognito chromium normally inherits the same WM_CLASS as a regular chromium
-- window, so focus-or-launch couldn't tell them apart. Override WM_CLASS via
-- --class=chromium-incognito so the incognito window has its own class and can
-- be focused (or spawned) independently. --class works here because this is
-- not an --app window.
hl.bind(modifier .. " + SHIFT + N", focusOrLaunch("chromium-incognito", browserApplication .. " --incognito --class=chromium-incognito"))
-- The file manager is the exception to the focus-or-launch treatment the other
-- apps get. Those are each one window you bring forward and hide again;
-- browsing files is something you do several of at once, next to whatever
-- you're already looking at. So Cmd+E always opens a new window — never
-- focuses or hides an existing one — and the window rule below keeps that
-- window on the current workspace.
hl.bind(modifier .. " + E", hl.dsp.exec_cmd("nautilus --new-window"))
hl.bind(modifier .. " + I", focusOrLaunch(messagesApplication, messagesApplication))
hl.bind(modifier .. " + SHIFT + D", runScript('focus-or-launch --name "Beekeeper Studio" beekeeper-studio beekeeper-studio'))
hl.bind(modifier .. " + SHIFT + C", focusOrLaunch(calendarWindowClass, calendarApplication))
hl.bind(modifier .. " + SHIFT + M", focusOrLaunch(mapsWindowClass, mapsApplication))
hl.bind(modifier .. " + SHIFT + S", focusOrLaunch(musicWindowClass, musicApplication))
hl.bind(modifier .. " + SHIFT + W", focusOrLaunch(weatherWindowClass, weatherApplication))
hl.bind(modifier .. " + SHIFT + E", focusOrLaunch(emailWindowClass, emailApplication))

-- Screenshots + recording, macOS-style shortcuts.
-- Cmd+Shift+3 → full-screen capture
-- Cmd+Shift+4 → region capture (slurp picker)
-- Cmd+Shift+5 → toggle screen recording (region picker on first press)
-- Cmd+Shift+6 → mark up a screenshot you already took (newest first)
-- All save to ~/pictures/screenshots/ or ~/videos/recordings/ AND copy
-- the screenshot to the clipboard for immediate paste.
--
-- A submap replaces the whole bind table, so every submap below repeats
-- these; without that, Cmd+Shift+3 lands in the focused window as a "#".
local function bindScreenshotKeys()
    hl.bind(modifier .. " + SHIFT + 3", runScript("screenshot full"))
    hl.bind(modifier .. " + SHIFT + 4", runScript("screenshot region"))
    hl.bind(modifier .. " + SHIFT + 5", runScript("screenrecord"))
    hl.bind(modifier .. " + SHIFT + 6", runScript("annotate-screenshot"))
end
bindScreenshotKeys()

-- AI usage panel under the bar (Claude Code and Codex) — same toggle as
-- clicking its robot.
-- While it's open the panel's submap is active (ai-usage-panel enters and
-- leaves it), so Escape dismisses it the way a menu would; the toggle chord is
-- repeated inside the submap so it keeps working there. Ordinary typing still
-- reaches the focused window — a submap only swaps the binds.
hl.bind(modifier .. " + SHIFT + U", runScript("ai-usage-panel"))
hl.define_submap("ai-usage", function()
    hl.bind("Escape", runScript("ai-usage-panel"))
    hl.bind(modifier .. " + SHIFT + U", runScript("ai-usage-panel"))
    bindScreenshotKeys()
end)

-- Apple TV mode (the apple-tv-remote feature): Cmd+Shift+R opens the remote
-- card in the bar's corner and enters this submap, where every key goes to
-- apple-tv-key — picker, PIN entry, and the vim remote. Escape, q, or the
-- same chord leave it. It is a real mode: the catchall at the end swallows
-- every key the remote has no use for, so nothing leaks into the window
-- behind the card — the card flashes its border instead, vim's beep for an
-- unmapped key. Not Cmd+Shift+T: xremap turns that into Ctrl+Shift+T
-- (reopen closed tab) before Hyprland sees it.
hl.bind(modifier .. " + SHIFT + R", runScript("apple-tv-mode"))
hl.define_submap("appletv", function()
    local function remoteKey(key, name)
        hl.bind(key, runScript("apple-tv-key " .. name))
    end
    remoteKey("h", "h")
    remoteKey("j", "j")
    remoteKey("k", "k")
    remoteKey("l", "l")
    remoteKey("m", "m")
    remoteKey("s", "s")
    remoteKey("q", "q")
    remoteKey("p", "p")
    remoteKey("left", "h")
    remoteKey("down", "j")
    remoteKey("up", "k")
    remoteKey("right", "l")
    remoteKey("Return", "enter")
    remoteKey("space", "space")
    remoteKey("SHIFT + h", "home")
    remoteKey("minus", "minus")
    remoteKey("equal", "equal")
    remoteKey("SHIFT + comma", "previous")
    remoteKey("SHIFT + period", "next")
    for digit = 0, 9 do
        remoteKey(tostring(digit), tostring(digit))
    end
    remoteKey("BackSpace", "backspace")
    remoteKey("Escape", "escape")
    bindScreenshotKeys()
    hl.bind(modifier .. " + SHIFT + R", runScript("apple-tv-mode"))
    remoteKey("catchall", "unknown")
end)

hl.bind(modifier .. " + SHIFT + P", focusOrLaunch(photosWindowClass, photosApplication))
hl.bind(modifier .. " + SHIFT + G", focusOrLaunch("gimp", "gimp"))
-- Claude on Cmd+Shift+O — same focus-or-launch toggle as the apps above.
hl.bind(modifier .. " + SHIFT + O", focusOrLaunch(claudeWindowClass, claudeApplication))

-- ── The bar's menus ─────────────────────────────────────────────────────────
hl.bind(modifier .. " + SHIFT + I", runScript("wifi-menu"))
hl.bind(modifier .. " + SHIFT + A", runScript("audio-menu"))
hl.bind(modifier .. " + SHIFT + B", runScript("bluetooth-menu"))
hl.bind(modifier .. " + SHIFT + V", runScript("nordvpn-menu"))
hl.bind(modifier .. " + comma", runScript("system-menu"))

-- The calculator. = because C is xremap's — Cmd+C is copy, rewritten before any
-- app sees it, so it can never be a launcher key — and K belongs to the window
-- directions below.
--
-- --here, and the window rule below, because a calculator belongs beside
-- whatever made you reach for it. Every other app here gets a desktop of its
-- own; this one gets yours.
hl.bind(modifier .. " + SHIFT + equal", runScript("focus-or-launch --here org.gnome.Calculator gnome-calculator"))

-- Windows that share a space: Cmd + a vim direction walks to the neighbor on
-- that side, and with Shift trades places with it. Ctrl+hjkl would be the
-- vim-tmux-navigator reflex, which is exactly why it is left alone: tmux and
-- nvim own those four, and Hyprland takes a key before any app sees it.
local vimDirections = { H = "left", J = "down", K = "up", L = "right" }
for key, direction in pairs(vimDirections) do
    hl.bind(modifier .. " + " .. key, hl.dsp.focus({ direction = direction }))
    hl.bind(modifier .. " + SHIFT + " .. key, hl.dsp.window.swap({ direction = direction }))
end

hl.bind(modifier .. " + Escape", hl.dsp.exec_cmd(quitHyprland))

-- Lock the screen.
--
-- The dedicated Delete key, not Backspace — which is the key a Mac calls Delete,
-- and which macOS already uses with Cmd for delete-to-start-of-line. Binding
-- that would mean a lifetime of Mac text-editing habits locking the screen
-- mid-sentence. This key sits alone in the top corner and is pressed on purpose
-- or not at all.
--
-- The trade is the Apple keyboard, which has no Delete key of its own and only
-- reaches this keysym via fn+Delete. Deliberate: a chord that's slightly awkward
-- on one machine beats one that fires by accident on both.
--
-- The guard matters. Without it a second press stacks another hyprlock on the
-- first, and each one wants its own password.
hl.bind(modifier .. " + Delete", hl.dsp.exec_cmd("pidof hyprlock || hyprlock"))

-- While the panel is dark (hypridle put it there), swallow the first key: it
-- wakes the screen and nothing else, instead of landing in the lock screen's
-- password field. hypridle enters this submap when it turns the panel off and
-- leaves it on any activity; the bind covers the case where that activity is
-- the key itself. `locked` so it fires under hyprlock. The panel is woken from
-- a timer rather than the bind itself, which is how Hyprland asks for DPMS to
-- be driven from a key.
hl.define_submap("dpms-off", function()
    hl.bind("catchall", function()
        hl.dispatch(hl.dsp.submap("reset"))
        hl.timer(function()
            hl.dispatch(hl.dsp.dpms({ action = "on", monitor = "eDP-1" }))
        end, { timeout = 1, type = "oneshot" })
    end, { locked = true })
end)

-- Cmd+Q quits the focused window (macOS-style). Works for any app at the
-- WM level, regardless of whether the app itself has a Ctrl+Q binding.
-- A separate watcher daemon (hypr-empty-workspace-watcher, started at login
-- below) handles jumping back to the previous workspace when this kill
-- — or any other close path — leaves the current workspace empty.
hl.bind(modifier .. " + Q", hl.dsp.window.close())
hl.bind(modifier .. " + SHIFT + Q", hl.dsp.window.kill())

-- Cmd+Tab cycles focus forward through the windows on the current
-- workspace; Cmd+` cycles backward through the same ring, so overshooting
-- is recoverable without releasing Cmd. cycle_next never leaves the current
-- workspace, which is the behavior we want: crossing spaces is already
-- Ctrl+←/→, so this stays the "what else is on this desktop" key.
--
-- Do not pair these with bring_to_top. Raising a window reorders the
-- very list cycle_next walks, so the newly-focused window becomes the
-- neighbor of the one you just left — which collapses the ring into a
-- ping-pong between two windows and makes Cmd+` useless. The cost is that
-- cycling to a buried floating window focuses it without raising it; the
-- cycle is worth more than the raise.
hl.bind(modifier .. " + Tab", hl.dsp.window.cycle_next())
hl.bind(modifier .. " + grave", hl.dsp.window.cycle_next({ next = false }))

-- Ctrl+Cmd+Space opens an emoji picker (macOS-style). The actual flow —
-- rofimoji into fuzzel, copy + ydotool-Ctrl+V because chromium ignores
-- synthetic typing of emoji, then restore the previous clipboard from
-- cliphist — lives in ~/.local/bin/emoji-picker (with the why).
hl.bind(modifier .. " + CTRL + space", runScript("emoji-picker"))

-- Clipboard history: a fuzzel list of recent entries; the selected one is
-- decoded and re-copied so the next paste uses it. wl-paste --watch (started
-- at login below) feeds cliphist.
--
-- On X rather than the more obvious V, which now opens the VPN menu — the
-- menus own the shifted keys. X keeps it in the cut/copy/paste family: bare
-- Cmd+X is cut, so the shifted variant reading as "the clipboard itself" is
-- close enough to guess.
hl.bind(modifier .. " + SHIFT + X", hl.dsp.exec_cmd("cliphist list | fuzzel --dmenu --width=60 --lines=15 | cliphist decode | wl-copy"))

-- Cmd+P — pixel picker. hyprpicker freezes the screen, click picks the color,
-- hex goes to the clipboard and pops a toast.
--
-- P for picker. It was on Cmd+Shift+C, borrowed from chromium devtools'
-- inspect-element chord — but that only reads as a color picker if you already
-- think in devtools, and it was squatting on a letter worth more elsewhere.
-- Photos keeps Cmd+Shift+P; nothing else wants the plain one.
hl.bind(modifier .. " + P", runScript("color-pick"))

-- Cmd+click adds to a selection, and opens a link in a new tab — the two things
-- Cmd+click does on a Mac. Both are really the same thing: Linux spells that
-- modifier Ctrl, so this swallows the Cmd+click and re-sends it as a Ctrl one.
--
-- It has to happen here, and it took a while to establish that. GTK asks GDK for
-- the "add to selection" modifier and GDK answers Ctrl — hardcoded, not a
-- setting. xremap can't help either: its own help says in so many words that
-- trackpads are not supported, and a tap-to-click never reaches the evdev layer
-- anyway — libinput synthesizes it downstream of anything that could rewrite it.
-- The compositor is the last place that still sees both the modifier and the
-- click.
--
-- What this gives up: Cmd+drag and Cmd+double-click, which the bind swallows and
-- does not reconstruct. Neither is a gesture anyone makes.
--
-- send_shortcut is called as a dispatcher, not through `exec hyprctl dispatch`.
-- The exec form works and is unreliable: it spawns a shell, which runs hyprctl,
-- which opens a socket back to Hyprland — three hops and a process launch, all
-- racing the real button's release. Land on the wrong side of that race and the
-- selection toggles twice, which looks exactly like nothing happening. A
-- dispatcher called straight from the bind has none of that in the way.
hl.bind(modifier .. " + mouse:272", hl.dsp.send_shortcut({ mods = "CTRL", key = "mouse:272", window = "activewindow" }))

-- Nothing that layers itself onto this desktop animates. Every surface here is
-- one you want *now* — a launcher, an OSD, the bar, a screen freeze, the
-- wallpaper — and an animation on any of them is a delay wearing a costume.
-- These suppress Hyprland's default layer animation; if something new starts
-- animating, find its namespace with `hyprctl layers` and add a line.
hl.layer_rule({ match = { namespace = "launcher" }, no_anim = true })
-- Frost the volume/brightness OSD: blur what's behind its translucent panel, and
-- ignore_alpha so the transparent surround isn't blurred into a halo — only the
-- square reads as frosted glass. Its styling lives in the
-- volume-and-brightness-controls feature.
hl.layer_rule({ match = { namespace = "eww-osd" }, no_anim = true, blur = true, ignore_alpha = 0.3 })
-- Same frosting for the AI usage dropdown under the bar (ai-usage
-- feature).
hl.layer_rule({ match = { namespace = "ai-usage" }, no_anim = true, blur = true, ignore_alpha = 0.3 })
-- And for the Apple TV remote card (apple-tv-remote feature).
hl.layer_rule({ match = { namespace = "apple-tv-remote" }, no_anim = true, blur = true, ignore_alpha = 0.3 })
-- waybar gets reloaded on theme switch (SIGUSR2). Without this rule the
-- surface tear-down + recreate animates, so a theme change looks like the bar
-- arriving rather than repainting.
hl.layer_rule({ match = { namespace = "waybar" }, no_anim = true })
-- hyprpicker is the screen-freeze overlay ~/.local/bin/screenshot uses during
-- region capture. Animating a freeze is a contradiction.
hl.layer_rule({ match = { namespace = "hyprpicker" }, no_anim = true })
-- awww-daemon paints the wallpaper as one persistent layer surface and runs
-- the theme-sweep transition inside it. Hyprland's own layer animation would
-- only ever fire at daemon start — sliding the whole desktop background in at
-- login — so it is suppressed; the sweep belongs to awww, not the compositor.
hl.layer_rule({ match = { namespace = "awww-daemon" }, no_anim = true })

-- Ctrl+Left/Right cycles workspaces, matching macOS Mission Control.
-- workspace-cycle walks the five spaces plus whatever exists above them (the
-- laptop panel's own space while docked, when 1..5 live on the monitor). It
-- never walks into a workspace that doesn't exist, so there's no drifting off
-- into an endless plain of empty desktops.
-- Trade-off: Ctrl+arrow word navigation in text fields is lost at the
-- system level — use Alt+arrow inside apps that support it instead.
hl.bind("CTRL + left", runScript("workspace-cycle left"))
hl.bind("CTRL + right", runScript("workspace-cycle right"))
-- Cmd+Left / Cmd+Right are intentionally NOT bound to workspace-cycle.
-- xremap rewrites them to Alt+Left / Alt+Right (see xremap config's
-- "page navigation" block), which chromium and similar apps treat
-- as history back/forward — matching macOS Cmd+Left/Right semantics.
-- Workspaces remain on Ctrl+Left/Right above.

-- Ctrl+1..Ctrl+5 jump directly to workspace 1..5 (macOS Spaces shortcut).
-- Capped at 5 to match the workspace count shown in waybar; workspace-cycle
-- also enforces this so Ctrl+→ can't drift past 5.
--
-- Dispatched from xremap (see dotfiles/config/xremap/config.yml) instead
-- of as a Hyprland bind. Hyprland binds run before the focused app gets
-- the keypress, so a global CTRL + 1 bind would steal Ctrl+1
-- from chromium tab switching (which is fed by Cmd+1 → Ctrl+1 via
-- xremap). Handling Ctrl+1..5 in xremap lets us route the workspace
-- switch and the chromium tab switch from the same physical inputs
-- without collision.

-- Cmd+Ctrl+1..5 moves the focused window to workspace 1..5 and follows
-- it (was Cmd+Shift+1..5 originally; reassigned because Cmd+Shift+3/4/5
-- now belong to screenshot/recording).
--
-- Dispatched from xremap alongside the Ctrl+1..5 workspace binds — see
-- the comment block on Ctrl+1..5 above for the why. Keeping these in
-- the same place avoids subtle ordering issues between xremap's
-- exact-match rules and Hyprland's bind matcher.

-- Every new window gets a desktop of its own: it is moved to the lowest of
-- the five spaces that holds nothing, and the view follows it there. When all
-- five are taken it stays on the one you are looking at — never a sixth.
--
-- This used to be Hyprland's `workspace = "empty"` window rule, whose "empty"
-- has no upper bound (its `empty[1-5]` form parses and is ignored), so a full
-- desktop overflowed onto 6: somewhere Cmd+1..5 can't reach and the bar never
-- promised. A watcher hauled each such window back, and waybar was left with a
-- ghost button for a workspace that had existed for a millisecond. Choosing the
-- space here, in the compositor, means 6 is never created at all.
--
-- Left where they open: anything a rule already placed elsewhere (BlueBubbles'
-- scratchpad), anything floating (dialogs, pickers, Quick Look — overlays
-- belong over what opened them), and the classes below, which you open
-- because of what you're already looking at.
local staysBesideWhatYouAreDoing = {
    ["org.gnome.Nautilus"] = true,          -- Cmd+E opens one beside your work, every time
    ["org.gnome.Calculator"] = true,
    ["chrome-localhost__-Default"] = true,  -- the markdown preview (:md in nvim)
    ["xdg-desktop-portal-gtk"] = true,      -- file pickers and system dialogs
}

local function isEmptyButForTheNewWindow(workspace, active)
    if workspace == nil or workspace.windows == 0 then
        return true
    end
    return workspace.id == active.id and workspace.windows == 1
end

local function lowestEmptySpace(active)
    for space = 1, spaceCount do
        if isEmptyButForTheNewWindow(hl.get_workspace(space), active) then
            return space
        end
    end
    return nil
end

-- One window to a space is what keeps the laptop panel readable, and it is
-- the wrong rule for a monitor with room for several: there a new window opens
-- beside the one you are in, and the layout divides the space (see dwindle).
local function getsASpaceOfItsOwn(window, active)
    return active ~= nil
        and active.monitor ~= nil
        and active.monitor.name == internalPanel
        and window.workspace ~= nil
        and window.workspace.id == active.id
        and not window.floating
        and not staysBesideWhatYouAreDoing[window.class]
end

hl.on("window.open", function(window)
    local active = hl.get_active_workspace()
    if getsASpaceOfItsOwn(window, active) then
        local space = lowestEmptySpace(active)
        if space ~= nil and space ~= active.id then
            hl.dispatch(hl.dsp.window.move({ window = window, workspace = tostring(space) }))
        end
    end
end)

-- …and the Quick Look preview (sushi, Space in Nautilus). It previews the
-- file you're looking at, so it floats over the folder it came from instead
-- of being sent to an empty desktop.
-- sushi shows its window only once the preview is ready and sized, so the
-- first frame is the final one — provided nothing resizes it afterwards. Its
-- own size is fixed by file-browser's patch-quick-look (it halves the
-- size on a scale-2 panel otherwise); forcing a size or minimum here instead
-- was what produced the pixelated flash, a half-size buffer stretched until
-- sushi repainted. `no_anim` keeps the open a cut rather than a tween.
hl.window_rule({
    match = { class = "org.gnome.NautilusPreviewer" },
    float = true,
    no_anim = true,
    center = true,
})

-- The music visualizer (projectM) asks SDL for fullscreen, which on Wayland
-- arrives as an ordinary toplevel; Hyprland has to be the one to make it
-- fullscreen. It still gets an empty space like any new window, so
-- it's a desktop of its own — Ctrl+arrow away from it, click the bar's
-- music levels (or Cmd+Q) to close it.
hl.window_rule({ match = { class = "projectMSDL" }, fullscreen = true })

-- BlueBubbles auto-starts hidden and lives in its special:bluebubbles
-- scratchpad (see the launch-hidden line at login below, and focus-or-launch
-- for Cmd+I). It maps its window ~12s after launch — late enough that
-- launch-hidden's reactive move can't beat the first frame, so the window
-- flashes on the current desktop and fades out. Placing it at map time
-- here keeps it off any real workspace; launch-hidden's move then no-ops.
-- Trade-off this reintroduces (why launch-hidden avoided a static rule): a
-- manual Cmd+I relaunch after a quit opens into the scratchpad, so the
-- first press shows nothing and a second brings it out.
hl.window_rule({ match = { class = "bluebubbles" }, workspace = "special:bluebubbles silent" })

-- xdg-desktop-portal-gtk hosts file pickers and other system dialogs for
-- apps that don't have their own (chromium's Save As, Open File, etc.).
-- Hyprland doesn't auto-float them, so explicitly float + size + center
-- so they read as overlays instead of fullscreen tiles.
hl.window_rule({
    match = { class = "xdg-desktop-portal-gtk" },
    float = true,
    size = { 900, 600 },
    center = true,
})

-- Disable Hyprland's compositor-level blur for ghostty. With ghostty
-- at low background-opacity (set per orchard-theme in ghostty.conf),
-- the wallpaper would otherwise show through *blurred*. Other layered
-- / translucent surfaces (fuzzel) keep their blur because the
-- rule is class-scoped.
hl.window_rule({ match = { class = "com.mitchellh.ghostty" }, no_blur = true })

-- --- hardware key bindings ---------------------------------------------
-- These do the actual work (audio level, brightness). Each routes through a
-- small script (volume / screen-brightness / kbd-brightness) that changes the
-- level and then pops the eww OSD square.
-- To swap the OSD layer, see the eww block below.

-- F1 / F2: screen brightness down/up
-- (in fnmode=3 these keys emit XF86MonBrightnessDown/Up directly)
-- screen-brightness handles the bl_power flip so 0% truly turns the panel off.
-- `repeating` so a real keyboard's hold repeats at the global rate. On the XPS
-- these are ACPI hotkeys that never hold — the firmware re-sends a tap ~4x/s —
-- so screen-brightness detects the hold itself and ramps faster on those ticks.
hl.bind("XF86MonBrightnessDown", runScript("screen-brightness down"), { repeating = true })
hl.bind("XF86MonBrightnessUp", runScript("screen-brightness up"), { repeating = true })

-- Fn+F1 / Fn+F2: keyboard backlight down/up
-- Same physical keys as screen brightness, but with Fn held. In fnmode=3,
-- plain F1/F2 emit XF86MonBrightnessDown/Up (caught by the binds above);
-- Fn+F1/F2 emit the literal F1/F2 keysyms, which is what we catch here.
-- kbd-brightness mirrors screen-brightness: brightnessctl + eww square.
hl.bind("F1", runScript("kbd-brightness down"), { repeating = true })
hl.bind("F2", runScript("kbd-brightness up"), { repeating = true })

-- F6 toggles do-not-disturb. Suppresses notifications
-- until pressed again (or the waybar bell is clicked). On Apple
-- keyboards in fnmode=3, F6 emits XF86Sleep — binding the literal F6
-- keysym wouldn't fire, and worse, logind catches XF86Sleep and would
-- put the screen to sleep. Hyprland binds run before logind sees the
-- key, so claiming XF86Sleep here both intercepts the sleep and gives
-- us our DND toggle.
hl.bind("XF86Sleep", runScript("dnd-toggle"))

-- F10 / F11 / F12: mute / volume down / volume up (3% step)
-- Up/down also unmute (matches macOS); the volume script handles that.
-- Up/down repeat while held; mute stays plain (toggle, no repeat).
hl.bind("XF86AudioMute", runScript("volume mute"))
hl.bind("XF86AudioLowerVolume", runScript("volume down"), { repeating = true })
hl.bind("XF86AudioRaiseVolume", runScript("volume up"), { repeating = true })

-- F7 / F8 / F9: prev / play-pause / next (whichever MPRIS player is active).
-- No OSD — macOS shows nothing for the media keys.
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"))
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"))
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"))

-- Lid close with an external monitor attached: fold the internal panel out, so
-- the external is the only screen and nothing is left stranded behind a shut
-- lid. hypr-lid also carries the workspace the laptop was showing across to the
-- monitor — disabling the output alone moves the workspaces but not the view.
-- `locked` so it fires even when the session is locked.
hl.bind("switch:on:Lid Switch", runScript("hypr-lid closed"), { locked = true })
hl.bind("switch:off:Lid Switch", runScript("hypr-lid opened"), { locked = true })

-- Run on every config load, not just at login (it sits outside the
-- hyprland.start block below on purpose). The eDP-1 monitor line above enables
-- the panel, and disabling it for a shut lid is only a runtime rule — so any
-- reload (a config edit, a theme switch) would resurrect a screen behind a
-- closed lid. It stays invisible, but the pointer walks off the monitor's left
-- edge onto it and never comes back.
hl.exec_cmd(localBin("hypr-lid sync"))

-- A monitor plugged in mid-session arrives bare: awww only paints outputs it
-- has already been handed an image for, so the wallpaper is put up again.
hl.on("monitor.added", function()
    hl.exec_cmd(localBin("set-wallpaper"))
end)

-- Hyprland leaves the kernel driving an unplugged monitor's pipe, and on this
-- laptop that stops the next plug-in from being detected at all (the why is in
-- the script). A no-op whenever there is nothing stale to release.
hl.on("monitor.removed", function()
    hl.exec_cmd(localBin("release-stale-display-pipes"))
end)

-- Everything that starts with the session. hyprland.start fires once, at
-- login; a config reload does not run these again.
hl.on("hyprland.start", function()
    -- --- OSD layer -----------------------------------------------------
    -- The eww daemon holds the frosted square that pops on volume/brightness
    -- changes. Purely visual; the audio/brightness work above happens
    -- regardless. Its widget, styling, and glyphs live in the
    -- volume-and-brightness-controls feature.
    hl.exec_cmd("eww daemon")
    -- The AI usage dropdown's own eww daemon (see the ai-usage feature).
    hl.exec_cmd(localBin("restart-ai-usage"))

    -- The Apple TV remote card's eww daemon (see the apple-tv-remote feature).
    hl.exec_cmd(localBin("restart-apple-tv-remote"))

    -- --- auth agent ----------------------------------------------------
    -- Polkit auth agent — pops the GUI password prompt when apps need
    -- privilege escalation (mounting drives, etc.).
    hl.exec_cmd(localBin("fuzzel-polkit-agent --width=30"))

    -- Top status bar.
    hl.exec_cmd("waybar")

    -- Geoclue agent — without this, geoclue can't grant location permission
    -- to apps (gnome-shell normally provides one; on Hyprland we don't have
    -- that, so we run the bundled demo agent which auto-allows). Required
    -- for gnome-maps "find me" to work, plus any future location-aware tool.
    hl.exec_cmd("/usr/lib/geoclue-2.0/demos/agent")

    -- Switch to the previously-used workspace when the active one becomes
    -- empty (any close path: Cmd+Q, ghostty's Cmd+W on the last tab, etc.).
    hl.exec_cmd(localBin("hypr-empty-workspace-watcher"))

    -- Begin the session on desktop 1. The workspace rules above pin 1..5 to
    -- DP-1, and Hyprland honors that pinning even when DP-1 is unplugged — so
    -- undocked the laptop panel comes up on six, which Cmd+1..5 cannot reach.
    -- See the script for the whole story.
    hl.exec_cmd(localBin("hypr-start-on-first-workspace"))

    -- macOS-style waybar auto-hide: bar hides during fullscreen, peeks
    -- back when the cursor hits the top edge. Lets you check the time /
    -- battery during a fullscreen video without leaving fullscreen.
    hl.exec_cmd(localBin("hypr-fullscreen-autohide"))

    -- Messages, running but never seen. It comes up at login and goes
    -- straight into its own scratchpad — the same place Cmd+I puts it when
    -- you hide it — so the app is connected from the moment you sign in, and
    -- a text arrives as a notification without a window ever having
    -- appeared. Cmd+I brings it out, exactly as though you had stashed it
    -- yourself. See launch-hidden for the two obvious approaches that don't
    -- work.
    hl.exec_cmd(localBin("launch-hidden bluebubbles bluebubbles"))

    -- Notification daemon. It paints nothing: notifications appear where the
    -- clock is, in the bar, and the bar draws them (see waybar-clock). This
    -- just owns org.freedesktop.Notifications and says what's currently
    -- showing.
    hl.exec_cmd(localBin("orchard-notifications"))

    -- The charger chime (battery feature): a sound when mains power connects.
    hl.exec_cmd(localBin("charge-chime"))

    -- Dims at 5 minutes, locks at 10, powers the panel off at 10:30. The panel
    -- is OLED and every lit pixel ages, so the screen going *off* is the only
    -- real protection against burn-in — see the lock feature's hypridle.conf.
    hl.exec_cmd("hypridle")

    -- Dell OLED white-balance correction — pulls the panel's green cast out so
    -- dark blues read blue, matched by hand to a MacBook Air. No-op on Apple
    -- panels. See configuration/desktop/display-color.
    hl.exec_cmd(localBin("apply-display-color"))

    -- Clipboard history watchers: cliphist stores every text/image copy so
    -- Cmd+Shift+X can pull them back. Two watchers because wl-paste --watch
    -- only handles one MIME type per invocation.
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")

    -- Shared clipboard (clipboard-sharing feature): a copy here lands on every
    -- other machine of yours on the tailnet, and theirs land here.
    hl.exec_cmd(localBin("shared-clipboard") .. " receive")
    hl.exec_cmd("wl-paste --type text --watch " .. localBin("shared-clipboard") .. " send")

    -- Propagate Hyprland's session env (incl. QT_QPA_PLATFORMTHEME) into D-Bus
    -- and systemd user services so xdg-desktop-portal-hyprland (D-Bus-launched
    -- lazily on first screencast) sees the Qt theme variables.
    hl.exec_cmd("dbus-update-activation-environment --systemd --all")

    -- Restart xremap now that the wayland session is up, so it can connect
    -- to Hyprland's foreign-toplevel protocol and see app classes — without
    -- this, per-app rules (the ghostty exclusion) silently fail because
    -- xremap can't tell which window is focused.
    hl.exec_cmd("systemctl --user restart xremap.service")

    -- Wallpaper — awww-daemon paints the image via wlr-layer-shell;
    -- set-wallpaper starts the daemon when it finds none running, so it owns
    -- login too. Nothing is being chosen at login, so it is called with no
    -- image: put up whatever ought to be up. That's an image chosen with
    -- set-wallpaper (kept in ~/.local/state/orchard/) if there is one,
    -- otherwise the active theme's own wallpaper.<ext>.
    hl.exec_cmd(localBin("set-wallpaper"))

    -- Keyboard backlight — set to max on every Hyprland start. The kernel
    -- leaves whatever value was there at boot, which on this hardware can be
    -- below the visible-light threshold (we've seen ~103/255 read as "off" in
    -- a dark room).
    --
    -- Goes through kbd-brightness rather than calling brightnessctl directly,
    -- because the LED's name is whatever the platform driver decided to call
    -- it — `dell::kbd_backlight` here, plain `kbd_backlight` on the mac. This
    -- line used to hardcode the bare name and had therefore never once worked
    -- on the XPS: brightnessctl answered "Device not found" and the exit code
    -- was thrown away. The script finds the device instead of guessing at it.
    hl.exec_cmd(localBin("kbd-brightness max"))
end)

-- --- key remapping -----------------------------------------------------
-- xremap translates Cmd+C/V/X/A/Z to Ctrl+ equivalents in non-terminal
-- apps so macOS-style shortcuts work everywhere. Ghostty is excluded in
-- xremap's config; ghostty handles Super+C/V via its own keybinds.
-- Lifecycle is handled by the systemd user unit at
-- dotfiles/config/systemd/user/xremap.service (WantedBy=default.target),
-- so it starts at user login — nothing to start here.

hl.env("XCURSOR_SIZE", "18")
hl.env("HYPRCURSOR_SIZE", "18")

-- Qt theming pipeline: qt6ct reads ~/.config/qt6ct/qt6ct.conf, which
-- delegates to Kvantum, which reads ~/.config/Kvantum/kvantum.kvconfig
-- for the active theme (Catppuccin Frappé). Affects hyprland-share-picker
-- and any other Qt app.
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")

-- Electron's equivalent of chromium's --ozone-platform-hint=auto: run on
-- Wayland when there is a compositor, fall back to X11 otherwise. Electron apps
-- don't read chromium-flags.conf, so the hint has to come from the environment.
-- "auto" is why the Claude desktop app (Cmd+Shift+O) lands on Wayland at native
-- HiDPI instead of a soft XWayland upscale. Applies to any Electron app.
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")

hl.config({
    -- When an app sends an XDG activation request (e.g. chromium opening
    -- an image from nautilus, or Slack/etc. surfacing a notification), follow
    -- the request and focus that window instead of staying put. Off by
    -- default — without this, opening a file in an external app silently
    -- routes it to a window/workspace you have to navigate to manually.
    misc = {
        focus_on_activate = true,
    },

    cursor = {
        -- hide the cursor while typing
        hide_on_key_press = true,
        -- don't yank the cursor to the new window when focuswindow / workspace
        -- switches happen — leaves the pointer where the user put it
        no_warps = true,
    },

    -- Leave a small edge around each window: a gap between tiled windows and
    -- a matching margin to the screen edge, so windows don't sit flush against
    -- the bezel or each other, plus a thin border to frame the focused window.
    general = {
        gaps_in = 5,
        gaps_out = 10,
        border_size = 2,
    },

    -- Round the corners to the 10 the rest of the desktop already rounds to —
    -- fuzzel's radius is 10 — so a window, a picker
    -- and the bar read as the same material rather than unrelated ones.
    -- The bar stays square on purpose: it spans the screen edge to edge, and a
    -- rounded full-width bar just lets the wallpaper into its corners.
    --
    -- rounding_power is the part that makes it read as macOS. Apple's corners
    -- are not circular arcs, they're superellipses — the curve runs flatter
    -- along the edge and then turns tighter into the corner. Hyprland's
    -- default 2.0 is a plain circle; 4.0 is the squircle. It is the difference
    -- you can't name and can see.
    --
    -- Nothing needs a rounding-suppression rule. Hyprland already leaves
    -- fullscreen windows square, so no wallpaper leaks into their corners, and
    -- layer surfaces (waybar) never take window rounding in the first place.
    -- Both were checked.
    -- dwindle halves whichever window you are in, along its longer side. Half
    -- of an ultrawide is still wider than it is tall, so left alone a third
    -- window makes a third column; counting height for half as much again
    -- makes that half read as tall, and the third window takes a quarter.
    dwindle = {
        split_width_multiplier = 1.5,
    },

    decoration = {
        rounding = 10,
        rounding_power = 4,
    },

    input = {
        kb_layout = "us",

        -- Keyboard focus follows clicks, not the mouse. Default (follow_mouse
        -- = 1) is sloppy focus: hovering the browser while typing in the
        -- terminal yanks keyboard focus mid-keystroke. With 2, keyboard focus
        -- stays on the last window you clicked/typed in; hovering still routes
        -- scroll-wheel events to the window under the cursor (macOS-style),
        -- and the active-border accent no longer flickers on passing hover.
        -- Click a window to focus it.
        follow_mouse = 2,

        -- Caps Lock → Ctrl is deliberately NOT done here. xremap's modmap does
        -- it at the input layer instead (see xremap/config/config.yml), which
        -- means it holds in a bare TTY and in tmux, not just inside Hyprland.
        -- An XKB-level `kb_options = "ctrl:nocaps"` here would be dead weight
        -- on top of that — xremap runs first, so Hyprland only ever sees a
        -- Ctrl that has already been translated, and there is no Caps left to
        -- remap.

        -- libinput's neutral speed, which is what mice want. The trackpad
        -- needs more gain than a mouse to cross the screen in one swipe and
        -- gets its boost back in the device blocks below — setting it here
        -- instead applied the same boost to every mouse, which made them
        -- unusably fast.
        sensitivity = 0,

        -- same scroll direction as the trackpad below — this one is the mouse
        natural_scroll = true,

        touchpad = {
            -- use sane scroll direction
            natural_scroll = true,

            -- disable the cursor while typing
            disable_while_typing = true,

            -- decrease scroll sensitivity
            scroll_factor = 0.1,
        },
    },

    gestures = {
        -- Swiping past the last desktop must NOT conjure another one. There
        -- are five workspaces on purpose — five in the bar, five on Cmd+1..5,
        -- and new windows are placed among those five and no further. Left at
        -- its default (on), this would hand you a sixth with a flick of three
        -- fingers.
        workspace_swipe_create_new = false,
    },
})

-- Border colors live per-theme so the focused-window frame tracks the
-- active orchard-theme. The partial sets general.col.active_border /
-- inactive_border; set-theme repoints the `active` symlink and runs
-- `hyprctl reload`, so switching themes repaints the borders. Loaded
-- after the general block above so its colors merge into it.
require(home .. "/.config/orchard-themes/active/hyprland")

-- The trackpad keeps the gain that input.sensitivity used to apply globally.
-- A Windows Precision touchpad shows up as two devices — a multitouch node and
-- a HID mouse node the firmware falls back to — and which one drives the
-- pointer isn't ours to decide, so both carry the same figure.
--
-- One block per laptop, matched by device name: a machine that doesn't have
-- the device ignores the block, so this is how the per-machine tuning stays
-- in one file without an install-time branch.
local trackpadSensitivity = 0.5

-- Dell XPS 14
hl.device({ name = "ven_2c2f:00-2c2f:0034-touchpad", sensitivity = trackpadSensitivity })
hl.device({ name = "ven_2c2f:00-2c2f:0034-mouse", sensitivity = trackpadSensitivity })

-- Framework Laptop 13
hl.device({ name = "pixa3854:00-093a:0274-touchpad", sensitivity = trackpadSensitivity })
hl.device({ name = "pixa3854:00-093a:0274-mouse", sensitivity = trackpadSensitivity })

-- Three fingers sideways moves between desktops, the way it does on a Mac. The
-- workspace follows your fingers as you drag, rather than snapping at the end,
-- so a half-swipe you change your mind about can be walked back.
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
