
-- >>> MacShell module (manual install: put this at ~/.config/hypr/macshell.lua and add  require("macshell")  to hyprland.lua) >>>
-- autostart (remove other bars / docks / notification daemons first).
-- install.sh adds this for you; macshell-start waits for the compositor and restarts the shell if it crashes.
hl.on("hyprland.start", function()
    hl.exec_cmd("awww-daemon")
    -- Install/update Hypridle's before_sleep_cmd hook (lid close is covered when it suspends).
    hl.exec_cmd("sh ~/.config/quickshell/MacLock/enable-sleep-lock.sh")
    hl.exec_cmd("qs -c MacShell")
end)
-- The Settings window floats and centres itself: the shell registers its own window rule at start-up, so this file needs none.

-- keybinds (the name after -c is the config folder name, case-sensitive)
local qs = "qs -c MacShell ipc call "

hl.bind("SUPER + SPACE",          hl.dsp.exec_cmd(qs .. "settings toggle"))
hl.bind("SUPER + V",          hl.dsp.exec_cmd(qs .. "spotlight clipboard"))
hl.bind("SUPER + period",     hl.dsp.exec_cmd(qs .. "spotlight emoji"))
hl.bind("SUPER + S",      hl.dsp.exec_cmd(qs .. "spotlight toggle"))
hl.bind("ALT + TAB",          hl.dsp.exec_cmd(qs .. "switcher next"))
hl.bind("CTRL + ALT + W",     hl.dsp.exec_cmd(qs .. "wallpapers toggle"))
hl.bind("SUPER + PRINT",              hl.dsp.exec_cmd(qs .. "screenshot region"))

hl.bind("SUPER + SUPER_L", hl.dsp.exec_cmd(qs .. "spotlight apps"),      {release = true} )
hl.bind("SUPER + A",         hl.dsp.exec_cmd(qs .. "spotlight apps"),    { description = "App launcher" })

-- Hardware keys (laptop buttons too): volume, mute, brightness, media. MacShell handles them itself and shows its
-- on-screen display. If the shell is not running, wpctl / brightnessctl do the work instead.
-- "locked" keeps the keys working on the lock screen. Any earlier bind on the same key is dropped first, so a key never fires twice.
local function hw(action, fallback)
    return "sh -c '" .. qs .. "hardware " .. action .. " >/dev/null 2>&1 || " .. fallback .. "'"
end
local hwkeys = {
    { "XF86MonBrightnessUp",   hw("brightnessUp",   "brightnessctl -q -c backlight set 5%+ 2>/dev/null || ddcutil setvcp 10 + 5"),                      true  },
    { "XF86MonBrightnessDown", hw("brightnessDown", "brightnessctl -q -n1 -c backlight set 5%- 2>/dev/null || ddcutil setvcp 10 - 5"),                  true  },
    { "XF86KbdBrightnessUp",   "brightnessctl -q -d '*kbd_backlight*' set 10%+",                         true  },
    { "XF86KbdBrightnessDown", "brightnessctl -q -d '*kbd_backlight*' set 10%-",                         true  },
}
for _, k in ipairs(hwkeys) do
    pcall(hl.unbind, k[1])
    hl.bind(k[1], hl.dsp.exec_cmd(k[2]), { locked = true, repeating = k[3] })
end

-- MacLock (lock screen)
hl.bind("SUPER + L",          hl.dsp.exec_cmd("sh ~/.config/quickshell/MacLock/lock-via-ipc.sh"))
-- <<< MacShell module <<<
hl.window_rule({
    name  = "macshell-settings",
    match = { title = "^(macshell Settings)$" },
               float = true,
               center = true,
               border_size = 0,
               rounding = 12,
               rounding_power = 2,   -- plain circular arc, same as the QML Rectangle
})
hl.window_rule({
    name  = "macshell-about",
    match = { title = "^(About This Linux)$" },
               float = true,
               center = true,
               border_size = 0,
               rounding = 18,
               rounding_power = 2,
})
hl.config({ decoration = { rounding = 12 } })


