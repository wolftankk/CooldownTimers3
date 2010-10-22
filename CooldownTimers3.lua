local addonName, cdt = ...;
cdt = LibStub("AceAddon-3.0"):NewAddon(cdt, addonName, "AceEvent-3.0", "AceComm-3.0", "AceSerializer-3.0", "AceHook-3.0", "AceConsole-3.0", "AceTimer-3.0");
local CallbackHandler = LibStub("CallbackHandler-1.0");
cdt.version = GetAddOnMetadata(addonName, "version");
cdt.reversion = tonumber(("$Revision$"):match("%d+"));
local L = LibStub("AceLocale-3.0"):GetLocale(addonName);
local candy = LibStub("LibCandyBar-3.0");
local SM = LibStub("LibSharedMedia-3.0")
local LDB = LibStub("LibDataBroker-1.1", true);
local icon = LibStub("LibDBIcon-1.0", true);
local db;
local barlist = {};
local timerlist = {};--for acetimer

local new, del
do
    local list = setmetatable({}, {__mode='k'});
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
                ["colors1"] = {0.9, 0.9, 0.1, 1},
                ["colors2"] = {0.1, 1, 0.09, 1},
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

local function openConfigPanel()
    LibStub("AceConfigDialog-3.0"):SetDefaultSize(addonName, 730, 590)
    LibStub("AceConfigDialog-3.0"):Open(addonName)
end

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

    self.db.RegisterCallback(self, "OnProfileChanged");
    self.db.RegisterCallback(self, "OnProfileReset", "OnProfileChanged");
    self.db.RegisterCallback(self, "OnProfileCopied", "OnProfileChanged");
    
    SM:Register("statusbar", "Smooth", "Interface\\AddOns\\"..addonName.."\\textures\\smooth");
    SM:Register("statusbar", "Cilo", "Interface\\AddOns\\"..addonName.."\\textures\\cilo");
    SM:Register("statusbar", "BantoBar", "Interface\\AddOns\\"..addonName.."\\textures\\bar");

    self.callbacks = CallbackHandler:New(self);

    --add options
    self:SetupOptions();
    self:CreateLDB();

    self:RegisterChatCommand("cdt", openConfigPanel)
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
    self:RegisterEvent("SPELLS_CHANGED", "PopulateCooldowns");--add
    self:RegisterEvent("PLAYER_ALIVE", "PopulateCooldowns");
    self:RegisterEvent("SPELLS_CHANGED", "PopulateCooldowns");
    self:RegisterEvent("PLAYER_ENTERING_WORLD");
    self:RegisterEvent("BAG_UPDATE_COOLDOWN");
    self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED");

    --self:RegisterEvent("UNIT_ENTERED_VEHICLE");
    --
    --if UnitHasVehicleUI("player") then
    --    self:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN"); 
    --    self:RegisterEvent("UNIT_EXITED_VEHICLE");
    --end
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

    --update config
    self:FixGroups();
    
    self.bars = {};
    self.baralphas = {};
    
    self.queue = {first = 0, last = -1, isEmpty = true};
    self.queue.push = qpush;
    self.queue.pop = qpop;

    if not self.announce then
        self:MakeAnnounce();
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

function cdt:OnProfileChanged(key, name)
end

function cdt:CreateLDB()
    local cdtLDB;
    if LDB then
        cdtLDB = LDB:NewDataObject("CooldownTimers3", {
            type = "data source",
            text = "CooldownTimers3",
            icon = "Interface\\Icons\\INV_Misc_PocketWatch_02",
            OnClick = function()
                openConfigPanel();
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
        icon:Register(addonName, cdtLDB, db.minimap);
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
        --self:Fire("OnCommReqoffsets")
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

function cdt:OnCommReqoffsets(commType, sender, ...)
    if not sender or sender == UnitName("player") then
        self:Party()
    end
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
        self:RequestOffsets();
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

function cdt:RequestOffsets(...)

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
                        cooldowns[index].name = k;
                        cooldowns[index].spell = v;
                    end
                else
                    self:SetUpBar(k, v, duration); 
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

    if UnitExists("pet") and HasPetUI() then
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
    if UnitExists("pet") and HasPetUI() then
        self:RegisterEvent("PET_BAR_UPDATE_COOLDOWN");
    else
        self:UnregisterEvent("PET_BAR_UPDATE_COOLDOWN");
    end
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
                if not self.db.char.petcooldowns[cooldown] or (not self.db.char.petcooldowns[cooldown].group) then
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

function cdt:OnSpellFail(event, ...)
    local type, _, _, srcFlag = select(2, ...);
    if ((type ~= "SPELL_CAST_FAILED") or not CombatLog_Object_IsA(srcFlags, COMBATLOG_FILTER_MINE))  then
        return
    end
    local skill, _, reason = select(10, ...);
    if reason ~= SPELL_FAILED_NOT_READY then
        return
    end
    if not db.autogroup and self.db.class.skillgroups[skill] then
        skill = self.db.class.skillgroups[skill]
    end

    if not self.db.class.cooldowns[skill] then return end
    
    local group = db.groups[self.db.class.cooldowns[skill].group];
    local barname = self.bars[skill]; 
    local bar = barlist[barname];
    if self.bars[skill] and not self.baralphas[barname] then
        self.baralphas[barname] = new(1, 0.05);
        timerlist["cdt-flash-"..skill] = self:ScheduleRepeatingTimer("FlashBar", 0.001, {skill, bar, db.barOptions.scale});
    end
end

-----------------------------------------------------
-- bar handling
-----auto adjust bar position
local barSorter, SetGradient, SetFade, barUpdade, rearrangeBars 
do
    function barSorter(a, b)
        return a.remaining < b.remaining and true or false;
    end

    local cachegradient = {};
    function SetGradient(bar, c1, c2, ...)
        if not bar then return end
        local gtable = new();
        local gradientid = nil;
        if type(c1) == "number" then
            local n = select("#", ...);
            gtable[1] = new();
            gtable[1][1] = c1;
            gtable[1][2] = c2;
            gtable[1][3] = select(1, ...);
            gradientid = string.format("%d%d%d", c1, c2, gtable[1][3]);

            for i = 2, n, 3 do
                local r, g, b = select(i, ...);
                if r and g and b then
                    local t = new();
                    t[1], t[2], t[3] = r, g, b;
                    tinsert(gtable, t);
                    gradientid = string.format("%s_%d%d%d", gradientid, r, g, b);
                else
                    break;
                end
            end
        end

        local max = #gtable;
        for i = 1, max do
            if not gtable[i][4] then
                gtable[i][4] = 1
            end
            gtable[i][5] = (i - 1) / (max - 1);
        end

        if bar.gradienttable then
            for k, v in pairs(bar.gradienttable) do
                v = del(v);
            end
            bar.gradienttable = del(bar.gradienttable);
        end

        bar.gradienttable = gtable;
        bar.gradient = true;
        bar.gradientid = gradientid;

        if not cachegradient[gradientid] then
            cachegradient[gradientid] = {}
        end

        bar:SetColor(unpack(gtable[1], 1, 4));
        return true
    end
    
    function SetFade(bar, time)
        bar:Set("fadetime", time);
        bar:Set("fadeout", true);
        bar:Set("stayonscreen", time < 0);
        bar:Set("fading", nil);
    end
    
    function UpdateFade(bar)
        if not bar:Get("fading") then return end
        if bar:Get("stayonscreen") then return end

        if bar:Get("fadeelapsed") > bar:Get("time") then
            bar:Set("fading", nil);
            bar:Set("fade:starttime", nil);
            bar:Set("fade:endtime", 0);
            --bar.candyBarBar:Hide ?
        end
    end

    function barUpdade(bar)
        --gradientBar;
        local colors = bar:Get("colors");
        local r1, g1, b1, r2, g2, b2 = unpack(colors);
        local exp = bar:Get("duration");
        local p = floor((bar.remaining / exp) * 100) / 100;
        if bar.gradient then
            if not cachegradient[bar.gradientid][p] then
                local gstart, gend, gp
                for i = 1, #bar.gradienttable - 1 do
                    if bar.gradienttable[i][5] < p and p <= bar.gradienttable[i+1][5] then
                        gstart = bar.gradienttable[i];
                        gend = bar.gradienttable[i + 1];
                        gp = (p - gstart[5]) / (gend[5] - gstart[5])
                    end
                end
                if gstart and gend then
                    cachegradient[bar.gradientid][p] = new();
                    local i;
                    for i = 1, 4 do
                        cachegradient[bar.gradientid][p][i] = gstart[i]*(1-gp) + gend[i]*(gp)
                    end
                end
            end
            if cachegradient[bar.gradientid][p] then
                bar:SetColor(unpack(cachegradient[bar.gradientid][p], 1, 4));
            end
        end

        --TODO: add fadeout
        --[[if bar:Get("fading") and not bar:Get("stayonscreen") then
            bar:Set("fadeelapsed", bar.remaining);
            UpdateFade(bar);
        end]]
    end

    function rearrangeBars()
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
end
function cdt:SetUpBar(skillName, skillOptions, duration)
    local group = db.groups[skillOptions.group];
    if skillOptions.share and next(self.offsets) then
        self:SendComm("New", skillName, skillOptions.icon, skillOptions.start, duration);
    end
    local r1, g1, b1, a1 = unpack(self.db.profile.barOptions.colors.colors1)
    local r2, g2, b2, a2 = unpack(self.db.profile.barOptions.colors.colors2)
    local colors;

    if skillOptions.colors then
        colors = skillOptions.colors
    elseif group and group.colors then
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
        bar:Set("icon", skillOptions.icon)
        bar:Set("duration", duration + skillOptions.start - GetTime());
        bar:SetScale(group.scale or db.barOptions.scale); 
        bar:SetIcon(skillOptions.icon);
        bar:SetDuration(duration + skillOptions.start - GetTime());
        bar:SetTimeVisibility(true);
        bar:SetLabel(skillOptions.name or skillName);
        SetFade(bar, skillOptions.fade or group.fade or db.barOptions.scale)
        SetGradient(bar, unpack(colors))
        --add update func
        bar:AddUpdateFunction(barUpdade);
        bar:Start();
        self.bars[skillName] = barname;
    else
       --create a new candy bar 
       print("Group Timers bar, coming soon")
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
            local barname = "cdt-test";
            local bar = candy:New(SM:Fetch("statusbar", db.groups[group].texture or db.barOptions.texture), db.groups[group].barwidth or db.barOptions.barwidth, db.groups[group].barheight or db.barOptions.barheight); 
            --barlist[barname] = bar;
            bar:SetDuration(30);
            bar:SetScale(1);
            bar:SetIcon("Interface\\Icons\\INV_Misc_QuestionMark");
            bar:SetTimeVisibility(true);
            bar:SetTexture(SM:Fetch("statusbar", db.groups[group].texture or db.barOptions.texture));
            bar:SetLabel("Test bar");
            bar:SetColor(1, 0, 0, 0.6);
            bar:Set("barName", "Testbar");
            bar:Start();
            --cdt.bars["test"] = barname;
            bar:SetPoint("BOTTOM", cdt.anchors[group], 4, -15);
            --test flash bar
            --[[if cdt.bars["test"] and not cdt.baralphas[barname] then
                cdt.baralphas[barname] = new(1, 0.05);
                timerlist["cdt-flash-test"] = cdt:ScheduleRepeatingTimer(
                "FlashBar", 0.001, {"test", bar, db.barOptions.scale}
            );
            end
            ]]
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
    for k, v in pairs(self.db.class.cooldowns) do
        if not v.group or not db.groups[v.group] or db.groups[v.group].disabled then
            self:Print(k, L["moved from group"], v.group, L["to"], "CDT");
            v.group = "CDT";
        end
    end
    for k, v in pairs(self.db.char.petcooldowns) do
        if not v.group or not db.groups[v.group] or db.groups[v.group].disabled then
            self:Print(k, L["moved from group"], v.group, L["to"], "CDT");
            v.group = "CDT";
        end
    end
    for k, v in pairs(db.itemcooldowns) do
        if not v.group or not db.groups[v.group] or db.groups[v.group].disabled then
            self:Print(k, L["moved from group"], v.group, L["to"], "CDT");
            v.group = "CDT";
        end
    end
end

function cdt:GetOffset(bar, group, groupName)

end

function cdt:FlashBar(args)
    local skill, bar, scale = args[1], args[2], args[3];
    if not self.bars[skill] or not self.baralphas[self.bars[skill]] then
        self:CancelTimer(timerlist["cdt-flash-"..skill], true)
        if self.baralphas[self.bars[skill]] then
            del(self.baralphas[self.bars[skill]]);
            self.baralphas[self.bars[skill]] = nil;
            timerlist["cdt-flash-"..skill] = nil;
        end
    end

    local barname = self.bars[skill];
    self.baralphas[barname][1] = self.baralphas[barname][1] + self.baralphas[barname][2]
    bar:SetScale(self.baralphas[barname][1] * scale);
    if self.baralphas[barname][1] >= 1.5 then
        self.baralphas[barname][2] = -self.baralphas[barname][2]
    elseif self.baralphas[barname][1] <= 1 then
        self:CancelTimer(timerlist["cdt-flash-"..skill], true)
	del(self.baralphas[barname])
	self.baralphas[barname] = nil
	bar:SetScale(scale);
        timerlist["cdt-flash-"..skill] = nil;
    end
end

function cdt:KillAllBars()
    for k, v in pairs(barlist) do
        v:Stop();
    end
end

--CandyBar-3.0: LibCandyBar_Stop callback;
function cdt:barStopped(event, bar)
    local skillName = bar:Get("skillName"); 
    local barName = self.bars[skillName];
    if barlist[barName] then
        barlist[barName] = nil;
        self.bars[skillName] = nil;
        rearrangeBars();
    end
    
    if not db.announce.enabled then
        return
    end
    self.queue:push(skillName, bar:Get("icon"));
    self.pulse:Show();
end

--------------------------------------------------
--announce
function cdt:MakeAnnounce()
    self.announce = {};
    local anchor = CreateFrame("Frame", nil, UIParent);
    anchor:ClearAllPoints();
    anchor:SetPoint(db.announce.point, UIParent, db.announce.relPoint, db.announce.x, db.announce.y);
    anchor:SetBackdrop({
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
    anchor:SetBackdropColor(0.1, 0.1, 0.3);
    anchor:SetWidth(45);
    anchor:SetHeight(45);
    anchor:EnableMouse(true);
    anchor:SetMovable(true);
    anchor:SetScript("OnDragStart", function(self)
        self:StartMoving();
        GameTooltip:Hide();
    end);
    
    anchor:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing();
        db.announce.point, _, db.announce.relPoint, db.announce.x, db.announce.y = self:GetPoint();
    end);

    anchor:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT")
        GameTooltip:AddLine(L["CDT Announce Anchor"])
        GameTooltip:AddLine(L["Drag this to reposition the announcement text."])
        GameTooltip:AddLine(L["Shift+Click this to lock it in position."])
        GameTooltip:Show()
    end);

    anchor:SetScript("OnLeave", function(self)
        GameTooltip:Hide();
    end);

    anchor:SetScript("OnMouseUp", function(self, button)
        if IsShiftKeyDown() then
            self:Hide();
            db.announce.locked = true;
        end
    end);

    anchor:RegisterForDrag("LeftButton");
    self.announce.anchor = anchor;
    
    local f = CreateFrame("Frame", nil, UIParent);
    f:ClearAllPoints();
    local text = f:CreateFontString(nil, "OVERLAY", "ZoneTextFont");
    text:ClearAllPoints();
    text:SetPoint("CENTER", anchor, "CENTER", 0, 0);
    text:SetTextColor(unpack(db.announce.fontcolor));
    f:SetAllPoints(text);
    f:SetScale(db.announce.scale);
    text:SetText(db.announce.announceString);
    self.announce.frame = f;
    self.announce.text = text;
    self.announce.alpha = 1;
    self.announce.last = GetTime();
    self.announce.frame:SetScript("OnUpdate", function(self, elapsed)
        if anchor:IsShown() then
            return;
        end
        if (GetTime() - cdt.announce.last) > db.announce.fade then
            cdt.announce.alpha = cdt.announce.alpha - 0.1
        end
        self:SetAlpha(cdt.announce.alpha);
        if cdt.announce.alpha <= 0 then
            self:Hide();
        end
    end);
    self.announce.text:Show();
    self.announce.anchor:SetFrameStrata("BACKGROUND");
    self.announce.frame:SetFrameStrata("BACKGROUND");

    if not db.announce.locked and db.announce.enabled then
        self.announce.anchor:Show();
        self.announce.frame:Show();
    else
        self.announce.anchor:Hide();
        self.announce.frame:Hide();
    end

    if not self.pulse then
        self:CreatePulse()
    end
end

function cdt:UpdateAnnounce()
    if db.enabled then
        self.announce.text:Show()
        self.announce.anchor:Show()
        self.announce.frame:Show()
        self.announce.frame:SetAlpha(1)
        self.announce.alpha = 1
    else
        self.announce.text:Hide()
        self.announce.anchor:Hide()
        self.announce.frame:Hide()
    end
    self.announce.frame:SetScale(db.announce.scale)
    self.announce.text:SetTextColor(unpack(db.announce.fontcolor));
end

function cdt:CreatePulse()
    local b = CreateFrame("Button", nil, UIParent);
    local anchor = CreateFrame("Frame", nil, UIParent);
    anchor:ClearAllPoints();
    anchor:SetSize(30, 30);
    anchor:SetBackdrop({
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
    anchor:SetBackdropColor(0.1, 0.1, 0.3);
    local ploc = db.pulse.loc;
    anchor:EnableMouse(true);
    anchor:SetMovable(true);
    anchor:SetPoint(ploc.point, UIParent, ploc.relPoint, ploc.x, ploc.y);
    anchor:SetFrameLevel(5);
    anchor:RegisterForDrag("LeftButton");
    anchor:SetScript("OnDragStart", function(self)
        self:StartMoving(); 
    end)
    anchor:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing();
        ploc.point, _, ploc.relPoint, ploc.x, ploc.y = self:GetPoint();
    end);
    b.anchor = anchor;
    b:ClearAllPoints();
    b:SetPoint("CENTER", anchor, "CENTER", 0, 0);
    b:SetSize(db.pulse.size, db.pulse.size);
    b:EnableMouse(false);
    b.animating = false;
    b:SetResizable(true);
    b:SetMaxResize(300, 300);
    b:SetMinResize(50, 50);
    b.animate = function()
        cdt:AnimatePulse();
    end
    b.configure = function()
        cdt:ConfigurePulse();
    end
    if db.pulse.locked then
        b.onUpdate = b.animate;
        b:Hide();
    else
        b.onUpdate = b.configure;
        b:Show();
    end
    b:SetScript("OnUpdate", function(self)
        self.onUpdate()
    end)
    b:SetNormalTexture("Interface\\Icons\\INV_Misc_QuestionMark");
    local scalechor = CreateFrame("Frame", nil, UIParent);
    scalechor:ClearAllPoints();
    scalechor:SetSize(30,30);
    scalechor:SetFrameLevel(5);
    scalechor:EnableMouse(true);
    scalechor:SetBackdrop({
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
    scalechor:SetBackdropColor(0.1, 0.1, 0.3);
    scalechor:SetPoint("CENTER", b, "CENTER", 0, 0);
    scalechor:RegisterForDrag("LEFTBUTTON");
    scalechor.checkWidths = function()
        if b:GetHeight() > b:GetWidth() then
            b:SetWidth(b:GetHeight());
        else
            b:SetHeight(b:GetWidth());
        end
    end
    scalechor.onUpdate = function() end;
    scalechor:SetScript("OnUpdate", function(self) self.onUpdate() end);
    scalechor:SetScript("OnDragStart", function(self)
        b:StartSizing("BOTTOMRIGHT");
        b.anchor:ClearAllPoints();
        b.anchor:SetPoint("CENTER", b, "CENTER", 0, 0);
        self.onUpdate = self.checkWidths;
    end)
    scalechor:SetScript("OnDragStop", function(self)
        b:StopMovingOrSizing();
        db.pulse.size = b:GetHeight();
        b.anchor:ClearAllPoints();
        b.anchor:StartMoving();
        b.anchor:StopMovingOrSizing();
        b:ClearAllPoints();
        b:SetPoint("CENTER", b.anchor, "CENTER", 0, 0);
        b.anchor:EnableMouse(true);
        ploc.point, _, ploc.relPoint, ploc.x, ploc.y = b.anchor:GetPoint();
        self.onUpdate = function() end
    end);
    
    b.anchor:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT")
	GameTooltip:AddLine(L["CDT Pulse Anchor"])
	GameTooltip:AddLine(L["Drag this to reposition the pulse icon."])
	GameTooltip:AddLine(L["Shift+Click this to lock it in position."])
	GameTooltip:Show()
    end)

    b.anchor:SetScript("OnLeave", function(self)
        GameTooltip:Hide();
    end);

    scalechor:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT")
	GameTooltip:AddLine(L["CDT Pulse Size Anchor"])
	GameTooltip:AddLine(L["Drag this to resize the the pulse icon."])
	GameTooltip:Show();
    end);

    scalechor:SetScript("OnLeave", function()
        GameTooltip:Hide();
    end);

    b.anchor:SetScript("OnMouseUp", function()
        if IsShiftKeyDown() then
            cdt:LockPluseIcon(true);
        end
    end)

    b.scaleanchor = scalechor;
    self.pulse = b;
    self:LockPluseIcon(db.pulse.locked);
end

function cdt:UpdatePulse()
    if db.profile.pulse.enabled then
        self.pulse.onUpdate = self.pulse.configure;
        self.pulse.anchor:Show();
        self.pulse.scaleanchor:Show();
        self.pulse:Show();
    else
        self.pulse.onUpdate = self.pulse.animate;
        self.pulse.anchor:Hide();
        self.pulse.scaleanchor:Hide();
        self.pulse:Hide();
    end
end

function cdt:LockPluseIcon(locked)
    if locked then
        self.pulse.onUpdate = self.pulse.animate;
        self.pulse.anchor:Hide();
        self.pulse.scaleanchor:Hide();
        db.pulse.locked = true;
    else
        self.pulse.onUpdate = self.pulse.configure;
        self.pulse.anchor:Show();
        self.pulse.scaleanchor:Show();
        self.pulse:Show();
        db.pulse.locked = false;
    end
end

function cdt:ConfigurePulse()
    self:AnimatePulse(true);
end

function cdt:AnimatePulse(config)
    local now = GetTime();
    local anim = self.pulse.animating and (now - self.pulse.pulsedAt);
    local pulsedb = db.pulse;

    if anim then
        local fadeout = (not self.queue.isEmpty and pulsedb.fadeout) or pulsedb.min;
        self.pulse:SetAlpha((anim < pulsedb.fadein) and anim * pulsedb.alpha / pulsedb.fadein 
        or ( anim < fadeout )	and ( fadeout - anim ) * pulsedb.alpha / ( fadeout )
        or 0 );

        if anim >= fadeout then
            self.pulse.pulsedAt = nil;
            self.pulse.animating = false;
        end
    elseif not self.queue.isEmpty then
        local skill, icon = self.queue:pop();
        if skill == nil then skill = "Test" end
        self.announce.text:SetText(string.format(db.announce.announceString, skill));
        self.announce.last = GetTime();
        self.announce.alpha = 1;
        self.announce.frame:Show();
        self.pulse.animating = true;
        self.pulse.pulsedAt = now;
        self.pulse:SetNormalTexture(icon);

        if db.sound then
            PlaySound("Deathbind Sound");
        end
    elseif config then
        self.pulse.pulsedAt = GetTime();
        self.pulse.animating = true;
    else
        self.pulse:Hide();
    end
end
