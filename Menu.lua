--Setup Libraries
local sm = LibStub("LibSharedMedia-2.0")
local dd = AceLibrary("Dewdrop-2.0")
local L = AceLibrary("AceLocale-2.2"):new("CooldownTimers")
local waterfall;
if AceLibrary:HasInstance("Waterfall-1.0") then
	waterfall = AceLibrary("Waterfall-1.0")
end
--bummed from ckknight's pitbull, with his permission:
local new, del, newHash
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
	--[[ I don't use these two anyway
	function newHash(...)
		local t = next(list)
		if t then
			list[t] = nil
		else
			t = {}
		end
		for i = 1, select('#', ...), 2 do
			t[select(i, ...)] = select(i+1, ...)
		end
		return t
	end
	
	function newSet(...)
		local t = next(list)
		if t then
			list[t] = nil
		else
			t = {}
		end
		for i = 1, select('#', ...) do
			t[select(i, ...)] = true
		end
		return t
	end
	--]]
	function del(t)
		for k in pairs(t) do
			t[k] = nil
		end
		list[t] = true
		return nil
	end
end
--end sleazy code borrowing
--Setup Minimap icon
CooldownTimers.hasNoColor = true
CooldownTimers.defaultMinimapPosition = 300
CooldownTimers.independentProfile = true
CooldownTimers.cannotDetachTooltip = true
CooldownTimers.hideWithoutStandby = true
CooldownTimers.hasIcon = "Interface/Icons/INV_Misc_PocketWatch_02"

--Setup Dewdrop Menu
function CooldownTimers:OnMenuRequest(level, value, inTooltip, v1, v2, v3, v4)
	--self:Print(level, value, inTooltip, v1, v2, v3, v4)
	--Level 1
	if level == 1 then
		
		if waterfall then
			dd:AddLine(
				'text', L["GUI Configuration"],
				'hasTooltip', true,
				'tooltipText', L["Opens the Waterfall GUI configuration menu"],
				'func', function()
					CooldownTimers:OpenWaterfall()
					if dd then
						dd:Close()
					end
				end
			)
      
  		dd:AddLine(
  			'notClickable', true,
  			'text', ""
  		)
		end	
		dd:AddLine(
			'text', L["Default Bar Settings"],
			'hasArrow', true,
			'value', "defaults",
			'hasTooltip', true,
			'tooltipText', L["Sets the default bar look, used after\ncustom group settings and\nindividual skill settings"]
		)
		dd:AddLine(
			'text', L["Group Settings"],
			'hasArrow', true,
			'value', "groups",
			'hasTooltip', true,
			'tooltipText', L["Sets the settings for a particular group."]
		)
		dd:AddLine(
			'text', L["Announce Settings"],
			'hasArrow', true,
			'value', "announce",
			'hasTooltip', true,
			'tooltipText', L["Settings for the Announce display"]
		)
		dd:AddLine(
			'text', L["Skill Cooldowns"],
			'hasArrow', true,
			'value', "skills",
			'hasTooltip', true,
			'tooltipText', L["Sets the settings for individual cooldowns.\nEnable/Disable cooldowns here."]
		)
		dd:AddLine(
			'text', L["Item Cooldowns"],
			'hasArrow', true,
			'value', "items",
			'hasTooltip', true,
			'tooltipText', L["Sets the settings for individual cooldowns.\nEnable/Disable cooldowns here."],
			'disabled', not next(CooldownTimers.db.profile.itemcooldowns)
		)
		dd:AddLine(
			'text', L["Pet Cooldowns"],
			'hasArrow', true,
			'value', "pets",
			'hasTooltip', true,
			'tooltipText', L["Sets the settings for individual cooldowns.\nEnable/Disable cooldowns here."],
			'disabled', not next(CooldownTimers.db.char.petcooldowns)
		)
    dd:AddLine(
      'text', L["Group Cooldowns"],
      'hasArrow', next(CooldownTimers.db.profile.groupcooldowns) and not self.db.profile.groups.GroupCooldowns.disabled,
      'value', "groupcooldowns",
      'hasTooltip', true,
      'tooltipText', L["Cooldowns from other people, click to disable"],
      'checked', not self.db.profile.groups["GroupCooldowns"].disabled,
      'func', function()
        self.db.profile.groups.GroupCooldowns.disabled = not self.db.profile.groups.GroupCooldowns.disabled;
        if self.db.profile.groups.GroupCooldowns.disabled then
          self:UnregisterComm("CooldownTimers2");
          self.anchors.GroupCooldowns:Hide();
        elseif not self.db.profile.groups.GroupCooldowns.locked then
          self:RegisterComm("CooldownTimers2", "GROUP");
          self.anchors.GroupCooldowns:Show();
        end
      end
    );
		dd:AddLine(
			'notClickable', true,
			'text', ""
		)
		dd:AddLine(
			'text', L["Enable Sound"],
			'hasTooltip', true,
			'tooltipText', L["Disable or enable the sound that plays when a cooldown is finished"],
			'checked', CooldownTimers.db.profile.sound,
			'func', function()
				CooldownTimers.db.profile.sound = not CooldownTimers.db.profile.sound
			end
		)
		dd:AddLine(
			'text', L["Min Time"],
			'hasArrow', true,
			'hasEditBox', true,
			'editBoxText', CooldownTimers.db.profile.mintime,
			'editBoxFunc', function(s)
				if not string.find(s, "^%d+%.?%d*$") then
					self:Print(L["Usage: <minTime> (in seconds)"])
					return
				end
				CooldownTimers.db.profile.mintime = tonumber(s)
				self:Print(L["Min Time"], L["set to:"], CooldownTimers.db.profile.mintime)
			end
		)
		dd:AddLine(
			'text', L["Max Time"],
			'hasArrow', true,
			'hasEditBox', true,
			'editBoxText', CooldownTimers.db.profile.maxtime,
			'editBoxFunc', function(s)
				if not string.find(s, "^%d+%.?%d*$") then
					self:Print(L["Usage: <maxTime> (in seconds)"])
					return
				end
				CooldownTimers.db.profile.maxtime = tonumber(s)
				self:Print(L["Max Time"], L["set to:"], CooldownTimers.db.profile.maxtime)
			end
		)
		dd:AddLine(
			'text', L["Auto Condense Groups"],
			'hasTooltip', true,
			'tooltipText', L["Try to have the addon determine what should be condensed, tries to use the last skill/item used"],
			'checked', self.db.profile.autogroup,
      'func', function()
        self.db.profile.autogroup = not self.db.profile.autogroup;
        self:PopulateCooldowns();
      end
      
		)
		dd:AddLine(
			'text', L["Condense Groups"],
			'hasTooltip', true,
			'tooltipText', L["Use this to condense multiple skills/items\nwith the same cooldown into a single bar."],
			'value', 'condense',
			'hasArrow', true,
      'disabled', self.db.profile.autogroup
		)
		dd:AddLine(
			'notClickable', true,
			'text', ""
		)
		
	--Level 2
	elseif level == 2 then
		--Defaults
		if value == "defaults" then
			--color settings
			local colors
			for k,v in ipairs(CooldownTimers.db.profile.barOptions.colors) do
				if not colors then
					colors = v
				else
					colors = colors.." "..v
				end
			end
			dd:AddLine(
				'text', L["Bar Texture"],
				'hasTooltip', true,
				'tooltipText', L["Sets the status bar texture."],
				'hasArrow', true,
				'value', "texture"
			)
			dd:AddLine(
				'text', L["Colors"],
				'hasTooltip', true,
				'tooltipText', L["Sets the fade colors. Needs at least two, but\nwill take as many colors as you want.\n"]..L["Usage: <color1> <color2> ..."],
				'hasArrow', true,
				'hasEditBox', true,
				'editBoxText', colors,
				'editBoxFunc', function(s)
					if not string.find(s, "%a+ %a+") then
						self:Print(L["Usage: <color1> <color2> ..."])
						return
					end
					CooldownTimers.db.profile.barOptions.colors = {}
					for color in string.gmatch(s, "%a+") do
						table.insert(CooldownTimers.db.profile.barOptions.colors, color)
					end
					self:Print(L["Default Bar Colors set to: "], unpack(CooldownTimers.db.profile.barOptions.colors))
					return CooldownTimers.db.profile.barOptions.colors
				end
			)
			--fade time
			dd:AddLine(
				'text', L["Fade Time"],
				'hasTooltip', true,
				'tooltipText', L["Sets how long bars take to fade after\nthe bar completes.\n"]
					..L["Usage: <fadetime> (in seconds)"],
				'hasArrow', true,
				'hasEditBox', true,
				'editBoxText', CooldownTimers.db.profile.barOptions.fade,
				'editBoxFunc', function(s)
					if not string.find(s, "^%d+%.?%d*") then
						self:Print(L["Usage: <fadetime> (in seconds)"])
						return
					end
					CooldownTimers.db.profile.barOptions.fade = tonumber(s)
					self:Print(L["Fade time set to: "], CooldownTimers.db.profile.barOptions.fade)
					return CooldownTimers.db.profile.barOptions.fade
				end
			)
			--barwidth, max 300 min 32
			dd:AddLine(
				'text', L["Bar Width"],
				'hasTooltip', true,
				'tooltipText', L["Sets the default bar width."],
				'hasArrow', true,
				'hasSlider', true,
				'sliderMin', 32,
				'sliderMax', 200,
				'sliderStep', 1,
				'sliderValue', CooldownTimers.db.profile.barOptions.barwidth,
				'sliderFunc', function(v)
					CooldownTimers.db.profile.barOptions.barwidth = v
					return CooldownTimers.db.profile.barOptions.barwidth
				end
			)
			--barheight
			dd:AddLine(
				'text', L["Bar Height"],
				'hasTooltip', true,
				'tooltipText', L["Sets the default bar height."],
				'hasArrow', true,
				'hasSlider', true,
				'sliderMin', 16,
				'sliderMax', 64,
				'sliderStep', 1,
				'sliderValue', CooldownTimers.db.profile.barOptions.barheight,
				'sliderFunc', function(v)
					CooldownTimers.db.profile.barOptions.barheight = v
					return CooldownTimers.db.profile.barOptions.barheight
				end
			)
			--scale
			dd:AddLine(
				'text', L["Bar Scale"],
				'hasTooltip', true,
				'tooltipText', L["Sets the default bar scale."],
				'hasArrow', true,
				'hasSlider', true,
				'sliderMin', 0.5,
				'sliderMax', 2.0,
				'sliderStep', 0.1,
				'sliderValue', CooldownTimers.db.profile.barOptions.scale,
				'sliderFunc', function(v)
					CooldownTimers.db.profile.barOptions.scale = v
					return CooldownTimers.db.profile.barOptions.scale
				end
			)
			--pulse
			dd:AddLine(
				'text', L["Pulse on hit"],
				'hasTooltip', true,
				'tooltipText', L["Will pulse a bar of a skill that the player attempts to use while still on cooldown"],
				'checked', CooldownTimers.db.profile.pulseoncooldown,
				'func', function()
					CooldownTimers.db.profile.pulseoncooldown = not CooldownTimers.db.profile.pulseoncooldown
					if CooldownTimers.db.profile.pulseoncooldown and not self:IsEventRegistered("CHAT_MSG_SPELL_FAILED_LOCALPLAYER") then
						self:RegisterEvent("CHAT_MSG_SPELL_FAILED_LOCALPLAYER", "OnSpellFail")
					elseif not CooldownTimers.db.profile.pulsecooldown and self:IsEventRegistered("CHAT_MSG_SPELL_FAILED_LOCALPLAYER") then
						self:UnregisterEvent("CHAT_MSG_SPELL_FAILED_LOCALPLAYER")
					end
				end
			)
			--grow upwards
			dd:AddLine(
				'text', L["Grow Downwards"],
				'hasTooltip', true,
				'tooltipText', L["Whether the bars will stack up, or stack down"],
				'checked', not CooldownTimers.db.profile.barOptions.up,
				'func', function()
					CooldownTimers.db.profile.barOptions.up = not CooldownTimers.db.profile.barOptions.up
				end
			)
			--collapse
			dd:AddLine(
				'text', L["Sort and Collapse Bars"],
				'hasTooltip', true,
				'tooltipText', L["Whether the bars will be automatically\nsorted and automatically collapse"],
				'checked', CooldownTimers.db.profile.barOptions.collapse,
				'func', function()
					CooldownTimers.db.profile.barOptions.collapse = not CooldownTimers.db.profile.barOptions.collapse
				end
			)
			if not CooldownTimers.db.profile.barOptions.collapse then
				--bargap
				dd:AddLine(
					'text', L["Bar Gap"],
					'hasTooltip', true,
					'tooltipText', L["Sets the default space between bars."]..L["\n(Only used when bars do not automatically collapse.)"],
					'hasArrow', true,
					'hasSlider', true,
					'sliderMin', 0,
					'sliderMax', 32,
					'sliderStep', 1,
					'sliderValue', CooldownTimers.db.profile.barOptions.bargap,
					'sliderFunc', function(v)
						CooldownTimers.db.profile.barOptions.bargap = v
						return CooldownTimers.db.profile.barOptions.bargap
					end
				)
				--columns
				dd:AddLine(
					'text', L["Bar Columns"],
					'hasTooltip', true,
					'tooltipText', L["Sets the number of bar columns."]..L["\n(Only used when bars do not automatically collapse.)"],
					'hasArrow', true,
					'hasSlider', true,
					'sliderMin', 1,
					'sliderMax', 5,
					'sliderStep', 1,
					'sliderValue', CooldownTimers.db.profile.barOptions.columns,
					'sliderFunc', function(v)
						CooldownTimers.db.profile.barOptions.columns = v
						return CooldownTimers.db.profile.barOptions.columns
					end
				)
			end
			
		--groups
		elseif value == "groups" then
			
			--new group
			dd:AddLine(
				'text', L["Create New Group"],
				'hasTooltip', true,
				'tooltipText', L["Make a new group to show cooldowns in.\n"]..L["Group names must contain only letters"],
				'hasArrow', true,
				'hasEditBox', true,
				'editBoxText', "",
				'editBoxFunc', function(s)
					if string.find(s, "%A") then
						self:Print(L["Group names must contain only letters"])
						return
					end
					if CooldownTimers.db.profile.groups[s] and not CooldownTimers.db.profile.groups[s].disabled then
						self:Print(L["Group already exists: "], s)
						return
					end
					CooldownTimers.db.profile.groups[s] = {}
					self:MakeAnchor(s, CooldownTimers.db.profile.groups[s])
				end
			)
			for k,v in pairs(CooldownTimers.db.profile.groups) do
				if not v.disabled then
					dd:AddLine(
						'text', k,
						'hasArrow', true,
						'value', k
					)
				end
			end
		--announce
		elseif value == "announce" then
			dd:AddLine(
				'text', L["Enabled"],
				'checked', CooldownTimers.db.profile.announce.enabled,
				'tooltipText', L["Enables and disables the announcement\nof a cooldown completion."],
				'func', function()
					CooldownTimers.db.profile.announce.enabled = not CooldownTimers.db.profile.announce.enabled
					if not CooldownTimers.db.profile.announce.locked then
						if CooldownTimers.db.profile.announce.enabled then
							CooldownTimers.announce.anchor:Show()
							CooldownTimers.announce.frame:Show()
							CooldownTimers.announce.frame:SetAlpha(1)
							CooldownTimers.announce.alpha = 1
						else
							CooldownTimers.announce.anchor:Hide()
						end
					end
				end
			)
			dd:AddLine(
				'text', L["Locked"],
				'checked', CooldownTimers.db.profile.announce.locked,
				'tooltipText', L["Shows/Hides the announce anchor.\nWithout locking the announce will never\ndissapear!"],
				'disabled', not CooldownTimers.db.profile.announce.enabled,
				'func', function()
					CooldownTimers.db.profile.announce.locked = not CooldownTimers.db.profile.announce.locked
					if not CooldownTimers.db.profile.announce.locked then
						CooldownTimers.announce.anchor:Show()
						CooldownTimers.announce.frame:Show()
						CooldownTimers.announce.frame:SetAlpha(1)
						CooldownTimers.announce.alpha = 1
					else
						CooldownTimers.announce.anchor:Hide()
					end
				end
			)
			dd:AddLine(
				'text', L["Display String"],
				'tooltipText', L["What you want the announce\nto say. Use %s for the skill name."],
				'hasEditBox', true,
				'hasArrow', true,
				'editBoxText', CooldownTimers.db.profile.announce.announceString,
				'disabled', not CooldownTimers.db.profile.announce.enabled,
				'editBoxFunc', function(s)
					CooldownTimers.db.profile.announce.announceString = s
				end
			)
			dd:AddLine(
				'text', L["Fade Time"],
				'tooltipText', L["How long until the announce\nbegins fading."],
				'hasSlider', true,
				'sliderValue', CooldownTimers.db.profile.announce.fade,
				'disabled', not CooldownTimers.db.profile.announce.enabled,
				'hasArrow', true,
				'sliderMin', 0,
				'sliderMax', 10,
				'sliderStep', 0.5,
				'sliderFunc', function(v)
					CooldownTimers.db.profile.announce.fade = v
				end
			)
			dd:AddLine(
				'text', L["Announce Scale"],
				'tooltipText', L["Scale of the announce text."]..L["\nSee the readme for important notes about this option."],
				'hasSlider', true,
				'sliderValue', CooldownTimers.db.profile.announce.scale,
				'disabled', not CooldownTimers.db.profile.announce.enabled,
				'hasArrow', true,
				'sliderMin', 0.5,
				'sliderMax', 2,
				'sliderStep', 0.1,
				'sliderFunc', function(v)
					CooldownTimers.db.profile.announce.scale = v
					CooldownTimers.announce.frame:SetScale(v)
				end
			)
      dd:AddLine(
        'text', L["Pulse Locked"],
        'tooltipText', L["Lock/Unlock the pulse"],
        'checked', CooldownTimers.db.profile.pulse.locked,
        'func', function()
          CooldownTimers.db.profile.pulse.locked = not CooldownTimers.db.profile.pulse.locked;
          CooldownTimers:LockPulseIcon(CooldownTimers.db.profile.pulse.locked);
        end
      );
      dd:AddLine(
        'text', L["Pulse Fade-in"],
        'tooltipText', L["Time it takes for the pulse icon to fade in."],
        'hasSlider', true,
        'sliderValue', CooldownTimers.db.profile.pulse.fadein,
        'hasArrow', true,
        'sliderMin', 0,
        'sliderMax', 1,
        'sliderStep', 0.05,
        'sliderFunc', function(v)
          CooldownTimers.db.profile.pulse.fadein = v;
        end
      );
      dd:AddLine(
        'text', L["Pulse Fade-out"],
        'tooltipText', L["Time it takes for the pulse icon to fade out."],
        'hasSlider', true,
        'sliderValue', CooldownTimers.db.profile.pulse.fadeout,
        'hasArrow', true,
        'sliderMin', 0,
        'sliderMax', 1,
        'sliderStep', 0.05,
        'sliderFunc', function(v)
          CooldownTimers.db.profile.pulse.fadeout = v;
        end
      );
      dd:AddLine(
        'text', L["Pulse Alpha"],
        'tooltipText', L["Maximum alpha of the pulse icon."],
        'hasSlider', true,
        'sliderValue', CooldownTimers.db.profile.pulse.alpha,
        'hasArrow', true,
        'sliderMin', 0,
        'sliderMax', 1,
        'sliderStep', 0.1,
        'sliderFunc', function(v)
          CooldownTimers.db.profile.pulse.alpha = v;
        end
      );
		--cooldowns
		elseif value == "skills" then
			local sorted = new();
      for k,v in pairs(CooldownTimers.db.class.cooldowns) do
        table.insert(sorted,k);
        table.sort(sorted);
			end
      for k,v in ipairs(sorted) do
        dd:AddLine(
					'text', v,
					'hasArrow', true,
					'value', v
				)
      end
		elseif value == "pets" then
      local sorted = new();
			for k,v in pairs(CooldownTimers.db.char.petcooldowns) do
        table.insert(sorted,k);
        table.sort(sorted);
			end
      for k,v in ipairs(sorted) do
        dd:AddLine(
					'text', v,
					'hasArrow', true,
					'value', v
				)
      end
		elseif value == "items" then
      local sorted = new();
			for k,v in pairs(CooldownTimers.db.profile.itemcooldowns) do
        table.insert(sorted,k);
        table.sort(sorted);
			end
      for k,v in ipairs(sorted) do
        dd:AddLine(
					'text', v,
					'hasArrow', true,
					'value', v
				)
      end
    elseif value == "groupcooldowns" then
      local sorted = new();
			for k,v in pairs(CooldownTimers.db.profile.groupcooldowns) do
        table.insert(sorted,k);
        table.sort(sorted);
			end
      for k,v in ipairs(sorted) do
        dd:AddLine(
					'text', v,
					'hasArrow', true,
					'value', v
				)
      end
		elseif value == "condense" then
			CooldownTimers.groups = {}
			for k,v in pairs(CooldownTimers.db.profile.itemgroups) do
				if not CooldownTimers.groups[v] then
					CooldownTimers.groups[v] = {}
				end
				table.insert(CooldownTimers.groups[v], k)
			end
			for k,v in pairs(CooldownTimers.db.class.skillgroups) do
				if not CooldownTimers.groups[v] then
					CooldownTimers.groups[v] = {}
				end
				table.insert(CooldownTimers.groups[v], k)
			end
			for k in pairs(CooldownTimers.groups) do
				dd:AddLine(
					'text', k,
					'value', k,
					'hasArrow', k
				)
			end
		end
		
	--Level 3
	elseif level == 3 then
		if v1 == "defaults" then
			if value == "texture" then
				for _,v in pairs(sm:List("statusbar")) do
					dd:AddLine(
						'text', v,
						'checked', (CooldownTimers.db.profile.barOptions.texture == v),
						'isRadio', true,
						'func', function()
							CooldownTimers.db.profile.barOptions.texture = v
						end
					)
				end
			end
		elseif v1 == "groups" then
			--delete group
			dd:AddLine(
				'text', L["Delete Group"],
				'hasTooltip', true,
				'tooltipText', L["Delete this group (NOT RESTORABLE)\nDefault groups cannot be deleted."],
				'func', function()
					StaticPopupDialogs["CDT_DELETE_GROUP_CHECK"] = {
						text = L["Are you sure you want to delete group: "]..value,
						button1 = L["Yes"],
						button2 = L["No"],
						OnAccept = function()
							if value == "PetCooldowns" or value == "ItemCooldowns" then
								CooldownTimers.db.profile.groups[value].disabled = true --otherwise it'll just be recreated by default
							else	
								CooldownTimers.db.profile.groups[value] = nil
							end
							CooldownTimers.anchors[value]:Hide()
							self:Print(L["Group deleted: "], value)
							for k,v in pairs(CooldownTimers.db.class.cooldowns) do
								if v.group == value then
									v.group = "CDT"
								end
							end
							for k,v in pairs(CooldownTimers.db.profile.itemcooldowns) do
								if v.group == value then
									v.group = "CDT"
								end
							end
							for k,v in pairs(CooldownTimers.db.char.petcooldowns) do
								if v.group == value then
									v.group = "CDT"
								end
							end
							dd:Close()
						end,
						showAlert = true,
						timeout = 0,
					}
					StaticPopup_Show("CDT_DELETE_GROUP_CHECK")
				end,
			'disabled', (value == "CDT")
			)
			--locked
			dd:AddLine(
				'text', L["Locked"],
				'checked', CooldownTimers.db.profile.groups[value].locked,
				'hasTooltip', true,
				'tooltipText', L["Shows/Hides the group anchor."],
				'func', function()
					CooldownTimers.db.profile.groups[value].locked = not CooldownTimers.db.profile.groups[value].locked
					if CooldownTimers.db.profile.groups[value].locked then
						CooldownTimers.anchors[value]:Hide()
					else
						CooldownTimers.anchors[value]:Show()
					end
				end
			)
			--group options
			dd:AddLine(
				'text', L["Bar Texture"],
				'hasTooltip', true,
				'tooltipText', L["Sets the status bar texture."],
				'hasArrow', true,
				'value', "texture"
			)
			dd:AddLine(
				'text', L["Colors"],
				'hasArrow', true,
				'hasTooltip', true,
				'tooltipText', L["Sets default colors for this group"],
				'value', "colors"
			)
			dd:AddLine(
				'text', L["Fade Time"],
				'hasArrow', true,
				'hasTooltip', true,
				'tooltipText', L["Sets default fade time for this group"],
				'value', "fade"
			)
			dd:AddLine(
				'text', L["Bar Width"],
				'hasArrow', true,
				'hasTooltip', true,
				'tooltipText', L["Sets bar width for this group"],
				'value', "barwidth"
			)
			dd:AddLine(
				'text', L["Bar Height"],
				'hasArrow', true,
				'hasTooltip', true,
				'tooltipText', L["Sets bar height for this group"],
				'value', "barheight"
			)
			dd:AddLine(
				'text', L["Bar Scale"],
				'hasArrow', true,
				'hasTooltip', true,
				'tooltipText', L["Sets scale for this group"],
				'value', "scale"
			)
			dd:AddLine(
				'text', L["Grow Downwards"],
				'hasArrow', true,
				'hasTooltip', true,
				'tooltipText', L["Whether the bars will stack up, or stack down"],
				'value', "up"
			)
			dd:AddLine(
				'text', L["Sort and Collapse Bars"],
				'hasArrow', true,
				'hasTooltip', true,
				'tooltipText', L["Whether the bars will be automatically\nsorted and automatically collapse"],
				'value', "collapse"
			)
			local collapse = CooldownTimers.db.profile.groups[value].collapse
			if collapse == nil then
				collapse = CooldownTimers.db.profile.barOptions.collapse
			end
			dd:AddLine(
				'text', L["Bar Gap"],
				'hasArrow', true,
				'hasTooltip', true,
				'tooltipText', L["Sets the default space between bars."]..L["\n(Only used when bars do not automatically collapse.)"],
				'value', "bargap",
				'disabled', collapse
			)
			dd:AddLine(
				'text', L["Bar Columns"],
				'hasArrow', true,
				'hasTooltip', true,
				'tooltipText', L["Sets the number of bar columns."]..L["\n(Only used when bars do not automatically collapse.)"],
				'value', "columns",
				'disabled', collapse
			)
		elseif v1 == "skills" or v1 == "pets" or v1 == "items" or v1 == "groupcooldowns" then
			local cooldowns
			if v1 == "skills" then
				cooldowns = CooldownTimers.db.class.cooldowns
			elseif v1 == "pets" then
				cooldowns = CooldownTimers.db.char.petcooldowns
			elseif v1 == "items" then
				cooldowns = CooldownTimers.db.profile.itemcooldowns
      elseif v1 == "groupcooldowns" then
        cooldowns = CooldownTimers.db.profile.groupcooldowns;
			end
			dd:AddLine(
				'text', L["Enabled"],
				'checked', not cooldowns[value].disabled,
				'hasTooltip', true,
				'tooltipText', L["Enable tracking for this cooldown."],
				'func', function()
					cooldowns[value].disabled = not cooldowns[value].disabled
				end
			)
			dd:AddLine(
				'text', L["Group"],
				'hasArrow', true,
				'value', "group",
				'disabled', cooldowns[value].disabled
			)
			dd:AddLine(
				'text', L["Bar Texture"],
				'hasTooltip', true,
				'tooltipText', L["Sets the status bar texture."],
				'hasArrow', true,
				'value', "texture"
			)
			dd:AddLine(
				'text', L["Colors"],
				'hasArrow', true,
				'value', "colors",
				'disabled', cooldowns[value].disabled
			)
			dd:AddLine(
				'text', L["Fade Time"],
				'hasArrow', true,
				'value', "fade",
				'disabled', cooldowns[value].disabled
			)
      if v1 == "skills" then
        dd:AddLine(
          'text', L["Share"],
          'checked', cooldowns[value].share,
          'tooltipText', L["Share this cooldown with your group"],
          'func', function()
            cooldowns[value].share = not cooldowns[value].share;
          end
        );
      end
			if v1 ~= "pets" and not CooldownTimers.db.profile.autogroup then
				dd:AddLine(
					'text', L["Condense Into"],
					'hasArrow', true,
					'value', "condenseinto",
					'tooltipText', L["Condense this bar into a condense group"]
				)
			end
		elseif v1 == "condense" then
			for _, v in ipairs(CooldownTimers.groups[value]) do
				dd:AddLine(
					'text', v,
					'hasArrow', true,
					'value', v
				)
			end
		end
		
	--level
	elseif level == 4 then
		if v2 == "groups" then
			local default = false
			if CooldownTimers.db.profile.groups[v1][value] == nil then
				default = true
			end
			dd:AddLine(
				'text', L["Use Default"],
				'checked', default,
				'hasTooltip', true,
				'tooltipText', L["Uses the default bar settings"],
				'func', function()
					if CooldownTimers.db.profile.groups[v1][value] ~= nil then
						CooldownTimers.db.profile.groups[v1][value] = nil
					else
						CooldownTimers.db.profile.groups[v1][value] = CooldownTimers.db.profile.barOptions[value]
					end
				end
			)
			if value == "texture" then
				for _,v in pairs(sm:List("statusbar")) do
					dd:AddLine(
						'text', v,
						'checked', (CooldownTimers.db.profile.groups[v1].texture == v),
						'isRadio', true,
						'func', function()
							CooldownTimers.db.profile.groups[v1].texture = v
						end,
						'disabled', default
					)
				end
			elseif value == "colors" then
				local colors
				if CooldownTimers.db.profile.groups[v1][value] then
					for k,v in pairs(CooldownTimers.db.profile.groups[v1][value]) do
						if not colors then
							colors = v
						else 
							colors = colors.." "..v
						end
					end
				else
					colors = ""
				end
				dd:AddLine(
					'text', L["Custom "]..L["Colors"],
					'disabled', default,
					'hasEditBox', true,
					'hasArrow', true,
					'editBoxText', colors,
					'editBoxFunc', function(s)
						if not string.find(s, "^%a+ %a+") then
							self:Print(L["Usage: <color1> <color2> ..."])
							return
						end
						CooldownTimers.db.profile.groups[v1].colors = {}
						for color in string.gmatch(s, "%a+") do
							table.insert(CooldownTimers.db.profile.groups[v1].colors, color)
						end
						self:Print(v1,L["colors set to: "], unpack(CooldownTimers.db.profile.groups[v1].colors))
					end
				)
			elseif value == "fade" then
				dd:AddLine(
					'text', L["Custom "]..L["Fade Time"],
					'disabled', default,
					'hasEditBox', true,
					'hasArrow', true,
					'editBoxText', CooldownTimers.db.profile.groups[v1].fade or CooldownTimers.db.profile.barOptions.fade,
					'editBoxFunc', function(v)
						if not string.find(v, "^%d+%.?%d*$") then
							self:Print(L["Usage: <fadetime> (in seconds)"])
							return
						end
						CooldownTimers.db.profile.groups[v1].fade = tonumber(v)
						self:Print(v1, L["fade time set to:"], CooldownTimers.db.profile.groups[v1].fade)
					end
				)
			elseif value == "barwidth" then
				dd:AddLine(
					'text', L["Custom "]..L["Bar Width"],
					'disabled', default,
					'hasSlider', true,
					'hasArrow', true,
					'sliderMin', 32,
					'sliderMax', 200,
					'sliderStep', 1,
					'sliderValue', CooldownTimers.db.profile.groups[v1].barwidth or CooldownTimers.db.profile.barOptions.barwidth,
					'sliderFunc', function(v)
						CooldownTimers.db.profile.groups[v1].barwidth = v
					end
				)
			elseif value == "barheight" then
				dd:AddLine(
					'text', L["Custom "]..L["Bar Height"],
					'disabled', default,
					'hasSlider', true,
					'hasArrow', true,
					'sliderMin', 16,
					'sliderMax', 64,
					'sliderStep', 1,
					'sliderValue', CooldownTimers.db.profile.groups[v1].barheight or CooldownTimers.db.profile.barOptions.barheight,
					'sliderFunc', function(v)
						CooldownTimers.db.profile.groups[v1].barheight = v
					end
				)
			elseif value == "scale" then
				dd:AddLine(
					'text', L["Custom "]..L["Bar Scale"],
					'disabled', default,
					'hasSlider', true,
					'hasArrow', true,
					'sliderMin', 0.5,
					'sliderMax', 2,
					'sliderStep', 0.1,
					'sliderValue', CooldownTimers.db.profile.groups[v1].scale or CooldownTimers.db.profile.barOptions.scale,
					'sliderFunc', function(v)
						CooldownTimers.db.profile.groups[v1].scale = v
					end
				)
			elseif value == "up" then
				local up = CooldownTimers.db.profile.groups[v1].up
				if up == nil then
					up = CooldownTimers.db.profile.barOptions.up
				end
				dd:AddLine(
					'text', L["Grow Downwards"],
					'disabled', default,
					'checked', not up,
					'func', function()
						CooldownTimers.db.profile.groups[v1].up = not CooldownTimers.db.profile.groups[v1].up
						self:SetCandyBarGroupGrowth(v1, CooldownTimers.db.profile.groups[v1].up)
					end
				)
			elseif value == "collapse" then
				local collapse = CooldownTimers.db.profile.groups[v1].collapse
				if collapse == nil then
					collapse = CooldownTimers.db.profile.barOptions.collapse
				end
				dd:AddLine(
					'text', L["Sort and Collapse Bars"],
					'disabled', default,
					'checked', collapse,
					'func', function()
						CooldownTimers.db.profile.groups[v1].collapse = not CooldownTimers.db.profile.groups[v1].collapse
					end
				)
			elseif value == "bargap" then
				dd:AddLine(
					'text', L["Custom "]..L["Bar Gap"],
					'disabled', default,
					'hasArrow', true,
					'hasSlider', true,
					'sliderValue', CooldownTimers.db.profile.groups[v1].bargap or CooldownTimers.db.profile.barOptions.bargap,
					'sliderMin', 0,
					'sliderMax', 32,
					'sliderStep', 1,
					'sliderFunc', function(v)
						CooldownTimers.db.profile.groups[v1].bargap = v
					end
				)
			elseif value == "columns" then
				dd:AddLine(
					'text', L["Custom "]..L["Columns"],
					'disabled', default,
					'hasArrow', true,
					'hasSlider', true,
					'sliderValue', CooldownTimers.db.profile.groups[v1].columns or CooldownTimers.db.profile.barOptions.columns,
					'sliderMin', 1,
					'sliderMax', 5,
					'sliderStep', 1,
					'sliderFunc', function(v)
						CooldownTimers.db.profile.groups[v1].columns = v
					end
				)
			end
		elseif v2 == "skills" or v2 == "items" or v2 == "pets" then
			if value ~= "group" and value ~= "condenseinto" then
				local default = false
				local cooldowns = CooldownTimers.db.class.cooldowns
				if v2 == "items" then
					cooldowns = CooldownTimers.db.profile.itemcooldowns
				elseif v2 == "pets" then
					cooldowns = CooldownTimers.db.char.petcooldowns
				end
				if cooldowns[v1][value] == nil then
					default = true
				end
				dd:AddLine(
					'text', L["Use Default"],
					'checked', default,
					'hasTooltip', true,
					'tooltipText', L["Uses the default bar settings"],
					'func', function()
						if cooldowns[v1][value] ~= nil then
							cooldowns[v1][value] = nil
						else
							if CooldownTimers.db.profile.groups[cooldowns[v1].group][value] ~= nil then
								cooldowns[v1][value] = CooldownTimers.db.profile.groups[cooldowns[v1].group][value]
							else
								cooldowns[v1][value] = CooldownTimers.db.profile.barOptions[value]
							end
						end
					end
				)
				if value == "texture" then
					for _,v in pairs(sm:List("statusbar")) do
						dd:AddLine(
							'text', v,
							'checked', (cooldowns[v1].texture == v),
							'isRadio', true,
							'func', function()
								cooldowns[v1].texture = v
							end,
							'disabled', default
						)
					end
				elseif value == "colors" then
					local colors
					if cooldowns[v1][value] then
						for k,v in ipairs(cooldowns[v1][value]) do
							if not colors then
								colors = v
							else 
								colors = colors.." "..v
							end
						end
					else
						colors = ""
					end
					dd:AddLine(
						'text', L["Custom "]..L["Colors"],
						'disabled', default,
						'hasEditBox', true,
						'hasArrow', true,
						'editBoxText', colors,
						'editBoxFunc', function(s)
							if not string.find(s, "^%a+ %a+") then
								self:Print(L["Usage: <color1> <color2> ..."])
								return
							end
							cooldowns[v1].colors = {}
							for color in string.gmatch(s, "%a+") do
								table.insert(cooldowns[v1].colors, color)
							end
							self:Print(v1,L["colors set to: "], unpack(cooldowns[v1].colors))
						end
					)
				elseif value == "fade" then
					dd:AddLine(
						'text', L["Custom "]..L["Fade Time"],
						'disabled', default,
						'hasEditBox', true,
						'hasArrow', true,
						'editBoxText', cooldowns[v1].fade or CooldownTimers.db.profile.groups[cooldowns[v1].group].fade or CooldownTimers.db.profile.barOptions.fade,
						'editBoxFunc', function(v)
							if not string.find(v, "^%d+%.?%d*$") then
								self:Print(L["Usage: <fadetime> (in seconds)"])
								return
							end
							cooldowns[v1].fade = tonumber(v)
							self:Print(v1, L["fade time set to:"], cooldowns[v1].fade)
						end
					)
				end
			elseif value == "condenseinto" then
				local cooldowns = CooldownTimers.db.class.cooldowns
				if v2 == "items" then
					cooldowns = CooldownTimers.db.profile.itemcooldowns
				elseif v2 == "pets" then
					cooldowns = CooldownTimers.db.char.petcooldowns
				end
				dd:AddLine(
					'text', L["New Condense Group"],
					'tooltipText', L["Create a new Condense Group with\nthis as a member"],
					'hasEditBox', true,
					'hasArrow', true,
					'editBoxText', "",
					'editBoxFunc', function(s)
						cooldowns[v1] = nil
						if v2 == "skills" then
							CooldownTimers.db.class.skillgroups[v1] = s
						elseif v2 == "items" then
							CooldownTimers.db.profile.itemgroups[v1] = s
						end
						self:UpdateData()
						dd:Close()
					end
				)
				CooldownTimers.groups = {}
				for k,v in pairs(CooldownTimers.db.profile.itemgroups) do
					if not CooldownTimers.groups[v] then
						CooldownTimers.groups[v] = {}
					end
				end
				for k,v in pairs(CooldownTimers.db.class.skillgroups) do
					if not CooldownTimers.groups[v] then
						CooldownTimers.groups[v] = {}
					end
				end
				for k in pairs(CooldownTimers.groups) do
					dd:AddLine(
						'text', k,
						'func', function()
							cooldowns[v1] = nil
							if v2 == "skills" then
								CooldownTimers.db.class.skillgroups[v1] = k
							elseif v2 == "items" then
								CooldownTimers.db.profile.itemgroups[v1] = k
							end
							self:UpdateData()
							dd:Close()
						end
					)
				end
			else
				local skill
				if v2 == "skills" then
					skill = CooldownTimers.db.class.cooldowns[v1]
				elseif v2 == "items" then
					skill = CooldownTimers.db.profile.itemcooldowns[v1]
				elseif v2 == "pets" then
					skill = CooldownTimers.db.char.petcooldowns[v1]
				end
				for k,v in pairs(CooldownTimers.db.profile.groups) do
					if not v.disabled then
						dd:AddLine(
							'text', k,
							'checked', (skill.group == k),
							'isRadio', true,
							'func', function()
								skill.group = k
							end
						)
					end
				end
			end
		elseif v2 == "condense" then
			if string.find(value, "^%%") then
			end
			dd:AddLine(
				'text', L["Remove"],
				'tooltipText', L["Remove this item from the condense group."],
				'func', function()
					CooldownTimers.db.profile.itemgroups[value] = nil
					CooldownTimers.db.class.skillgroups[value] = nil
					self:PopulateCooldowns()
					self:UpdateData()
					dd:Close()
				end
			)
		end
	end
end

function CooldownTimers:OnClick(arg1)
	if arg1 == "LeftButton" and waterfall ~= nil then
		CooldownTimers:OpenWaterfall()
	elseif arg1 == "RightButton" then
		self:OpenMenu()
	end
end

--Register options with Waterfall
function CooldownTimers:OnInitialize()
	if waterfall then
		waterfall:Register("CooldownTimers2",
						   "aceOptions", CooldownTimers.Options,
						   "treeType","TREE",
						   "colorR", 0.26, "colorG", 0.41, "colorB", 0.57
						   )
	end
end
