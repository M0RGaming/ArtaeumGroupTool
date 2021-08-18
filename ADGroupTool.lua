ArtaeumGroupTool = {}
local AD = ArtaeumGroupTool

-- Written by M0R_Gaming

AD.name = "ArtaeumGroupTool"
AD.varversion = 1

AD.Settings = {}
AD.Settings.DefaultSettings = {
	SOC = {
		offCrownTimer = 600,
		radius = 25500,
		whitelistGuild = -1,
	},
	Discord = {
		discordLink = "[Insert Discord Link Here]",
		discordInvite = "Come join us in discord! Even if you don't have a mic, it still helps us coordinate attacks! Come join us at",
	},
	FD = {
		rightClickMenu = true
	},
	Guild = {
		listenTo = "",
		transmitTo = "",
		guildID = -1,
		phase = 0,
		markerColour = {0,1,0,0.5}
	},
	Crown = {
		enabled = true,
		showMarker = true,
		showArrow = true,
		markerType = "Crown",
		cyrodilOnly = false,
		markerColour = {0,1,1,0.5}
	},
	Group = {
		enabled = true,
		cyrodilOnly = true,
		frequency = 1000,
		windowLocations = {},
		windowLocked = false,
		amountOfWindows = 1,
		hideBaseUnitFrames = false,
		barToShare = nil,
		scale = 1,
		colours = {
			marker = {1,0,0,0.5},
			standardHealth = {0.8,26/255,26/255,0.8},
			fullUlt = {0,0.8,0,0.8}
		}
	}
}

-- The following was adapted from https://wiki.esoui.com/Circonians_Stamina_Bar_Tutorial#lua_Structure



-------------------------------------------------------------------------------------------------
--  OnAddOnLoaded  --
-------------------------------------------------------------------------------------------------
function AD.OnAddOnLoaded(event, addonName)
	if addonName ~= AD.name then return end

	AD:Initialize()
end
 
-------------------------------------------------------------------------------------------------
--  Initialize Function --
-------------------------------------------------------------------------------------------------
function AD:Initialize()
	-- Addon Settings Menu
	AD.vars = ZO_SavedVars:NewAccountWide("ADVars", AD.varversion, nil, AD.Settings.DefaultSettings)
	AD.Settings.createSettings()

	AD.Discord.init()
	AD.SOC.init()
	AD.FD.init()
	AD.Guild.init()
	AD.Crown.init()
	AD.Group.init()

	EVENT_MANAGER:UnregisterForEvent(AD.name, EVENT_ADD_ON_LOADED)
end
 
-------------------------------------------------------------------------------------------------
--  Register Events --
-------------------------------------------------------------------------------------------------
EVENT_MANAGER:RegisterForEvent(AD.name, EVENT_ADD_ON_LOADED, AD.OnAddOnLoaded)