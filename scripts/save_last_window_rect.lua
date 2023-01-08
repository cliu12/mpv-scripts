-- Sometime the leftmost screen doesn't have id 0
-- not sure yet how to detect this automatically
local leftMostScreen = 'default' --1

local utils = require 'mp.utils'
local options = require 'mp.options'

local opts = {
    save_window_position_on_exit=true,
    x = 50,
    y = 50,
    width = "50%",
    height = "50%",
    reset=false
}
options.read_options(opts, mp.get_script_name(), function (e)
    mp.msg.info("On_update " .. tostring(e))
    mp.msg.info("On_update " .. tostring(opts.save_window_position_on_exit))
end)

mp.msg.debug(opts.save_window_position_on_exit)
mp.msg.debug(opts.x .. opts.y .. opts.width .. opts.height)
mp.msg.debug(mp.get_script_name())

--local opts_path = "~~/script-opts/" .. mp.get_script_name() .. ".conf"
local opts_path = mp.command_native({"expand-path", "~~/script-opts/" .. mp.get_script_name() .. ".conf"})
--local ps1_script = mp.find_config_file("scripts/Get-Client-Rect.ps1")
--if (not ps1_script) then
--    mp.msg.error("Get-Client-Rect.ps1 not found")
--    return 
--end

mp.msg.debug(opts_path)
--mp.msg.debug(ps1_script)

-- Some setup used by both reading and writing

-- Read last window rect if present
function set_rect() 
    if (opts.reset) then
        return
    end
    
    mp.set_property("screen", leftMostScreen)
    local geometry = tostring(opts.width) .. "x" .. tostring(opts.height) .. "+" 
        .. tostring(opts.x) .. "+" .. tostring(opts.y)
    mp.msg.info("Set geometry: " .. geometry)
    mp.set_property("geometry", geometry)
end

-- Get current window position
function get_rect()
    -- local args={"powershell", ("& \"" .. ps1_script .. "\" " .. utils.getpid())}
    local args = {
				'powershell', '-NoProfile', '-Command', [[& {
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Window {
    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool GetClientRect(IntPtr hWnd, out RECT lpRect);
    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool ClientToScreen(IntPtr hWnd, ref POINT lpPoint);
}
public struct RECT
{
    public int Left;
    public int Top;
    public int Right;
    public int Bottom;
}
public struct POINT
{
    public int x;
    public int y;
}
"@

#Write-Output "Args[0]: $($Args[0])"
$Handle = (Get-Process -Id $Args[0]).MainWindowHandle
$ClientRect = New-Object RECT
$Position = New-Object POINT
$Size = New-Object POINT

[Window]::GetClientRect($Handle, [ref]$ClientRect) | out-null
$Position.x = 0 # $ClientRect.Left is always 0
$Position.y = 0 # $ClientRect.Top
$Size.x = $ClientRect.Right
$Size.y = $ClientRect.Bottom
[Window]::ClientToScreen($Handle, [ref]$Position) | out-null

#Write-Output "$($Position.x) $($Position.y) $($Size.x) $($Size.y)"
"x=$($Position.x)"
"y=$($Position.y)"
"width=$($Size.x)"
"height=$($Size.y)"
				}]],
                "" .. utils.getpid()
			}
    local rect = utils.subprocess({ args=args, cancellable=false }).stdout
    --The two below not work
    --local output = mp.utils.subprocess({ args: ["powershell", "-file", ps1_script, mp.utils.getpid()], cancellable: false }).stdout
    
    for k, v in string.gmatch(rect, "(%w+)=(%w+)") do
        opts[k] = v
    end
    
    --mp.msg.info(rect)
    mp.msg.debug(opts.x)
    mp.msg.debug(opts.y)
    mp.msg.debug(opts.width)
    mp.msg.debug(opts.height)
    
end


-- Save the conf file
function save_conf()
	
    local strconf=""
    if( opts.save_window_position_on_exit ) then
        strconf="save_window_position_on_exit=yes" 
    else
        strconf="save_window_position_on_exit=no" 
    end
    strconf = strconf .. "\n" .. "x=" .. opts.x
    strconf = strconf .. "\n" .. "y=" .. opts.y
    strconf = strconf .. "\n" .. "width=" .. opts.width
    strconf = strconf .. "\n" .. "height=" .. opts.height
    strconf = strconf .. "\n" .. "#reset=no"
    
    --'d:/AppData/mpv/script-opts/save_last_window_rect.conf'
    local file = io.open(opts_path, "w")
    file:write(strconf)
    -- closes the open file
    file:close()
    
    --mp.msg.info("Position saved, " .. output)
    --mp.utils.write_file("file://~~/script-opts/" + mp.get_script_name() + ".conf", strconf)
end

function toggle_save_window_position_on_exit(opt)
    mp.msg.info("toggle " .. tostring(opt))
    if (opt == nil) then
        opts.save_window_position_on_exit = not opts.save_window_position_on_exit
    elseif ( type(opt) == 'boolean' ) then
		opts.save_window_position_on_exit = opt
	elseif ( string.lower(tostring(opt)) == 'false' or 
	    string.lower(tostring(opt)) == "no" or 
	    tostring(opt) == "0" ) then 
		opts.save_window_position_on_exit = false
    else 
        opts.save_window_position_on_exit = true
    end
    mp.msg.info("toggle " .. tostring(opts.save_window_position_on_exit))
    return opts.save_window_position_on_exit
end

function get_save_window_position_on_exit()
    mp.msg.info("opt " .. tostring(opts.save_window_position_on_exit))
    _G.save_window_position_on_exit = opts.save_window_position_on_exit
    return opts.save_window_position_on_exit
end


set_rect()

mp.register_event("shutdown", function()
    if (opts.save_window_position_on_exit) then
		get_rect()
        save_conf()
    else
        mp.msg.info("save_window_position_on_exit is " .. tostring(opts.save_window_position_on_exit))
    end
end )
mp.register_script_message("get_window_position", get_rect)
mp.register_script_message("save_window_position_conf", save_conf)
mp.register_script_message("toggle_save_window_position_on_exit", toggle_save_window_position_on_exit)
mp.register_script_message("get_save_window_position_on_exit", get_save_window_position_on_exit)

