ArtaeumGroupTool = {}
local AD = ArtaeumGroupTool

-- Written by M0R_Gaming

local debugMode = false

AD.name = "ArtaeumGroupTool"
AD.varversion = 1

AD.Settings = {}
AD.Settings.DefaultSettings = {
	Crown = {
		enabled = false,
		showMarker = true,
		showArrow = true,
		markerType = "Crown",
		cyrodilOnly = false,
		markerColour = {0,1,1,0.5},
		scale = 1,
		userOffset = 0,
	},
	Group = {
		enabled = true,
		cyrodilOnly = false,
		windowLocations = {{40,40},{315,40}},
		windowLocked = true,
		amountOfWindows = 2,
		hideUI = false,
		hideBaseUnitFrames = true,
		scale = 1,
		colours = {
			marker = {1,0,0,0.5},
			standardHealth = {0.8,26/255,26/255,0.8},
			fullUlt = {0,0.8,0,0.8}
		},
		showMagStam = false,
		groupFrameText = "Ult Percent", -- Ult Number, Ult Percent, Health
	}
}

function AD.print(...) 
	d(...)
end

if not debugMode then
	AD.print = function(...) end
end





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

	AD.Crown.init()
	AD.Group.init()

	EVENT_MANAGER:UnregisterForEvent(AD.name, EVENT_ADD_ON_LOADED)
end
 
-------------------------------------------------------------------------------------------------
--  Register Events --
-------------------------------------------------------------------------------------------------
EVENT_MANAGER:RegisterForEvent(AD.name, EVENT_ADD_ON_LOADED, AD.OnAddOnLoaded)