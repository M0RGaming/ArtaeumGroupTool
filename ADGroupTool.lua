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
		dackVisType = "Outlines",
		dackUIEnabled = false,
	},
	latestUpdateMessage = 0

}

function AD.print(...) 
	if AD.filter then
		AD.filter:AddMessage(...)
	end
end

if not debugMode then
	AD.print = function(...) end
end



local updateMessages = {
	[1] = "[ArtaeumGroupTool] Artaeum has updated to version 5.0, adding a new custom group frame layout designed by @DakJaniels. This is disabled by default, and "..
	"can be enabled via the Group Share Settings menu!"
}

local playerActivated = function()
	d(updateMessages[#updateMessages])
	AD.vars.latestUpdateMessage = #updateMessages
	EVENT_MANAGER:UnregisterForEvent("AD Group Tool Update Message", EVENT_PLAYER_ACTIVATED)
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
	local startInit = 0
	if debugMode then
		startInit = os.rawclock()
	end
	-- Addon Settings Menu
	AD.vars = ZO_SavedVars:NewAccountWide("ADVars", AD.varversion, nil, AD.Settings.DefaultSettings)

	if LibFilteredChatPanel then
		AD.filter = LibFilteredChatPanel:CreateFilter("ArtaeumGroupTool", "/esoui/art/crowncrates/psijic/crowncrate_psijic_back.dds", {0, 0.8, 0.8}, false)
	end



	AD.Settings.createSettings()

	AD.Crown.init()

	if IsConsoleUI() then
		AD.initLaterObject = ZO_DeferredInitializingObject:New(HUD_SCENE)
		function AD.initLaterObject:OnDeferredInitialize()
			AD.Group.init()
		end
	else
		AD.Group.init()
	end
	
	if AD.vars.latestUpdateMessage < #updateMessages then
		EVENT_MANAGER:RegisterForEvent("AD Group Tool Update Message", EVENT_PLAYER_ACTIVATED, playerActivated)
	end
	

	EVENT_MANAGER:UnregisterForEvent(AD.name, EVENT_ADD_ON_LOADED)

	if debugMode then
		AD.initTime = os.rawclock() - startInit
		SLASH_COMMANDS['/adinittime'] = function() d(string.format("Artaeum took %dms to initialize", AD.initTime)) end
	end
end
 
-------------------------------------------------------------------------------------------------
--  Register Events --
-------------------------------------------------------------------------------------------------
EVENT_MANAGER:RegisterForEvent(AD.name, EVENT_ADD_ON_LOADED, AD.OnAddOnLoaded)
