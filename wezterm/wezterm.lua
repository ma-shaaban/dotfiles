local wezterm = require("wezterm")
local config = wezterm.config_builder()
local act = wezterm.action

-- General

config.font_size = 15
config.line_height = 1.2
config.window_decorations = "RESIZE"
-- WezTerm bundles a Nerd Font symbols fallback; install.sh also installs
-- FiraCode Nerd Font if you want it as the main font:
-- config.font = wezterm.font("FiraCode Nerd Font")
-- config.color_scheme = "Catppuccin Mocha"
config.color_scheme = "Catppuccin Macchiato"
-- config.color_scheme = "Catppuccin Latte"

-- Key bindings
config.keys = {
    {
        key = "w",
        mods = "CMD",
        action = act.CloseCurrentPane({ confirm = false }),
    },
    {
        key = "d",
        mods = "CMD",
        action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }),
    },
    {
        key = "d",
        mods = "CMD | SHIFT",
        action = act.SplitVertical({ domain = "CurrentPaneDomain" }),
    },
    {
        key = "k",
        mods = "CMD",
        action = act.SendString("clear\n"),
    },
    {
        key = "LeftArrow",
        mods = "OPT",
        action = act.SendKey({ key = "b", mods = "ALT" }),
    },
    {
        key = "RightArrow",
        mods = "OPT",
        action = act.SendKey({ key = "f", mods = "ALT" }),
    },

    -- Switch to the previous tab
    { key = "j", mods = "CMD | SHIFT", action = act.ActivateTabRelative(-1) },
    -- Switch to the next tab
    { key = "k", mods = "CMD | SHIFT", action = act.ActivateTabRelative(1) },

    {
        key = "Enter",
        mods = "SHIFT",
        action = act.SendString("\x1b[13;2u"),
    },
}

for i = 1, 8 do
    -- CTRL+CMD + number to move the tab to that position
    table.insert(config.keys, {
        key = tostring(i),
        mods = "CTRL|CMD",
        action = act.MoveTab(i - 1),
    })
end

-- Machine-specific settings (ssh_domains, etc.) live in
-- ~/.config/wezterm/local.lua, which is not in the repo. It returns a
-- function that receives the config. See wezterm/local.example.lua.
local ok, apply_local = pcall(dofile, wezterm.home_dir .. "/.config/wezterm/local.lua")
if ok and type(apply_local) == "function" then
    apply_local(config)
end

return config
