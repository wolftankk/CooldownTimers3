local _, cdt = ...;
cdt = LibStub("AceAddon-3.0"):NewAddon(cdt, "CooldownTimers3", "AceEvent-3.0", "AceComm-3.0", "AceSerializer-3.0", "AceHook-3.0", "AceConsole-3.0");
local CallbackHandler = LibStub("CallbackHandler-1.0");
cdt.version = GetAddOnMetadata("CooldownTimers3", "version");
cdt.reversion = tonumber(("$Revision: 39$"):match("%d+"));
local L = LibStub("AceLocale-3.0"):GetLocale("CooldownTimers3");
local candy = LibStub("LibCandyBar-3.0");
local SM = LibStub("LibSharedMedia-3.0")
local LDB = LibStub("LibDataBroker-1.1", true);
local icon = LibStub("LibDBIcon-1.0", true);
local db;
local barlist = {}

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

local _, pclass = UnitClass("player");
cdt.pclass = pclass;

local abs = math.abs;
local GetTime = GetTime;
local CreateFrame = CreateFrame;
local format = string.format;
local gsub = string.gsub;

local defaults = {
    profile = {
        enabled = true,
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
        minimap = {
            hide = false,
        }
    },
    char = {
        ["petcooldowns"] = {},
    },
    class = {}
}

function cdt:OnInitialize()
    --update class data  
    --[[if pclass == "HUNTER" then

    elseif pclass == "SHAMAN" then

    elseif pclass == "PALADIN" then

    else]]
        defaults["class"]["cooldowns"] = {}
        defaults["class"]["skillgroups"] = {};
    --end


    self.db = LibStub("AceDB-3.0"):New("CooldownTimersDB", defaults, "Default");
    db = self.db.profile;

    self.db.RegisterCallback(self, "OnProfileChanged", "OnProfileChanged");
    self.db.RegisterCallback(self, "OnProfileReset", "OnProfileChanged");
    self.db.RegisterCallback(self, "OnProfileCopied", "OnProfileChanged");
    
    SM:Register("statusbar", "Smooth", "Interface\\AddOns\\CooldownTimers3\\textures\\smooth");
    SM:Register("statusbar", "Cilo", "Interface\\AddOns\\CooldownTimers3\\textures\\cilo");
    SM:Register("statusbar", "BantoBar", "Interface\\AddOns\\CooldownTimers3\\textures\\bar");

    self.callbacks = CallbackHandler:New(self);

    self:CreateLDB();
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
    return s, t
end

function cdt:OnEnable()
    self:RegisterEvent("SPELL_UPDATE_COOLDOWN");  
    self:RegisterEvent("PLAYER_ALIVE", "PopulateCooldowns");
    self:RegisterEvent("SPELLS_CHANGED", "PopulateCooldowns");
    self:RegisterEvent("PLAYER_ENTERING_WORLD");
    self:RegisterEvent("BAG_UPDATE_COOLDOWN");
    self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED");
    if db.pulseoncooldown then
        self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", "OnSpellFail");
    end
    self:RegisterEvent("PARTY_MEMBERS_CHANGED", "Party");
    self:RegisterEvent("UNIT_PET");

    candy.RegisterCallback(self, "LibCandyBar_Stop", "barStopped");
    --cdt.RegisterCallback(self, "OnCommNew");
    --cdt.RegisterCallback(self, "OnCommOffset");

    local tooltip = CreateFrame("GameTooltip", "CDTTooltip", UIParent, "GameTooltipTemplate");
    tooltip:SetOwner(UIParent, "ANCHOR_NONE");
    self.tooltip = tooltip;

    self.anchors = {};
    for k, v in pairs(db.groups) do
        self:CreateGroupHeader(k, v)
    end
    self:FixGroups();
    
    self.bars = {};
    self.baralphas = {};
    
    self.queue = {first = 1, last = -1, isEmpty = true};
    self.queue.push = qpush;
    self.queue.qpop = qpop;

    if not self.announce then
        --self:MakeAnnounce();
    end
    if db.autogroup then
        self:SecureHook("UseAction");
        self:SecureHook("UseContainerItem");
        self:SecureHook("UseInventoryItem");
        self:SecureHook("UseItemByName");
    end

    --sync your cooldown data
    self:RegisterComm("CooldownTimers3");
    self.offsets = {}
    self.lastsend = 0;
end

function cdt:OnDisable()
    self:UnregisterAllEvents();
end

function cdt:OnProfileChanged()

end

function cdt:CreateLDB()
    local cdtLDB;
    if LDB then
        cdtLDB = LDB:NewDataObject("CooldownTimers3", {
            type = "data source",
            text = "CooldownTimers3",
            icon = "Interface\\Icons\\INV_Misc_PocketWatch_02",
            OnClick = function()

            end,
            OnEnter = function(self)
                GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT");
                GameTooltip:AddLine("CooldownTimers3");
                GameTooltip:AddLine("Open CooldownTimers3 configure panel");
                GameTooltip:Show();
            end,
            OnHide = function(self)
                GameTooltip:Hide();
            end
        })
    end

    if icon and cdtLDB then
        icon:Register("CooldownTimers3", cdtLDB, db.minimap);
    end
end

---------------------------------------------------------------
-- comm handling
function cdt:SendComm(...)
    self:SendCommMessage("CooldownTimers3", self:Serialize(...), "PARTY", nil, "ALERT");
end

local function dispatchComm(sender, ok, commType, ...)
    if ok and type(commType) == "string" then
        cdt.callbacks:Fire("OnComm"..commType, sender, ...);
    end
end

function cdt:OnCommReceived(prefix, message, distribution, sender)
    if db.groups.GroupCooldowns.disabled then return end
    dispatchComm(sender, self:Deserialize(message))
end

function cdt:OnCommOffset(commType, sender, offset)
    if not self.offsets[sender] then
        self.offsets[sender] = new();
        self.offsets[sender].offset = 0;
        self.offsets[sender].x = 0;
    end
    offset = offset - GetTime() + select(3, GetNetStats())/1000;
    if abs(self.offsets[sender].offset - offset) > 3 * (select(3, GetNetStats()) / 1000) then
        self.offsets[sender].x = 1;
        self.offsets[sender].offset = offset;
    else
        self.offsets[sender].offset = (self.offsets[sender].offset * self.offsets[sender].x + offset)/(self.offsets[offset].x + 1);
        self.offsets[sender].x = self.offsets[sender].x + 1;
    end
    
    --"cdt-req-sender"
    if self.offsets[sender].x < 5 then
    elseif self.offsets[sender].x >= 5 then
    end
end

function cdt:OnCommNew(commType, sender, skillName, skillIcon, start, duration)
    if not db.groupcooldowns[skillName] then
        db.groupcooldowns[skillName] = new();
        db.groupcooldowns[skillName].icon = skillIcon;
        db.groupcooldowns[skillName].start = 0;
        db.groupcooldowns[skillName].group = "GroupCooldowns";
    end

    if not db.groupcooldowns[skillName].disabled then
        db.groupcooldowns[skillName].icon = skillIcon;
        db.groupcooldowns[skillName].start = start + self.offsets[sender].offset;
        self:SetUpBar(sender.." - "..skillName, db.groupcooldowns[skillName], duration);
    end
end

function cdt:OnCommKill()

end

function cdt:OnCommReqoffsets()

end

-----------------------------------------------------------
-- hook
function cdt:UseAction(slot)
    local item, id = GetActionInfo(slot);
    if item == "item" then
        self.lastitem = id;
    end
end

function cdt:UseContainerItem(bag, slot)
    self.lastitem = GetContainerItemLink(bag, slot)
end

function cdt:UseInventoryItem(slot)
    self.lastitem = GetInventoryItemLink("player", slot);
end

function cdt:UseItemByName(name)
    self.lastitem = name
end

-----------------------------------------------------------
--event
function cdt:PLAYER_ENTERING_WORLD()
    self:ResetCooldowns();
    if GetNumPartyMembers() > 0 then
        self:Party();
    end
end

function cdt:Party()
    if GetNumPartyMembers() > 0 and abs(GetTime() - self.lastsend) > 3 then
        self.lastsend = GetTime();
        self:SendComm("offset", GetTime());
    else
        for k, v in pairs(self.offsets) do
            self.offsets[k] = del(v)
        end
    end
end

function cdt:SPELL_UPDATE_COOLDOWN()
    local start, duration, enable, name;
    local cooldowns = new();

    for k, v in pairs(self.db.class.cooldowns) do
        name = GetSpellBookItemName(v.id, BOOKTYPE_SPELL);
        if not v.disabled and (k == name or k == self.db.class.skillgroups[name]) then
            start, duration, enable = GetSpellCooldown(v.id, BOOKTYPE_SPELL);
            if enable == 1 and duration > db.mintime and duration <= db.maxtime and v.start ~= start then
                v.start = start;
                if db.autogroup then
                    local index = floor(start * duration);
                    if not cooldowns[index] then
                        cooldowns[index] = new();
                        cooldowns[index].name = k;
                        cooldowns[index].spell = v;
                        cooldowns[index].duration = duration;
                    end
                    if name == self.lastcast then
                        cooldowns[index].name = name;
                        cooldowns[index].spell = v;
                    end
                else
                    self:SetUpBar(name, db.itemcooldowns[name], duration); 
                end
            end
        end
    end
    for k, v in pairs(cooldowns) do
        self:SetUpBar(v.name, v.spell, v.duration);
        del(cooldowns[k])
    end
    del(cooldowns);
end

function cdt:BAG_UPDATE_COOLDOWN()
    local solts, id, name, start, duration, enable, link, _;
    local cooldowns = new();
    for i = 1, 18 do
        start, duration, enable = GetInventoryItemCooldown("player", i);
        if enable == 1 and duration > db.mintime and duration <= db.maxtime then
            link = GetInventoryItemLink("player", i);
            _, _, name = string.find(link, "Hitem[^|]+|h%[([^[]+)%]");
            if db.itemgroups[name] then
                name = db.itemgroups[name]
            end
            if not db.itemcooldowns[name] then
                db.itemcooldowns[name] = {
                    ["disabled"] = false,
                    ["icon"] = GetInventoryItemTexture("player", i);
                }
                if not db.groups.ItemCooldowns.disabled then
                    db.itemcooldowns[name].group = "ItemCooldowns";
                else
                    db.itemcooldowns[name].group = "CDT";
                end
            end

            if not db.itemcooldowns[name].disabled and db.itemcooldowns[name].start ~= start then
                db.itemcooldowns[name].start = start;
                if db.autogroup then
                    local index = floor(start * duration);
                    if not cooldowns[index] then
                        cooldowns[index] = new();
                        cooldowns[index].name = name;
                        cooldowns[index].item = db.itemcooldowns[name];
                        cooldowns[index].duration = duration
                    end

                    if self.lastitem and strfind(link, self.lastitem, 1, true) then
                        cooldowns[index].name = name;
                        cooldowns[index].item = db.itemcooldowns[name];
                    end
                else
                    self:SetUpBar(name, db.itemcooldowns[name], duration);
                end
            end
        end
    end

    for bag = 0, 4 do
        slots = GetContainerNumSlots(bag);
        for s = 1, slots do
            start, duration, enable = GetContainerItemCooldown(bag, s);
            if enable == 1 and duration > db.mintime and duration <= db.maxtime then
                link = GetContainerItemLink(bag, s);
                _, _, name = strfind(link, "Hitem[^|]+|h%[([^[]+)%]");
                if db.itemgroups[name] then
                    name = db.itemgroups[name]
                end
                if not db.itemcooldowns[name] then
                    db.itemcooldowns[name] = {
                        ["disabled"] = false,
                        ["icon"] = GetContainerItemInfo(bag, s);
                    }
                    if not db.groups.ItemCooldowns.disabled then
                        db.itemcooldowns[name].group = "ItemCooldowns";
                    else
                        db.itemcooldowns[name].group = "CDT";
                    end
                end

                if not db.itemcooldowns[name].disabled and db.itemcooldowns[name].start ~= start then
                    db.itemcooldowns[name].start = start;
                    if db.autogroup then
                        local index = floor(start * duration);
                        if not cooldowns[index] then
                            cooldowns[index] = new();
                            cooldowns[index].name = name;
                            cooldowns[index].item = db.itemcooldowns[name];
                            cooldowns[index].duration = duration;
                        end
                        if self.lastitem and strfind(link, self.lastitem, 1, true) then
                            cooldowns[index].name = name;
                            cooldowns[index].item = db.itemcooldowns[name];
                        end
                    else
                        self:SetUpBar(name, db.itemcooldowns[name], duration);
                    end
                end
            end
        end
    end

    for k, v in pairs(cooldowns) do
        self:SetUpBar(v.name, v.item, v.duration)
        del(cooldowns[k]);
    end
    del(cooldowns)
end

function cdt:UNIT_SPELLCAST_SUCCEEDED(unit, spell)
    self.lastcast = spell;
    if unit ~= "player" or spell ~= self.reset then
        return
    end
    self:ResetCooldowns();
    self:PET_BAR_UPDATE_COOLDOWN();
    self:BAG_UPDATE_COOLDOWN();
end

function cdt:ResetCooldowns()
    self:KillAllBars();
    for k, v in pairs(self.db.class.cooldowns) do
        v.start = 0;
    end
    for k, v in pairs(self.db.char.petcooldowns) do
        v.start = 0;
    end
    for k, v in pairs(db.itemcooldowns) do
        v.start = 0;
    end

    self:SPELL_UPDATE_COOLDOWN();
    self:BAG_UPDATE_COOLDOWN();
    if UnitExists("pet") then
        self:PET_BAR_UPDATE_COOLDOWN();
    end
end

local function checkRight(rtip)
    local cooldown1 = gsub(SPELL_RECAST_TIME_MIN, "%%%.%d[fg]", "(.+)");
    local cooldown2 = gsub(SPELL_RECAST_TIME_SEC, "%%%.%d[fg]", "(.+)");
    local t = rtip and rtip:GetText();
    if t and (strmatch(t, cooldown1) or strmatch(t, cooldown2)) then
        return true
    end
end

function cdt:PopulateCooldowns()
    local i = 1;
    local cooldown = GetSpellBookItemName(i, BOOKTYPE_SPELL);
    local last;
    local tooltip = self.tooltip;
    local GetSpellBookItemName = GetSpellBookItemName;
    local cooldowns = self.db.class.cooldowns; 
    
    while cooldown do
        if cooldown ~= last then
            last = cooldown;
            CDTTooltipTextRight2:SetText("");
            CDTTooltipTextRight3:SetText("");
            CDTTooltipTextRight4:SetText("");
            CDTTooltipTextRight5:SetText("");
            tooltip:SetSpellBookItem(i, BOOKTYPE_SPELL);
            if (checkRight(CDTTooltipTextRight2) or checkRight(CDTTooltipTextRight3) or checkRight(CDTTooltipTextRight4) or checkRight(CDTTooltipTextRight4) or checkRight(CDTTooltipTextRight5)) then
                if ((not cooldowns[cooldown]) and (db.autogroup or not self.db.class.skillgroups[cooldown])) then
                    cooldowns[cooldown] = {
                        ["start"] = 0,
                        ["id"] = i,
                        ["icon"] = GetSpellBookItemTexture(i, BOOKTYPE_SPELL),
                        ["group"] = "CDT"
                    }
                elseif not db.autogroup and self.db.class.skillgroups[cooldown] and not cooldowns[self.db.class.skillgroups[cooldown]] then
                    cooldowns[self.db.class.skillgroups[cooldown]] = {
                        ["start"] = 0,
                        ["id"] = i,
                        ["icon"] = GetSpellBookItemTexture(i, BOOKTYPE_SPELL),
                        ["group"] = "CDT"
                    }
                elseif cooldowns[cooldown] then
                    cooldowns[cooldown].id = i;
                elseif not db.autogroup and self.db.class.skillgroups[cooldown] and cooldowns[self.db.class.skillgroups[cooldown]] then
                    cooldowns[self.db.class.skillgroups[cooldown]].id = i;
                end
            end
        end
        i = i + 1;
        cooldown = GetSpellBookItemName(i, BOOKTYPE_SPELL);
    end

    db.cooldowns = cooldowns;

    if UnitExists("pet") then
        self:PopulatePetCooldowns();
    end
    self:SPELL_UPDATE_COOLDOWN();
    self:BAG_UPDATE_COOLDOWN();
end

function cdt:UNIT_PET(unit)
    if unit ~= "player" then
        return
    end
    self:PopulatePetCooldowns();
end

function cdt:PET_BAR_UPDATE_COOLDOWN()
    local start, duration, enable, name;
    for k, v in pairs(self.db.char.petcooldowns) do
        name = GetSpellBookItemName(v.id, BOOKTYPE_PET);
        if not v.disabled and k == name then
            start, duration, enable = GetSpellCooldown(v.id, BOOKTYPE_PET);
            if enable == 1 and duration > db.mintime and duration <= db.maxtime and v.start ~= start then
                v.start = start;
                self:SetUpBar(k, v, duration);
            end
        end
    end
end

function cdt:PopulatePetCooldowns()
    self:RegisterEvent("PET_BAR_UPDATE_COOLDOWN");
    local i = 1;
    local cooldown = GetSpellBookItemName(i, BOOKTYPE_PET);
    local last;
    if db.groups.PetCooldowns == nil then
        db.groups.PetCooldowns = {};
        self:CreateGroupHeader("PetCooldowns", db.groups.PetCooldowns)
    end

    while cooldown do
        if cooldown ~= last then
            last = cooldown;
            CDTTooltipTextRight2:SetText("");
            CDTTooltipTextRight3:SetText("");
            self.tooltip:SetSpellBookItem(i, BOOKTYPE_PET);
            if (checkRight(CDTTooltipTextRight2)) or (checkRight(CDTTooltipTextRight3)) then
                if not self.db.char.petcooldowns[cooldown] then
                    self.db.char.petcooldowns[cooldown] = {
                        start = 0,
                        id = i,
                        icon = GetSpellBookItemTexture(i, BOOKTYPE_PET)
                    }
                    if not db.groups.PetCooldowns.disabled then
                        self.db.char.petcooldowns[cooldown].group = "PetCooldowns";
                    else
                        self.db.char.petcooldowns[cooldown].group = "CDT";
                    end
                elseif self.db.char.petcooldowns[cooldown] then
                    self.db.char.petcooldowns[cooldown].id = i;
                end
            end
        end
        i = i + 1;
        cooldown = GetSpellBookItemName(i, BOOKTYPE_PET);
    end
    self:PET_BAR_UPDATE_COOLDOWN();
end

function cdt:OnSpellFail()

end

-----------------------------------------------------
-- bar handling
-----auto adjust bar position

local function barSorter(a, b)
    return a.remaining < b.remaining and true or false;
end

local function gradientBar(bar)

end

local function rearrangeBars()
    local tmp = new();
    for k, v in pairs(barlist) do
        tmp[#tmp + 1] = v;
    end
    table.sort(tmp, barSorter);
    local lastBar = {};
    for i, bar in next, tmp do
        bar:ClearAllPoints();
        bar:Hide();
        local g = bar:Get("group");
        if not lastBar[g] then
            bar:SetPoint("BOTTOM", cdt.anchors[g], 0, -15);  
        else
            bar:SetPoint("TOPLEFT", lastBar[g], "BOTTOMLEFT");
            bar:SetPoint("TOPRIGHT", lastBar[g], "BOTTOMRIGHT");
        end
        lastBar[g] = bar;
        bar:Show();
    end
    del(tmp);
end

function cdt:SetUpBar(skillName, skillOptions, duration)
    local group = db.groups[skillOptions.group];
    if skillOptions.share and next(self.offsets) then
        self:SendComm("New", skillName, skillOptions.icon, skillOptions.start, duration);
    end

    local r1, g1, b1 = unpack(self.db.profile.barOptions.colors.colors1)
    local r2, g2, b2 = unpack(self.db.profile.barOptions.colors.colors2)
    local colors;

    if skillOptions.colors then
        colors = skillOptions.colors
    elseif group.colors then
        local gr1, gg1, gb1 = unpack(group.colors.colors1);
        local gr2, gg2, gb2 = unpack(group.colors.colors2);
        colors = {gr1, gg1, gb1, gr2, gg2, gb2};
    else
        colors = {r1, g1, b1, r2, g2, b2};  
    end

    if self.bars[skillName] then
        barlist[self.bars[skillName]]:Stop();
    end
    
    if group.collapse or (group.collapse == nil and db.barOptions.collapse) then
        local barname = "cdt-"..skillName;
        if not barlist[barname] then
            local barwidth = group.barwidth or db.barOptions.barwidth;
            local barheight = group.barheight or db.barOptions.barheight;
            local bartexture = SM:Fetch("statusbar", skillOptions.texture or group.texture or db.barOptions.texture);
            barlist[barname] = candy:New(bartexture, barwidth, barheight);
        end
        local bar = barlist[barname];
        --set bar attribute
        bar:Set("group", skillOptions.group);
        bar:Set("colors", colors);
        bar:Set("barName", barname);
        bar:Set("skillName", skillName or skillOptions.name);
        bar:Set("fade", 1);
        bar:SetScale(group.scale or db.barOptions.scale); 
        bar:SetIcon(skillOptions.icon);
        bar:SetDuration(duration);
        bar:SetTimeVisibility(true);
        bar:SetLabel(skillOptions.name or skillName);
        bar:SetColor(unpack(colors));
        --add update func
        --bar:AddUpdateFunction();
        bar:Start();
        self.bars[skillName] = barname;
    else
       --create a new candy bar 
       print(123131)
    end
    
    rearrangeBars();
end

--create group frame
local SavePosition, OnAnchorClick, ShowAnchorTooltip, LockAnchor
do
    function SavePosition(group)
        db.groups[group].point, _, db.groups[group].relPoint, db.groups[group].x, db.groups[group].y = cdt.anchors[group]:GetPoint();
    end

    function LockAnchor(group)
        db.groups[group].locked = true;
        cdt.anchors[group]:Hide();
    end

    function ShowAnchorTooltip(f)
	GameTooltip:SetOwner(f, "ANCHOR_BOTTOMRIGHT")
	GameTooltip:AddLine(L["CDT Group Anchor"])
	GameTooltip:AddLine("- "..L["Drag this to reposition"])
	GameTooltip:AddLine("- "..L["Shift+Left Click to hide"])
	GameTooltip:AddLine("- "..L["Alt+Left Click to show a test bar"])
	GameTooltip:AddLine("- "..L["Alt+Left Click again to hide the test bar"])
	GameTooltip:AddLine("- "..L["If you hide this, you can show it again by going to Group Options -> groupname -> Uncheck Lock"])
	GameTooltip:Show()
    end
    
    local testbar;
    function OnAnchorClick(group, altkey)
        if IsAltKeyDown() or altkey then
            --create test bar 
            if testbar then
                testbar:Stop();
                testbar = nil;
                return;
            end
            local bar = candy:New(SM:Fetch("statusbar", db.groups[group].texture or db.barOptions.texture), db.groups[group].barwidth or db.barOptions.barwidth, db.groups[group].barheight or db.barOptions.barheight); 
            bar:SetDuration(30);
            bar:SetScale(1);
            bar:SetIcon("Interface\\Icons\\INV_Misc_QuestionMark");
            bar:SetTimeVisibility(true);
            bar:SetTexture(SM:Fetch("statusbar", db.groups[group].texture or db.barOptions.texture));
            bar:SetLabel("Test bar");
            bar:SetColor(1, 0, 0, 0.6);
            bar:Set("barName", "Testbar");
            bar:Start();
            bar:SetPoint("BOTTOM", cdt.anchors[group], 4, -15);
            bar:Show();
            testbar = bar;
        end

        if IsShiftKeyDown() then
            LockAnchor(group)
        end
    end
end

function cdt:CreateGroupHeader(group, info)
    if info.disabled then
        return;
    end
    local f = CreateFrame("Frame", nil, UIParent);
    f:ClearAllPoints();
    f:SetBackdrop({
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

    if not info.x then
        info.x = 0;
        info.y = 0;
        info.relPoint = "CENTER";
        info.point = "CENTER";
    end

    f:SetSize(128, 30);
    f:SetBackdropColor(0.1, 0.1, 0.1, 0.6);
    f:EnableMouse(true);
    f:SetPoint(info.point, UIParent, info.relPoint, info.x, info.y);
    local msg = f:CreateFontString(nil, "OVERLAY", "GameFontNormal");
    msg:ClearAllPoints();
    msg:SetPoint("CENTER", f, "CENTER", 0, 0);
    msg:SetText(group);
    f:SetMovable(true);
    f:SetScript("OnDragStart", function(self)
        self:StartMoving();
        GameTooltip:Hide();
    end);
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing();
        SavePosition(group);
    end);
    f:SetScript("OnMouseUp", function(self)
        OnAnchorClick(group)
    end);
    
    f:SetScript("OnEnter", function(self)
        ShowAnchorTooltip(self); 
    end)
    
    f:SetScript("OnLeave", function(self)
        GameTooltip:Hide();
    end);
    f:RegisterForDrag("LeftButton");
    
    if db.groups[group].locked or db.groups[group].disabled then
        f:Hide();
    else
        f:Show()
    end

    self.anchors[group] = f;
end

function cdt:FixGroups()

end

function cdt:GetOffset(bar, group, groupName)

end

function cdt:FlashBar()

end

function cdt:KillAllBars()
    for k, v in pairs(barlist) do
        v:Stop();
    end
end

function cdt:barStopped(event, bar)
    local skillName = bar:Get("skillName"); 
    local barName = self.bars[skillName];
    if barlist[barName] then
        barlist[barName] = nil;
        self.bars[skillName] = nil;
        rearrangeBars();
    end
end

--------------------------------------------------
--announce
function cdt:MakeAnnounce()

end

function cdt:LockPluseIcon(locked)

end
