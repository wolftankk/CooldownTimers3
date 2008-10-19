--$Id$

--bummed from ckknight's pitbull, with his permission:
local new, del
do
	local list = setmetatable({}, {__mode='k'})
	function new(...)
		local t = next(list)
		if t then
			list[t] = nil
			for i = 1, select('#',...) do
				t[i] = select(i,...)
			end
			return t
		else
			return {...}
		end
	end
	function del(t)
		for k in pairs(t) do
			t[k] = nil
		end
		list[t] = true
		return nil
	end
end
--end sleazy code borrowing

--- Register Ace3 Addon
CooldownTimers = LibStub("AceAddon-3.0"):NewAddon("CooldownTimers3", "AceConsole-3.0", "AceEvent-3.0", "AceHook-3.0", "AceComm-3.0", "LibCandyBar-2.1", "AceTimer-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("CooldownTimers3");
local SM = LibStub("LibSharedMedia-3.0")
local df = LibStub("LibDeformat-3.0")
local db;

LibStub("AceAddon-3.0"):EmbedLibrary(CooldownTimers, "LibFuBarPlugin-3.0", true);

local abs = math.abs;
local GetTime = GetTime
local CreateFrame = CreateFrame
local format = string.format

local defaults = {
	profile = {
		["groups"] = {
			["CDT"] = {
			},
			["ItemCooldowns"] = {
			},
			["GroupCooldowns"] = {
			},
		},
		["announce"] = {
			x = 0,
			y = 0,
			point = "CENTER",
			relPoint = "CENTER",
			announceString = L["%s ready!"],
			scale = 1,
			fade = 1,
			font = "Friz Quadrata TT",
			enabled = true,
			fontcolor = {1.0, 0.9294, 0.7607},
			spellcolor = {1.0, 0.9294, 0.7607},
		},
		["barOptions"] = {
			["colors"] = {
				["colors1"] = {0.9, 0.9, 0.1},
				["colors2"] = {0.1, 1, 0.09},
			},
			["fade"] = 1,
			["barwidth"] = 200,
			["barheight"] = 16,
			["bargap"] = 0,
			["columns"] = 1,
			["scale"] = 1,
			["up"] = false,
			["collapse"] = true,
			--["announce"] = true,--?what do?
			["texture"] = "Smooth",
		},
		["maxtime"] = 3600,
		["mintime"] = 1.5,
		["itemgroups"] = {},
		["itemcooldowns"] = {},
	  groupcooldowns = {
	  },
	  pulseoncooldown = true,
	  sound = true,
	  autogroup = true,
	  ["pulse"] = {
		enabled = true,
		size = 100,
		alpha = 0.5,
		fadein = 0.25,
		fadeout = 1,
		min = 0.75,
		loc = {
		  x = 0,
		  y = 0,
		  point = "CENTER",
		  relPoint = "CENTER",
		},
	  },
	  fubar = {
		  hideMinimapButton = false,
	  },
	},
	char = {
		["petcooldowns"] = {},
	},
	class = {}
}

local function getspellname(id)
	local name = GetSpellInfo(id)
	return name
end

function CooldownTimers:OnInitialize()
	self.VERSION = GetAddOnMetadata("CooldownTimers3", "Version")
	self.revesion = self.VERSION.." (r"..(tonumber(("$Rev$"):match("%d+")))..")";
	self.db = LibStub("AceDB-3.0"):New("CooldownTimersDB", defaults, "Default");
	local _,playerclass = UnitClass("player");

	if playerclass == "HUNTER" then
		if not (self.db.class["cooldowns"]) then
			self.db.class["cooldowns"] = {}
		end
		if not (self.db.class["skillgroups"]) then
			self.db.class["skillgroups"] = {
				[getspellname(14311)] = L["Traps"],
				[getspellname(13809)] = L["Traps"],
				[getspellname(27023)] = L["Traps"],
				[getspellname(34600)] = L["Traps"],
				[getspellname(27025)] = L["Traps"],
			}
		end
	elseif playerclass == "SHAMAN" then
		if not(self.db.class["cooldowns"]) then
			self.db.class["cooldowns"] = {}
		end
		if not(self.db.class["skillgroups"]) then
			self.db.class["skillgroups"] = {
				[getspellname(25464)] = L["Shocks"],
				[getspellname(25457)] = L["Shocks"],
				[getspellname(25454)] = L["Shocks"],
			}
		end
	elseif playerclass == "PALADIN" then
		if not(self.db.class["cooldowns"]) then
			self.db.class["cooldowns"] = {}
		end
		if not(self.db.class["skillgroups"]) then
			self.db.class["skillgroups"] = {
				[getspellname(20271)] = L["Judgement"],--light
				[getspellname(53408)] = L["Judgement"],--wisdom
				[getspellname(53407)] = L["Judgement"],--justice
			}
		end
	else
		if not(self.db.class["cooldowns"]) then
			self.db.class["cooldowns"] = {}
		end
		if not(self.db.class["skillgroups"]) then
			self.db.class["skillgroups"] = {}
		end
	end

	self:SetupOptions()
	self:RegisterChatCommand("cdt", openConfigFrame);
	
	self.db.RegisterCallback(self, 'OnProfileChanged', "OnProfileChanged");
	self.db.RegisterCallback(self, 'OnProfileCopied', "OnProfileChanged");
	self.db.RegisterCallback(self, 'OnProfileReset', "OnProfileChanged");

	if LibStub:GetLibrary("LibFuBarPlugin-3.0", true) then
		self:SetFuBarOption("tooltipType", "GameTooltip")
		self:SetFuBarOption("hasNoColor", true)
		self:SetFuBarOption("cannotDetachTooltip", true)
		self:SetFuBarOption("hideWithoutStandby", true)
		self:SetFuBarOption("iconPath", "Interface\\Icons\\INV_Misc_PocketWatch_02")
	end
end

local function qpush(self, ...)
  self.last = self.last + 1;
  self[self.last] = new(...);
  self.isEmpty = false;
end

local function qpop(self)
  if self.isEmpty then return nil end
  local s,t = unpack(self[self.first]);
  self[self.first] = del(self[self.first]);
  self.first = self.first + 1;
  if self.first > self.last then
    self.isEmpty = true;
  end
  return s,t;
  
end

function CooldownTimers:OnEnable()
	self:RegisterEvent("SPELL_UPDATE_COOLDOWN");
	self:RegisterEvent("PLAYER_ALIVE", "PopulateCooldowns");
	self:RegisterEvent("SPELLS_CHANGED", "PopulateCooldowns");
	self:RegisterEvent("PLAYER_ENTERING_WORLD");
	self:RegisterEvent("BAG_UPDATE_COOLDOWN");
	self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED");

	if self.db.profile.pulseoncooldown then
		self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", "OnSpellFail");
	end
		
	self:RegisterEvent("PARTY_MEMBERS_CHANGED", "Party");
	self:RegisterEvent("UNIT_PET");

	self.tooltip = CreateFrame("GameTooltip", "CDTTooltip", UIParent, "GameTooltipTemplate");
	--self.tooltip:SetScript("OnLoad", function(self) self:SetOwner(UIParent, "ANCHOR_NONE") end);
	self.tooltip:SetOwner(UIParent, "ANCHOR_NONE");
	self.anchors = {}
	
	
	for k, v in pairs(self.db.profile.groups) do
		self:MakeAnchor(k, v)
	end

	self:FixGroups()

	SM:Register("statusbar", "Blizzard Default", "Interface\\TargetingFrame\\UI-StatusBar")
	SM:Register("statusbar", "Smooth", "Interface\\AddOns\\CooldownTimers2\\Textures\\smooth.tga")
	SM:Register("statusbar", "Cilo", "Interface\\AddOns\\CooldownTimers2\\Textures\\cilo.tga")
	SM:Register("statusbar", "BantoBar", "Interface\\AddOns\\CooldownTimers2\\Textures\\bar.tga")

	if not self.bars then
		self.bars = {}
	end

	if not self.baralphas then
		self.baralphas = {}
	end

	self.queue = { first =0, last = -1, isEmpty = true}
	self.queue.push = qpush;
	self.queue.pop = qpop;

	if not self.announce then
		self:MakeAnnounce()
	end

	db = self.db.profile;

	if db.autogroup then
		self:SecureHook("UseAction", "useAction");
		self:SecureHook("UseContainerItem", "useContainer");
		self:SecureHook("UseInventoryItem", "useInventory");
		self:SecureHook("UseItemByName", "useItem");
	end

	--if not self.db.profile.groups.GroupCooldowns.disabled then
	--	self:RegisterComm("CDT3");
	--end
	--self.offsets = {}
	--self.lastsend = 0
end

--NOTE: 此部分用来同步传输, 目前根据ace3的 暂时取消

function CooldownTimers:Party()
	--if GetNumPartyMembers() > 0 and abs(GetTime() - self.lastsent) > 3 then
		--self.lastsent = GetTime()
		--self:SendCommMessage("CDT3", GetTime(), "GROUP", "ALERT");
	--end
end

--Comm 目前需要重写
--function CooldownTimers:OnCommReceived(pre, sender, dis, cmd, ...)
	--self:Print(pre, sender, dis, cmd, ...)
--end


function openConfigFrame()
	LibStub("AceConfigDialog-3.0"):SetDefaultSize("CooldownTimers3", 600, 530)
	LibStub("AceConfigDialog-3.0"):Open("CooldownTimers3")
end

function CooldownTimers:OnUpdateFuBarTooltip()
	GameTooltip:AddLine("|cffffffffCooldownTimers3      "..CooldownTimers.revesion.."|r")
	GameTooltip:AddLine("|cffffff00" .. "Right-Click|r to open Config Frame")
end

CooldownTimers.OpenMenu = openConfigFrame -- for fubar

function CooldownTimers:OnProfileChanged(db, name)
	--CooldownTimers:ResetMemoizations()
	--CooldownTimers:SetAnchors(true)
	--CooldownTimers:UpdateDisplay()
end

function CooldownTimers:useAction(slot)
	local item, id = GetActionInfo(slot)
	if item == "item" then
		self.lastitem = id
	end
end

function CooldownTimers:useContainer(bag, slot)
	self.lastitem = GetContainerItemLink(bag, slot)
end

function CooldownTimers:useInventory(slot)
	self.lastitem = GetInventoryItemLink("player", solt)
end

function CooldownTimers:useItem(name)
	self.lastitem = name;
end

function CooldownTimers:PLAYER_ENTERING_WORLD()
	self:ResetCooldowns();
	if GetNumPartyMembers() > 0 then
		self:Party();
		--self:RequestOffsets();
	end
end

function CooldownTimers:RequestOffsets(...)
	--self:SendCommMessage("CDT3", ... , "GROUP", "NORMAL")
end


function CooldownTimers:OnSpellFail(event, ...)
	local eventtype,_,_,srcFlag = select(2, ...)

	if (eventtype == "SPELL_CAST_FAILED") then
	end
	
	if (eventtype ~= "SPELL_CAST_FAILED" or (not CombatLog_Object_IsA(srcFlag, COMBATLOG_FILTER_MINE))) then
		return
	end

	local skill, _, reason = select(10, ...)
	if reason ~= SPELL_FAILED_NOT_READY then
		return
	end
	if not self.db.profile.autogroup and self.db.class.skillgroups[skill] then
		skill = self.db.class.skillgroups[skill]
	end
	if not self.db.class.cooldowns[skill] then
		return
	end
	local group = self.db.profile.groups[self.db.class.cooldowns[skill].group]
	if self.bars[skill] and not self.baralphas[self.bars[skill]] then
		self.baralphas[self.bars[skill]] = new(1, 0.05);
		self:ScheduleRepeatingTimer(function()
			self:FlashBar(skill, self.bars[skill], group.scale or self.db.profile.barOptions.scale)
			end, 0.0001);
	end
end

function CooldownTimers:FlashBar(skill, bar, scale)
	if not self.bars[skill] or not self.baralphas[bar] then
		self:CancelAllTimers()
		if self.baralphas[bar] then
			del(self.baralphas[bar])
			self.baralphas[bar] = nil
		end
		return
	end
	
	self.baralphas[bar][1] = self.baralphas[bar][1] +  self.baralphas[bar][2]
	self:SetCandyBarScale(bar, self.baralphas[bar][1] * scale)
	if self.baralphas[bar][1] >= 1.5 then
		self.baralphas[bar][2] = -self.baralphas[bar][2]
	elseif self.baralphas[bar][1] <= 1 then
		self:CancelAllTimers()
		del(self.baralphas[bar])
		self.baralphas[bar] = nil
		self:SetCandyBarScale(bar, scale)
	end
end

function CooldownTimers:ResetCooldowns()
	self:KillAllBars()
	for k, v in pairs(self.db.class.cooldowns) do
		--print (k)
		v.start = 0;
	end
	for k, v in pairs(self.db.char.petcooldowns) do
		v.start = 0
	end

	self:SPELL_UPDATE_COOLDOWN()
	self:BAG_UPDATE_COOLDOWN()
	if UnitExists("pet") then
		self:PET_BAR_UPDATE_COOLDOWN()
	end
end

function CooldownTimers:MakeAnchor(group, info)
	if info.disabled then
		return
	end

	self.anchors[group] = CreateFrame("Frame", group..tostring(math.floor(GetTime())), UIParent)
	self.anchors[group]:ClearAllPoints();
	self.anchors[group]:SetBackdrop({
		bgFile = [[Interface\Tooltips\UI-Tooltip-Background]],
		edgeFile = [[Interface\Tooltips\UI-Tooltip-Border]],
		tile = true,
		tileSize = 16,
		edgeSize = 16,
		insets = {
			left = 5,
			right = 5,
			top = 5,
			bottom = 5,
			},
		})

	if not info.point then
		info.x = 0;
		info.y = 0;
		info.relPoint = "CENTER";
		info.point = "CENTER";
	end

	self.anchors[group]:SetWidth(128);
	self.anchors[group]:SetHeight(30);
	self.anchors[group]:SetBackdropColor(0.1, 0.1, 0.3);
	self.anchors[group]:EnableMouse(true);
	self.anchors[group]:SetPoint(info.point, "UIParent", info.relPoint, info.x, info.y);


	local msg = self.anchors[group]:CreateFontString(nil, "OVERLAY", "GameFontNormal");
	msg:ClearAllPoints();
	msg:SetPoint("CENTER", self.anchors[group], "CENTER");
	msg:SetText(group);

	self.anchors[group]:SetMovable(true);
	self.anchors[group]:SetScript("OnDragStart", 
		function()
			self.anchors[group]:StartMoving()
			GameTooltip:Hide()
		end
		)
	self.anchors[group]:SetScript("OnDragStop",
		function()
			self.anchors[group]:StopMovingOrSizing()
			self:SavePosition(group)
		end
		)
	self.anchors[group]:SetScript("OnMouseUp",
		function()
			self:OnAnchorClick(group)
		end)

	self.anchors[group]:SetScript("OnEnter",
		function()
			self:ShowAnchorTooltip()
		end)
	self.anchors[group]:SetScript("OnLeave",
		function()
			GameTooltip:Hide()
		end)

	self.anchors[group]:RegisterForDrag("LeftButton")
	if self.db.profile.groups[group].locked or self.db.profile.groups[group].disabled then
		self.anchors[group]:Hide()
	else
		self.anchors[group]:Show()
	end
	--self:Print(group)

	self:RegisterCandyBarGroup(group)

	if info.up or self.db.profile.barOptions.up then
		self:SetCandyBarGroupPoint(group, "BOTTOM", self.anchors[group]:GetName(), "TOP", 0, 0)
	else
		self:SetCandyBarGroupPoint(group, "TOP", self.anchors[group]:GetName(), "BOTTOM", 0, 0)
	end
	self:SetCandyBarGroupGrowth(group, info.up or self.db.profile.barOptions.up)
end

function CooldownTimers:MakeAnnounce()
	self.announce = {}
	self.announce.anchor = CreateFrame("Frame", "CDTAnnounceAnchor", UIParent);
	self.announce.anchor:ClearAllPoints();
	self.announce.anchor:SetPoint(
		self.db.profile.announce.point,
		UIParent,
		self.db.profile.announce.relPoint,
		self.db.profile.announce.x,
		self.db.profile.announce.y)
	self.announce.anchor:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true,
		tileSize = 16,
		edgeSize = 16,
		insets = {
			left = 5,
			right = 5,
			top = 5,
			bottom = 5
		},
	})
	self.announce.anchor:SetBackdropColor(0.1,0.1,0.3)
	self.announce.anchor:SetWidth(45)
	self.announce.anchor:SetHeight(45)
	self.announce.anchor:EnableMouse(true)
	self.announce.anchor:SetMovable(true)
	self.announce.anchor:SetScript("OnDragStart",
		function()
			self.announce.anchor:StartMoving()
			GameTooltip:Hide()
		end
	)
	self.announce.anchor:SetScript("OnDragStop",
		function()
			self.announce.anchor:StopMovingOrSizing()
			self.db.profile.announce.point, _, self.db.profile.announce.relPoint, self.db.profile.announce.x, self.db.profile.announce.y = self.announce.anchor:GetPoint()
		end
	)
	self.announce.anchor:SetScript("OnEnter",
		function()
			GameTooltip:SetOwner(this, "ANCHOR_BOTTOMRIGHT")
			GameTooltip:AddLine(L["CDT Announce Anchor"])
			GameTooltip:AddLine(L["Drag this to reposition the announcement text."])
			GameTooltip:AddLine(L["Shift+Click this to lock it in position."])
			GameTooltip:Show()
		end
	)
	self.announce.anchor:SetScript("OnLeave",
		function()
			GameTooltip:Hide()
		end
	)
	self.announce.anchor:SetScript("OnMouseUp",
		function()
			if IsShiftKeyDown() then
				self.announce.anchor:Hide()
				self.db.profile.announce.locked = true
			end
		end
	)
	self.announce.anchor:RegisterForDrag("LeftButton")
	
	self.announce.frame = CreateFrame("Frame","CDTAnnounceFrame",UIParent)
	self.announce.text = self.announce.frame:CreateFontString("CDTAnnounceText", "OVERLAY")
	self.announce.text:SetFont(SM:Fetch('font',self.db.profile.announce.font), 102, "THICK")
	self.announce.text:SetTextColor(unpack(self.db.profile.announce.fontcolor))
	self.announce.text:SetShadowColor( 0, 0, 0, 1)
	self.announce.text:SetShadowOffset( 0.8, -0.8 )
	self.announce.text:ClearAllPoints()
	self.announce.text:SetPoint("CENTER", self.announce.anchor, "CENTER", 0,0)
	self.announce.frame:ClearAllPoints()
	self.announce.frame:SetAllPoints(self.announce.text)
	self.announce.frame:SetScale(self.db.profile.announce.scale)
	local hex = format("%02x%02x%02x", self.db.profile.announce.spellcolor[1]*255, self.db.profile.announce.spellcolor[2]*255, self.db.profile.announce.spellcolor[3]*255)
	self.announce.text:SetText(format(self.db.profile.announce.announceString, '|cff'..hex..'%s|r'))
	self.announce.last = GetTime()
	self.announce.alpha = 1
	self.announce.frame:SetScript("OnUpdate",
		function()
			if self.announce.anchor:IsShown() then
				return
			end
			if (GetTime() - self.announce.last) > self.db.profile.announce.fade then
				self.announce.alpha = self.announce.alpha - 0.1
			end
			self.announce.frame:SetAlpha(self.announce.alpha)
			if self.announce.alpha <= 0 then
				self.announce.frame:Hide()
			end
		end
	)
	self.announce.text:Show()
	self.announce.anchor:SetFrameStrata("BACKGROUND")
	self.announce.frame:SetFrameStrata("BACKGROUND")
	
	if not self.db.profile.announce.locked and self.db.profile.announce.enabled then
		self.announce.anchor:Show()
		self.announce.frame:Show()
	else
		self.announce.anchor:Hide()
		self.announce.frame:Hide()
	end

        --[[
        --  Sets up the pulse location
        --]]
  self.pulse = CreateFrame("Button","CDTPulseImage",UIParent)
  self.pulse.anchor = CreateFrame("Frame","CDTPulseAnchor",UIParent);
  self.pulse.anchor:ClearAllPoints();
  self.pulse.anchor:SetWidth(30);
  self.pulse.anchor:SetHeight(30);
  self.pulse.anchor:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true,
		tileSize = 16,
		edgeSize = 16,
		insets = {
			left = 5,
			right = 5,
			top = 5,
			bottom = 5
		},
	});
	self.pulse.anchor:SetBackdropColor(0.1,0.1,0.3)
	local ploc = self.db.profile.pulse.loc;
	self.pulse.anchor:EnableMouse(true);
	self.pulse.anchor:SetMovable(true);
	self.pulse.anchor:SetPoint( ploc.point, UIParent, ploc.relPoint, ploc.x, ploc.y );
	self.pulse.anchor:SetFrameLevel(5);
	self.pulse.anchor:RegisterForDrag("LeftButton");
	self.pulse.anchor:SetScript("OnDragStart", function() self.pulse.anchor:StartMoving(); end );
	self.pulse.anchor:SetScript("OnDragStop", function() self.pulse.anchor:StopMovingOrSizing(); local _;
	ploc.point, _, ploc.relPoint, ploc.x, ploc.y = self.pulse.anchor:GetPoint(); end);
	self.pulse:ClearAllPoints();
	self.pulse:SetPoint("CENTER", self.pulse.anchor, "CENTER", 0, 0);
	self.pulse:SetHeight(self.db.profile.pulse.size)
	self.pulse:SetWidth(self.db.profile.pulse.size)
	self.pulse:EnableMouse(false)
	self.pulse.animating = false;
	self.pulse:SetResizable(true);
	self.pulse:SetMaxResize(300,300);
	self.pulse:SetMinResize(50,50);
	self.pulse.animate = function()
		self:AnimatePulse();
	end
	self.pulse.configure = function()
		self:ConfigurePulse();
	end
	if self.db.profile.pulse.locked then
		self.pulse.onUpdate = self.pulse.animate;
		self.pulse:Hide();
	else
		self.pulse.onUpdate = self.pulse.configure;
		self.pulse:Show();
	end  
	self.pulse:SetScript("OnUpdate", function()
		self.pulse.onUpdate()
	end);
	self.pulse:SetNormalTexture("Interface\\Icons\\INV_Misc_QuestionMark");
	self.pulse.scaleanchor = CreateFrame("Frame","CDTPulseAnchor",UIParent);
	self.pulse.scaleanchor:ClearAllPoints();
	self.pulse.scaleanchor:SetWidth(30);
	self.pulse.scaleanchor:SetHeight(30);
	self.pulse.scaleanchor:SetFrameLevel(5);
	self.pulse.scaleanchor:EnableMouse(true);
	self.pulse.scaleanchor:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true,
		tileSize = 16,
		edgeSize = 16,
		insets = {
			left = 5,
			right = 5,
			top = 5,
			bottom = 5
		},
	});
	self.pulse.scaleanchor:SetBackdropColor(0.1,0.1,0.3)
	self.pulse.scaleanchor:SetPoint("CENTER", self.pulse, "BOTTOMRIGHT", 0, 0);
	self.pulse.scaleanchor:RegisterForDrag("LeftButton");
	self.pulse.scaleanchor.checkWidths = function()
		if self.pulse:GetHeight() > self.pulse:GetWidth() then
			self.pulse:SetWidth(self.pulse:GetHeight());
		else
			self.pulse:SetHeight(self.pulse:GetWidth());
		end
	end
  self.pulse.scaleanchor.onUpdate = function() end;
  self.pulse.scaleanchor:SetScript("OnUpdate", function() self.pulse.scaleanchor.onUpdate() end);
  self.pulse.scaleanchor:SetScript("OnDragStart", function() 
    self.pulse:StartSizing("BOTTOMRIGHT");
    self.pulse.anchor:ClearAllPoints();
    self.pulse.anchor:SetPoint("CENTER", self.pulse, "CENTER", 0, 0);
    self.pulse.scaleanchor.onUpdate = self.pulse.scaleanchor.checkWidths;
  end);
  self.pulse.scaleanchor:SetScript("OnDragStop", function() 
    self.pulse:StopMovingOrSizing(); 
    self.db.profile.pulse.size = self.pulse:GetHeight();
    self.pulse.anchor:ClearAllPoints();
    self.pulse.anchor:StartMoving();
    self.pulse.anchor:StopMovingOrSizing();
    self.pulse:ClearAllPoints();
    self.pulse:SetPoint("CENTER", self.pulse.anchor, "CENTER", 0, 0);
    local _;
    self.pulse.anchor:EnableMouse(true);
    ploc.point, _, ploc.relPoint, ploc.x, ploc.y = self.pulse.anchor:GetPoint();
    self.pulse.scaleanchor.onUpdate = function() end;
  end);
  
  
	self.pulse.anchor:SetScript("OnEnter",
		function()
			GameTooltip:SetOwner(this, "ANCHOR_BOTTOMRIGHT")
			GameTooltip:AddLine(L["CDT Pulse Anchor"])
			GameTooltip:AddLine(L["Drag this to reposition the pulse icon."])
			GameTooltip:AddLine(L["Shift+Click this to lock it in position."])
			GameTooltip:Show()
		end
	);
  
  self.pulse.anchor:SetScript("OnLeave", function() GameTooltip:Hide(); end);
  
	self.pulse.scaleanchor:SetScript("OnEnter",
		function()
			GameTooltip:SetOwner(this, "ANCHOR_BOTTOMRIGHT")
			GameTooltip:AddLine(L["CDT Pulse Size Anchor"])
			GameTooltip:AddLine(L["Drag this to resize the the pulse icon."])
			GameTooltip:Show()
		end
	);
  self.pulse.scaleanchor:SetScript("OnLeave", function() GameTooltip:Hide(); end);
  
	self.pulse.anchor:SetScript("OnMouseUp",
		function()
			if IsShiftKeyDown() then
				self:LockPulseIcon(true);
			end
		end
	);
  
  self:LockPulseIcon(self.db.profile.pulse.locked);
end

function CooldownTimers:LockPulseIcon(locked)
	if locked then
		self.pulse.onUpdate = self.pulse.animate;
		self.pulse.anchor:Hide();
		self.pulse.scaleanchor:Hide();
		self.db.profile.pulse.locked = true;
	else
		self.pulse.onUpdate = self.pulse.configure;
		self.pulse.anchor:Show();
		self.pulse.scaleanchor:Show();
		self.pulse:Show();
		self.db.profile.pulse.locked = false;
	end    
end

function CooldownTimers:LockAnchor(group)
	self.db.profile.groups[group].locked = true
	self.anchors[group]:Hide()
end

function CooldownTimers:ConfigurePulse()
	self:AnimatePulse(true);
end

function CooldownTimers:ShowAnchorTooltip()
	GameTooltip:SetOwner(this, "ANCHOR_BOTTOMRIGHT")
	GameTooltip:AddLine(L["CDT Group Anchor"])
	GameTooltip:AddLine(L["Drag this to reposition"])
	GameTooltip:AddLine(L["Shift+Left Click to hide"])
	GameTooltip:AddLine(L["Alt+Left Click to show a test bar"])
	GameTooltip:AddLine(L["Alt+Left Click again to hide the test bar"])
	GameTooltip:AddLine(L["If you hide this, you can show it again by going to Group Options -> groupname -> Uncheck Lock"])
	GameTooltip:Show()
end

function CooldownTimers:OnAnchorClick(group, altkey)
	if IsAltKeyDown() or altkey then
		if self:IsCandyBarRegistered(group.."testbar") then
			self:StopCandyBar(group.."testbar")
			return
		end

		local r1, g1, b1, a1 = unpack(self.db.profile.barOptions.colors.colors1)
		local r2, g2, b2, a2 = unpack(self.db.profile.barOptions.colors.colors2)
		self:RegisterCandyBar(group.."testbar", 30, "Test bar", "Interface\\Icons\\INV_Misc_QuestionMark", r1, g1, b1, r2, g2, b2)
		
		self:RegisterCandyBarWithGroup(group.."testbar", group)
		self:SetCandyBarTexture(group.."testbar", SM:Fetch("statusbar", self.db.profile.groups[group].texture or self.db.profile.barOptions.texture))
		self:SetCandyBarWidth(group.."testbar", self.db.profile.groups[group].barwidth or self.db.profile.barOptions.barwidth)
		self:SetCandyBarHeight(group.."testbar", self.db.profile.groups[group].barheight or self.db.profile.barOptions.barheight)
		self:SetCandyBarScale(group.."testbar", self.db.profile.groups[group].scale or self.db.profile.barOptions.scale)
		self:StartCandyBar(group.."testbar", true)
	end
	if IsShiftKeyDown() then
		self:LockAnchor(group)
		return
	end
end

function CooldownTimers:SavePosition(group)
	self.db.profile.groups[group].point, _, self.db.profile.groups[group].relPoint, self.db.profile.groups[group].x, self.db.profile.groups[group].y = self.anchors[group]:GetPoint()
end

function CooldownTimers:OnDisable()

end

function CooldownTimers:SPELL_UPDATE_COOLDOWN()
	local start, duration, enable, name
	local cooldowns = new();
	
	for k, v in pairs(self.db.class.cooldowns) do
		name = GetSpellName(v.id, BOOKTYPE_SPELL)
		
		if not v.disabled and (k == name or k == self.db.class.skillgroups[name]) then
			start, duration, enable = GetSpellCooldown(v.id, BOOKTYPE_SPELL)
				if enable == 1 and duration > self.db.profile.mintime and duration <= self.db.profile.maxtime and v.start ~= start then
					v.start = start
						if self.db.profile.autogroup then
							local index = floor(start*duration);
								if not cooldowns[index] then
									cooldowns[index] = new();
									cooldowns[index].name = k;
									cooldowns[index].spell = v;
									cooldowns[index].duration = duration;
								end
								if name == self.lastcast then
									cooldowns[index].name = k;
									cooldowns[index].spell = v;
								end
						else
							self:SetUpBar(k, v, duration)
						end
				end
		end
	end
	for k,v in pairs(cooldowns) do
		self:SetUpBar(v.name, v.spell, v.duration);
		del(cooldowns[k]);
	end
	del(cooldowns);
end

function CooldownTimers:BAG_UPDATE_COOLDOWN()
	local slots, id, name, start, duration, enable, link, _
	local cooldowns = new();
	for i=1,18 do
		start, duration, enable = GetInventoryItemCooldown("player", i)
		if enable == 1 and duration > self.db.profile.mintime and duration <= self.db.profile.maxtime then
			link = GetInventoryItemLink("player",i);
			_, _, name = string.find(link, "Hitem[^|]+|h%[([^[]+)%]");
			if self.db.profile.itemgroups[name] then
				name = self.db.profile.itemgroups[name]
			end
			if not self.db.profile.itemcooldowns[name] then
				self.db.profile.itemcooldowns[name] = {
					["disabled"] = false,
					["icon"] = GetInventoryItemTexture("player", i),
				}
				if not self.db.profile.groups.ItemCooldowns.disabled then
					self.db.profile.itemcooldowns[name].group = "ItemCooldowns"
				else
					self.db.profile.itemcooldowns[name].group = "CDT"
				end
			end
			if not self.db.profile.itemcooldowns[name].disabled and self.db.profile.itemcooldowns[name].start ~= start then
				self.db.profile.itemcooldowns[name].start = start
				if self.db.profile.autogroup then
					 local index = floor(start * duration);
						if not cooldowns[index] then 
							cooldowns[index] = new();
							cooldowns[index].name = name;
							cooldowns[index].item = self.db.profile.itemcooldowns[name];
							cooldowns[index].duration = duration;
						end
						if self.lastitem and string.find(link, self.lastitem, 1, true) then
							cooldowns[index].name = name;
							cooldowns[index].item = self.db.profile.itemcooldowns[name];
						end
				else
					self:SetUpBar(name, self.db.profile.itemcooldowns[name], duration)
				end
			end
		end
	end
	for i=0,4 do
		slots = GetContainerNumSlots(i)
		for j=1,slots do
			start, duration, enable = GetContainerItemCooldown(i,j)
			if enable == 1 and duration > self.db.profile.mintime and duration <= self.db.profile.maxtime then
				link = GetContainerItemLink(i,j);
				_, _, name = string.find(link, "Hitem[^|]+|h%[([^[]+)%]");
				if self.db.profile.itemgroups[name] then
					name = self.db.profile.itemgroups[name]
				end
				if not self.db.profile.itemcooldowns[name] then
					self.db.profile.itemcooldowns[name] = {
						["disabled"] = false,
						["icon"] = GetContainerItemInfo(i,j),
					}
					if not self.db.profile.groups.ItemCooldowns.disabled then
						self.db.profile.itemcooldowns[name].group = "ItemCooldowns"
					else
						self.db.profile.itemcooldowns[name].group = "CDT"
					end
				end
				if not self.db.profile.itemcooldowns[name].disabled and self.db.profile.itemcooldowns[name].start ~= start then
  					self.db.profile.itemcooldowns[name].start = start
					if self.db.profile.autogroup then
						local index = floor(start * duration);
							if not cooldowns[index] then 
								cooldowns[index] = new();
								cooldowns[index].name = name;
								cooldowns[index].item = self.db.profile.itemcooldowns[name];
								cooldowns[index].duration = duration;
							end
							if self.lastitem and string.find(link, self.lastitem, 1, true) then
								cooldowns[index].name = name;
								cooldowns[index].item = self.db.profile.itemcooldowns[name];
							end
					else
						self:SetUpBar(name, self.db.profile.itemcooldowns[name], duration)
					end
				end
			end
		end
	end
	for k,v in pairs(cooldowns) do
		self:SetUpBar(v.name, v.item, v.duration);
		del(cooldowns[k]);
	end
		del(cooldowns);
end

function CooldownTimers:PopulateCooldowns()
	local i = 1
	local cooldown = GetSpellName(i, BOOKTYPE_SPELL)
	local last
	while cooldown do
		if cooldown ~= last then
			last = cooldown
			CDTTooltipTextRight2:SetText("")
			CDTTooltipTextRight3:SetText("")
			CDTTooltipTextRight4:SetText("")
			CDTTooltipTextRight5:SetText("")
			self.tooltip:SetSpell(i, BOOKTYPE_SPELL)
			
			if (CDTTooltipTextRight2:GetText() and (df:Deformat(CDTTooltipTextRight2:GetText(), SPELL_RECAST_TIME_MIN) or df:Deformat(CDTTooltipTextRight2:GetText(), SPELL_RECAST_TIME_SEC)))
			or (CDTTooltipTextRight3:GetText() and (df:Deformat(CDTTooltipTextRight3:GetText(), SPELL_RECAST_TIME_MIN) or df:Deformat(CDTTooltipTextRight3:GetText(), SPELL_RECAST_TIME_SEC)))
			or (CDTTooltipTextRight4:GetText() and (df:Deformat(CDTTooltipTextRight4:GetText(), SPELL_RECAST_TIME_MIN) or df:Deformat(CDTTooltipTextRight4:GetText(), SPELL_RECAST_TIME_SEC))) 
			or (CDTTooltipTextRight5:GetText() and (df:Deformat(CDTTooltipTextRight5:GetText(), SPELL_RECAST_TIME_MIN) or df:Deformat(CDTTooltipTextRight5:GetText(), SPELL_RECAST_TIME_SEC))) then
				if ((not self.db.class.cooldowns[cooldown]) and (self.db.profile.autogroup or not self.db.class.skillgroups[cooldown])) then
					self.db.class.cooldowns[cooldown] = {
						["start"] = 0,
						["id"] = i,
						["icon"] = GetSpellTexture(i, BOOKTYPE_SPELL),
						["group"] = "CDT",
					}
				elseif not self.db.profile.autogroup and self.db.class.skillgroups[cooldown] and not self.db.class.cooldowns[self.db.class.skillgroups[cooldown]] then
					self.db.class.cooldowns[self.db.class.skillgroups[cooldown]] = {
						["start"] = 0,
						["id"] = i,
						["icon"] = GetSpellTexture(i, BOOKTYPE_SPELL),
						["group"] = "CDT",
					}
				elseif self.db.class.cooldowns[cooldown] then
					self.db.class.cooldowns[cooldown].id = i
				elseif not self.db.profile.autogroup and self.db.class.skillgroups[cooldown] and self.db.class.cooldowns[self.db.class.skillgroups[cooldown] ] then
					self.db.class.cooldowns[self.db.class.skillgroups[cooldown] ].id = i
				end
				--Disabled until I can figure out why it is bugging out
				if cooldown == L["Preparation"] or cooldown == L["Readiness"] or cooldown == L["Cold Snap"] then
					self.reset = cooldown
				end
			end
		end
		i = i + 1
		cooldown = GetSpellName(i, BOOKTYPE_SPELL)
	end
	if UnitExists("pet") then
		self:PopulatePetCooldowns()
	end
	self:SPELL_UPDATE_COOLDOWN()
	self:BAG_UPDATE_COOLDOWN()
end

function CooldownTimers:UNIT_PET()
	if arg1 ~= "player" then
		return
	end
	self:PopulatePetCooldowns()
end

function CooldownTimers:PopulatePetCooldowns()
	self:RegisterEvent("PET_BAR_UPDATE_COOLDOWN")
	local i = 1
	local cooldown = GetSpellName(i, BOOKTYPE_PET)
	local last
	if self.db.profile.groups.PetCooldowns == nil then
		self.db.profile.groups.PetCooldowns = {}
		self:MakeAnchor("PetCooldowns", self.db.profile.groups.PetCooldowns)
	end
	while cooldown do
		if cooldown ~= last then
			--self:Print(cooldown)
			last = cooldown
			CDTTooltipTextRight2:SetText("")
			CDTTooltipTextRight3:SetText("")
			self.tooltip:SetSpell(i, BOOKTYPE_PET)
				
			if (CDTTooltipTextRight2:GetText() and (df:Deformat(CDTTooltipTextRight2:GetText(), SPELL_RECAST_TIME_MIN) or df:Deformat(CDTTooltipTextRight2:GetText(), SPELL_RECAST_TIME_SEC)))
			or (CDTTooltipTextRight3:GetText() and (df:Deformat(CDTTooltipTextRight3:GetText(), SPELL_RECAST_TIME_MIN) or df:Deformat(CDTTooltipTextRight3:GetText(), SPELL_RECAST_TIME_SEC))) then

				if not self.db.char.petcooldowns[cooldown] then
					self.db.char.petcooldowns[cooldown] = {
						["start"] = 0,
						["id"] = i,
						["icon"] = GetSpellTexture(i, BOOKTYPE_PET),
					}
					if not self.db.profile.groups.PetCooldowns.disabled then
						self.db.char.petcooldowns[cooldown].group = "PetCooldowns"
					else
						self.db.char.petcooldowns[cooldown].group = "CDT"
					end
				elseif self.db.char.petcooldowns[cooldown] then
					self.db.char.petcooldowns[cooldown].id = i
				end
			end
		end
		i = i + 1
		cooldown = GetSpellName(i, BOOKTYPE_PET)
	end
	self:PET_BAR_UPDATE_COOLDOWN()
end

function CooldownTimers:PET_BAR_UPDATE_COOLDOWN()
	local start, duration, enable, name
	for k, v in pairs(self.db.char.petcooldowns) do
		name = GetSpellName(v.id, BOOKTYPE_PET)
		if not v.disabled and k == name then
			start, duration, enable = GetSpellCooldown(v.id, BOOKTYPE_PET)
			if enable == 1 and duration > self.db.profile.mintime and duration <= self.db.profile.maxtime and v.start ~= start then
				v.start = start
				self:SetUpBar(k, v, duration)
			end
		end
	end
end

function CooldownTimers:UNIT_SPELLCAST_SUCCEEDED(event, player, spell)
	self.lastcast = spell;
		if player ~= "player" or spell ~= self.reset then
			return
		end
	self:ResetCooldowns();
	self:PET_BAR_UPDATE_COOLDOWN();
	self:BAG_UPDATE_COOLDOWN();
end

function CooldownTimers:SetUpBar(skillName, skilloptions, duration)
	local group = self.db.profile.groups[skilloptions.group];
	--if skilloptions.share and next(self.offsets) then
	--	self:SendCommMessage("GROUP", "new", skillName, skilloptions.icon, skilloptions.start, duration);
	--end
	
	local r1, g1, b1 = unpack(self.db.profile.barOptions.colors.colors1)
	local r2, g2, b2 = unpack(self.db.profile.barOptions.colors.colors2)
	

	local colors;
	if skilloptions.colors then
		colors = skilloptions.colors --check
	elseif group.colors then
		local gr1, gg1, gb1 = unpack(group.colors.colors1)
		local gr2, gg2, gb2 = unpack(group.colors.colors2)
		colors = {gr1, gg1, gb1, gr2, gg2, gb2}
	else
		colors = {r1, g1, b1, r2, g2, b2}
	end

	if self.bars[skillName] then
		self:StopCandyBar(self.bars[skillName])
	end
	
	if group.collapse or (group.collapse == nil and self.db.profile.barOptions.collapse) then
		local barname = "cdt-"..skillName
		if not self:IsCandyBarRegistered(barname) then
			self:RegisterCandyBar(barname, duration, skilloptions.name or skillName, skilloptions.icon, unpack(colors))
		end
		self:RegisterCandyBarWithGroup(barname, skilloptions.group)
		self:SetCandyBarTexture(barname, SM:Fetch("statusbar", skilloptions.texture or group.texture or self.db.profile.barOptions.texture))
		self:SetCandyBarWidth(barname, group.barwidth or self.db.profile.barOptions.barwidth)
		self:SetCandyBarHeight(barname, group.barheight or self.db.profile.barOptions.barheight)
		self:SetCandyBarScale(barname, group.scale or self.db.profile.barOptions.scale)
		self:SetCandyBarFade(barname, skilloptions.fade or group.fade or self.db.profile.barOptions.scale)
		self:StartCandyBar(barname)
		self:SetCandyBarTimeLeft(barname, duration - (GetTime() - skilloptions.start))
		self:SetCandyBarCompletion(barname, self.BarComplete, self, skillName, skilloptions.icon)
		self.bars[skillName] = barname
	else
		local i = 1
		while select(1, self:CandyBarStatus("cdt-group-"..skilloptions.group..i)) and select(4, self:CandyBarStatus("cdt-group-"..skilloptions.group..i)) do
			i = i + 1
		end
		local barname = "cdt-group-"..skilloptions.group..i
		--self:Print(barname);
		if not self:IsCandyBarRegistered(barname) then
			self:RegisterCandyBar(barname, 0, "-", "-", unpack(colors))
		end
		self:SetCandyBarTexture(barname, SM:Fetch("statusbar", skilloptions.texture or group.texture or self.db.profile.barOptions.texture))
		self:SetCandyBarPoint(barname, self:GetOffSet(i, group, skilloptions.group))
		self:SetCandyBarWidth(barname, group.barwidth or self.db.profile.barOptions.barwidth)
		self:SetCandyBarHeight(barname, group.barheight or self.db.profile.barOptions.barheight)
		self:SetCandyBarScale(barname, group.scale or self.db.profile.barOptions.scale)
		self:SetCandyBarTime(barname, duration)
		self:SetCandyBarIcon(barname, skilloptions.icon)
		self:SetCandyBarText(barname, skilloptions.name or skillName)
		self:SetCandyBarFade(barname, skilloptions.fade or group.fade or self.db.profile.barOptions.fade)
		self:StartCandyBar(barname)
		self:SetCandyBarTimeLeft(barname, duration - (GetTime() - skilloptions.start))
		self:SetCandyBarCompletion(barname, self.BarComplete, self, skillName, skilloptions.icon)
		self.bars[skillName] = barname
	end
end

function CooldownTimers:GetOffSet(bar, group, groupName)
	local column = (math.fmod(bar-1, group.columns or self.db.profile.barOptions.columns)) * ((group.barheight or self.db.profile.barOptions.barheight) + (group.barwidth or self.db.profile.barOptions.barwidth) + (group.bargap or self.db.profile.barOptions.bargap))
	local height = (math.floor((bar-1)/(group.columns or self.db.profile.barOptions.columns))) * ((group.barheight or self.db.profile.barOptions.barheight) + (group.bargap or self.db.profile.barOptions.bargap))
	local point = "BOTTOM"
	if (group.up == nil and not self.db.profile.barOptions.up) or (group.up == false) then
		height = -height
		point = "TOP"
	end
	return point, self.anchors[groupName]:GetName(), "BOTTOM", column, height
end

function CooldownTimers:KillAllBars()
	for k,v in pairs(self.bars) do
		self:StopCandyBar(v)
		self:SetCandyBarCompletion("cdt-"..k, self.BarComplete, self, k)
	end
end

function CooldownTimers:FixGroups()
	for k,v in pairs(self.db.class.cooldowns) do
		if not v.group or not self.db.profile.groups[v.group] or self.db.profile.groups[v.group].disabled then
			self:Print(k,L["moved from group"],v.group,L["to"],"CDT")
			v.group = "CDT"
		end
	end
	for k,v in pairs(self.db.char.petcooldowns) do
		if not v.group or not self.db.profile.groups[v.group] or self.db.profile.groups[v.group].disabled then
			self:Print(k,L["moved from group"],v.group,L["to"],"CDT")
			v.group = "CDT"
		end
	end
	for k,v in pairs(self.db.profile.itemcooldowns) do
		if not v.group or not self.db.profile.groups[v.group] or self.db.profile.groups[v.group].disabled then
			self:Print(k,L["moved from group"],v.group,L["to"],"CDT")
			v.group = "CDT"
		end
	end
end


function CooldownTimers:BarComplete(skill, icon)
	self.bars[skill] = nil
	for k,v in pairs(self.baralphas) do
		self.baralphas[k][v] = nil
		self.baralphas[k] = nil
	end
	self:UnregisterCandyBar("cdt-"..skill)
	if not self.db.profile.announce.enabled then
		return
	end
	
	self.queue:push(skill,icon);
	self.pulse:Show();
end

-- Some of this is so stolen from Jim's Cooldown Pulse.  Thanks JIM!

--[[
--  Flash each icon in the queue of cooldown that are compleate
--  Animates a puluse by quickly fading a spell or ablity image in and out
--  All ablities in the queue should need their ablity flashed as soon as possible
--]]

-- Hard coded for now

function CooldownTimers:AnimatePulse(config)
	local now = GetTime()
	local anim = self.pulse.animating and (now - self.pulse.pulsedAt)
	local db = self.db.profile.pulse;
	--self:Print("AnimatePulse called")
	--Need to loop though the queue here and set the icon of the self.pulse.frame
	--[[ Animation progress: anim records not the current time, but the progress of the animation in seconds.
	 Based on this value, the effect's "alpha" can be set so that its image appears to be pulsing to the sound of a heartbeat.

	  This entire function is called however often your Frames Per Second permit,
	  so computers with more memory and faster video cards will get smoother animations!
	  I say that like it's a good thing, but really I should tone down the frequency of this function.
	  --]]
	if ( anim ) then
		--self:Print("Animating")
		local fadeout = (not self.queue.isEmpty and db.fadeout) or db.min; -- use min time if stuffs in the queue
		self.pulse:SetAlpha(( anim < db.fadein ) and anim * db.alpha / db.fadein --fade in
      or	( anim < fadeout )	and ( fadeout - anim ) * db.alpha / ( fadeout )-- pulse fade out
      or	0	-- animation over
    )

		if ( anim >= fadeout ) then
			self.pulse.pulsedAt= nil
			self.pulse.animating= false
		  --self:Print("Ending animation")
		end
		elseif not self.queue.isEmpty then
			local skill,icon = self.queue:pop();
			local hex = format("%02x%02x%02x", self.db.profile.announce.spellcolor[1]*255, self.db.profile.announce.spellcolor[2]*255, self.db.profile.announce.spellcolor[3]*255)
			--self:Print(hex)
			self.announce.text:SetText(format(self.db.profile.announce.announceString, '|cff'..hex..skill..'|r'))
			self.announce.last = GetTime();
			self.announce.alpha = 1;
			self.announce.frame:Show();
			self.pulse.animating = true
			self.pulse.pulsedAt = now
			self.pulse:SetNormalTexture(icon)
    
		if self.db.profile.sound then
			PlaySound("Deathbind Sound")
		end
		elseif config then
			self.pulse.pulsedAt = GetTime();
			self.pulse.animating = true;
		else
			self.pulse:Hide();
		end
end