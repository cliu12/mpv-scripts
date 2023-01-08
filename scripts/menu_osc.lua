-- 
-- menu_osc
--
-- Got the ideas from multiple plugins, menu.lua, playlistmanager.lua and context.lua,
-- create this on screen menu
--
-- Updated by Chao Liu
-- 01/07/2023 initial release
--
-- http://www.aegisub.org/ un-accessible
-- https://aegi.vmoe.info/docs/3.1/ASS_Tags/
--

local settings = {
  display_timeout = 10,

  loop_cursor   = true,

  key_moveup    = "UP WHEEL_UP",
  key_movedown  = "DOWN WHEEL_DOWN",
  key_moveleft  = "LEFT",
  key_moveright = "RIGHT",
  key_execute   = "ENTER MBTN_MID",
  key_closemenu = "ESC MBTN_RIGHT",
  
  showamount    = 13,
  
  --font size scales by window, if false requires larger font and padding sizes
  scale_playlist_by_window = true,
  --playlist ass style overrides inside curly brackets, \keyvalue is one field, extra \ for escape in lua
  --example {\\fnUbuntu\\fs10\\b0\\bord1} equals: font=Ubuntu, size=10, bold=no, border=1
  --read http://docs.aegisub.org/3.2/ASS_Tags/ for reference of tags
  --undeclared tags will use default osd settings
  --these styles will be used for the whole playlist

  --scale_playlist_by_window=yes,
  style_ass_tags  = "{\\fs12\\b0\\bord1}",
  text_padding_x  = 30,
  text_padding_y  = 40,

  curtain_opacity = 0,
  
  --color in bbggrr
  text_color = "BBBBBB",
  text_border_color = "0F0F0F",
  text_selected_color = "FF0F00",
  text_border_selected_color = "FFB78A",

}

local utils = require("mp.utils")
local msg = require("mp.msg")
local assdraw = require("mp.assdraw")
local prop_native = mp.get_property_native
local opts = require("mp.options")
opts.read_options(settings, "menu_osc")

--------------------------------------
--Prefer menu stored in json, seperated file, but it has limited features,
--missing function for dynamtic support
--for this version, menu_items is in lua
--local file = assert(io.open(mp.command_native({"expand-path", "~~/script-opts"}) .. "/menu.json"))
--local json = file:read("*all")
--file:close()
--local menu_items = utils.parse_json(json)

--------------------------------------
-- menu_items contains multiple of menu_item
-- Menu item
-- {
--   label = "string" or function, required, function for dynamic text
--   type = "commandstr", function, or menu, optional, default to arary
--   command = "string", function or array, required
--   keep_open = true or false, optional, default to false, true menu will stay open
-- },
-- Type: commandstr
-- command: string, which run by mp.command
-- Type: function
-- command: function
-- Type: menu
-- command: menu item, prefer added a go-back action, 
--    {label="Back", type="function", command=function() moveleft() end}
-- type: missing
-- command: single array run by mp.command_native, 2d array will be run in sequenced
--
---------------------------------------
local menu_items = {
  {
    label = function() return prop_native("pause") and "Play" or "Pause" end,
    type = "commandstr",
    command = "cycle pause",
  },
  {
    label = function() return prop_native("mute") and "Un-mute" or "Mute" end,
    type = "commandstr",
    command = "cycle mute"
  },
  {
    label = "Volume Up",
    type = "commandstr",
    command = "add volume 10",
    keep_open = true
  },
  {
    label = "Volume Down",
    type = "commandstr",
    command = "add volume -10",
    keep_open = true
  },
  {
    label = "Volume 100",
    type = "commandstr",
    command = "set volume 100",
    keep_open = true
  },
  {
    label = "Open File",
    command = {"script-message-to", "PSOpenFileDialog", "open-files"},
  },
  {
    label = "Open URL",
    command = {"script-message-to", "PSOpenFileDialog", "open-url"},
  },
  {
    label = "Open Sub",
    command = {"script-message-to", "PSOpenFileDialog", "open-subs"},
  },
  {
    label = "Scale: .1",
    command = {"add", "window-scale",  ".1"},
  },
  {
    label = "Scale: -.1",
    command = {"add", "window-scale",  "-.1"}
  },
  {
    label = "Scale: 1",
    command = {"set", "window-scale",  "1"}
  },
  {
    label = "Manage playlist",
    command = {"script-binding", "showplaylist"},
  },
  {
    label = "Sort playlist",
    command = {"script-message", "playlistmanager", "sort"},
  },
  {
    label = "Sub-menu 菜单",
    type = "menu",
    command = {
      {
        label = "Back",
        type = "function",
        command = function() moveleft() end
      },
      {
        label = "1 Video Rotate Clockwise",
        command = {"cycle-values", "video-rotate", "90", "180", "270", "0"},
      },
      {
        label = "2 Video Rotate Counter Clockwise",
        command = {"cycle-values", "video-rotate", "270", "180", "90", "0"},
      },
    },
  },
  {
    label = "Audio",
    command = {"keypress", "F9"},
  },
  {
    label = "Video",
    type = "menu",
    command = {
      {
        label = "Back",
        type = "function",
        command = function() moveleft() end
      },
      {label = "cycle video-unscaled",
        command = "cycle video-unscaled",
        type = "commandstr",
        keep_open = true},
      {label = "cycle-values window-scale",
        command = "cycle-values window-scale 2 3 1 .5",
        type = "commandstr",
        keep_open = true
      },
      {label = "Rotate Clockwise",
        command = "cycle-values video-rotate 90 180 270 0",
        type = "commandstr",
        keep_open = true},
      {label = "Rotate Counter Clockwise",
        command = "cycle-values video-rotate 270 180 90 0",
        type = "commandstr",
        keep_open = true},
      {label = "add video-zoom -0.25",
        command = "add video-zoom -0.25",
        type = "commandstr",
        keep_open = true},
      {label = "add video-zoom 0.25",
        command = "add video-zoom 0.25",
        type = "commandstr",
        keep_open = true},
      {label = "add video-pan-x -0.05",
        command = "add video-pan-x -0.05",
        type = "commandstr",
        keep_open = true},
      {label = "add video-pan-x 0.05",
        command = "add video-pan-x 0.05",
        type = "commandstr",
        keep_open = true},
      {label = "add video-pan-y 0.05",
        command = "add video-pan-y 0.05",
        type = "commandstr",
        keep_open = true},
      {label = "add video-pan-y -0.05",
        command = "add video-pan-y -0.05",
        type = "commandstr",
        keep_open = true},
      {label = "Reset Pan",
        command = "set video-zoom 0; set video-pan-x 0; set video-pan-y 0",
        type = "commandstr",
        keep_open = true},
      {label = "Reset All",
        command = "set video-unscaled no; set window-scale 1; set video-rotate 0; set video-zoom 0; set video-pan-x 0; set video-pan-y 0",
        type = "commandstr",
        keep_open = true
      },
    
      {
        label = "menu Test 2",
        type = "menu",
        command = {
          {
            label = "Back",
            type = "function",
            command = function() moveleft() end
          },
          {
            label = "3 Video Rotate Clockwise",
            command = {"cycle-values", "video-rotate", "90", "180", "270", "0"},
          },
          {
            label = "4 Video Rotate Counter Clockwise",
            command = {"cycle-values", "video-rotate", "270", "180", "90", "0"},
          },
        },
      },
    },
  },
  {
    label = "Version",
    type = "function",
    command = function() mp.osd_message(prop_native("mpv-version") .. "\n" .. prop_native("ffmpeg-version"),5) end,
  },
  {
    label = "Quit",
    command = {"quit"},
  }
}

----------------------------
--Todo: check menu_items format
--
----------------------------

if #menu_items == 0 then
  msg.warn("Menu list is empty. The script is disabled.")
  return
end

local menu = {}
local menulastpos = {}
local level = 1
menu[level] = menu_items
menulastpos[level] = 1
local menu_size = #(menu[level])
local menu_visible = false
local cursor = 1

--local ass_start = mp.get_property_osd("osd-ass-cc/0")
--local ass_stop = mp.get_property_osd("osd-ass-cc/1")
    

function execute()
  local command = menu[level][cursor].command
  if (menu[level][cursor].type == "function") then
    command()
  elseif (menu[level][cursor].type == "commandstr") then
    mp.command(command)
  elseif (menu[level][cursor].type == "menu") then
    menulastpos[level] = cursor
    level = level + 1
    menu[level] = command
    cursor = 1
    render()
    return
  else
      local is_nested_command = type(command[1]) == "table"

      if is_nested_command then
        for _, cmd in ipairs(command) do
          mp.command_native(cmd)
        end
      else
        mp.command_native(command)
      end
  end

  if menu[level][cursor].keep_open or menu[level][cursor].type == "menu" then
    render()
  else
    remove_keybinds()
  end
end

function toggle_menu()
  if menu_visible then
    remove_keybinds()
    return
  end
  render()
end

function render()
  local ass = assdraw.ass_new()
	
  local _, _, a = mp.get_osd_size()
  local h = 360
  local w = h * a

  local alpha = 255 - math.ceil(255 * settings.curtain_opacity)
  ass.text = string.format('{\\pos(0,0)\\rDefault\\an7\\1c&H000000&\\alpha&H%X&}', alpha)
  ass:draw_start()
  ass:rect_cw(0, 0, w, h)
  ass:draw_stop()
  ass:new_event()
	
  ass:append(settings.style_ass_tags)

  ass:pos(settings.text_padding_x, settings.text_padding_y)

  local menu_len = #(menu[level])
  local start = cursor - math.floor(settings.showamount/2)
  local showall = false
  local showrest = false
  
  if start<1 then start=1 end
  if menu_len <= settings.showamount then
    start=1
    showall=true
  end
  if start > math.max(menu_len-settings.showamount+1, 1) then
    start=menu_len-settings.showamount+1
    showrest=true
  end
  
  if level == 1 then 
    ass:append("Menu OSC".."\\N") 
  else
    local labelparent = (type(menu[level-1][menulastpos[level-1]].label) == "string") and 
      menu[level-1][menulastpos[level-1]].label or menu[level-1][menulastpos[level-1]].label()
    ass:append("" .. labelparent .. "\\N") 
  end
  if start > 1 and not showall then ass:append("{\\1c&H" .. settings.text_color .. "&\\3c&H" .. settings.text_border_color .. "&}..." .. "\\N") end
  
  for index=start, start+settings.showamount-1, 1 do
    if index == menu_len+1 then break end
    local selected = index == cursor
    local prefix = ""
    if (selected ) then
      if (menu[level][index].type == "menu") then
        if (level > 1) then
          prefix = "{\\1c&H" .. settings.text_selected_color .. "&\\3c&H" .. settings.text_border_selected_color .. "&}⮜ ⮞ " --◆
        else
          prefix = "{\\1c&H" .. settings.text_selected_color .. "&\\3c&H" .. settings.text_border_selected_color .. "&}⮞ "  --➤
        end
      else
        prefix = "{\\1c&H" .. settings.text_selected_color .. "&\\3c&H" .. settings.text_border_selected_color .. "&}● "  --⧑
      end
    else
      if (level > 1) then
        if (menu[level][index].type == "menu") then
          prefix = "{\\1c&H" .. settings.text_color .. "&\\3c&H" .. settings.text_border_color .. "&}<> " --◇
        else
          prefix = "{\\1c&H" .. settings.text_color .. "&\\3c&H" .. settings.text_border_color .. "&}< "
        end
      else
        if (menu[level][index].type == "menu") then
          prefix = "{\\1c&H" .. settings.text_color .. "&\\3c&H" .. settings.text_border_color .. "&}> "
        else
          prefix = "{\\1c&H" .. settings.text_color .. "&\\3c&H" .. settings.text_border_color .. "&}○ "
        end
      end
    end
    
    local label = (type(menu[level][index].label) == "string") and 
      menu[level][index].label or menu[level][index].label()
    ass:append(prefix .. label .. "\\N")
    
    if index == start+settings.showamount-1 and not showall and not showrest then
      ass:append("...")
    end
  end

  local _, _, a = mp.get_osd_size()
  local h = 360
  local w = h * a
  if settings.scale_playlist_by_window then w,h = 0, 0 end
  mp.set_osd_ass(w, h, ass.text)

  menu_visible = true
  add_keybinds()
  keybindstimer:kill()
  keybindstimer:resume()
end

function moveup()
  if cursor ~= 1 then
    cursor = cursor - 1
  elseif settings.loop_cursor then
    cursor = #(menu[level])
  end
  render()
end

function movedown()
  if cursor ~= #(menu[level]) then
    cursor = cursor + 1
  elseif settings.loop_cursor then
    cursor = 1
  end
  render()
end

function moveleft()
  if level > 1 then
    cursor = menulastpos[level-1]
    level = level - 1
  end
  render()
end

function moveright()
  if (menu[level][cursor].type == "menu") then
    menulastpos[level] = cursor
    level = level + 1
    menu[level] = menu[level-1][cursor].command
    cursor = 1
    render()
  end
  return
end

function bind_keys(keys, name, func, opts)
  if not keys then
    mp.add_forced_key_binding(keys, name, func, opts)
    return
  end
  local i = 1
  for key in keys:gmatch("[^%s]+") do
    local prefix = i == 1 and '' or i
    mp.add_forced_key_binding(key, name..prefix, func, opts)
    i = i + 1
  end
end

function unbind_keys(keys, name)
  if not keys then
    mp.remove_key_binding(name)
    return
  end
  local i = 1
  for key in keys:gmatch("[^%s]+") do
    local prefix = i == 1 and '' or i
    mp.remove_key_binding(name..prefix)
    i = i + 1
  end
end

function add_keybinds()
  bind_keys(settings.key_moveup, 'menu_osc-moveup', moveup, "repeatable")
  bind_keys(settings.key_movedown, 'menu_osc-movedown', movedown, "repeatable")
  bind_keys(settings.key_moveleft, 'menu_osc-moveleft', moveleft)
  bind_keys(settings.key_moveright, 'menu_osc-moveright', moveright)
  bind_keys(settings.key_execute, 'menu_osc-execute', execute)
  bind_keys(settings.key_closemenu, 'menu_osc-closemenu', remove_keybinds)
end

function remove_keybinds()
  keybindstimer:kill()
  menu_visible = false
  mp.set_osd_ass(0, 0, "")
  unbind_keys(settings.key_moveup, 'menu_osc-moveup')
  unbind_keys(settings.key_movedown, 'menu_osc-movedown')
  unbind_keys(settings.key_moveleft, 'menu_osc-moveleft')
  unbind_keys(settings.key_moveright, 'menu_osc-moveright')
  unbind_keys(settings.key_execute, 'menu_osc-execute')
  unbind_keys(settings.key_closemenu, 'menu_osc-closemenu')
end

keybindstimer = mp.add_periodic_timer(settings.display_timeout, remove_keybinds)
keybindstimer:kill()


if menu[level] and menu_size > 0 then
  mp.register_script_message("menu_osc-toggle", toggle_menu)
  mp.add_key_binding("MBTN_MID", "menu_osc-toggle", toggle_menu)
end