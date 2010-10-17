local _, cdt = ...;
cdt = LibStub(cdt, "CooldownTimers3", "AceEvent-3.0", "AceComm-3.0", "AceSerializer-3.0", "AceHook-3.0", "AceConsole-3.0");
local CallbackHandler = LibStub("CallbackHandler-1.0");
cdt.version = GetAddOnMetadata("CooldownTimers3", "version");
cdt.reversion = tonumber(("$Revision: 39$"):match("%d+"));
local L = LibStub("AceLocale-3.0"):GetLocale("CooldownTimers3");
local candy = LibStub("LibCandyBar-3.0");
local SM = LibStub("LibSharedMedia-3.0")
local LDB = LibStub("LibDataBroker-1.1", true);
local icon = LibStub("LibDBIcon-1.0", true);
local db;

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
    if pclass == "HUNTER" then

    elseif pclass == "SHAMAN" then

    elseif pclass == "PALADIN" then

    else
        defaults["class"]["cooldowns"] = {}
        defaults["class"]["skillgroups"] = {};
    end

    self.db = LibStub("AceDB-3.0"):New("CooldownTimersDB", defaults, "Default");
    local db = self.db.profile;

    self.db.RegisterCallback(self, "OnPorfileChanged", "OnPorifleChanged");
    self.db.RegisterCallback(self, "OnProfileReset", "OnProfileChanged");
    self.db.RegisterCallback(self, "OnPorfileCopied", "OnPorfileChanged");
    
    SM:Register("statusbar", "Smooth", "Interface\\AddOns\\CooldownTimers3\\texture\\smooth");
    SM:Register("statusbar", "Cilo", "Interface\\AddOns\\CooldownTimers3\\texture\\cilo");
    SM:Register("statusbar", "BantoBar", "Interface\\AddOns\\CooldownTimers3\\texture\\bar");

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

    local tooltip = CreateFrame("GameTooltip", "CDTTooltip", UIParent, "GameTooltipTemplate");
    tooltip:SetOwner(UIParent, "ANCHOR_NONE");
    self.tooltip = tooltip;

    self.anchors = {};
    for k, v in pairs(db.groups) do
        self:MakeAnchor(k, v)
    end
    self:FixGroups();
    
    self.bars = {};
    self.baralphas = {};
    
    self.queue = {first = 1, last = -1, isEmpty = true};
    self.queue.push = qpush;
    self.queue.qpop = qpop;

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
    dispatchComm(sender, self:Deserialize(...))
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
        self:SetUpBar(v.name, v.item, v.duration);
        del(cooldowns[k])
    end
    del(cooldowns);
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

function cdt:PopulateCooldowns()
    local i = 1;
    local cooldown = GetSpellBookItemName(i, BOOKTYPE_SPELL);
    local last;
    local tooltip = self.tooltip;
    local GetSpellBookItemName = GetSpellBookItemName;
    local cooldown1 = gsub(SPELL_RECAST_TIME_MIN, "%%%.%d[fg]", "(.+)");
    local cooldown2 = gsub(SPELL_RECAST_TIME_SEC, "%%%.%d[fg]", "(.+)");
    local cooldowns = self.db.class.cooldowns; 
    local function checkRight(rtip)
        local t = rtip and rtip:GetText();
        if rtip and (strmatch(t, cooldown1) or strmatch(t, cooldown2)) then
            return true
        end
    end

    while cooldown do
        if cooldown ~= last then
            last = cooldown;
            --clear right tooltip text 
            CDTTooltipTextRight2:SetText("");
            CDTTooltipTextRight3:SetText("");
            CDTTooltipTextRight4:SetText("");
            CDTTooltipTextRight5:SetText("");
            tooltip:SetSpell(i, BOOKTYPE_SPELL);

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

function cdt:PopulatePetCooldowns()

end

-----------------------------------------------------
-- bar handling
function cdt:SetUpBar(skillName, skillOptions, duration)
    print(skillName);
    local group = db.groups[skillOptions.group];
    if skillOptions.share and next(self.offsets) then
        self:SendComm("New", skillName, skillOptions.icon, skillOptions.start, duration);
    end
    local colors = skillOptions.colors or group.colors or db.barOptions.colors;
    if self.bars[skillName] then
        self.bars[skillName]:Stop();
    end

    if group.collapse or (group.collapse == nil and db.barOptions.collapse) then
    
    else
       --create a new candy bar 

    end
end
