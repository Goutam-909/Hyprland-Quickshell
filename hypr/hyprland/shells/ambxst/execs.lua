-- ambxst: NO hypridle. Ambxst has its own idle handling,
-- and loginlock.sh is what answers `loginctl lock-session`.
return function()
    -- Removable media manager (no automount, sits in tray)
    hl.exec_cmd("udiskie --no-automount --smart-tray")

    -- Quickshell shell (bar, widgets, etc.)
    hl.exec_cmd("qs -p ~/.config/quickshell/Ambxst/shell.qml")

    -- Login lock script
    hl.exec_cmd("~/.config/quickshell/Ambxst/scripts/loginlock.sh")

    hl.exec_cmd("sleep 5 && arch-update --tray")
end
