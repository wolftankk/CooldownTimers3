local major, minor = "LibCandyBar-2.1", "$Revision$"

local lib, oldMinor = LibStub:NewLibrary(major, minor)
if not lib then return end

if not lib.frame then
	lib.frame = CreateFrame("Frame")
	lib.frame.name = "CandyBar-2.1 Frame"
	lib.frame:Hide()
end

lib.handlers = lib.handlers or {}
lib.groups = lib.groups or {}
lib.framepool = lib.framepool or {}
lib.addons = lib.addons or {}
lib.embeds = lib.embeds or {}

lib.vars = lib.vars or {rgb = {},rgbperc = {},hex = {}}
local colors = " white:ffffff black:000000 blue:0000ff magenta:ff00ff cyan:00ffff green:00ff00 yellow:ffff00 orange:ff7f00 red:ff0000"

local function print(text)
	ChatFrame1:AddMessage(text)
end

local paint = true

local mixins = {
	"RegisterCandyBar",
	"UnregisterCandyBar",
	"IsCandyBarRegistered",
	"StartCandyBar",
	"StopCandyBar",
	"PauseCandyBar",
	"CandyBarStatus",
	"SetCandyBarTexture",
	"SetCandyBarTime",
	"SetCandyBarColor",
	"SetCandyBarText",
	"SetCandyBarIcon",
	"SetCandyBarIconPosition",
	"SetCandyBarWidth",
	"SetCandyBarHeight",
	"SetCandyBarBackgroundColor",
	"SetCandyBarTextColor",
	"SetCandyBarTimerTextColor",
	"SetCandyBarFontSize",
	"SetCandyBarPoint",
	"GetCandyBarPoint",
	"GetCandyBarCenter",
	"GetCandyBarOffsets",
	"GetCandyBarEffectiveScale",
	"SetCandyBarGradient",
	"SetCandyBarScale",
	"SetCandyBarTimeFormat",
	"SetCandyBarTimeLeft",
	"SetCandyBarCompletion",
	"SetCandyBarFade",
	"RegisterCandyBarGroup",
	"UnregisterCandyBarGroup",
	"IsCandyBarGroupRegistered",
	"SetCandyBarGroupPoint",
	"SetCandyBarGroupGrowth",
	"SetCandyBarGroupVerticalSpacing",
	"UpdateCandyBarGroup",
	"GetCandyBarNextBarPointInGroup",
	"RegisterCandyBarWithGroup",
	"UnregisterCandyBarWithGroup",
	"IsCandyBarRegisteredWithGroup",
	"SetCandyBarReversed",
	"IsCandyBarReversed",
	"SetCandyBarOnClick",
	"SetCandyBarOnSizeGroup",
}

local defaults = {
	texture = "Interface\\TargetingFrame\\UI-StatusBar",
	width = 200,
	height = 16,
	scale = 1,
	point = "CENTER",
	rframe = UIParent,
	rpoint = "CENTER",
	iconpos = "LEFT",
	xoffset = 0,
	yoffset = 0,
	fontsize = 11,
	color = {1, 0, 1, 1},
	bgcolor = {0, 0.5, 0.5, 0.5},
	textcolor = {1, 1, 1, 1},
	timertextcolor = {1, 1, 1, 1},
    stayonscreen = false,
}

local getArgs
do
	local numargs
	local function _get(t, str, i, ...)
		if i<=numargs then
			return t[format("%s%d", str, i)],  _get(t, str, i+1, ...)
		end
		return ...
	end

	function getArgs(t, str, ...)
		numargs = t[str.."#" or 0]
		return _get(t,str,1, ...)
	end
end

local function setArgs(t, str, ...)
	local n = select("#", ...)
	for i=1,n do
	  t[format("%s%d",str,i)]=select(i,...)
	end
	for i=n+1, (t[str.."#"] or 0) do
		t[format("%s%d",str,i)]=nil
	end
	t[str.."#"] = n
end

local new, del
do
	local cache = setmetatable({},{__mode='k'})
	function new()
		local t = next(cache)
		if t then
			cache[t] = nil
			return t
		else
			return {}
		end
	end
	function del(t)
		for k in pairs(t) do
			t[k] = nil
		end
		cache[t] = true
		return nil
	end
end

function lib:argCheck(var, nr, ...)
	local total = select("#", ...)
	local ok = false
	for i=1,total do
		if type(var) == select(i,...) then
			ok = true
		end
	end
	if not ok then
		error("Wrong type for argument "..nr, 2)
	end
end

function lib:RegisterColor(name, hexorred, green, blue)
	if type(name) == "string" and type(hexorred) == "number" and type(green) == "number" and type(blue) == "number" then
		name = name:lower()
		if hexorred <=1 and green <= 1 and blue <= 1 then hexorred, green, blue = hexorred*255, green*255, blue*255 end
		local hex = string.format("%02x%02x%02x", hexorred, green, blue)
		lib.vars.hex[name] = hex
	elseif type(name) == "string" and type(hexorred) == "string" and hexorred:len() == 6 then
		name = name:lower()
		if not lib.vars.hex[name] then lib.vars.hex[name] = hexorred end
	else
		error('Usage: RegisterColor("name", "hexcode") or RegisterColor("name", red, green, blue)')
	end
end

function lib:UnregisterColor(name)
  if not name then return end
  name = name:lower();
  lib.vars.hex[name] = nil;
  lib.vars.rgb[name] = nil;
  lib.vars.rgbperc[name] = nil;
end

-- Accepts hex strings in three formats: "|cAARRGGBB", "AARRGGBB", "RRGGBB"
-- string will be indexed by the exact string you pass, use this as the name for any query calls
function lib:RegisterHex(hex)
	local l = hex:len()
	if l < 6 then error("RegisterHex: Invalid hex string %q.", hex) end
	if l > 6 then hex = hex:sub(l-5) end

	local name = hex:lower()
	if not lib.vars.hex[name] then lib.vars.hex[name] = hex end
end


function lib:GetHex(name)
	if not name then return end
	name = name:lower()

	if not self.vars.hex[name] then
		local hex = select(3, colors:find(" "..name..":(%S+)"))
		if hex then self.vars.hex[name] = hex end
	end

	return lib.vars.hex[name]
end


function lib:GetRGB(name)
	local hex = lib:GetHex(name)
	if not hex then return end

	if not self.vars.rgb[hex] then
		local rhex, ghex,bhex = hex:sub(1,2), hex:sub(3,4), hex:sub(5,6)
		local r,g,b = tonumber(rhex, 16), tonumber(ghex, 16), tonumber(bhex, 16)

		lib.vars.rgb[hex] = {r,g,b}
	end

	return lib.vars.rgb[hex], unpack(self.vars.rgb[hex])
end


function lib:GetRGBPercent(name)
	local hex = lib:GetHex(name)
	if not hex then return end

	if not lib.vars.rgbperc[hex] then
		local rhex, ghex,bhex = hex:sub(1,2), hex:sub(3,4), hex:sub(5,6)
		local r,g,b = tonumber(rhex, 16)/255, tonumber(ghex, 16)/255, tonumber(bhex, 16)/255

		lib.vars.rgbperc[hex] = {r,g,b}
	end
	return lib.vars.rgbperc[hex], unpack(lib.vars.rgbperc[hex])
end


-- Registers a new candy bar
-- name - A unique identifier for your bar.
-- time - Time for the bar
-- text - text displayed on the bar [defaults to the name if not set]
-- icon - icon off the bar [optional]
-- c1 - c10 - color of the bar [optional]
-- returns true on a succesful register
function lib:Register(name, time, text, icon, c1, c2, c3, c4, ...)
	lib:argCheck(name, 2, "string")
	lib:argCheck(time, 3, "number")
	lib:argCheck(text, 4, "string", "nil")
	lib:argCheck(icon, 5, "string", "nil")
	lib:argCheck(c1, 6, "string", "number", "nil")
	lib:argCheck(c2, 7, "string", "number", "nil")
	lib:argCheck(c3, 8, "string", "number", "nil")
	lib:argCheck(c4, 9, "string", "number", "nil")
	if not text then text = name end
	if lib.handlers[name] then
		self:Unregister(name)
	end
	local handler = new()
	handler.name, handler.time, handler.text, handler.icon = name, time, text or name, icon
	handler.texture = defaults.texture
	local c1Type = type(c1)
	if c1Type ~= "number" and not paint then
		error("You need the PaintChips-2.0 library if you don't pass in RGB pairs as colors.")
	end
	if c1Type == "nil" or (c1Type ~= "number" and not lib:GetRGBPercent(c1)) then
		c1 = "green"
	end
	handler.color = new()
	if c1Type == "number" then
		handler.color[1] = c1
		handler.color[2] = c2
		handler.color[3] = c3
	else
		handler.color[1], handler.color[2], handler.color[3] = select(2, lib:GetRGBPercent(c1))
	end
	handler.color[4] = 1
	handler.running = nil
	handler.endtime = 0
	handler.reversed = nil
	lib.handlers[name] = handler
	handler.frame = lib:AcquireBarFrame(name)
	if (c1Type == "number" and c4) or (c1Type == "string" and c2) then
		lib:SetGradient(name, c1, c2, c3, c4, ...)
	end
	handler.stayonscreen = defaults.stayonscreen
	return true
end


-- Removes a candy bar
-- a1 - a10 handlers that you wish to remove
-- returns true upon sucessful removal
function lib:Unregister(a1, ...)
	lib:argCheck(a1, 2, "string")
	if not lib.handlers[a1] then
		return
	end
	lib:UnregisterWithGroup(a1)
	lib:ReleaseBarFrame(a1)
	local handler = lib.handlers[a1]
	lib.handlers[a1] = nil
	if handler.color then
		handler.color = del(handler.color)
	end
	if handler.bgcolor then
		handler.bgcolor = del(handler.bgcolor)
	end
	if handler.textcolor then
		handler.textcolor = del(handler.textcolor)
	end
	if handler.timertextcolor then
		handler.timertextcolor = del(handler.timertextcolor)
	end
	if handler.gradienttable then
		for i,v in ipairs(handler.gradienttable) do
			v = del(v)
		end
		handler.gradienttable = del(handler.gradienttable)
	end
	handler = del(handler)
	if ... then
		lib:Unregister(...)
	elseif not lib:HasHandlers() then
		lib.frame:Hide()
	end
	return true
end

-- Checks if a candy bar is registered
-- Args: name - name of the candybar
-- returns true if a the candybar is registered
function lib:IsRegistered(name)
	lib:argCheck(name, 2, "string")
	if lib.handlers[name] then
		return true
	end
	return false
end

-- Start a bar
-- Args:  name - the candybar you want to start
--		fireforget [optional] - pass true if you want the bar to unregister upon completion
-- returns true if succesful
function lib:Start(name, fireforget)
	lib:argCheck(name, 2, "string")
	lib:argCheck(fireforget, 3, "boolean", "nil")
	local handler = lib.handlers[name]
	if not handler then
		return
	end
	local t = GetTime()
	if handler.paused then
		local pauseoffset = t - handler.pausetime
		handler.endtime = handler.endtime + pauseoffset
		handler.starttime = handler.starttime + pauseoffset
	elseif handler.elapsed and not handler.running then
		handler.endtime = t + handler.time - handler.elapsed
		handler.starttime = t - handler.elapsed
	else
		-- bar hasn't elapsed a second.
		handler.elapsed = 0
		handler.endtime = t + handler.time
		handler.starttime = t
	end
	handler.fireforget = fireforget
	handler.running = true
	handler.paused = nil
	handler.fading = nil
	lib:AcquireBarFrame(name) -- this will reset the barframe incase we were fading out when it was restarted
	handler.frame:Show()
	if handler.group then
		lib:UpdateGroup(handler.group) -- update the group
	end
	lib.frame:Show()
	return true
end

-- Stop a bar
-- Args:  name - the candybar you want to stop
-- returns true if succesful
function lib:Stop(name)
	lib:argCheck(name, 2, "string")
	
	local handler = lib.handlers[name]
	
	if not handler then
		return
	end

	handler.running = nil
	handler.paused = nil
	handler.elapsed = 0

	if handler.fadeout then
		handler.frame.spark:Hide()
		if not handler.stayonscreen then
			handler.fading = true
			handler.fadeelapsed = 0
			local t = GetTime()
			if handler.endtime > t then
				handler.endtime = t
			end
		end
	else
		handler.frame:Hide()
		handler.starttime = nil
		handler.endtime = 0
		if handler.group then
			lib:UpdateGroup(handler.group)
		end
		if handler.fireforget then
			return lib:Unregister(name)
		end
	end
	if not lib:HasHandlers() then
		lib.frame:Hide()
	end
	return true
end

-- Pause a bar
-- Name - the candybar you want to pause
-- returns true if succesful
function lib:Pause(name)
	lib:argCheck(name, 2, "string")
	local handler = lib.handlers[name]
	if not handler then
		return
	end
	handler.pausetime = GetTime()
	handler.paused = true
	handler.running = nil
end

-- Query a timer's status
-- Args: name - the schedule you wish to look up
-- Returns: registered - true if a schedule exists with this name
--		time	- time for this bar
--		  elapsed - time elapsed for this bar
--		  running - true if this schedule is currently running
function lib:Status(name)
	lib:argCheck(name, 2, "string")
	local handler = lib.handlers[name]
	if not handler then
		return
	end
	return true, handler.time, handler.elapsed, handler.running, handler.paused
end


-- Set the time for a bar.
-- Args: name - the candybar name
--	 time - the new time for this bar
-- returns true if succesful
function lib:SetTime(name, time)
	lib:argCheck(name, 2, "string")
	lib:argCheck(time, 3, "number")
	
	local handler = lib.handlers[name]
	if not handler then
		return
	end
	handler.time = time
	if handler.starttime and handler.endtime then
		handler.endtime = handler.starttime + time 
	end
	return true
end

-- Set the time left for a bar.
-- Args: name - the candybar name
--	   time - time left on the bar
-- returns true if succesful

function lib:SetTimeLeft(name, time)
	lib:argCheck(name, 2, "string")
	lib:argCheck(time, 3, "number")
	
	local handler = lib.handlers[name]
	if not handler then
		return
	end
	if handler.time < time or time < 0 then
		return
	end

	local e = handler.time - time
	if handler.starttime and handler.endtime then
		local d = handler.elapsed - e
		handler.starttime = handler.starttime + d
		handler.endtime = handler.endtime + d
	end

	handler.elapsed = e

	if handler.group then
		lib:UpdateGroup(handler.group)
	end

	return true
end

-- Sets smooth coloring of the bar depending on time elapsed
-- Args: name - the candybar name
--	   c1 - c10 color order of the gradient
-- returns true when succesful
local cachedgradient = {}
function lib:SetGradient(name, c1, c2, ...)
	lib:argCheck(name, 2, "string")
	lib:argCheck(c1, 3, "string", "number", "nil")
	lib:argCheck(c2, 4, "string", "number", "nil")

	local handler = lib.handlers[name]

	if not handler then
		return
	end

	local gtable = new()
	local gradientid = nil

	-- We got string values passed in, which means they're not rgb values
	-- directly, but a color most likely registered with paintchips
	if type(c1) == "string" then
		--if not paint then
		--	error("You need the PaintChips-2.0 library if you don't pass in RGB pairs as colors.")
		--end
		if not lib:GetRGBPercent(c1) then c1 = "green" end
		if not lib:GetRGBPercent(c2) then c2 = "red" end

		gtable[1] = new()
		gtable[2] = new()

		gradientid = c1 .. "_" .. c2

		gtable[1][1], gtable[1][2], gtable[1][3] = select(2, lib:GetRGBPercent(c1))
		gtable[2][1], gtable[2][2], gtable[2][3] = select(2, lib:GetRGBPercent(c2))
		for i = 1, select('#', ...) do
			local c = select(i, ...)
			if not c or not lib:GetRGBPercent(c) then
				break
			end
			local t = new()
			t[1], t[2], t[3] = select(2, lib:GetRGBPercent(c))
			table.insert(gtable, t)
			gradientid = gradientid .. "_" .. c
		end
	elseif type(c1) == "number" then
		-- It's a number, which means we should expect r,g,b values
		local n = select("#", ...)
		--print(n)
		if n < 4 then error("Not enough extra arguments to :SetGradient, need at least 2 RGB pairs.") end
		gtable[1] = new()
		gtable[1][1] = c1
		gtable[1][2] = c2
		gtable[1][3] = select(1, ...)
		gradientid = string.format("%d%d%d", c1, c2, gtable[1][3])

		for i = 2, n, 3 do
			local r, g, b = select(i, ...)
			if r and g and b then
				local t = new()
				t[1], t[2], t[3] = r, g, b
				table.insert(gtable, t)
				gradientid = string.format("%s_%d%d%d", gradientid, r, g, b)
			else
				break
			end
		end
	end

	local max = #gtable
	for i = 1, max do
		if not gtable[i][4] then
			gtable[i][4] = 1
		end
		gtable[i][5] = (i-1) / (max-1)
	end
	if handler.gradienttable then
		for i,v in ipairs(handler.gradienttable) do
			v = del(v)
		end
		handler.gradienttable = del(handler.gradienttable)
	end
	handler.gradienttable = gtable
	handler.gradient = true
	handler.gradientid = gradientid
	if not cachedgradient[gradientid] then
		cachedgradient[gradientid] = {}
	end

	handler.frame.statusbar:SetStatusBarColor(unpack(gtable[1], 1, 4))
	return true
end

local function setColor(color, alpha, b, a)
	lib:argCheck(color, 3, "string", "number")
	local ctable = nil
	if type(color) == "string" then
		--if not paint then
		--	error("You need the PaintChips-2.0 library if you don't pass in RGB pairs as colors.")
		--end
		if not lib:GetRGBPercent(color) then
			return
		end
		lib:argCheck(alpha, 4, "number", "nil")
		ctable = new()
		ctable[1], ctable[2], ctable[3] = select(2, lib:GetRGBPercent(color))
		if alpha then
			ctable[4] = alpha
		else
			ctable[4] = 1
		end
	else
		lib:argCheck(alpha, 4, "number")
		lib:argCheck(b, 5, "number")
		lib:argCheck(a, 6, "number", "nil")
		ctable = new()
		ctable[1], ctable[2], ctable[3] = color, alpha, b
		if a then
			ctable[4] = a
		else
			ctable[4] = 1
		end
	end
	return ctable
end

-- Set the color of the bar
-- Args: name - the candybar name
--	 color - new color of the bar
--	 alpha - new alpha of the bar
-- Setting the color will override smooth settings.
function lib:SetColor(name, color, alpha, b, a)
	lib:argCheck(name, 2, "string")
	local handler = lib.handlers[name]
	if not handler then
		return
	end
	local t = setColor(color, alpha, b, a)
	if not t then return end

	if handler.color then
		handler.color = del(handler.color)
	end
	handler.color = t
	handler.gradient = nil

	handler.frame.statusbar:SetStatusBarColor(unpack(t, 1, 4))
	return true
end

-- Set the color of background of the bar
-- Args: name - the candybar name
--	 color - new color of the bar
-- 	 alpha - new alpha of the bar
-- Setting the color will override smooth settings.
function lib:SetBackgroundColor(name, color, alpha, b, a)
	lib:argCheck(name, 2, "string")
	local handler = lib.handlers[name]
	if not handler then
		return
	end

	local t = setColor(color, alpha, b, a)
	if not t then return end

	if handler.bgcolor then
		handler.bgcolor = del(handler.bgcolor)
	end
	handler.bgcolor = t
	handler.frame.statusbarbg:SetStatusBarColor(unpack(t, 1, 4))

	return true
end

-- Set the color for the bar text
-- Args: name - name of the candybar
--	 color - new color of the text
--	 alpha - new alpha of the text
-- returns true when succesful
function lib:SetTextColor(name, color, alpha, b, a)
	lib:argCheck(name, 2, "string")
	local handler = lib.handlers[name]
	if not handler then
		return
	end

	local t = setColor(color, alpha, b, a)
	if not t then return end

	if handler.textcolor then
		handler.textcolor = del(handler.textcolor)
	end
	handler.textcolor = t
	handler.frame.text:SetTextColor(unpack(t, 1, 4))

	return true
end

-- Set the color for the timer text
-- Args: name - name of the candybar
--	 color - new color of the text
--	 alpha - new alpha of the text
-- returns true when succesful
function lib:SetTimerTextColor(name, color, alpha, b, a)
	lib:argCheck(name, 2, "string")
	local handler = lib.handlers[name]
	if not handler then
		return
	end

	local t = setColor(color, alpha, b, a)
	if not t then return end

	if handler.timertextcolor then
		handler.timertextcolor = del(handler.timertextcolor)
	end
	handler.timertextcolor = t
	handler.frame.timertext:SetTextColor(unpack(t, 1, 4))

	return true
end

-- Set the text for the bar
-- Args: name - name of the candybar
--	   text - text to set it to
-- returns true when succesful
function lib:SetText(name, text)
	lib:argCheck(name, 2, "string")
	lib:argCheck(text, 3, "string")
	
	local handler = lib.handlers[name]
	if not handler then
		return
	end

	handler.text = text
	handler.frame.text:SetText(text)

	return true
end

-- Set the fontsize
-- Args: name - name of the candybar
-- 		 fontsize - new fontsize
-- returns true when succesful
function lib:SetFontSize(name, fontsize)
	lib:argCheck(name, 2, "string")
	lib:argCheck(fontsize, 3, "number")
	
	local handler = lib.handlers[name]
	if not handler then
		return
	end
	
	local font, _, style = GameFontHighlight:GetFont()
	local timertextwidth = fontsize * 3.6
	local width = handler.width or defaults.width
	local f = handler.frame
	
	handler.fontsize = fontsize
	f.timertext:SetFont(font, fontsize, style)
	f.text:SetFont(font, fontsize, style)
	f.timertext:SetWidth(timertextwidth)
	f.text:SetWidth((width - timertextwidth) * .9)
	
	return true
end


-- Set the point where a bar should be anchored
-- Args: name -- name of the bar
-- 	 point -- anchor point
-- 	 rframe -- relative frame
-- 	 rpoint -- relative point
-- 	 xoffset -- x offset
-- 	 yoffset -- y offset
-- returns true when succesful
function lib:SetPoint(name, point, rframe, rpoint, xoffset, yoffset)
	lib:argCheck(name, 2, "string")
	lib:argCheck(point, 3, "string")
	lib:argCheck(rframe, 4, "table", "string", "nil")
	lib:argCheck(rpoint, 5, "string", "nil")
	lib:argCheck(xoffset, 6, "number", "nil")
	lib:argCheck(yoffset, 7, "number", "nil")
	
	local handler = lib.handlers[name]
	if not handler then
		return
	end

	handler.point = point
	handler.rframe = rframe
	handler.rpoint = rpoint
	handler.xoffset = xoffset
	handler.yoffset = yoffset

	handler.frame:ClearAllPoints()
	handler.frame:SetPoint(point, rframe, rpoint, xoffset, yoffset)

	return true
end

function lib:GetPoint(name)
	lib:argCheck(name, 2, "string")
	
	local handler = lib.handlers[name]
	if not handler then
		return
	end
	
	return handler.point, handler.rframe, handler.rpoint, handler.xoffset, handler.yoffset
end

function lib:GetCenter(name)
	lib:argCheck(name, 2, "string")
	
	local handler = lib.handlers[name]
	if not handler then
		return
	end

	return handler.frame:GetCenter()
end

function lib:GetOffsets(name)
	lib:argCheck(name, 2, "string")
	
	local handler = lib.handlers[name]
	if not handler then
		return
	end
	
	local bottom = handler.frame:GetBottom()
	local top = handler.frame:GetTop()
	local left = handler.frame:GetLeft()
	local right = handler.frame:GetRight()
	
	return left, top, bottom, right
end

function lib:GetEffectiveScale(name)
	lib:argCheck(name, 2, "string")
	
	local handler = lib.handlers[name]
	if not handler then
		return
	end

	return handler.frame:GetEffectiveScale()
end

-- Set the width for a bar
-- Args: name - name of the candybar
--	   width - new width of the candybar
-- returns true when succesful
function lib:SetWidth(name, width)
	lib:argCheck(name, 2, "string")
	lib:argCheck(width, 3, "number")

	local handler = lib.handlers[name]
	if not lib.handlers[name] then
		return
	end

	local height = handler.height or defaults.height
	local fontsize = handler.fontsize or defaults.fontsize
	local timertextwidth = fontsize * 3.6
	local f = handler.frame
	f:SetWidth(width + height)
	f.statusbar:SetWidth(width)
	f.statusbarbg:SetWidth(width)

	f.timertext:SetWidth(timertextwidth)
	f.text:SetWidth((width - timertextwidth) * .9)

	handler.width = width

	return true
end

-- Set the height for a bar
-- Args: name - name of the candybar
--	   height - new height for the bar
-- returs true when succesful
function lib:SetHeight(name, height)
	lib:argCheck(name, 2, "string")
	lib:argCheck(height, 3, "number")

	local handler = lib.handlers[name]
	if not handler then
		return
	end
	
	local width = handler.width or defaults.width
	local f = handler.frame
	
	f:SetWidth(width + height)
	f:SetHeight(height)
	f.icon:SetWidth(height)
	f.icon:SetHeight(height)
	f.statusbar:SetHeight(height)
	f.statusbarbg:SetHeight(height)
	f.spark:SetHeight(height + 25)

	f.statusbarbg:SetPoint("TOPLEFT", f, "TOPLEFT", height, 0)
	f.statusbar:SetPoint("TOPLEFT", f, "TOPLEFT", height, 0)

	handler.height = height

	return true
end

-- Set the scale for a bar
-- Args: name - name of the candybar
-- 	 scale - new scale of the bar
-- returns true when succesful
function lib:SetScale(name, scale)
	lib:argCheck(name, 2, "string")
	lib:argCheck(scale, 3, "number")

	local handler = lib.handlers[name]
	if not handler then
		return
	end

	handler.scale = scale

	handler.frame:SetScale(scale)

	return true
end

-- Set the time formatting function for a bar
-- Args: name - name of the candybar
--	   func - function that returns the formatted string
-- 		 a1-a10 - optional arguments to that function
-- returns true when succesful

function lib:SetTimeFormat(name, func, ...)
	lib:argCheck(name, 2, "string")
	lib:argCheck(func, 3, "function")

	local handler = lib.handlers[name]

	if not handler then
		return
	end
	handler.timeformat = func
	setArgs(handler, "timeformat", ...)

	return true
end

-- Set the completion function for a bar
-- Args: name - name of the candybar
--		   func - function to call upon ending of the bar
--	   a1 - a10 - arguments to pass to the function
-- returns true when succesful
function lib:SetCompletion(name, func, ...)
	lib:argCheck(name, 2, "string")
	lib:argCheck(func, 3, "function")
	
	local handler = lib.handlers[name]
	
	if not handler then
		return
	end
	handler.completion = func
	setArgs(handler, "completion", ...)
	
	return true
end

local function onClick()
	lib:OnClick()
end

-- Set the on click function for a bar
-- Args: name - name of the candybar
--		   func - function to call when the bar is clicked
--	   a1 - a10 - arguments to pass to the function
-- returns true when succesful
function lib:SetOnClick(name, func, ...)
	lib:argCheck(name, 2, "string")
	lib:argCheck(func, 3, "function", "nil")

	local handler = lib.handlers[name]
	
	if not handler then
		return
	end
	handler.onclick = func
	setArgs(handler, "onclick", ...)
	
	local frame = handler.frame
	if func then
		-- enable mouse
		frame:EnableMouse(true)
		frame:RegisterForClicks("LeftButtonUp", "RightButtonUp", "MiddleButtonUp", "Button4Up", "Button5Up")
		frame:SetScript("OnClick", onClick)
		frame.icon:EnableMouse(true)
		frame.icon:RegisterForClicks("LeftButtonUp", "RightButtonUp", "MiddleButtonUp", "Button4Up", "Button5Up")
		frame.icon:SetScript("OnClick", onClick)
	else
		frame:EnableMouse(false)
		frame:RegisterForClicks()
		frame:SetScript("OnClick", nil)
		frame.icon:EnableMouse(false)
		frame.icon:RegisterForClicks()
		frame.icon:SetScript("OnClick", nil)
	end

	return true

end

-- Set the "on size" function for a group
-- Args: name - name of the candybar
--		   func - function to call when a group changes size
--	     ...  - arguments to pass to the function
--              (the new size of the bar, in pixels, will be appended last)
-- returns true when succesful
function lib:SetOnSizeGroup(name, func, ...)
	lib:argCheck(name, 2, "string")
	lib:argCheck(func, 3, "function", "nil")

	local group = assert(lib.groups[name])

	group.onsize = func
	setArgs(group, "onsize", ...)
end


-- Set the texture for a bar
-- Args: name - name of the candybar
--	 texture - new texture, if passed nil, the texture is reset to default
-- returns true when succesful
function lib:SetTexture(name, texture)
	lib:argCheck(name, 2, "string")
	lib:argCheck(texture, 3, "string", "nil")
	
	local handler = lib.handlers[name]
	if not handler then
		return
	end
	if not texture then
		texture = defaults.texture
	end

	handler.texture = texture

	handler.frame.statusbar:SetStatusBarTexture(texture)
	handler.frame.statusbarbg:SetStatusBarTexture(texture)

	return true
end

-- Set the icon on a bar
-- Args: name - name of the candybar
-- 	 icon - icon path, nil removes the icon
--   left, right, top, bottom - optional texture coordinates
-- returns true when succesful
function lib:SetIcon(name, icon, left, right, top, bottom)
	lib:argCheck(name, 2, "string")
	lib:argCheck(icon, 3, "string", "nil")
	lib:argCheck(left, 4, "number", "nil")
	lib:argCheck(right, 5, "number", "nil")
	lib:argCheck(top, 6, "number", "nil")
	lib:argCheck(bottom, 7, "number", "nil")
	
	local handler = lib.handlers[name]
	if not handler then
		return
	end
	handler.icon = icon

	if not icon then
		handler.frame.icon:Hide()
	else
		left = left or 0.07
		right = right or 0.93
		top = top or 0.07
		bottom = bottom or 0.93
		handler.frame.icon:SetNormalTexture(icon)
		handler.frame.icon:GetNormalTexture():SetTexCoord(left, right, top, bottom)
		handler.frame.icon:Show()
	end

	return true
end

-- Set the icon position on bar
-- Args: name - name of the candybar
--	 position  - icon position, "LEFT" or "RIGHT"
-- returns true when succesful
function lib:SetIconPosition(name, position)
	lib:argCheck(name, 2, "string")
	lib:argCheck(position, 3, "string", "LEFT", "RIGHT")

	local handler = lib.handlers[name]
	if not handler then
		return
	end

	handler.iconpos = position
	if handler.running then
		handler.frame.icon:SetPoint("LEFT", handler.frame, position, 0, 0)
	end
	return true
end

-- Sets the fading style of a candybar
-- args: name - name of the candybar
--			 time - duration of the fade (default .5 seconds), negative to keep the bar on screen
-- returns true when succesful
function lib:SetFade(name, time)
	lib:argCheck(name, 2, "string")
	lib:argCheck(time, 3, "number")
	
	local handler = lib.handlers[name]
	if not handler then
		return
	end

	handler.fadetime = time
	handler.fadeout = true
	handler.stayonscreen = (handler.fadetime < 0)
    
	return true
end

function lib:SetReversed(name, reversed)
	lib:argCheck(name, 2, "string")
	lib:argCheck(reversed, 3, "boolean", "nil")
	
	local handler = lib.handlers[name]
	if not handler then
		return
	end
	
	handler.reversed = reversed
	return true
end

function lib:IsReversed(name)
	lib:argCheck(name, 2, "string")
	
	local handler = lib.handlers[name]
	if not handler then
		return
	end

	return handler.reversed
end


-- Registers a candybar with a certain candybar group
-- args: name - name of the candybar
--	   group - group to register the bar with
-- returns true when succesful
function lib:RegisterWithGroup(name, group)
	lib:argCheck(name, 2, "string")
	lib:argCheck(group, 3, "string")
	
	local handler = lib.handlers[name]
	local gtable = lib.groups[group]
	if not handler or not gtable then
		return
	end

	lib:UnregisterWithGroup(name)

	table.insert(gtable.bars, name)
	-- lib.groups[group].bars[name] = name
	handler.group = group
	lib:UpdateGroup(group)

	return true
end

-- Unregisters a candybar from its group
-- args: name - name of the candybar
-- returns true when succesful

function lib:UnregisterWithGroup(name)
	lib:argCheck(name, 2, "string")
	
	local handler = lib.handlers[name]
	if not handler then
		return
	end
	--if not lib.handlers[name].group then return end

	local group = handler.group
	local gtable = lib.groups[group]
	if not gtable then
		return
	end

	for k,v in pairs(gtable.bars) do
		if v == name then
			table.remove(gtable.bars, k)
		end
	end
	-- lib.groups[group].bars[name] = nil
	handler.group = nil

	lib:UpdateGroup(group)

	return true
end

-- Register a Candybar group
-- Args: name - name of the candybar group
-- returns true when succesful
function lib:RegisterGroup(name)
	lib:argCheck(name, 2, "string")
	
	if lib.groups[name] then
		return
	end

	local t = new()

	t.point = "CENTER"
	t.rframe = UIParent
	t.rpoint = "CENTER"
	t.xoffset = 0
	t.yoffset = 0
	t.bars = new()
	t.height = -1

	lib.groups[name] = t
	return true
end

-- Unregister a candybar group
-- Args: a1-a2 candybar group ids
-- returns true when succesful
function lib:UnregisterGroup(a1, ...)
	lib:argCheck(a1, 2, "string")
	if not lib.groups[a1] then
		return
	end
	lib.groups[a1].bars = del(lib.groups[a1].bars)
	lib.groups[a1] = del(lib.groups[a1])

	if ... then
		lib:UnregisterGroup(...)
	end

	return true
end

-- Checks if a group is registered
-- Args: name - Candybar group
-- returns true if the candybar group is registered
function lib:IsGroupRegistered(name)
	lib:argCheck(name, 2, "string")
	return lib.groups[name] and true or false
end

-- Checks if a bar is registered with a group
-- Args: name - Candybar name
--	   group - group id [optional]
-- returns true is the candybar is registered with a/the group
function lib:IsRegisteredWithGroup(name, group)
	lib:argCheck(name, 2, "string")
	lib:argCheck(group, 3, "string", "nil")
	local handler = lib.handlers[name]
	if not handler then
		return
	end

	if group then
		if not lib.groups[group] then
			return false
		end
		if handler.group == group then
			return true
		end
	elseif handler.group then
		return true
	end
	return false
end


-- Set the point for a CandyBargroup
-- 	 point -- anchor point
-- 	 rframe -- relative frame
-- 	 rpoint -- relative point
-- 	 xoffset [optional] -- x offset
-- 	 yoffset [optional] -- y offset
-- The first bar of the group will be anchored at the anchor.
-- returns true when succesful
function lib:SetGroupPoint(name, point, rframe, rpoint, xoffset, yoffset)
	lib:argCheck(name, 2, "string")
	lib:argCheck(point, 3, "string")
	lib:argCheck(rframe, 4, "string", "table", "nil")
	lib:argCheck(rpoint, 5, "string", "nil")
	lib:argCheck(xoffset, 6, "number", "nil")
	lib:argCheck(yoffset, 6, "number", "nil")
	
	local group = lib.groups[name]
	if not group then
		return
	end

	group.point = point
	group.rframe = rframe
	group.rpoint = rpoint
	group.xoffset = xoffset
	group.yoffset = yoffset
	lib:UpdateGroup(name)
	return true
end

-- SetGroupGrowth - sets the group to grow up or down
-- Args: name - name of the candybar group
--	   growup - true if growing up, false for growing down
-- returns true when succesful
function lib:SetGroupGrowth(name, growup)
	lib:argCheck(name, 2, "string")
	lib:argCheck(growup, 3, "boolean")
	
	local group = lib.groups[name]
	if not group then
		return
	end

	group.growup = growup

	lib:UpdateGroup(name)

	return true
end

-- SetGroupVerticalSpacing - sets a vertical spacing between the bars of the group
-- Args: name - name of the candybar group
--	   spacing - y offset for the bars
-- returns true when succesful
function lib:SetGroupVerticalSpacing(name, spacing)
	lib:argCheck(name, 2, "string");
	lib:argCheck(spacing, 3, "number");
	
	local group = lib.groups[name]
	if not group then
		return
	end

	group.vertspacing = spacing;

	lib:UpdateGroup(name)

	return true
end

local mysort = function(a, b)
	return lib.handlers[a].endtime < lib.handlers[b].endtime
end
function lib:SortGroup(name)
	local group = lib.groups[name]
	if not group then
		return
	end
	table.sort(group.bars, mysort)
end

-- internal method
-- UpdateGroup - updates the location of bars in a group
-- Args: name - name of the candybar group
-- returns true when succesful

function lib:UpdateGroup(name)
	local group = lib.groups[name]
	if not lib.groups[name] then
		return
	end

	local point = group.point
	local rframe = group.rframe
	local rpoint = group.rpoint
	local xoffset = group.xoffset
	local yoffset = group.yoffset
	local m = -1
	if group.growup then
		m = 1
	end
	local vertspacing = group.vertspacing or 0

	local bar = 0
	local barh = 0

	lib:SortGroup(name)

	for c,n in pairs(group.bars) do
		local handler = lib.handlers[n]
		if handler then
			if handler.frame:IsShown() then
				lib:SetPoint(n, point, rframe, rpoint, xoffset, yoffset + (m * bar))
				barh = handler.height or defaults.height
				bar = bar + barh + vertspacing
			end
		end
	end
	
	if group.height ~= bar then
		group.height = bar
		if group.onsize then
			group.onsize(getArgs(group, "onsize", bar))
		end
	end
	
	return true
end

function lib:GetNextBarPointInGroup(name)
	lib:argCheck(name, 2, "string")
	
	local group = lib.groups[name]
	if not lib.groups[name] then
		return
	end
	
	local xoffset = group.xoffset
	local yoffset = group.yoffset
	local m = -1
	if group.growup then
		m = 1
	end
	
	local bar = 0
	local barh = 0
	
	local vertspacing = group.vertspacing or 0
	
	for c,n in pairs(group.bars) do
		local handler = lib.handlers[n]
		if handler then
			if handler.frame:IsShown() then
				barh = handler.height or defaults.height
				bar = bar + barh + vertspacing
			end
		end
	end
	
	return xoffset, yoffset + (m * bar)
end

-- Internal Method
-- Update a bar on screen
function lib:Update(name)
	local handler = lib.handlers[name]
	if not handler then
		return
	end

	local t = handler.time - handler.elapsed
	handler.slow = t>11

	local timetext
	if handler.timeformat then
		timetext = handler.timeformat(t, getArgs(handler, "timeformat"))
	else
		local h = floor(t/3600)
		local m = t - (h*3600)
		m = floor(m/60)
		local s = t - ((h*3600) + (m*60))
		if h > 0 then
			timetext = ("%d:%02d"):format(h, m)
		elseif m > 0 then
			timetext = string.format("%d:%02d", m, floor(s))
		elseif s < 10 then
			timetext = string.format("%1.1f", s)
		else
			timetext = string.format("%.0f", floor(s))
		end
	end
	handler.frame.timertext:SetText(timetext)

	local perc = t / handler.time

	local reversed = handler.reversed
	handler.frame.statusbar:SetValue(reversed and 1-perc or perc)

	local width = handler.width or defaults.width

	local sp = width * perc
	sp = reversed and -sp or sp
	handler.frame.spark:SetPoint("CENTER", handler.frame.statusbar, reversed and "RIGHT" or "LEFT", sp, 0)

	if handler.gradient then
		local p = floor( (handler.elapsed / handler.time) * 100 ) / 100
		if not cachedgradient[handler.gradientid][p] then
			-- find the appropriate start/end
			local gstart, gend, gp
			for i = 1, #handler.gradienttable - 1 do
				if handler.gradienttable[i][5] < p and p <= handler.gradienttable[i+1][5] then
					-- the bounds are to assure no divide by zero error here.
	
					gstart = handler.gradienttable[i]
					gend = handler.gradienttable[i+1]
					gp = (p - gstart[5]) / (gend[5] - gstart[5])
				end
			end
			if gstart and gend then
				-- calculate new gradient
				cachedgradient[handler.gradientid][p] = new()
				local i
				for i = 1, 4 do
					-- these may be the same.. but I'm lazy to make sure.
					cachedgradient[handler.gradientid][p][i] = gstart[i]*(1-gp) + gend[i]*(gp)
				end
			end
		end
		if cachedgradient[handler.gradientid][p] then
			handler.frame.statusbar:SetStatusBarColor(unpack(cachedgradient[handler.gradientid][p], 1, 4))
		end
	end
end

-- Intenal Method
-- Fades the bar out when it's complete.
function lib:UpdateFade(name)
	local handler = lib.handlers[name]
	if not handler then
		return
	end
	if not handler.fading then
		return
	end
	if handler.stayonscreen then
		return
	end

	-- if the fade is done go and keel the bar.
	if handler.fadeelapsed > handler.fadetime then
		handler.fading = nil
		handler.starttime = nil
		handler.endtime = 0
		handler.frame:Hide()
		if handler.group then
			lib:UpdateGroup(handler.group)
		end
		if handler.fireforget then
			return lib:Unregister(name)
		end
	else -- we're fading, set the alpha for the texts, statusbar and background. fade from default to 0 in the time given.
		local t = handler.fadetime - lib.handlers[name].fadeelapsed
		local p = t / handler.fadetime
		local color = handler.color or defaults.color
		local bgcolor = handler.bgcolor or defaults.bgcolor
		local textcolor = handler.textcolor or defaults.textcolor
		local timertextcolor = handler.timertextcolor or defaults.timertextcolor
		local colora = color[4] * p
		local bgcolora = bgcolor[4] * p
		local textcolora = textcolor[4] * p
		local timertextcolora = timertextcolor[4] * p

		handler.frame.statusbarbg:SetStatusBarColor(bgcolor[1], bgcolor[2], bgcolor[3], bgcolora)
		handler.frame.statusbar:SetStatusBarColor(color[1], color[2], color[3], colora)
		handler.frame.text:SetTextColor(textcolor[1], textcolor[2], textcolor[3], textcolora)
		handler.frame.timertext:SetTextColor(timertextcolor[1], timertextcolor[2], timertextcolor[3], timertextcolora)
		handler.frame.icon:SetAlpha(p)
	end
	return true
end

-- Internal Method
-- Create and return a new bar frame, recycles where needed
-- Name - which candybar is this for
-- Returns the frame
function lib:AcquireBarFrame(name)
	local handler = lib.handlers[name]
	if not handler then
		return
	end

	local f = handler.frame

	local color = handler.color or defaults.color
	local bgcolor = handler.bgcolor or defaults.bgcolor
	local icon = handler.icon or nil
	local iconpos = handler.iconpos or defaults.iconpos
	local texture = handler.texture or defaults.texture
	local width = handler.width or defaults.width
	local height = handler.height or defaults.height
	local point = handler.point or defaults.point
	local rframe = handler.rframe or defaults.rframe
	local rpoint = handler.rpoint or defaults.rpoint
	local xoffset = handler.xoffset or defaults.xoffset
	local yoffset = handler.yoffset or defaults.yoffset
	local text = handler.text or defaults.text
	local fontsize = handler.fontsize or defaults.fontsize
	local textcolor = handler.textcolor or defaults.textcolor
	local timertextcolor = handler.timertextcolor or defaults.timertextcolor
	local scale = handler.scale or defaults.scale
	if not scale then
		scale = 1
	end
	local timertextwidth = fontsize * 3.6
	local font, _, style = GameFontHighlight:GetFont()

	if not f and #lib.framepool > 0 then
		f = table.remove(lib.framepool)
	end

	if not f then
		f = CreateFrame("Button", nil, UIParent)
	end
	f:Hide()
	f.owner = name
	-- yes we add the height to the width for the icon.
	f:SetWidth(width + height)
	f:SetHeight(height)
	f:ClearAllPoints()
	f:SetPoint(point, rframe, rpoint, xoffset, yoffset)
	-- disable mouse
	f:EnableMouse(false)
	f:RegisterForClicks()
	f:SetScript("OnClick", nil)
	f:SetScale(scale)

	if not f.icon then
		f.icon = CreateFrame("Button", nil, f)
	end
	f.icon:ClearAllPoints()
	f.icon.owner = name
	f.icon:EnableMouse(false)
	f.icon:RegisterForClicks()
	f.icon:SetScript("OnClick", nil)
	-- an icno is square and the height of the bar, so yes 2x height there
	f.icon:SetHeight(height)
	f.icon:SetWidth(height)
	f.icon:SetPoint("LEFT", f, iconpos, 0, 0)
	f.icon:SetNormalTexture(icon)
	if f.icon:GetNormalTexture() then 
		f.icon:GetNormalTexture():SetTexCoord( 0.07, 0.93, 0.07, 0.93)
	end 
	f.icon:SetAlpha(1)
	f.icon:Show()

	if not f.statusbarbg then
		f.statusbarbg = CreateFrame("StatusBar", nil, f)
		f.statusbarbg:SetFrameLevel(f.statusbarbg:GetFrameLevel() - 1)
	end
	f.statusbarbg:ClearAllPoints()
	f.statusbarbg:SetHeight(height)
	f.statusbarbg:SetWidth(width)
	-- offset the height of the frame on the x-axis for the icon.
	f.statusbarbg:SetPoint("TOPLEFT", f, "TOPLEFT", height, 0)
	f.statusbarbg:SetStatusBarTexture(texture)
	f.statusbarbg:SetStatusBarColor(bgcolor[1],bgcolor[2],bgcolor[3],bgcolor[4])
	f.statusbarbg:SetMinMaxValues(0,100)
	f.statusbarbg:SetValue(100)

	if not f.statusbar then
		f.statusbar = CreateFrame("StatusBar", nil, f)
	end
	f.statusbar:ClearAllPoints()
	f.statusbar:SetHeight(height)
	f.statusbar:SetWidth(width)
	-- offset the height of the frame on the x-axis for the icon.
	f.statusbar:SetPoint("TOPLEFT", f, "TOPLEFT", height, 0)
	f.statusbar:SetStatusBarTexture(texture)
	f.statusbar:SetStatusBarColor(color[1], color[2], color[3], color[4])
	f.statusbar:SetMinMaxValues(0,1)
	f.statusbar:SetValue(1)


	if not f.spark then
		f.spark = f.statusbar:CreateTexture(nil, "OVERLAY")
	end
	f.spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
	f.spark:SetWidth(16)
	f.spark:SetHeight(height + 25)
	f.spark:SetBlendMode("ADD")
	f.spark:Show()

	if not f.timertext then
		f.timertext = f.statusbar:CreateFontString(nil, "OVERLAY")
	end
	f.timertext:SetFontObject(GameFontHighlight)
	f.timertext:SetFont(font, fontsize, style)
	f.timertext:SetHeight(height)
	f.timertext:SetWidth(timertextwidth)
	f.timertext:SetPoint("LEFT", f.statusbar, "LEFT", 0, 0)
	f.timertext:SetJustifyH("RIGHT")
	f.timertext:SetText("")
	f.timertext:SetTextColor(timertextcolor[1], timertextcolor[2], timertextcolor[3], timertextcolor[4])

	if not f.text then
		f.text = f.statusbar:CreateFontString(nil, "OVERLAY")
	end
	f.text:SetFontObject(GameFontHighlight)
	f.text:SetFont(font, fontsize, style)
	f.text:SetHeight(height)
	f.text:SetWidth((width - timertextwidth) *.9)
	f.text:SetPoint("RIGHT", f.statusbar, "RIGHT", 0, 0)
	f.text:SetJustifyH("LEFT")
	f.text:SetText(text)
	f.text:SetTextColor(textcolor[1], textcolor[2], textcolor[3], textcolor[4])

	if handler.onclick then
		f:EnableMouse(true)
		f:RegisterForClicks("LeftButtonUp", "RightButtonUp", "MiddleButtonUp", "Button4Up", "Button5Up")
		f:SetScript("OnClick", onClick)
		f.icon:EnableMouse(true)
		f.icon:RegisterForClicks("LeftButtonUp", "RightButtonUp", "MiddleButtonUp", "Button4Up", "Button5Up")
		f.icon:SetScript("OnClick", onClick)
	end
	
	return f
end

-- Internal Method
-- Releases a bar frame into the pool
-- Name - which candybar's frame are we're releasing
-- Returns true when succesful
function lib:ReleaseBarFrame(name)
	local handler = lib.handlers[name]
	if not handler then
		return
	end
	if not handler.frame then
		return
	end
	handler.frame:Hide()
	table.insert(lib.framepool, handler.frame)
	return true
end

-- Internal Method
-- Executes the OnClick function of a bar
function lib:OnClick()
	if not this.owner then
		return
	end
	local handler = lib.handlers[this.owner]
	if not handler then
		return
	end
	if not handler.onclick then
		return
	end
	-- pass the name of the handlers first, and the button clicked as the second argument
	local button = arg1
	handler.onclick(this.owner, button, getArgs(handler, "onclick"))
	return true
end

-- Internal Method
-- on update handler
local lastSlow = 0
function lib.OnUpdate(self, elapsed)
	local doslow
	lastSlow = lastSlow + elapsed
	if lastSlow > 0.04 then
		doslow = true
		lastSlow = 0
	end

	local t
	for i,v in pairs(lib.handlers) do
		if not t then t = GetTime() end
		if (not doslow) and v.slow then
			-- nada
		elseif v.running then
			v.elapsed = t - v.starttime
			if v.endtime <= t then
				local c = lib.handlers[i]
				if c.completion then
					if not c.completion(getArgs(c, "completion")) then
						lib:Stop(i)
					end
				else
					lib:Stop(i)
				end
			else
				lib:Update(i)
			end
		elseif v.fading and not v.stayonscreen then
			v.fadeelapsed = (t - v.endtime)
			lib:UpdateFade(i)
		end
	end
end

-- Internal Method
-- returns true if we have any handlers
function lib:HasHandlers()
	return next(lib.handlers) and true
end

------------------------------
--	  Mixins Methods	  --
------------------------------

lib.IsCandyBarRegistered = lib.IsRegistered
lib.StartCandyBar = lib.Start
lib.StopCandyBar = lib.Stop
lib.PauseCandyBar = lib.Pause
lib.CandyBarStatus = lib.Status
lib.SetCandyBarTexture = lib.SetTexture
lib.SetCandyBarTime = lib.SetTime
lib.SetCandyBarColor = lib.SetColor
lib.SetCandyBarText = lib.SetText
lib.SetCandyBarIcon = lib.SetIcon
lib.SetCandyBarIconPosition = lib.SetIconPosition
lib.SetCandyBarBackgroundColor = lib.SetBackgroundColor
lib.SetCandyBarTextColor = lib.SetTextColor
lib.SetCandyBarTimerTextColor = lib.SetTimerTextColor
lib.SetCandyBarFontSize = lib.SetFontSize
lib.SetCandyBarPoint = lib.SetPoint
lib.GetCandyBarPoint = lib.GetPoint
lib.GetCandyBarCenter = lib.GetCenter
lib.GetCandyBarOffsets = lib.GetOffsets
lib.GetCandyBarEffectiveScale = lib.GetEffectiveScale
lib.SetCandyBarScale = lib.SetScale
lib.SetCandyBarTimeFormat = lib.SetTimeFormat
lib.SetCandyBarTimeLeft = lib.SetTimeLeft
lib.SetCandyBarCompletion = lib.SetCompletion
lib.RegisterCandyBarGroup = lib.RegisterGroup
lib.UnregisterCandyBarGroup = lib.UnregisterGroup
lib.IsCandyBarGroupRegistered = lib.IsGroupRegistered
lib.SetCandyBarGroupPoint = lib.SetGroupPoint
lib.SetCandyBarGroupGrowth = lib.SetGroupGrowth
lib.SetCandyBarGroupVerticalSpacing = lib.SetGroupVerticalSpacing
lib.UpdateCandyBarGroup = lib.UpdateGroup
lib.GetCandyBarNextBarPointInGroup = lib.GetNextBarPointInGroup
lib.SetCandyBarOnClick = lib.SetOnClick
lib.SetCandyBarFade = lib.SetFade
lib.RegisterCandyBarWithGroup = lib.RegisterWithGroup
lib.UnregisterCandyBarWithGroup = lib.UnregisterWithGroup
lib.IsCandyBarRegisteredWithGroup = lib.IsRegisteredWithGroup
lib.SetCandyBarReversed = lib.SetReversed
lib.IsCandyBarReversed = lib.IsReversed
lib.SetCandyBarOnClick = lib.SetOnClick
lib.SetCandyBarHeight = lib.SetHeight
lib.SetCandyBarWidth = lib.SetWidth
lib.SetCandyBarOnSizeGroup = lib.SetOnSizeGroup

function lib:RegisterCandyBar(name, time, text, icon, ...)
	if not lib.addons[self] then
		lib.addons[self] = new()
	end
	lib.addons[self][name] = lib:Register(name, time, text, icon, ...)
end

function lib:UnregisterCandyBar(a1, ...)
	lib:argCheck(a1, 2, "string")
	if lib.addons[self] then
		lib.addons[self][a1] = nil
	end
	lib:Unregister(a1)
	if ... then
		self:UnregisterCandyBar(...)
	end
end

function lib:OnEmbedDisable(target)
	if self.addons[target] then
		for i in pairs(self.addons[target]) do
			self:Unregister(i)
		end
	end
end

function lib:Embed(target)
	for k, v in pairs(mixins) do
		target[v] = lib[v]
	end
	self.embeds[target] = true
	return target	
end

-- last step of upgrading

lib.frame:SetScript("OnUpdate", lib.OnUpdate)

for target, v in pairs(lib.embeds) do
	lib:Embed(target)
end


