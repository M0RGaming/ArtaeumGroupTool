local AD = ArtaeumGroupTool
local settings = AD.Settings

function settings.createSettings()

	local vars = AD.vars

	local panelName = "ArtaeumGroupToolSettingsPanel"
	local panelData = {
		type = "panel",
		name = "|cFFD700Artaeum Group Tool|r",
		author = "|c0DC1CF@M0R_Gaming|r",
		slashCommand = "/ad"
	}

	local optionsTable = {

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
					setFunc = function(value) vars.Group.cyrodilOnly = value end
				},
				{
					type = "editbox",
					name = "Frequency (ms)",
					tooltip = "How much time should be spent between transmissions, in milliseconds.",
					getFunc = function() return vars.Group.frequency end,
					setFunc = function(value) vars.Group.frequency = tonumber(value) end,
					isMultiline = false,
					requiresReload = true
				}
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
					choices = {"Crown", "Beam"},
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
					setFunc = function(value) vars.SOC.radius = value end,
					isMultiline = false
				},
				{
					type = "editbox",
					name = "Guild ID",
					tooltip = "Enter your whitelist Guild ID in here (-1 for no whitelist)",
					getFunc = function() return vars.SOC.whitelistGuild end,
					setFunc = function(value) vars.SOC.whitelistGuild = value end,
					isMultiline = false
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
					type = "editbox",
					name = "Guild ID",
					tooltip = "Please add the Guild ID of where you would like to transmit/recieve data from.",
					getFunc = function() return vars.Guild.guildID end,
					setFunc = AD.Guild.setGuild,
					isMultiline = false
				},
				{
					type = "editbox",
					name = "Listen To",
					tooltip = "Please add the @ Name of the person who's notes you would like to recieve data from.",
					getFunc = function() return vars.Guild.listenTo end,
					setFunc = function(value) vars.Guild.listenTo = value end,
					isMultiline = false
				},
				{
					type = "editbox",
					name = "Transmit To",
					tooltip = "Please add the @ Name of the person who's notes you would like to send data to.",
					getFunc = function() return vars.Guild.transmitTo end,
					setFunc = function(value) vars.Guild.transmitTo = value end,
					isMultiline = false
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
					func = AD.Guild.toggleTransmit
				},
				{
					type = "button",
					name = "Toggle Listening",
					tooltip = "Click here to toggle listening for the data of crown location.",
					func = AD.Guild.toggleListen
				}
			}
		}

		


	}


	local panel = LibAddonMenu2:RegisterAddonPanel(panelName, panelData)
	LibAddonMenu2:RegisterOptionControls(panelName, optionsTable)

end