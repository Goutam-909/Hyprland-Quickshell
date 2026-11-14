-- ██╗  ██╗███████╗██╗   ██╗██████╗ ██╗███╗   ██╗██████╗ ███████╗
-- ██║ ██╔╝██╔════╝╚██╗ ██╔╝██╔══██╗██║████╗  ██║██╔══██╗██╔════╝
-- █████╔╝ █████╗   ╚████╔╝ ██████╔╝██║██╔██╗ ██║██║  ██║███████╗
-- ██╔═██╗ ██╔══╝    ╚██╔╝  ██╔══██╗██║██║╚██╗██║██║  ██║╚════██║
-- ██║  ██╗███████╗   ██║   ██████╔╝██║██║ ╚████║██████╔╝███████║
-- ╚═╝  ╚═╝╚══════╝   ╚═╝   ╚═════╝ ╚═╝╚═╝  ╚═══╝╚═════╝ ╚══════╝

-- ── Variables ─────────────────────────────────────────────────────────────────
local term     = "kitty"
local editor   = "code"
local file     = "dolphin"
local browser  = "zen-browser"
local hyprScripts = "$HOME/.config/hypr/hyprland/scripts"
local qsIpcCall = "qs -c end4-pC ipc call"

-- ── Window / Session actions ──────────────────────────────────────────────────
hl.bind("SUPER + Q",          hl.dsp.window.close(),          { description = "Close focused window" })
hl.bind("ALT + F4",           hl.dsp.window.close())
hl.bind("SUPER + Delete",     hl.dsp.exit(),                  { description = "Kill Hyprland session" })
hl.bind("SUPER + W", hl.dsp.window.float({ action = "toggle" }), { description = "Toggle floating" })
hl.bind("ALT + Return",       hl.dsp.window.fullscreen(),     { description = "Toggle fullscreen" })
hl.bind("SUPER + SHIFT + F",  hl.dsp.exec_cmd(hyprScripts .. "/windowpin.sh"), { description = "Toggle pin on focused window" })

-- Toggle split (dwindle)
hl.bind("SUPER + J", hl.dsp.layout("togglesplit"), { description = "Toggle split" })


-- ── Application shortcuts ─────────────────────────────────────────────────────
hl.bind("SUPER + T",          hl.dsp.exec_cmd(term),                          { description = "Terminal" })
hl.bind("SUPER + E",          hl.dsp.exec_cmd(file),                          { description = "File manager" })
hl.bind("SUPER + F",          hl.dsp.exec_cmd(browser),                       { description = "Browser" })
hl.bind("SUPER + Return",     hl.dsp.exec_cmd("kitty --class kitty-float"),   { description = "Floating kitty" })
hl.bind("SUPER + R", hl.dsp.exec_cmd("bash -c 'pgrep -x rofi && pkill rofi || /home/goutam/.config/uchiha/scripts/ani-cli-menu.sh'"))
--hl.bind("SUPER + R",          hl.dsp.exec_cmd('sh -c "rmpc rescan && kitty --class rmpc-term -e rmpc"'), { description = "rmpc (music client)" })
hl.bind("CTRL + SHIFT + Escape", hl.dsp.exec_cmd("kitty -1 fish -i -c  btop"),            { description = "System monitor (btop)" })

-- Restart widgets
hl.bind("CTRL + SUPER + R",
        hl.dsp.exec_cmd("qs -c caelestia kill; sleep .1; caelestia shell -d"),
        { description = "Restart widgets" })

-- Record screen (with sound) – locked so it works on lock screen
hl.bind("SUPER + SHIFT + R",
        hl.dsp.exec_cmd(hyprScripts .. "/record.sh --fullscreen-sound"),
        { locked = true, description = "Record screen (with sound)" })


-- ── uchiha launcher bindings ──────────────────────────────────────────────────
hl.bind("SUPER + SUPER_L", hl.dsp.global("caelestia:launcher"), { release = true })

hl.bind("SUPER + A", hl.dsp.global("quickshell:overviewAppsToggle"))
hl.bind("SUPER + D", hl.dsp.global("caelestia:sidebar"), { description = "Shell: Toggle right sidebar" })
hl.bind("SUPER + V", hl.dsp.global("caelestia:showall"))
hl.bind("SUPER + C", hl.dsp.exec_cmd("pkill fuzzel || caelestia clipboard"))
hl.bind("SUPER + Period", hl.dsp.global("quickshell:overviewEmojiToggle"))
hl.bind("SUPER + N",         hl.dsp.exec_cmd("caelestia toggle todo"),       { description = "Notes" })

hl.bind("SUPER +CTRL + T", hl.dsp.global("quickshell:wallpaperSelectorToggle"), { description = "Shell: Change wallpaper" })
hl.bind("SUPER + SPACE", hl.dsp.global("quickshell:wallpaperSelectorV2Toggle"), { description = "Shell: Change wallpaper" })
hl.bind("SUPER + Tab", hl.dsp.global("quickshell:overviewWorkspacesToggle"), { description = "Shell: Toggle overview" })
hl.bind("SUPER + ALT + A", hl.dsp.global("quickshell:sidebarLeftToggleDetach"))
hl.bind("SUPER + BackSpace", hl.dsp.global("caelestia:session"), { description = "Shell: Toggle session menu" })
hl.bind("SUPER + Slash", hl.dsp.global("quickshell:cheatsheetToggle"), { description = "Shell: Toggle cheatsheet" })
hl.bind("SUPER + G", hl.dsp.global("quickshell:overlayToggle"), { description = "Shell: Toggle widget overlay" })
--hl.bind("SUPER + S",         hl.dsp.exec_cmd("ambxst run tools"),       { description = "Tools" })
hl.bind("SUPER + L", hl.dsp.global("caelestia:lock"), { description = "Session: Lock" })
hl.bind("SUPER + M", hl.dsp.global("quickshell:mediaControlsToggle"), { description = "Shell: Toggle media controls" })
hl.bind("SUPER + B",         hl.dsp.global("quickshell:barToggle"), { description = "Bar Toggle" })
hl.bind("SUPER +  Print", hl.dsp.global("caelestia:screenshotFreeze"))
hl.bind("CTRL + SUPER + W", hl.dsp.global("quickshell:panelFamilyCycle"), { description = "Shell: Cycle panel family" })
-- ── Touch deck / quick web shortcuts ─────────────────────────────────────────
hl.bind("ALT + F1", hl.dsp.exec_cmd('xdg-open "https://unacademy.com"'))
hl.bind("ALT + F2", hl.dsp.exec_cmd('xdg-open "https://youtube.com"'))
hl.bind("ALT + F3", hl.dsp.exec_cmd('xdg-open "https://web.whatsapp.com"'))
hl.bind("ALT + F5", hl.dsp.exec_cmd('xdg-open "https://your-mock-test-link.com"'))
hl.bind("ALT + F6", hl.dsp.exec_cmd('xdg-open "https://music.youtube.com"'))


-- ── Media control ─────────────────────────────────────────────────────────────
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })

-- Fn key aliases for media
hl.bind("F9",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true, description = "Play/pause" })
hl.bind("F10", hl.dsp.exec_cmd("playerctl next"),       { locked = true, description = "Next track" })
hl.bind("F8",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true, description = "Previous track" })



-- Brightness
hl.bind("XF86MonBrightnessUp", hl.dsp.global("caelestia:brightnessUp"), { locked = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.global("caelestia:brightnessDown"), { locked = true })

-- ── Volume ────────────────────────────────────────────────────────────────────
hl.bind("XF86AudioRaiseVolume",
        hl.dsp.exec_cmd("$HOME/.config/waybar/scripts/Volume.sh --inc"),
        { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",
        hl.dsp.exec_cmd("$HOME/.config/waybar/scripts/Volume.sh --dec"),
        { locked = true, repeating = true })
hl.bind("XF86AudioMute",
        hl.dsp.exec_cmd("$HOME/.config/waybar/scripts/Volume.sh --toggle"),
        { locked = true })
hl.bind("XF86AudioMicMute",
        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),
        { locked = true })


-- ── Screenshot / Screencapture ────────────────────────────────────────────────
-- Region screenshot
--hl.bind("SUPER + Print",
--        hl.dsp.exec_cmd("hyprshot -m region"),
--        { description = "Screenshot region" })

-- Fullscreen screenshot → save to file
hl.bind("Print",
        hl.dsp.exec_cmd(
                'mkdir -p $(xdg-user-dir PICTURES)/Screenshots && ' ..
                'grim $(xdg-user-dir PICTURES)/Screenshots/Screenshot_"$(date \'+%Y-%m-%d_%H.%M.%S\')".png && ' ..
                "notify-send 'Screenshot Captured' 'Fullscreen'"
        ),
        { locked = true, description = "Screenshot >> save to file" })


-- ── Window focus (arrow keys) ─────────────────────────────────────────────────
hl.bind("SUPER + Left",  hl.dsp.focus({ direction = "l" }))
hl.bind("SUPER + Right", hl.dsp.focus({ direction = "r" }))
hl.bind("SUPER + Up",    hl.dsp.focus({ direction = "u" }))
hl.bind("SUPER + Down",  hl.dsp.focus({ direction = "d" }))
hl.bind("ALT + Tab",     hl.dsp.focus({ direction = "d" }))


-- ── Resize windows ────────────────────────────────────────────────────────────
hl.bind("SUPER + SHIFT + Right", hl.dsp.window.resize({ x =  30, y =   0 }), { repeating = true })
hl.bind("SUPER + SHIFT + Left",  hl.dsp.window.resize({ x = -30, y =   0 }), { repeating = true })
hl.bind("SUPER + SHIFT + Up",    hl.dsp.window.resize({ x =   0, y = -30 }), { repeating = true })
hl.bind("SUPER + SHIFT + Down",  hl.dsp.window.resize({ x =   0, y =  30 }), { repeating = true })


-- ── Move / Resize with mouse ──────────────────────────────────────────────────
hl.bind("SUPER + mouse:272", hl.dsp.window.drag(),   { mouse = true, description = "Drag window" })
hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true, description = "Resize window" })
hl.bind("SUPER + Z",         hl.dsp.window.drag(),   { description = "Drag window (keyboard)" })
hl.bind("SUPER + X",         hl.dsp.window.resize(), { description = "Resize window (keyboard)" })


-- ── Switch workspaces ─────────────────────────────────────────────────────────
for i = 1, 9 do
        hl.bind("SUPER + " .. i, hl.dsp.focus({ workspace = i }))
        end
        hl.bind("SUPER + 0", hl.dsp.focus({ workspace = 10 }))

        -- Relative workspace switch
        hl.bind("SUPER + CTRL + Right", hl.dsp.focus({ workspace = "r+1" }))
        hl.bind("SUPER + CTRL + Left",  hl.dsp.focus({ workspace = "r-1" }))

        -- Move to first empty workspace
        hl.bind("SUPER + CTRL + Down", hl.dsp.focus({ workspace = "empty" }))

        -- Scroll through workspaces with mouse wheel
        hl.bind("SUPER + mouse_up",   hl.dsp.focus({ workspace = "e+1" }))
        hl.bind("SUPER + mouse_down", hl.dsp.focus({ workspace = "e-1" }))


        -- ── Move focused window to workspace ─────────────────────────────────────────
        for i = 1, 9 do
                hl.bind("SUPER + SHIFT + " .. i, hl.dsp.window.move({ workspace = i }))
                end
                hl.bind("SUPER + SHIFT + 0", hl.dsp.window.move({ workspace = 10 }))

                -- Move to relative workspace
                hl.bind("SUPER + CTRL + ALT + Right", hl.dsp.window.move({ workspace = "r+1" }))
                hl.bind("SUPER + CTRL + ALT + Left",  hl.dsp.window.move({ workspace = "r-1" }))


                -- ── Move to workspace silently (no focus switch) ──────────────────────────────
                for i = 1, 9 do
                        hl.bind("SUPER + ALT + " .. i, hl.dsp.window.move({ workspace = i, silent = true }))
                        end
                        hl.bind("SUPER + ALT + 0", hl.dsp.window.move({ workspace = 10, silent = true }))

                        -- Move to scratchpad silently
                        hl.bind("SUPER + ALT + S", hl.dsp.window.move({ workspace = "special", silent = true }),
                                { description = "Move to scratchpad" })


                        -- ── Scrolling layout binds ────────────────────────────────────────────────────
                      --  hl.bind("SUPER + Period", hl.dsp.layout("move +col"), { description = "Move window to next column" })
                      --  hl.bind("SUPER + Comma",  hl.dsp.layout("move -col"), { description = "Move window to prev column" })
