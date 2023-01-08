--[[ *************************************************************
 * Context menu for mpv using Tcl/Tk. Mostly proof of concept.
 * Avi Halachmi (:avih) https://github.com/avih
 * 
 * Features:
 * - Simple construction: ["<some text>", "<mpv-command>"] is a complete menu item.
 * - Possibly dynamic menu items and commands, disabled items, separators.
 * - Possibly keeping the menu open after clicking an item (via re-launch).
 * - Hacky pseudo sub menus. Really, this is an ugly hack.
 * - Reasonably well behaved/integrated considering it's an external application.
 * 
 * Setup:
 * - Make sure Tcl/Tk is installed and `wish` is accessible and works.
 *   - Alternatively, configure `interpreter` below to `tclsh`, which may work smoother.
 *   - For windows, download a zip from http://www.tcl3d.org/html/appTclkits.html
 *     extract and then rename to wish.exe and put it at the path or at the mpv.exe dir.
 *     - Or, tclsh/wish from git/msys2(mingw) works too - set `interpreter` below.
 * - Put context.lua (this file) and context.tcl at the mpv scripts dir.
 * - Add a key/mouse binding at input.conf, e.g. "MOUSE_BTN2 script_message contextmenu"
 * - Once it works, configure the context_menu items below to your liking.
 *
 * 2017-02-02 - Version 0.1 - initial version
 * 
 * Edit by Chao Liu
 * 2023-01-02 - Version 0.2 - add sub menu popup without click/re-launch
 * 
 ***************************************************************
--]]

--[[ ************ CONFIG: start ************ ]]--

-- context_menu is an array of items, where each item is an array of:
-- - Display string or a function which returns such string, or "-" for separator.
-- - Command string or a function which is executed on click. Empty to disable/gray.
-- - Optional re-launch: a submenu array, or true to "keep" the same menu open.
-- 
-- Version 0.2
-- context_menu is an one dimensional array.  Sub menu starts with
-- {"=", "Submenu label"},
-- end with
-- {"=", ""},

function noop() end
local prop_native = mp.get_property_native

local options = require 'mp.options'
local opts = {
    save_window_position_on_exit=true,
    x = 50,
    y = 50,
    width = "50%",
    height = "50%",
    reset=false
}
        
local context_menu = {
    {function() return prop_native("pause") and "Play" or "Pause" end, "cycle pause"},
    {"-"},
    {function() return prop_native("mute") and "Un-mute" or "Mute" end, "cycle mute"},
    {"* Volume Up",   "add volume  10", true},
    {"* Volume Down", "add volume -10", true},
    {function() return "[ Volume: " .. tostring(math.floor(prop_native("volume"))) .. " ]" end},
    {"-"},
    {"* Scale: .1",  "add window-scale .1", true},
    {"* Scale: -.1", "add window-scale -.1", true},
    {"* Scale: 1",   "set window-scale 1", true},
    {"-"},
    --{"playlist", "show-text ${playlist}"},
    {"Playlist", "script-binding showplaylist"},
    {"-"},
    {"Audio", "keypress F9"},
    {"=", "Video"},
        {"cycle video-unscaled", "cycle video-unscaled", true},
		{"cycle-values window-scale", "cycle-values window-scale 2 3 1 .5", true},
		{"Rotate Clockwise", "cycle-values video-rotate 90 180 270 0", true},
		{"Rotate Counter Clockwise", "cycle-values video-rotate 270 180 90 0", true},
		{"add video-zoom -0.25", "add video-zoom -0.25", true},
		{"add video-zoom 0.25", "add video-zoom 0.25", true},
		{"add video-pan-x -0.05", "add video-pan-x -0.05", true},
		{"add video-pan-x 0.05", "add video-pan-x 0.05", true},
        {"add video-pan-y 0.05", "add video-pan-y 0.05", true},
        {"add video-pan-y -0.05", "add video-pan-y -0.05", true},
        {"Reset Pan", "set video-zoom 0; set video-pan-x 0; set video-pan-y 0", true},
        {"Reset All", "set video-unscaled no; set window-scale 1; set video-rotate 0; set video-zoom 0; set video-pan-x 0; set video-pan-y 0", true},
    {"=", ""},
    {"-"},
    {"=", "Test Commands"},
        {"Test Command", function()
            mp.msg.info("Opts " .. tostring(opts.save_window_position_on_exit))
            end},
        {"Get Opts", function() mp.msg.info("Opts2 " .. tostring(opts.save_window_position_on_exit)) end},
        {"toggle Opts", function() mp.commandv("script-message", "toggle_save_window_position_on_exit")  end},
        {"-"},
        {"* Press space with the mouse!", "keypress SPACE", true},
        {"GOTO 0", "set time-pos 0"},
        {"=", "Another pseudo sub-menu"},
            {"Yay!", "show_text Yay!"},
            {"* Yay+!", function() mp.osd_message("Yay! " .. tostring(math.random())) end, true},
        {"=", ""},
    {"=", ""},
    {"-"},
    {"Get window position", function() mp.commandv("script-message", "get_window_position") end},
    {"Save window position", function() mp.commandv("script-message", "save_window_position") end},
    {function()
        options.read_options(opts, "save_last_window_rect", function (e)
            mp.msg.info("On_update 2 " .. tostring(e))
            mp.msg.info("On_update 2 " .. tostring(opts.save_window_position_on_exit))
        end)
		return "Save pos on exit: " .. tostring(opts.save_window_position_on_exit) --" " .. tostring(err)
	end, function() 
        mp.commandv("script-message", "toggle_save_window_position_on_exit") 
        mp.commandv("script-message", "save_window_position_conf")
    end},
    {"-"},
    {"Quit watch-later", "quit-watch-later"},
    {"Quit", "quit"},
    {"-"},
    {"Version", function() mp.osd_message(prop_native("mpv-version") .. "\n" .. prop_native("ffmpeg-version"),5) end},
    {"Dismiss", noop},
}

local verbose = false  -- true -> dump console messages also without -v
local interpreter = "tclkit-gui";  -- tclkit-gui/tclsh/wish/full-path
local menuscript = mp.find_config_file("scripts/context.tcl")

--[[ ************ CONFIG: end ************ ]]--


function info(x) mp.msg[verbose and "info" or "verbose"](x) end
local utils = require 'mp.utils'

local function do_menu(items, x, y)
    local args = {interpreter, menuscript, tostring(x), tostring(y)}
    for i = 1, #items do
        local item = items[i]
        args[#args+1] = (type(item[1]) == "string") and item[1] or item[1]()
        if (item[1] == "=") then
            args[#args+1] = (type(item[2]) == "string") and item[2] or item[2]()
        else
            args[#args+1] = item[2] and tostring(i) or ""
        end
    end

    local ret = utils.subprocess({
        args = args,
        cancellable = true
    })

    if (ret.status ~= 0) then
        mp.osd_message("Something happened ...")
        return
    end

    info("ret: " .. ret.stdout)
    local res = utils.parse_json(ret.stdout)
    x = tonumber(res.x)
    y = tonumber(res.y)
    res.rv = tonumber(res.rv)
    if (res.rv == -1) then
        info("Context menu cancelled")
        return
    end

    local item = items[res.rv]
    if (not (item and item[2])) then
        mp.msg.error("Unknown menu item index: " .. tostring(res.rv))
        return
    end

    -- run the command
    if (type(item[2]) == "string") then
        mp.command(item[2])
    else
        item[2]()
    end

    -- re-launch
    if (item[3]) then
        if (type(item[3]) ~= "boolean") then
            items = item[3]  -- sub-menu, launch at mouse position
            x = -1
            y = -1
        end
        -- Break direct recursion with async, stack overflow can come quick.
        -- Also allow to un-congest the events queue.
        mp.add_timeout(0, function() do_menu(items, x, y) end)
    end
end

mp.register_script_message("contextmenu", function()
    do_menu(context_menu, -1, -1)
end)
