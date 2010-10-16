local _, cdt = ...;
cdt = LibStub(cdt, "CooldownTimers3", "AceEvent-3.0", "AceComm-3.0", "AceConsole-3.0");
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

    self:CreateLDB();
end

function cdt:OnEnable()
    self:RegisterEvent("SPELL_UPDATE_COOLDOWN");  
    self:RegisterEvent("PLAYER_ALIVE", "PopulateCooldowns");
    self:RegisterEvent("SPELLS_CHANGED", "PopulateCooldowns");
    self:RegisterEvent("UNIT_PET");

    local tooltip = CreateFrame("GameTooltip", "CDTTooltip", UIParent, "GameTooltipTemplate");
    tooltip:SetOwner(UIParent, "ANCHOR_NONE");
    self.tooltip = tooltip;

    self.anchors = {};
    self.bars = {};
    self.baralphas = {};

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

function cdt:SPELL_UPDATE_COOLDOWN()
    local start, duration, enable, name;
    local cooldowns = new();

    for k, v in pairs(self.db.class.cooldowns) do

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
end

function cdt:UNIT_PET(unit)
    if unit ~= "player" then
        return
    end
    self:PopulatePetCooldowns();
end

function cdt:PopulatePetCooldowns()

end
