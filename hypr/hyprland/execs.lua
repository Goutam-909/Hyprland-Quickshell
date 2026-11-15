-- exec-once. Only the ACTIVE shell's execs file is loaded (see shells/current).
local cfg    = (os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")) .. "/hypr"
local shells = cfg .. "/hyprland/shells"

local function pick(file)
    local p = shells .. "/current/" .. file
    local f = io.open(p, "r")
    if f then f:close() return p end
    return shells .. "/end4-pC/" .. file          -- fallback if the link is missing
end

-- shells/<name>/execs.lua returns a function with that shell's startup lines
local shell_execs = dofile(pick("execs.lua"))

hl.on("hyprland.start", function()

    -- Kill leftovers of the OTHER shell (hypridle / loginlock / sleep_monitor / its qs)
    hl.exec_cmd(cfg .. "/hyprland/scripts/switch-shell.sh boot-cleanup")

    -- DBus environment (run first so other services can find the session)
    hl.exec_cmd("sleep 2 && dbus-update-activation-environment --systemd --all")

    -- Polkit authentication agent
    --hl.exec_cmd("~/.config/hypr/scripts/polkit.sh")

    -- Clipboard history
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")

    -- Shell specific: udiskie, idle/lock, quickshell, arch-update
    shell_execs()

    -- Keyring daemon (pkcs11 + secrets + gpg)
    hl.exec_cmd("/usr/bin/gnome-keyring-daemon --start --components=pkcs11,secrets,gpg")

    -- OpenTabletDriver daemon
    hl.exec_cmd("otd-daemon")
    hl.exec_cmd("~/.config/hypr/custom/scripts/__restore_video_wallpaper.sh")

end)
