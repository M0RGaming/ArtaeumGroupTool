local AD = ArtaeumGroupTool
local settings = AD.Settings

function settings.createSettings()
	local guilds = {
		[-1] = "No Guild",
		["No Guild"] = -1
	}
	local guildNames = {
		"No Guild"
	}
	for i=1,GetNumGuilds() do
		local guildID = GetGuildId(i)
		guilds[GetGuildName(guildID)] = guildID
		guilds[guildID] = GetGuildName(guildID)
		guildNames[i+1] = GetGuildName(guildID)
	end

	settings.profileList = {}
	for i,v in pairs( getmetatable( AD.profiles )['__index'] ) do
		if type(v) == "table" then
			table.insert(settings.profileList, i)
		end
	end


	local UI_Options = {
		"Custom",
		"Vanilla"
	}

	local vars = AD.vars

	local panelName = "ArtaeumGroupToolSettingsPanel"
	local panelData = {
		type = "panel",
		name = "|cFFD700Artaeum Group Tool|r",
		author = "|c0DC1CF@M0R_Gaming|r",
		slashCommand = "/ad"
	}

	local optionsTable = {
		{
			type = "description",
			title = "|cFFD700Presets|r",
			text = "These are pre-made saved settings that you can choose to restore to at any point. You may have to reload your UI after loading a different profile for the settings to be applied.",
			width = "full"
		},
		{
			type = "dropdown",
			name = "Saved Preset",
			choices = settings.profileList,
			getFunc = function() return AD.profiles.currentSavedPreset end,
			setFunc = function(value) AD.profiles.currentSavedPreset = value end,
			width = "full",
			reference = "AD_Preset_List"
		},
		{
			type = "button",
			name = "Delete Preset",
			width = "half",
			func = function() AD.Profiles.delete(AD.profiles.currentSavedPreset) end,
		},
		{
			type = "button",
			name = "Load Preset",
			width = "half",
			func = function() AD.Profiles.set(AD.profiles.currentSavedPreset) end,
			requiresReload = true
		},
		{
			type = "editbox",
			name = "Current Preset Name",
			getFunc = function() return AD.profiles.currentSavedPreset end,
			setFunc = function(value) AD.profiles.currentSavedPreset = value end,
			isMultiline = false,
			width = "full",
			reference = "AD_Preset_Current"
		},
		{
			type = "button",
			name = "Save Preset",
			width = "full",
			func = function() AD.Profiles.save(AD.profiles.currentSavedPreset) end,
		},


		{
			type = "submenu",
			name = "|cff0000C|cff2a00h|cff5500a|cff7f00n|cffbf00g|cffff00e|caaff00 |c55ff00C|c00ff00o|c00ff80l|c00ffffo|c00aaffu|c0055ffr|c0000ffs|r",
			controls = {
				{
					type = "description",
					title = "|cFFD700[Group Share Module]|r",
					text = "The Following will edit the colours from the Group Ult Share Module",
					width = "full",
				},
				{
	                type = "colorpicker",
	                name = "Assist Ping Colour",
	                tooltip = "This sets the colour of the arrow and/or marker of the assist ping.",
	                getFunc = function() local rgb = vars.Group.colours.marker; return rgb[1], rgb[2], rgb[3] end,	--(alpha is optional)
	                setFunc = function(r,g,b) local rgb = vars.Group.colours.marker; rgb[1] = r; rgb[2] = g; rgb[3] = b; AD.Group.updateColours() end,	--(alpha is optional)
	            	width = "half",
	            },
	            {
			        type = "slider",
			        name = "Assist Ping Opacity",
			        tooltip = "This sets the opacity of the marker of the assist ping.",
			        min = 0,
			        max = 100,
			        step = 1,	--(optional)
			        getFunc = function() return vars.Group.colours.marker[4]*100 end,
			        setFunc = function(a) vars.Group.colours.marker[4] = a/100; AD.Group.updateColours() end,
			        width = "half",	--or "full" (optional)
			    },
			    {
	                type = "colorpicker",
	                name = "Standard Health Colour",
	                tooltip = "This sets the colour of players whos ultimate is not full.",
	                getFunc = function() local rgb = vars.Group.colours.standardHealth; return rgb[1], rgb[2], rgb[3], rgb[4] end,	--(alpha is optional)
	                setFunc = function(r,g,b,a) local rgb = vars.Group.colours.standardHealth; rgb[1] = r; rgb[2] = g; rgb[3] = b; rgb[4] = a; AD.Group.updateColours() end,	--(alpha is optional)
	            	width = "half",
	            },
	            {
	                type = "colorpicker",
	                name = "Full Ult Health Colour",
	                tooltip = "This sets the colour of players whos ultimate is full.",
	                getFunc = function() local rgb = vars.Group.colours.fullUlt; return rgb[1], rgb[2], rgb[3], rgb[4] end,	--(alpha is optional)
	                setFunc = function(r,g,b,a) local rgb = vars.Group.colours.fullUlt; rgb[1] = r; rgb[2] = g; rgb[3] = b; rgb[4] = a; AD.Group.updateColours() end,	--(alpha is optional)
	            	width = "half",
	            },
			    {
					type = "divider",
				},
				{
					type = "description",
					title = "|cFFD700[Crown Module]|r",
					text = "The Following will edit the colours from the Crown Arrow Module",
					width = "full",
				},
				{
	                type = "colorpicker",
	                name = "Arrow/Marker Colour",
	                tooltip = "This sets the colour of the arrow and/or marker. The alpha only affects the marker.",
	                getFunc = function() local rgb = vars.Crown.markerColour; return rgb[1], rgb[2], rgb[3] end,	--(alpha is optional)
	                setFunc = function(r,g,b) local rgb = vars.Crown.markerColour; rgb[1] = r; rgb[2] = g; rgb[3] = b; AD.Crown.updateColours() end,	--(alpha is optional)
	            	width = "half",
	            },
	            {
			        type = "slider",
			        name = "Marker Opacity",
			        tooltip = "This sets the opacity of the marker.",
			        min = 0,
			        max = 100,
			        step = 1,	--(optional)
			        getFunc = function() return vars.Crown.markerColour[4]*100 end,
			        setFunc = function(a) vars.Crown.markerColour[4] = a/100; AD.Crown.updateColours() end,
			        width = "half",	--or "full" (optional)
			    },
			    {
					type = "divider",
				},
			    {
					type = "description",
					title = "|cFFD700[Guild Note Module]|r",
					text = "The Following will edit the colours from the Guild Note Share Module",
					width = "full",
				},
				{
	                type = "colorpicker",
	                name = "Arrow/Marker Colour",
	                tooltip = "This sets the colour of the arrow and/or marker. The alpha only affects the marker.",
	                getFunc = function() local rgb = vars.Guild.markerColour; return rgb[1], rgb[2], rgb[3] end,	--(alpha is optional)
	                setFunc = function(r,g,b) local rgb = vars.Guild.markerColour; rgb[1] = r; rgb[2] = g; rgb[3] = b; AD.Guild.updateColours() end,	--(alpha is optional)
	            	width = "half",
	            },
	            {
			        type = "slider",
			        name = "Marker Opacity",
			        tooltip = "This sets the opacity of the marker.",
			        min = 0,
			        max = 100,
			        step = 1,	--(optional)
			        getFunc = function() return vars.Guild.markerColour[4]*100 end,
			        setFunc = function(a) vars.Guild.markerColour[4] = a/100; AD.Guild.updateColours() end,
			        width = "half",	--or "full" (optional)
			    },
			}
		},
		-- Group ULT share
		{
			type = "submenu",
			name = "|cFFD700[Group Ultimate Share Module]|r",
			controls = {
				{
					type = "checkbox",
					name = "Enable Module",
					tooltip = "If this is enabled, your ultimate will be shared with the group.",
					getFunc = function() return vars.Group.enabled end,
					setFunc = function(value) vars.Group.enabled = value end,
					requiresReload = true
				},
				
				{
					type = "checkbox",
					name = "PvP Only",
					tooltip = "If this is enabled, this module will only run in Cyrodiil and Imperial City",
					getFunc = function() return vars.Group.cyrodilOnly end,
					setFunc = function(value) vars.Group.cyrodilOnly = value end,
				},
				{
					type = "editbox",
					name = "Frequency (ms)",
					tooltip = "How much time should be spent between transmissions, in milliseconds.",
					warning = "If set to below 1000, you will be kicked for spam.",
					getFunc = function() return vars.Group.frequency end,
					setFunc = function(value) vars.Group.frequency = tonumber(value) end,
					isMultiline = false,
					requiresReload = true
				},
				{
					type = "dropdown",
					name = "UI Mode",
					choices = UI_Options,
					getFunc = function() return vars.Group.UI end,
					setFunc = function(value) vars.Group.UI = value end,
					width = "full",
					reference = "AD_UI_LIST",
					requiresReload = true
				},
				{
					type = "submenu",
					name = "|cCF9FFFCustom UI Options|r",
					reference = "AD_UI_CUSTOM_DROPDOWN",
					disabled = function() return not (vars.Group.UI == "Custom" and vars.Group.enabled) end,
					disabledLabel = function() return not (vars.Group.UI == "Custom" and vars.Group.enabled) end,
					controls = {
						{
							type = "checkbox",
							name = "Hide Base Game Healthbars",
							tooltip = "If this is enabled, the default group healthbars will be hidden.",
							getFunc = function() return vars.Group.hideBaseUnitFrames end,
							setFunc = function(value) vars.Group.hideBaseUnitFrames = value; ZO_UnitFramesGroups:SetHidden(value) end,
						},
						{
							type = "checkbox",
							name = "Hide Custom Healthbars",
							tooltip = "If this is enabled, the group healthbars from this addon will be hidden.",
							getFunc = function() return vars.Group.hideUI end,
							setFunc = function(value) vars.Group.hideUI = value; AD.Group.hideUI(value) end,
						},
						{
							type = "checkbox",
							name = "Show Magicka and Stamina Bars",
							tooltip = "If this is enabled, the you will be able to see your group's magicka and stamina bars on the UI.",
							getFunc = function() return vars.Group.showMagStam end,
							setFunc = function(value) vars.Group.showMagStam = value; AD.Group.setAllMagStamHidden(not value) end,
						},
						{
					        type = "slider",
					        name = "Window Scale",
					        tooltip = "This sets the size of the window.",
					        min = 0,
					        max = 2,
					        step = 0.1,	--(optional)
					        getFunc = function() return vars.Group.scale end,
					        setFunc = function(scale) vars.Group.scale = scale; AD.Group.scaleWindow() end,
					       	width = "half",
					    },
						{
					        type = "slider",
					        name = "Amount of group windows",
					        tooltip = "This sets the amount of windows to display. If set to 2, it will display 2 windows of 6 people each.",
					        min = 1,
					        max = 12,
					        step = 1,	--(optional)
					        getFunc = function() return vars.Group.amountOfWindows end,
					        setFunc = function(amount) vars.Group.amountOfWindows = amount end,
					        requiresReload = true,
					       	width = "half",
					    },
					    {
							type = "button",
							name = "Unlock Window",
							tooltip = "Click here to enable windows to move around",
							width = "half",
							func = AD.Group.unlockWindow,
						},
						{
							type = "button",
							name = "Lock Window",
							tooltip = "Click here to disable windows from moving around",
							width = "half",
							func = AD.Group.lockWindow,
						},
					}
				},
			    {
					type = "dropdown",
					name = "Ultimate Share Bar",
					tooltip = "Which ultimate should be shared.",
					choices = {"Active Bar", "Front Bar", "Back Bar"},
					getFunc = function()
						if vars.Group.barToShare == nil then
							return "Active Bar"
						elseif vars.Group.barToShare == HOTBAR_CATEGORY_PRIMARY then
							return "Front Bar"
						elseif vars.Group.barToShare == HOTBAR_CATEGORY_BACKUP then
							return "Back Bar"
						end
					end,
					setFunc = function(value)
						if value == "Active Bar" then
							vars.Group.barToShare = nil
						elseif value == "Front Bar" then
							vars.Group.barToShare = HOTBAR_CATEGORY_PRIMARY
						elseif value == "Back Bar" then
							vars.Group.barToShare = HOTBAR_CATEGORY_BACKUP
						end
					end
				},
				{
					type = "button",
					name = "Show Windows",
					tooltip = "Click here to Show Windows on this page",
					width = "full",
					func = AD.Group.showWindows,
				},
			}
		},
		-- Crown Arrow Module
		{
			type = "submenu",
			name = "|cFFD700[Crown Arrow Module]|r",
			controls = {
				{
					type = "checkbox",
					name = "Enable Module",
					tooltip = "If this is enabled, an arrow will point towards the group leader.",
					getFunc = function() return vars.Crown.enabled end,
					setFunc = function(value) vars.Crown.enabled = value; AD.Crown.updateToggle(value) end
				},
				
				{
					type = "checkbox",
					name = "PvP Only",
					tooltip = "If this is enabled, this module will only run in Cyrodiil and Imperial City",
					getFunc = function() return vars.Crown.cyrodilOnly end,
					setFunc = function(value) vars.Crown.cyrodilOnly = value; AD.Crown.toggleCyroOnly() end
				},
				
				{
					type = "checkbox",
					name = "Show Marker",
					tooltip = "If this is enabled, a crown/beam of light will be placed on the group leader (Beam Requires High Subsampling Quality)",
					getFunc = function() return vars.Crown.showMarker end,
					setFunc = AD.Crown.toggleMarker
				},
				{
					type = "dropdown",
					name = "Marker Type",
					tooltip = "Allows you to choose if you prefer a beam of light or a simple crown icon above the leader.",
					choices = {"Crown", "Beam", "Arrow"},
					getFunc = function() return vars.Crown.markerType end,
					setFunc = function(value)
						vars.Crown.markerType = value
						AD.Crown.pin:updateMarkerData(AD.Crown.markerTypes[value])
					end
				},
				{
					type = "checkbox",
					name = "Show 3D Arrow",
					tooltip = "If this is enabled, a 3D arrow will be created and point towards the group leader.",
					getFunc = function() return vars.Crown.showArrow end,
					setFunc = AD.Crown.toggleArrow
				}
			}
		},
		-- FRONT DOOR MODULE
		{
			type = "submenu",
			name = "|cFFD700[Front Door Module]|r",
			controls = {
				{
					type = "description",
					title = nil,
					text = "If you wish to disable the pins entirely, use the filter in your map.",
					width = "full",
				},
				{
					type = "checkbox",
					name = "Right Click to Set Rally Marker",
					tooltip = "If this is enabled, you can set your rally marker to the front door of a keep if you right click it.",
					getFunc = function() return vars.FD.rightClickMenu end,
					setFunc = function(value) vars.FD.rightClickMenu = value end
				}
			}
		},
		-- STAY ON CROWN MODULE
		{
			type = "submenu",
			name = "|cFFD700[Stay On Crown Module]|r",
			controls = {
				{
					type = "editbox",
					name = "Time to Kick",
					tooltip = "Time before pugs will be kicked (in minutes).",
					getFunc = function() return vars.SOC.offCrownTimer/60 end,
					setFunc = function(value) AD.SOC.setTimer(value) end,
					isMultiline = false
				},
				{
					type = "editbox",
					name = "Radius",
					tooltip = "If pugs are this much away, the timer will start counting for them. A forward camp radius is 25500 units.",
					getFunc = function() return vars.SOC.radius end,
					setFunc = function(value) vars.SOC.radius = tonumber(value) end,
					isMultiline = false
				},
				{
					type = "dropdown",
					name = "Whitelist Guild",
					tooltip = "Please select the Guild where you would like to not kick pugs from.",
					choices = guildNames,
					getFunc = function() return guilds[vars.SOC.whitelistGuild] end,
					setFunc = function(value) vars.SOC.whitelistGuild = guilds[value] end
				},
				{
					type = "button",
					name = "Toggle Module",
					tooltip = "Click here to toggle [Stay on Crown].",
					func = function() AD.SOC.startTimer() end
				}
			}
		},
		-- DISCORD MODULE
		{
			type = "submenu",
			name = "|cFFD700[Discord Module]|r",
			controls = {
				{
					type = "editbox",
					name = "Discord Invite Link",
					tooltip = "Please add your discord invite link here.",
					getFunc = function() return vars.Discord.discordLink end,
					setFunc = function(value) vars.Discord.discordLink = value end,
					isMultiline = false	--boolean
				},
				{
					type = "editbox",
					name = "Discord Invite Message",
					tooltip = "Please add your discord invite message here.",
					getFunc = function() return vars.Discord.discordInvite end,
					setFunc = function(value) vars.Discord.discordInvite = value end,
					isMultiline = true	--boolean
				},
				{
					type = "button",
					name = "Send Discord Invite",
					tooltip = "Click here to send a discord invite!",
					func = function() AD.Discord.sendDiscord() end
				}
			}
		},
		-- Multi Group Sharing Module
		{
			type = "submenu",
			name = "|cFFD700[Multi Group Share]|r",
			controls = {
				{
					type = "description",
					title = nil,
					text = "|cFF0000Warning|r: This is experimental. Report any bugs to the esoui page's comments section, or send a message to @M0R_Gaming",
					width = "full",
				},
				{
					type = "dropdown",
					name = "Guild To Share To",
					tooltip = "Please select the guild where you would like to transmit/recieve data from.",
					choices = guildNames,
					getFunc = function() return guilds[vars.Guild.guildID] end,
					setFunc = function(value)
						local guildID = guilds[value]
						vars.Guild.guildID = guildID
						AD.Guild.transmitTo = GetPlayerGuildMemberIndex(guildID)
					end
				},
				{
					type = "editbox",
					name = "Listen To",
					tooltip = "Please add the @ Name of the person who's notes you would like to recieve data from.",
					getFunc = function() return vars.Guild.listenTo end,
					setFunc = function(value) vars.Guild.listenTo = value end,
					isMultiline = false,
					reference = "AD_Settings_Listen"
				},
				{
					type = "editbox",
					name = "Transmit To",
					tooltip = "Please add the @ Name of the person who's notes you would like to send data to.",
					getFunc = function() return vars.Guild.transmitTo end,
					setFunc = function(value) vars.Guild.transmitTo = value end,
					isMultiline = false,
					reference = "AD_Settings_Transmit"
				},
				{
					type = "editbox",
					name = "Transmission Phase",
					tooltip = "Sets the phase shift of the transmission (if you are the only one transmitting, set this to 0), max value of 10.",
					getFunc = function() return vars.Guild.phase end,
					setFunc = function(value) vars.Guild.phase = tonumber(value) end,
					isMultiline = false
				},
				{
					type = "button",
					name = "Toggle Transmitting",
					tooltip = "Click here to toggle transmitting the data of crown location. Must have edit guild notes permission",
					func = AD.Guild.toggleTransmit,
					width = "half",
				},
				{
					type = "button",
					name = "Toggle Listening",
					tooltip = "Click here to toggle listening for the data of crown location.",
					func = AD.Guild.toggleListen,
					width = "half",
				}
			}
		}

		


	}


	local panel = LibAddonMenu2:RegisterAddonPanel(panelName, panelData)
	LibAddonMenu2:RegisterOptionControls(panelName, optionsTable)

end