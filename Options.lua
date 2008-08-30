local SM = LibStub("LibSharedMedia-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("CooldownTimers3");
local CDT = LibStub("AceAddon-3.0"):GetAddon("CooldownTimers3");
local optGetter, optSetter
local statusbars = SM:List("statusbar")
local fonts = SM:List("font");

local strfind = string.find

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
local function GetMinimapAttachedStatus()
	return CDT:IsFuBarMinimapAttached() or CDT.db.profile.fubar.hideMinimapButton
end

local cdtgroups = {}
local function getGroups()
	if not next(cdtgroups) then
		for k, v in pairs(CDT.db.profile.groups) do
			if not v.diabled then
				tinsert(cdtgroups, k)
			end
		end
	end
	return cdtgroups
end

local cdtskills = {}
local function getSkills()
	if not next(cdtskills) then
		for k in pairs(CDT.db.class.cooldowns) do
			tinsert(cdtskills, k)
		end
	end
	return cdtskills
end

local condensegroup = {}
local function getcondensegroup()
	local db = CDT.db
	CDT.groups = {}
	for _,s in pairs(db.class.skillgroups) do
		if not CDT.groups[s] then
			CDT.groups[s] = {}
		end
	end
	for _,s in pairs(db.profile.itemgroups) do
		if not CDT.groups[s] then
			CDT.groups[s] = {}
		end
	end
	if not next(condensegroup) then
		for l in pairs(CDT.groups) do
			tinsert(condensegroup, l)
		end
	end

	return condensegroup
end

local options
local function getOptions()
	local db = CDT.db
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
					name = "General Settings",
					desc = "General Settings",
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
							validate = function(_, v) return not strfind(v, "%D") end,
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
							validate = function(_, v) return not strfind(v, "%D") end,
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
								CDT:PopulateCooldowns();
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
				fubar = {
					type = "group",
					name = "FuBar options",
					desc = "Fubar options",
					order = order(),
					args = {
						attachMinimap = {
							name = "Attach to minimap",
							desc = "Attach to minimap",
							type = "toggle",
							order = order(),
							width = "full",
							get = function(info) return CDT:IsFuBarMinimapAttached() end,
							set = function(_, v)
								CDT:ToggleFuBarMinimapAttached()
								db.profile.fubar.attachMinimap =  CDT:IsFuBarMinimapAttached()
							end
						},
						hideIcon = {--check
							type = "toggle",
							name = "Hide minimap/FuBar icon",
							desc = "Hide minimap/FuBar icon",
							order = order(),
							width = "full",
							get = function(info) return db.profile.fubar.hideMinimapButton end,
							set = function(info, v) 
								db.profile.fubar.hideMinimapButton = v
								if v then
									CDT:Hide()
								else
									CDT:Show()
								end
							end,
						},
						showIcon = {
							type = "toggle",
							name = "Show icon",
							desc = "Show icon",
							order = order(),
							width = "full",
							get = function(info) return CDT:IsFuBarIconShown() end,
							set = function(info, v) CDT:ToggleFuBarIconShown() end,
							disabled = GetMinimapAttachedStatus,
						},
						showText = {
							type = "toggle",
							name = "Show text",
							desc = "Show text",
							order = order(),
							width = "full",
							get = function(info) return CDT:IsFuBarTextShown() end,
							set = function(info, v) CDT:ToggleFuBarTextShown() end,
							disabled = GetMinimapAttachedStatus,
						},
						position = {
							type = "select",
							name = "Position",
							desc = "Position",
							order = order(),
							width = "full",
							values = {LEFT = "Left", CENTER = "Center", RIGHT = "Right"},
							get = function(info) return CDT:GetPanel() and CDT:GetPanel():GetPluginSide(CDT) end,
							set = function(info, v)
								if CDT:GetPanel() and CDT:GetPanel().SetPluginSide then
									CDT:GetPanel():SetPluginSide(CDT, v)
								end
							end,
							disabled = GetMinimapAttachedStatus,
						},
					},
				},
				announce = {
					type = 'group',
					name = 'Announce Settings',
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
									CDT.announce.text:Show()
									CDT.announce.anchor:Show()
									CDT.announce.frame:Show()
									CDT.announce.frame:SetAlpha(1)
									CDT.announce.alpha = 1
								else
									CDT.announce.text:Hide()
									CDT.announce.anchor:Hide()
									CDT.announce.frame:Hide()
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
									CDT.announce.text:Hide()
									CDT.announce.anchor:Hide()
									CDT.announce.frame:Hide()
								else
									CDT.announce.text:Show()
									CDT.announce.anchor:Show()
									CDT.announce.frame:Show()
									CDT.announce.frame:SetAlpha(1)
									CDT.announce.alpha = 1
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
									CDT.pulse:Show();
								else
									CDT.pulse.onUpdate = CooldownTimers.pulse.animate;
									CDT.pulse.anchor:Hide();
									CDT.pulse.scaleanchor:Hide();
									CDT.pulse:Hide();
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
									CDT.pulse.onUpdate = CooldownTimers.pulse.animate;
									CDT.pulse.anchor:Hide();
									CDT.pulse.scaleanchor:Hide();
								else
									CDT.pulse.onUpdate = CooldownTimers.pulse.configure;
									CDT.pulse.anchor:Show();
									CDT.pulse.scaleanchor:Show();
									CDT.pulse:Show();
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
				barsetting = {
					type = "group",
					name = "Bar Settings",
					desc = "Sets the default bar look, used after custom group settings and individual skill settings",
					order = order(),
					args = {
						texture = {
							type = "select",
							name = "Bar Texture",
							desc = "Sets the status bar textur",
							values = statusbars,
							order = order(),
							width = "double",
							get = function() return GetLSMIndex("statusbar", db.profile.barOptions.texture) end,
							set = function(_, v) db.profile.barOptions.texture = SM:List("statusbar")[v] end,
						},
						colorstart = {
							name = "Starting Color",
							desc = "Color starting bar",
							type = "color",
							order = order(),
							get = function() return	unpack(db.profile.barOptions.colors.colors1) end,
							set = function(_, r, g, b)
								db.profile.barOptions.colors.colors1[1] = r;
								db.profile.barOptions.colors.colors1[2] = g;
								db.profile.barOptions.colors.colors1[3] = b;
							end,
						},
						colorend = {
							name = "End Color",
							desc = "Color end bar",
							type = "color",
							order = order(),
							get = function() return unpack(db.profile.barOptions.colors.colors2) end,
							set = function(_, r, g, b)
								db.profile.barOptions.colors.colors2[1] = r;
								db.profile.barOptions.colors.colors2[2] = g;
								db.profile.barOptions.colors.colors2[3] = b;
							end,
						},
						fade = {
							type = "input",
							name = "Fade time",
							desc = "Sets how long bars take to fade after the bar completes.",
							usage = "<fadetime> (in seconds)>",
							validate = function(_, v) return strfind(v, "^%d+%.?%d*") end,
							order = order(),
							width = "full",
							get = function() return tostring(db.profile.barOptions.fade) end,
							set = function(_, v) db.profile.barOptions.fade = tonumber(v) end,
						},
						barwidth = {
							type = "range",
							name = "Bar Width",
							desc = "Set the bar width",
							min = 32,
							max = 300,
							step = 1,
							order = order(),
							get = function() return db.profile.barOptions.barwidth end,
							set = function(_, v) db.profile.barOptions.barwidth = v end,
						},
						barheight = {
							type = 'range',
							name = 'Bar Height',
							desc = 'Set the bar height',
							min = 16,
							max = 64,
							step = 1,
							order = order(),
							get =function() return db.profile.barOptions.barheight end,
							set = function(_, v) db.profile.barOptions.barheight = v end,
						},
						barscale = {
							type = "range",
							name = "Bar Scale",
							desc = "Set the bar scale",
							min = 0.5,
							max = 2.0,
							step = 0.1,
							order =order(),
							get = function() return db.profile.barOptions.scale end,
							set = function(_, v) db.profile.barOptions.scale = v end,
						},
						checkboxspacer = {
							type = 'description',
							name = " ",
							order = order(),
						},
						stack = {
							type = "toggle",
							name = "Grow Downwards",
							desc = "Whether the bars will stack up or stack down",
							order = order(),
							get = function()
								return not db.profile.barOptions.up end,
							set = function(_, v) db.profile.barOptions.up = not v
							end,
						},
						collapse = {
							type = "toggle",
							name = "Sort and Collapse Bars",
							desc = "Whether the bars will be auto sorted and auto collapse.",
							order = order(),
							get = function() return db.profile.barOptions.collapse end,
							set = function(_, v) db.profile.barOptions.collapse = v end,
						},
						bargap = {
							type = "range",
							name = "Bar Gap",
							desc = "Sets the default space between bars.",
							min  = 0,
							max = 32,
							step = 1,
							order = order(),
							hidden = function() return db.profile.barOptions.collapse end,
							get = function() return db.profile.barOptions.bargap end,
							set = function(_, v) db.profile.barOptions.bargap = v end,
						},
						columns = {
							type = "range",
							name = "Bar Columns",
							desc = "Sets the number of bar columns",
							min = 1,
							max = 5,
							step = 1,
							hidden = function() return db.profile.barOptions.collapse end,
							order = order(),
							get = function() return db.profile.barOptions.columns end,
							set = function(_, v) db.profile.barOptions.columns = v end,
						},
					},
				},
				gobalgroups = {
					type = "group",
					name = "Group Settings",
					desc = "Sets the settings for a particula group.",
					order = order(),
					args = {
						newgroup = {
							type = "input",
							name = "Create New Group",
							desc = "Make a new group to show cooldowns in Group names must contain only letters",
							order = order(),
							width = "full",
							get = function() return end,
							set = function(_, v)
								db.profile.groups[v] = {};
								tinsert(cdtgroups, v)
								CDT:MakeAnchor(v, db.profile.groups[v])
								--must update 
							end,
							usage = "<group name> \n(Numbers are not allowed, and make sure the group doesn't already exist)",
						},
						groupslist = {
							type = "select",
							name = "Group List",
							desc = "Toggle enable/disable the group",
							order = order(),
							values = getGroups,
							get = function() return selectedgroups end,
							set = function(_, v) selectedgroups = v end,
						},
						deletegroup = {
							type = "execute",
							name = "DELETE GROUP",
							desc = "Delete you choose group. Default group cant be deleted. It Reload when you deleted a group",
							order = order(),
							disabled = function() getGroups(); 
								return (cdtgroups[selectedgroups] == "") or (cdtgroups[selectedgroups]==nil) or (cdtgroups[selectedgroups] == "CDT")
							end,
							func = function() 
								--delete
								if cdtgroups[selectedgroups] ~= "CDT" and cdtgroups[selectedgroups] ~= "" and cdtgroups[selectedgroups] ~=nil then
									StaticPopupDialogs["CDT_DELETE_GROUP_CHECK"] = {
										text = "Are you sure you want to delete group: \n|cff00ff00"..cdtgroups[selectedgroups].."|r. \nReload when you click accept button",
										button1 = TEXT(ACCEPT),
										button2 = TEXT(CANCEL),
										maxLetters = 100,
										OnAccept = function()
											if cdtgroups[selectedgroups] == "PetCooldowns" or cdtgroups[selectedgroups] == "ItemCooldowns" then
												db.profile.groups[cdtgroups[selectedgroups]].disabled = true
											else
												db.profile.groups[cdtgroups[selectedgroups]] = nil
											end
											CDT.anchors[cdtgroups[selectedgroups]]:Hide()
											for k, v in pairs (db.class.cooldowns) do
												if v.group ==  cdtgroups[selectedgroups] then
													v.group = "CDT"
												end
											end
											for k, v in pairs (db.profile.itemcooldowns) do
												if v.group ==  cdtgroups[selectedgroups] then
													v.group = "CDT"
												end
											end
											for k, v in pairs (db.char.petcooldowns) do
												if v.group ==  cdtgroups[selectedgroups] then
													v.group = "CDT"
												end
											end
											for k, v in pairs(cdtgroups) do
												if k == selectedgroups then
													tremove(cdtgroups, k)
												end
											end
											selectedgroups = ""
											ReloadUI()--now i cant update gui setting frame. so, i want to reload ui.
										end,
										showAlert = true,
										timeout = 0,
									}
									StaticPopup_Show("CDT_DELETE_GROUP_CHECK")
								end
							end,
						},
					},
				},
				skillgroups = {
					type = "group",
					name = "Skill Cooldowns",
					desc = "Sets the settings for individual cooldowns. Enable/Disable cooldowns here.",
					order = order(),
					childGroups = "select",
					args = {},
				},
				itemgroups = {
					type = "group",
					name = "Item Cooldowns",
					desc = "Sets the settings for individual cooldowns. Enable/Disable cooldowns here.",
					order = order(),
					childGroups = "select",
					args = {},
				},
			},
		}
		
		--for groupsettings
		getGroups();
		for k, v in pairs(cdtgroups) do
			options.args.gobalgroups.args[v] = {}
			options.args.gobalgroups.args[v].type = "group";
			options.args.gobalgroups.args[v].name = v;
			options.args.gobalgroups.args[v].desc = v.." Settings";
			options.args.gobalgroups.args[v].order = order();
			options.args.gobalgroups.args[v].args = {};
			--lock
			options.args.gobalgroups.args[v].args.locked = {
				width = "full",	
			}
			options.args.gobalgroups.args[v].args.locked.type = "toggle"
			options.args.gobalgroups.args[v].args.locked.name = "Locked"
			options.args.gobalgroups.args[v].args.locked.desc = "Shows/Hides the group anchor"
			options.args.gobalgroups.args[v].args.locked.order = order()
			options.args.gobalgroups.args[v].args.locked.get = function() return db.profile.groups[v].locked end
			options.args.gobalgroups.args[v].args.locked.set = function(_, s) 
				db.profile.groups[v].locked = s 
				if db.profile.groups[v].locked then
					CDT.anchors[v]:Hide()
				else
					CDT.anchors[v]:Show()
				end
			end
			
			--texture
			options.args.gobalgroups.args[v].args.texture = {
				type = "select",
				name = "Bar Texture",
				desc = "Sets the status bar texture.",
				order = order(),
				width = "full",
				values = statusbars
			}
			options.args.gobalgroups.args[v].args.texture.get = function() 
				if not db.profile.groups[v].texture then
					return GetLSMIndex("statusbar", db.profile["barOptions"].texture)
				else
					return GetLSMIndex("statusbar", db.profile.groups[v].texture)
				end
			end
			options.args.gobalgroups.args[v].args.texture.set = function(_, s)
				db.profile.groups[v].texture = SM:List("statusbar")[s]
			end
			
			--color
				--start
			options.args.gobalgroups.args[v].args.startcolor = {
				type = "color",
				name = "Straring Color",
				desc = "Color starting bar",
				order = order(),
			}
			options.args.gobalgroups.args[v].args.startcolor.get = function()
				if not db.profile.groups[v].colors then
					db.profile.groups[v].colors = {}
					if not db.profile.groups[v].colors.colors1 then
						db.profile.groups[v].colors.colors1 = {unpack(db.profile.barOptions.colors.colors1)}
						return unpack(db.profile.groups[v].colors.colors1)
					else
						return unpack(db.profile.groups[v].colors.colors1)
					end
				else
					if not db.profile.groups[v].colors.colors1 then
						db.profile.groups[v].colors.colors1 = {unpack(db.profile.barOptions.colors.colors1)}
						return unpack(db.profile.groups[v].colors.colors1)
					else
						return unpack(db.profile.groups[v].colors.colors1)
					end
				end
			end
			options.args.gobalgroups.args[v].args.startcolor.set = function(_, r, g, b)
				db.profile.groups[v].colors.colors1[1] = r
				db.profile.groups[v].colors.colors1[2] = g
				db.profile.groups[v].colors.colors1[3] = b
			end

			--end
			options.args.gobalgroups.args[v].args.endcolor = {
				type = "color",
				name = "Ending Color",
				desc = "Color ending bar",
				order = order(),
			}
			options.args.gobalgroups.args[v].args.endcolor.get = function()
				if not db.profile.groups[v].colors then
					db.profile.groups[v].colors = {}
					if not db.profile.groups[v].colors.colors2 then
						db.profile.groups[v].colors.colors2 = {unpack(db.profile.barOptions.colors.colors2)}
						return unpack(db.profile.groups[v].colors.colors2)
					else
						return unpack(db.profile.groups[v].colors.colors2)
					end
				else
					if not db.profile.groups[v].colors.colors2 then
						db.profile.groups[v].colors.colors2 = {unpack(db.profile.barOptions.colors.colors2)}
						return unpack(db.profile.groups[v].colors.colors2)
					else
						return unpack(db.profile.groups[v].colors.colors2)
					end
				end
			end
			options.args.gobalgroups.args[v].args.endcolor.set = function(_, r, g, b)
				db.profile.groups[v].colors.colors2[1] = r
				db.profile.groups[v].colors.colors2[2] = g
				db.profile.groups[v].colors.colors2[3] = b
			end
			
			--fade
			options.args.gobalgroups.args[v].args.fadetime = {
				type = "input",
				name = "Fade Time",
				desc = "Sets how long bars take to fade after the bar completes.",
				order = order(),
				width = "full",
				validate = function(_, s) return strfind(s, "^%d+%.?%d*") end,
				usage = "<fadetime> (in seconds)",
			}
			options.args.gobalgroups.args[v].args.fadetime.get = function()
				if not db.profile.groups[v].fade then
					return tostring(db.profile.barOptions.fade)
				else
					return tostring(db.profile.groups[v].fade)
				end
			end
			options.args.gobalgroups.args[v].args.fadetime.set = function(_, s)
				db.profile.groups[v].fade = tonumber(s)
			end

			--barwidth
			options.args.gobalgroups.args[v].args.barwidth = {
				type = "range",
				name = "Bar Width",
				desc = "Sets the bar width.",
				order = order(),
				min = 32,
				max = 300,
				step = 1,
			}
			options.args.gobalgroups.args[v].args.barwidth.get = function()
				if not db.profile.groups[v].barwidth then
					return db.profile.barOptions.barwidth
				else
					return db.profile.groups[v].barwidth
				end
			end
			options.args.gobalgroups.args[v].args.barwidth.set = function(_, s)
				db.profile.groups[v].barwidth = s
			end

			--bar height
			options.args.gobalgroups.args[v].args.barheight = {
				type = "range",
				name = "Bar Height",
				desc = "Sets the bar height",
				order = order(),
				min = 16,
				max = 64,
				step = 1,
			}
			options.args.gobalgroups.args[v].args.barheight.get = function()
				if not db.profile.groups[v].barheight then
					return db.profile.barOptions.barheight
				else
					return db.profile.groups[v].barheight
				end
			end
			options.args.gobalgroups.args[v].args.barheight.set = function(_,s)
				db.profile.groups[v].barheight = s
			end

			--barscale
			options.args.gobalgroups.args[v].args.barscale = {
				type = "range",
				name = "Bar Scale",
				desc = "Sets the bar scale",
				min = 0.5,
				max = 2,
				step = 0.1,
				order = order()
			}
			options.args.gobalgroups.args[v].args.barscale.get = function()
				if not db.profile.groups[v].scale then
					return db.profile.barOptions.scale
				else
					return db.profile.groups[v].scale
				end
			end
			options.args.gobalgroups.args[v].args.barscale.set = function(_, s)
				db.profile.groups[v].scale = s
			end

			--spacer
			options.args.gobalgroups.args[v].args.gggspacer = {
				type = 'description',
				name = " ",
				order = order(),
			}

			--stack
			options.args.gobalgroups.args[v].args.stack = {
				type = "toggle",
				name = "Grow Downwards",
				desc = "Whether the bars will stack up, or stack down",
				order  =order(),
			}
			options.args.gobalgroups.args[v].args.stack.get = function()
				if db.profile.groups[v].up ~= nil then
					return not db.profile.groups[v].up
				else
					return not db.profile.barOptions.up
				end
			end
			options.args.gobalgroups.args[v].args.stack.set = function(_, s)
				db.profile.groups[v].up = not s
				CDT:SetCandyBarGroupGrowth(v, (not db.profile.groups[v].up))
			end

			--sort
			options.args.gobalgroups.args[v].args.barsort = {
				type = "toggle",
				name = "Sort and Collapse Bars",
				desc = "Whether the bars will be automatically sorted and automatically collapse",
				order = order(),
			}
			options.args.gobalgroups.args[v].args.barsort.get = function()
				if db.profile.groups[v].collapse ~= nil then
					return db.profile.groups[v].collapse
				else
					return db.profile.barOptions.collapse
				end
			end
			options.args.gobalgroups.args[v].args.barsort.set = function(_, s)
				db.profile.groups[v].collapse = s
			end

			--spacer
			options.args.gobalgroups.args[v].args.gapspacer = {
				type = "description",
				name = " ",
				order = order()
			}
			--gap
			options.args.gobalgroups.args[v].args.gap = {
				type = "range",
				name = "Bar Gap",
				desc = "Sets the default space between bars. (Only used when bars do not automatically collapse.)",
				order = order(),
				min = 0,
				max = 32,
				step = 1,
			}
			options.args.gobalgroups.args[v].args.gap.hidden = function() return db.profile.groups[v].collapse end
			options.args.gobalgroups.args[v].args.gap.get = function()
				if db.profile.groups[v].gap then
					return db.profile.groups[v].bargap
				else
					return db.profile.barOptions.bargap
				end
			end
			options.args.gobalgroups.args[v].args.gap.set = function(_, s)
				db.profile.groups[v].bargap = s
			end

			--columns
			options.args.gobalgroups.args[v].args.columns = {
				type = "range",
				name = "Bar Columns",
				desc = "Sets the number of bar columns. (Only used when bars do not automatically collapse.)",
				order = order(),
				min = 0,
				max = 5,
				step = 1
			}
			options.args.gobalgroups.args[v].args.columns.hidden = function() return db.profile.groups[v].collapse end
			options.args.gobalgroups.args[v].args.columns.get = function()
				if db.profile.groups[v].columns then
					return db.profile.groups[v].columns
				else
					return db.profile.barOptions.columns
				end
			end
			options.args.gobalgroups.args[v].args.columns.set = function(_,s)
				db.profile.groups[v].columns = s
			end
		end

		--for skillgroups
		getSkills();
			getcondensegroup();
		for k, v in pairs(cdtskills) do
			options.args.skillgroups.args["cdtskill_"..k] = {
				type = "group",
				order = order(),
				args = {}
			}
			options.args.skillgroups.args["cdtskill_"..k].name = v
			options.args.skillgroups.args["cdtskill_"..k].desc = v.." Settings"

			options.args.skillgroups.args["cdtskill_"..k].args.enabled = {
				type = "toggle",
				width = "full",
				order = order(),
				name = "Enabled",
				desc = "Enables and disables tracking of individual skill cooldowns.",
			}
			options.args.skillgroups.args["cdtskill_"..k].args.enabled.get = function() return not db.class.cooldowns[v].disabled end;
			options.args.skillgroups.args["cdtskill_"..k].args.enabled.set = function(_, s) db.class.cooldowns[v].disabled = not s end;

			--select
			options.args.skillgroups.args["cdtskill_"..k].args.group = {
				type = "select",
				name = "Group",
				desc = "Cooldown group to put selected skill in",
				order = order(),
				width = "full",
				values = cdtgroups,
			}
			options.args.skillgroups.args["cdtskill_"..k].args.group.get = function() for i, k in pairs(cdtgroups) do if db.class.cooldowns[v].group == k then skillIndex = i end end
			return skillIndex end
			options.args.skillgroups.args["cdtskill_"..k].args.group.set = function(_, s) db.class.cooldowns[v].group = cdtgroups[s] end

			--texture
			options.args.skillgroups.args["cdtskill_"..k].args.texture = {
				type = "select",
				name = "Bar Texture",
				desc = "Sets the status bar texture.",
				order = order(),
				values = statusbars,
				width = "full",
			}
			options.args.skillgroups.args["cdtskill_"..k].args.texture.get = function() 
				if db.class.cooldowns[v].texture then
					return GetLSMIndex("statusbar", db.class.cooldowns[v].texture)
				else
					return GetLSMIndex("statusbar", db.profile["barOptions"].texture)
				end
			end
			options.args.skillgroups.args["cdtskill_"..k].args.texture.set = function(_, s)
				db.class.cooldowns[v].texture = statusbars[s] end

			--colors

			--fadetime
			options.args.skillgroups.args["cdtskill_"..k].args.fadetime = {
				type = "input",
				name = "Cutom Fade Time",
				desc = "Sets how long bars take to fade after the bar completes.",
				order = order(),
				width = "full",
				validate = function(_, s) return strfind(s, "^%d+%.?%d*") end,
				usage = "<fadetime> (in seconds)",
			}
			options.args.skillgroups.args["cdtskill_"..k].args.fadetime.get = function() if db.class.cooldowns[v].fade == nil then
					return tostring(db.profile.barOptions.fade)
				else
					return tostring(db.class.cooldowns[v].fade)
				end
			end

			options.args.skillgroups.args["cdtskill_"..k].args.fadetime.set = function(_, s)
				db.class.cooldowns[v].fade = tonumber(s); end

			--new condense
			options.args.skillgroups.args["cdtskill_"..k].args.newcondense = {
				type = "input",
				name = "New Condense Group",
				desc = "Create a new Condense Group with\nthis as a member",
				order = order(),
				width = "full",
				usage = "<group name> (Numbers are not allowed, and make sure the group doesn't already exist)",
			}
			options.args.skillgroups.args["cdtskill_"..k].args.newcondense.get = function() return end
			options.args.skillgroups.args["cdtskill_"..k].args.newcondense.set = function(_, s)
				db.class.cooldowns[v] = nil;
				db.class.skillgroups[v] = s;
				--CDT:UpdateData();
			end

			--condensegroup
			options.args.skillgroups.args["cdtskill_"..k].args.condensegroup = {
				type = "select",
				name = "Condense Group",
				desc = "Select a group to condense the selected skill into\n(e.g. for shared cooldowns)",
				order = order(),
				width = "full",
				values = condensegroup
			}
			options.args.skillgroups.args["cdtskill_"..k].args.condensegroup.get = function() 
				return	end
			options.args.skillgroups.args["cdtskill_"..k].args.condensegroup.set = function(_, s)
				db.class.cooldowns[v] = nil;
				db.class.skillgroups[v] = s;
				--CDT:UpdateData();
			end
		end

		--for item
	end

	options.args.Profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(CooldownTimers.db)
	options.args.Profiles.order = order()
	return options
end

function CDT:SetupOptions()
	LibStub("AceConfig-3.0"):RegisterOptionsTable("CooldownTimers3", getOptions)
end