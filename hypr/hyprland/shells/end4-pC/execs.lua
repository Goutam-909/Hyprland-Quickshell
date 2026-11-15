-- end4-pC: hypridle handles idle + lock
return function()
    -- Removable media manager (no automount, sits in tray)
    hl.exec_cmd("udiskie -A -t")

    -- Idle / lock screen daemon
    hl.exec_cmd("hypridle")

    -- Quickshell shell (bar, widgets, etc.)
    hl.exec_cmd("qs -c end4-pC")

    hl.exec_cmd("arch-update --tray")
end
