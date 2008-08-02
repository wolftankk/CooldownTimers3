local SM = LibStub("LibSharedMedia-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("CooldownTimers");
local CDT = LibStub("AceAddon-3.0"):GetAddon("CooldownTimers");
local optGetter, optSetter

local textures = SM:List("statusbar")
local fonts = SM:List("font");

--get libSM index val
local function GetLSMIndex(t, value)
	for k, v in pairs(SM:List(t)) do
		if v == value then
			return k
		end
	end
	return nil
end

do
	function optGetter(info)
		local key = info[#info]
		return db[key]
	end

	function optSetter(info, v)
		local key = info[#info]
		db[key] = v;
	end
end

local _order = 0
local function order()
	_order = _order + 1
	return _order
end

local _spaceCount = 0
local function AddSpacer()
	_spaceCount = _spaceCount + 1
	local spacer = "spacer".._spaceCount
	spacer = {
		order = order(),
		type = "description",
		name = "",
	}
end

local options
local function getOptions()
	local db = CooldownTimers.db
	if not options then
		options = {
			type = 'group',
			args = {
				version = {
					type = "description",
					name = "|cffffd200Version: "..CDT.revesion.."|r",
					order = order(),
				},
				general = {
					type = "group",
					name = "General Setting",
					desc = "General Setting",
					order = order(),
					args = {
						maxtime = {
							type = "input",
							name = "Max Time",
							desc = "Set the max time for a cooldown to be tracked.",
							order = order(),
							width = "full",
							get = function() return tostring(db.profile.maxtime) end,
							set = function(_, v) db.profile.maxtime = tonumber(v) end,
							usage = "<time>",
						},
						mintime = {
							type = "input",
							name = "Min Time",
							desc = "Set the min time for a cooldown to be tracked.",
							order = order(),
							width = "full",
							get = function() return tostring(db.profile.mintime) end,
							set = function(_, v) db.profile.mintime = tonumber(v) end,
							usage = "<time>",
						},
						barheader_1 = {
							type = "header",
							name = "",
							order = order(),
						},
						sound = {
							type = "toggle",
							name = "Enable Sound",
							width = "full",
							desc = "Disable or enable the sound that plays when a cooldown is finished",
							order = order(),
							get = function()  return db.profile.sound end,
							set = function(_, v) db.profile.sound = v end,
						},
						condense = {
							type = "toggle",
							name = "Auto Condense Groups",
							desc = "Try to have the addon determine what should be condensed, tries to use the last skill/item used",
							order = order(),
							width = "full",
							get = function() return db.profile.autogroup end,
							set = function(_, v) db.profile.autogroup = v 
								CooldownTimers:PopulateCooldowns();
							end,
						},
						pulseoncooldown = {
							type= "toggle",
							name = "Pulse on hit",
							desc = "Will pulse a bar of a skill that the player attempts to use while still on cooldown",
							order = order(),
							width = "full",
							get = function() return db.profile.pulseoncooldown end,
							set = function(_, v) db.profile.pulseoncooldown = v
								if not db.profile.pulsecooldown then
									CDT:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
								end
							end,
						},
						fixgroups = {
							type = "execute",
							name = "Fix Groups",
							desc = "Fix skills that have groups that no longer exist (moving them to groups that do exist).",
							order = order(),
							width = "full",
							func = function() CDT:FixGroups() end,
						},
					},
				},
				announce = {
					type = 'group',
					name = 'Announce Setting',
					desc = 'Settings for the Announce display',
					order = order(),
					args = {
						annenable = {
							type = 'toggle',
							name = 'Enabled',
							desc = 'Enables and disables the announcement of a cooldown completion.',
							order = order(),
							get = function()
								return db.profile.announce.enabled 
							end,
							set = function(_, v)
								db.profile.announce.enabled = v
								if db.profile.enabled then
									CooldownTimers.announce.text:Show()
									CooldownTimers.announce.anchor:Show()
									CooldownTimers.announce.frame:Show()
									CooldownTimers.announce.frame:SetAlpha(1)
									CooldownTimers.announce.alpha = 1
								else
									CooldownTimers.announce.text:Hide()
									CooldownTimers.announce.anchor:Hide()
									CooldownTimers.announce.frame:Hide()
								end
							end,
						},
						annlocked = {
							type = 'toggle',
							name = 'Locked',
							desc =  "Shows/Hides the announce anchor. Without locking the announce will never dissapear!",
							width = "full",
							order = order(),
							hidden =  function()
								if db.profile.announce.enabled then
									return false
								else return true
								end
							end,
							get = function()
								return db.profile.announce.locked end,
							set = function(_, v)
								db.profile.announce.locked = v

								if db.profile.announce.locked then
									CooldownTimers.announce.text:Hide()
									CooldownTimers.announce.anchor:Hide()
									CooldownTimers.announce.frame:Hide()
								else
									CooldownTimers.announce.text:Show()
									CooldownTimers.announce.anchor:Show()
									CooldownTimers.announce.frame:Show()
									CooldownTimers.announce.frame:SetAlpha(1)
									CooldownTimers.announce.alpha = 1
								end
							end,
						},
						annheader = {
							type = 'header',
							name = "",
							hidden =  function()
								if db.profile.announce.enabled then
									return false
								else return true
								end
							end,
							order = order()
						},
						annmessage = {
							type = "input",
							name = "Display String",
							desc = "What you want the announce to say. Use %s for the skill name.",
							order = order(),
							width = "full",
							hidden =  function()
								if db.profile.announce.enabled then
									return false
								else return true
								end
							end,
							get = function() return tostring(db.profile.announce.announceString) end,
							set = function(info, v)
								db.profile.announce.announceString = tostring(v)
								--must resh setting
							end,
						},
						annheader_1 = {
							type = 'header',
							name = "",
							hidden =  function()
								if db.profile.announce.enabled then
									return false
								else return true
								end
							end,
							order = order(),
						},
						annfadetime = {
							type = "range",
							name = "Fade Time",
							desc = "How long until the announce begins fading.",
							hidden =  function()
								if db.profile.announce.enabled then
									return false
								else return true
								end
							end,
							width = "full",
							order = order(),
							min = 0,
							max = 15,
							step = 0.5,
							get = function() return db.profile.announce.fade end,
							set = function(_, v)
								db.profile.announce.fade = v
								--Update
							end,
						},
						annscale = {
							type = "range",
							name = "Announce Scale",
							desc = "Scale of the announce text.",
							order = order(),
							hidden =  function()
								if db.profile.announce.enabled then
									return false
								else return true
								end
							end,
							width = "full",
							min = 0.5,
							max = 2,
							step = 0.1,
							get = function() return db.profile.announce.scale end,
							set = function(_, v) db.profile.announce.scale = v 
								--update
							end,
						},
						annfont = {
							type = "select",
							name = "Announce Font",
							desc = "Set font type for announce",
							order = order(),
							hidden =  function()
								if db.profile.announce.enabled then
									return false
								else return true
								end
							end,
							values = fonts,
							get = function() return GetLSMIndex("font", db.profile.announce.font) end,
							set = function(_, v) db.profile.announce.font = SM:List("font")[v] 
								--update
							end,
						},
						space_2 = {
							type = "description",
							order = order(),
							name = "",
						},
						annfontcolor = {
							type = "color",
							name = "Announce Font Color",
							desc = "Set font color for announce",
							order = order(),
							hidden =  function()
								if db.profile.announce.enabled then
									return false
								else return true
								end
							end,
							get = function() return unpack(db.profile.announce.fontcolor) end,
							set = function(_, r, g, b)
								db.profile.announce.fontcolor[1] = r
								db.profile.announce.fontcolor[2] = g
								db.profile.announce.fontcolor[3] = b
								--must update
							end
						},
						annspellcolor = {
							type = "color",
							name = "Announce Spell Color",
							desc = "Set font color for annnounce's spell",
							order = order(),
							hidden = function()
								if db.profile.announce.enabled then
									return false
								else return true
								end
							end,
							get = function() return unpack(db.profile.announce.spellcolor) end,
							set = function(_, r, g, b)
								db.profile.announce.spellcolor[1] = r
								db.profile.announce.spellcolor[2] = g
								db.profile.announce.spellcolor[3] = b
							end
						},
					},
				},
				pulse = {
					type = "group",
					name = "Pulse Settings",
					desc = "Settings for the Pulse display",
					order = order(),
					args = {
						plenable = {
							type = "toggle",
							name = "Enabled",
							desc = "Toggle the pulse of a cooldown completion.",
							order = order(),
							width = "full",
							get = function() return db.profile.pulse.enabled end,
							set = function(_, v)
								db.profile.pulse.enabled = v
								if db.profile.pulse.enabled then
									--CooldownTimers.pulse.onUpdate = CooldownTimers.pulse.configure;
									--CooldownTimers.pulse.anchor:Show();
									--CooldownTimers.pulse.scaleanchor:Show();
									CooldownTimers.pulse:Show();
								else
									CooldownTimers.pulse.onUpdate = CooldownTimers.pulse.animate;
									CooldownTimers.pulse.anchor:Hide();
									CooldownTimers.pulse.scaleanchor:Hide();
								end
							end,
						},
						pllocked = {
							type = "toggle",
							name = "Pulse Locked",
							desc = "Lock/Unlock the pulse",
							order = order(),
							width = "full",
							hidden = function()
								if db.profile.pulse.enabled then
									return false
								else return true
								end
							end,
							get = function() return db.profile.pulse.locked end,
							set = function(_, v) db.profile.pulse.locked = v
								if db.profile.pulse.locked then
									CooldownTimers.pulse.onUpdate = CooldownTimers.pulse.animate;
									CooldownTimers.pulse.anchor:Hide();
									CooldownTimers.pulse.scaleanchor:Hide();
								else
									CooldownTimers.pulse.onUpdate = CooldownTimers.pulse.configure;
									CooldownTimers.pulse.anchor:Show();
									CooldownTimers.pulse.scaleanchor:Show();
									CooldownTimers.pulse:Show();
								end
							end,
						},
						plheader = {
							type = "header",
							name = "",
							order = order(),
							hidden = function()
								if db.profile.pulse.enabled then
									return false
								else return true
								end
							end,
						},
						plalpha = {
							type = "range",
							name = "Pulse Alpha",
							desc = "Maximum alpha of the pulse icon.",
							max = 1,
							min = 0.1,
							step = 0.1,
							order = order(),
							hidden = function()
								if db.profile.pulse.enabled then
									return false
								else return true
								end
							end,
							get = function() return db.profile.pulse.alpha end,
							set = function(_, v) db.profile.pulse.alpha = v end,
						},
						plfadein = {
							type = "range",
							name = "Pulse Fade-in",
							desc = "Time it takes for the pulse icon to fade in.",
							min = 0,
							max = 1,
							step = 0.05,
							order = order(),
							hidden = function()
								if db.profile.pulse.enabled then
									return false
								else return true
								end
							end,
							get = function() return db.profile.pulse.fadein end,
							set = function(_, v) db.profile.pulse.fadein = v end,
						},
						plfadeout = {
							type = "range",
							name = "Pulse Fade-out",
							desc = "Time it takes for the pulse icon to fade out.",
							min = 0,
							max = 1,
							step = 0.05,
							order = order(),
							hidden = function()
								if db.profile.pulse.enabled then
									return false
								else return true
								end
							end,
							get = function() return db.profile.pulse.fadeout end,
							set = function(_, v) db.profile.pulse.fadeout = v end,
						},
						plmin = {
							type = "range",
							name = "Pulse Min Time",
							desc = "Use min time if stuffs in the queue for the pulse icon to fade out",
							min = 0,
							max = 1,
							step = 0.05,
							order = order(),
							hidden = function()
								if db.profile.pulse.enabled then
									return false
								else return true
								end
							end,
							get = function() return db.profile.pulse.min end,
							set = function(_, v) db.profile.pulse.min = v end,
						},
					},
				},
				--cdtbar = {
				--	type = "group",
				--	name = "",
				--}
			},
		}
	end
	
	options.args.Profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(CooldownTimers.db)
	return options
end

function CDT:SetupOptions()
	LibStub("AceConfig-3.0"):RegisterOptionsTable("CooldownTimers", getOptions)
end
