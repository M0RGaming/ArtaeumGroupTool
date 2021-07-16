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
		whitelistGuild = 341929,
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
		phase = 0
	},
	Crown = {
		enabled = true,
		showMarker = true,
		showArrow = true,
		markerType = "Crown",
		cyrodilOnly = false
	},
	Group = {
		enabled = false,
		cyrodilOnly = false,
		frequency = 3000
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