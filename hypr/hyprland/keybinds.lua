-- Keybinds loader.
-- Only the ACTIVE shell's file is loaded: hyprland/shells/current -> end4-pC | ambxst
-- (symlink managed by hyprland/scripts/switch-shell.sh). The other shell's
-- Lua is never executed, so the two setups are fully isolated.
local cfg    = (os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")) .. "/hypr"
local shells = cfg .. "/hyprland/shells"

local function pick(file)
    local p = shells .. "/current/" .. file
    local f = io.open(p, "r")
    if f then f:close() return p end
    return shells .. "/end4-pC/" .. file          -- fallback if the link is missing
end

dofile(pick("keybinds.lua"))
