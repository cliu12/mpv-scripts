-- 
-- menu_osc
-- https://github.com/cliu12/MPV-Plugins
--
-- Got the ideas from multiple plugins, menu.lua, playlistmanager.lua and context.lua,
-- create this on screen menu
--
-- Updated by Chao Liu
-- 01/07/2023 initial release
-- 
-- ASS tag reference
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
  scale_by_window = true,
  

  text_padding_x  = 30,
  text_padding_y  = 40,

  curtain_opacity = 0,
  
  --ass style without curly brackets, \keyvalue is one field, extra \ for escape in lua
  --\fn<name>  font name <name>
  --\fs# font size #
  --\b# bold 1 bold, 0 disable bold
  --\i# Italics 1 italics,  0 disable italics
  --\bord#  border size #
  --\1c&Hbbggrr&  1c text color, 3c border color in hex bbggrr
  --\alpha&H##& alpha in hex ##, 00 opaque/fully visible, FF fully transparent/invisible
  separator_style="\\fs8\\b0\\bord0\\1c&HBBBBBB&",
  header_style="\\fs12\\b1\\1c&H000000&\\3c&HFFFFFF&",
  item_style="\\fs12\\b0\\bord1\\1c&HBBBBBB&\\3c&H0F0F0F&",
  item_selected_style="\\fs12\\b1\\bord1\\1c&H000000&\\3c&HFFFFFF&",
  menu_style="\\fs12\\b0\\i1\\bord1\\1c&HBBBBBB&\\3c&H0F0F0F&",
  menu_selected_style="\\fs12\\b1\\i1\\bord1\\1c&H000000&\\3c&HFFFFFF&",
  
}

local utils   = require("mp.utils")
local msg     = require("mp.msg")
local assdraw = require("mp.assdraw")
local options = require("mp.options")
local prop_native = mp.get_property_native
options.read_options(settings, "menu_osc")

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
-- Menu item:
-- {
--   label = "string" or function, required, function for dynamic text
--   type = "commandstr", function, or menu, optional, default to arary
--   command = "string", function or array, required
--   keep_open = true or false, optional, default to false, true menu will stay open
-- },
--
-- Type: commandstr
-- command: string, which run by mp.command
-- Type: function
-- command: function
-- Type: menu
-- command: menu item, prefer added a go-back action, 
--    {label="Back", type="function", command=function() moveleft() end}
-- type: default
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
    label = "Volume & Speed",
    type = "menu",
    command = {
      {
        label = "Back",
        type = "function",
        command = function() moveleft() end
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
        label = "Volume 100%",
        type = "commandstr",
        command = "set volume 100"
      },
      {
        label = "——————————",
        type = "separator",
      },
      {
        label = "Speed Reset",
        type = "commandstr",
        command = "set speed 1",
        keep_open = true
      },
      {
        label = "Speed Up",
        type = "commandstr",
        command = "add speed .1",
        keep_open = true
      },
      {
        label = "Speed Down",
        type = "commandstr",
        command = "add speed -.1",
        keep_open = true
      },
      {
        label = "Sub Menu",
        type = "menu",
        command = {
          {
            label = "Back",
            type = "function",
            command = function() moveleft() end
          },
          {
            label = "Get window position", 
            type = "function",
            command = function() 
                local rect = mp.command_native({"script-message-to", "save_last_window_rect", "get_window_position"})
                --mp.osd_message(tostring(rect))
                end},
          {
            label = "Save window position", 
            type = "function",
            command = function() mp.commandv("script-message-to", "save_last_window_rect", "save_window_position") end},
          {
            label = function()
                local swpoe_opts = {
                    save_window_position_on_exit=true,
                    x = 50,
                    y = 50,
                    width = "50%",
                    height = "50%",
                    reset=false}
                options.read_options(swpoe_opts, "save_last_window_rect")
                --mp.msg.info("On_update 2 " .. tostring(swpoe_opts.save_window_position_on_exit) .. tostring(swpoe_opts.x) .. tostring(swpoe_opts.y))
                return "Save pos on exit: " .. tostring(swpoe_opts.save_window_position_on_exit)
            end, 
            type = "function",
            command = function() 
                mp.command_native({"script-message-to", "save_last_window_rect", "toggle_save_window_position_on_exit"})
                --mp.commandv("script-message-to", "save_last_window_rect", "save_window_position_conf")
            end
          },
        },
      },
    }
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
    label = "——————————",
    type = "separator",
  },
  {
    label = "Manage playlist",
    command = {"script-message-to", "playlistmanager", "showplaylist"},
  },
  {
    label = "Sort playlist",
    command = {"script-message-to", "playlistmanager", "sort"},
  },
  {
    label = "——————————",
    type = "separator",
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
      {
        label = "Toggle Crop",
        command = {"script-message-to", "easycrop",  "easy_crop"},
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
        label = "cycle video-unscaled",
        command = "cycle video-unscaled",
        type = "commandstr",
        keep_open = true},
      {
        label = "cycle-values window-scale",
        command = "cycle-values window-scale 2 3 1 .5",
        type = "commandstr",
        keep_open = true
      },
      {
        label = "Rotate Clockwise",
        command = "cycle-values video-rotate 90 180 270 0",
        type = "commandstr",
        keep_open = true},
      {
        label = "Rotate Counter Clockwise",
        command = "cycle-values video-rotate 270 180 90 0",
        type = "commandstr",
        keep_open = true},
      {
        label = "add video-zoom -0.25",
        command = "add video-zoom -0.25",
        type = "commandstr",
        keep_open = true},
      {
        label = "add video-zoom 0.25",
        command = "add video-zoom 0.25",
        type = "commandstr",
        keep_open = true},
      {
        label = "add video-pan-x -0.05",
        command = "add video-pan-x -0.05",
        type = "commandstr",
        keep_open = true},
      {
        label = "add video-pan-x 0.05",
        command = "add video-pan-x 0.05",
        type = "commandstr",
        keep_open = true},
      {
        label = "add video-pan-y 0.05",
        command = "add video-pan-y 0.05",
        type = "commandstr",
        keep_open = true},
      {
        label = "add video-pan-y -0.05",
        command = "add video-pan-y -0.05",
        type = "commandstr",
        keep_open = true},
      {
        label = "Reset Pan",
        command = "set video-zoom 0; set video-pan-x 0; set video-pan-y 0",
        type = "commandstr",
        keep_open = true},
      {
        label = "Reset All",
        command = "set video-unscaled no; set window-scale 1; set video-rotate 0; set video-zoom 0; set video-pan-x 0; set video-pan-y 0",
        type = "commandstr",
        keep_open = true
      },
    
    },
  },
  {
    label = "Properties",
    type = "menu",
    command = {
      {
        label = "Back",
        type = "function",
        command = function() moveleft() end
      },
      {
        label = "playlist",
        type = "commandstr",
        command = 'show-text "${playlist}"'
      },
      {
        label = "hwdec-current",
        type = "function",
        command = function() mp.osd_message(prop_native("hwdec-current")) end
      },
      {
        label = "Scale",
        type = "function",
        command = function() mp.osd_message(tostring(prop_native("scale"))) end
      },
      {
        label = "Volume",
        type = "function",
        command = function() mp.osd_message(tostring(prop_native("volume"))) end
      },
      {
        label = "ffmpeg-version",
        type = "function",
        command = function() mp.osd_message(tostring(prop_native("ffmpeg-version"))) end
      },
      {
        label = "mpv-version",
        type = "function",
        command = function() mp.osd_message(tostring(prop_native("mpv-version"))) end
      },
      {
        label = "osd",
        command = {"show-text", '"${playlist}"'}
      },
    },
  },
  {
    label = "Version",
    type = "function",
    command = function() mp.osd_message(prop_native("mpv-version") .. "\n" .. prop_native("ffmpeg-version"),5) end,
  },
  {
    label = "——————————",
    type = "separator",
  },
  {
    label = "Quit",
    command = {"quit"},
  }
}

----------------------------
--Todo: check menu_items format
--
--if #menu_items == 0 then
--  msg.warn("Menu list is empty. The script is disabled.")
--  return
--end
--
----------------------------


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
  elseif (menu[level][cursor].type == "separator") then
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
	
  ass:pos(settings.text_padding_x, settings.text_padding_y)
  ass:append("{\\rDefault" .. settings.header_style .. "}")


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
    start = menu_len-settings.showamount+1
    showrest = true
  end
  
  if level == 1 then 
    ass:append("Menu OSC".."\\N") 
  else
    local labelparent = (type(menu[level-1][menulastpos[level-1]].label) == "string") and 
      menu[level-1][menulastpos[level-1]].label or menu[level-1][menulastpos[level-1]].label()
    ass:append("" .. labelparent .. "\\N") 
  end
  if start > 1 and not showall then 
    ass:append("{\\rDefault" .. settings.item_style .. "}...\\N")
  else
    ass:append(" \\N")
  end
  
  for index=start, start+settings.showamount-1, 1 do
    if index == menu_len+1 then break end
    local selected = index == cursor
    local prefix = ""
    if (selected ) then
      if (menu[level][index].type == "menu") then
        if (level > 1) then
          prefix = "{\\rDefault" .. settings.menu_selected_style .. "}⮜⮞ " --◆◌▶▷▸▹►▻◀◁◂◃◄◅◆◇
        else
          prefix = "{\\rDefault" .. settings.menu_selected_style .. "}⮞ "  --➤
        end
      else
          prefix = "{\\rDefault" .. settings.item_selected_style .. "}● "  --⧑◀▶◁▷▸▹◄►▻◂◃◅◆◇
      end
    else
      if (level > 1) then
        if (menu[level][index].type == "menu") then
          prefix = "{\\rDefault" .. settings.menu_style .. "}<> " --◇◁▷
        else
          if menu[level][index].type == "separator" then
            prefix = "{\\rDefault" .. settings.separator_style .. "}◌ "  --⧑
          else
            prefix = "{\\rDefault" .. settings.item_style .. "}< "     -- ◁
          end
        end
      else
        if (menu[level][index].type == "menu") then
          prefix = "{\\rDefault" .. settings.menu_style .. "}> "  --▷
        else
          if menu[level][index].type == "separator" then
            prefix = "{\\rDefault" .. settings.separator_style .. "}◌ "
          else
            prefix = "{\\rDefault" .. settings.item_style .. "}○ " --◌▶▸▹►▻◀◂◃◄◅◆◇
            --prefix = "{\\1c&H" .. settings.text_color .. "&\\3c&H" .. settings.text_border_color .. "&}○ "
          end
        end
      end
    end
    
    local label = (type(menu[level][index].label) == "string") and 
        menu[level][index].label or menu[level][index].label()
    ass:append(prefix .. label .. "\\N")
    --if menu[level][index].type == "separator" then
    --  ass:append(settings.style_ass_tags)
    --end
    
    if index == start+settings.showamount-1 and not showall and not showrest then
      ass:append("{\\rDefault" .. settings.item_style .. "}...")
    end
  end

  if settings.scale_by_window then w,h = 0, 0 end
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
  if menu[level][cursor].type == "separator" then
    if cursor ~= 1 then
      cursor = cursor - 1
    elseif settings.loop_cursor then
      cursor = #(menu[level])
    end
  end
  render()
end

function movedown()
  if cursor ~= #(menu[level]) then
    cursor = cursor + 1
  elseif settings.loop_cursor then
    cursor = 1
  end
  if menu[level][cursor].type == "separator" then
    if cursor ~= #(menu[level]) then
      cursor = cursor + 1
    elseif settings.loop_cursor then
      cursor = 1
    end
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
  mp.add_key_binding("MBTN_RIGHT", "menu_osc-toggle", toggle_menu)
end