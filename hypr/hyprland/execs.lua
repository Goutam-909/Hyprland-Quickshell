-- put former exec-once commands inside the func and former exec commands outside
hl.on("hyprland.start", function()

    -- DBus environment (run first so other services can find the session)
    hl.exec_cmd("sleep 2 && dbus-update-activation-environment --systemd --all")

    -- Polkit authentication agent
    --hl.exec_cmd("~/.config/hypr/scripts/polkit.sh")

    -- Removable media manager (no automount, sits in tray)
    hl.exec_cmd("udiskie --no-automount --smart-tray")

    -- Clipboard history
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")

    -- Idle / lock screen daemon
    --hl.exec_cmd("hypridle")



    -- Keyring daemon (pkcs11 + secrets + gpg)
    hl.exec_cmd("/usr/bin/gnome-keyring-daemon --start --components=pkcs11,secrets,gpg")

    -- OpenTabletDriver daemon
    hl.exec_cmd("otd-daemon")

    hl.exec_cmd("sleep 5 && arch-update --tray")

end)
