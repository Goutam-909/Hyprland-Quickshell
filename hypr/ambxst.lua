 -- Quickshell shell (bar, widgets, etc.)
 hl.exec_cmd("qs -p ~/.config/quickshell/Ambxst/shell.qml")

 -- Login lock script
 hl.exec_cmd("~/.config/quickshell/Ambxst/scripts/loginlock.sh")
 -- ── ambxst launcher bindings ──────────────────────────────────────────────────

 hl.bind("SUPER + SUPER_L", hl.dsp.exec_cmd("ambxst run launcher"),      {release = true} )
 hl.bind("SUPER + A",         hl.dsp.exec_cmd("ambxst run launcher"),    { description = "App launcher" })
 hl.bind("SUPER + D",         hl.dsp.exec_cmd("ambxst run dashboard"),   { description = "Dashboard" })
 hl.bind("SUPER + V",         hl.dsp.exec_cmd("ambxst run assistant"),   { description = "Assistant" })
 hl.bind("SUPER + C",         hl.dsp.exec_cmd("ambxst run clipboard"),   { description = "Clipboard" })
 hl.bind("SUPER + Period",    hl.dsp.exec_cmd("ambxst run emoji"),       { description = "Emoji picker" })
 hl.bind("SUPER + N",         hl.dsp.exec_cmd("ambxst run notes"),       { description = "Notes" })
 hl.bind("SUPER + Space",     hl.dsp.exec_cmd("ambxst run wallpapers"),  { description = "Wallpapers" })
 hl.bind("SUPER + Tab",       hl.dsp.exec_cmd("ambxst run overview"),    { description = "Overview" })
 hl.bind("SUPER + BackSpace", hl.dsp.exec_cmd("ambxst run powermenu"),   { description = "Power menu" })
 hl.bind("SUPER + S",         hl.dsp.exec_cmd("ambxst run tools"),       { description = "Tools" })
 hl.bind("SUPER + L",         hl.dsp.exec_cmd("loginctl lock-session"),  { description = "Lock session" })
 hl.bind("SUPER + M",         hl.dsp.exec_cmd("ambxst run mediawindow"), { description = "Music" })
 hl.bind("SUPER + Print",     hl.dsp.exec_cmd("ambxst run screenshot"),  { description = "Screenshot" })
 -- ── Brightness ────────────────────────────────────────────────────────────────
 hl.bind("XF86MonBrightnessUp",
         hl.dsp.exec_cmd("ambxst brightness +5"),
         { locked = true, repeating = true })
 hl.bind("XF86MonBrightnessDown",
         hl.dsp.exec_cmd("ambxst brightness -5"),
         { locked = true, repeating = true })
