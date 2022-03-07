ArtaeumGroupTool = {}
local AD = ArtaeumGroupTool

-- Written by M0R_Gaming

AD.name = "ArtaeumGroupTool"
AD.varversion = 1

AD.Settings = {}
AD.Settings.DefaultSettings = {
	currentSavedPreset = "",
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
		enabled = false,
		showMarker = true,
		showArrow = true,
		markerType = "Crown",
		cyrodilOnly = false,
		markerColour = {0,1,1,0.5}
	},
	Group = {
		enabled = false,
		cyrodilOnly = true,
		frequency = 1000,
		windowLocations = {},
		windowLocked = false,
		amountOfWindows = 1,
		hideUI = false,
		hideBaseUnitFrames = false,
		barToShare = nil,
		scale = 1,
		colours = {
			marker = {1,0,0,0.5},
			standardHealth = {0.8,26/255,26/255,0.8},
			fullUlt = {0,0.8,0,0.8}
		},
		UI = "Custom" -- Vanilla, Custom, AUI, Bandits
	}
}


AD.Profiles = {}
AD.Profiles.DefaultSettings = {
	["M0R's Default"] = {
		Group = {
	        windowLocations = { {43.5,75} , {289.5,75} },
	        frequency = 1000,
	        hideBaseUnitFrames = true,
	        windowLocked = true,
	        enabled = true,
	        amountOfWindows = 2,
	        scale = 1,
	        colours = {
				marker = {1,0,0,0.5},
				standardHealth = {0.8,26/255,26/255,0.8},
				fullUlt = {0,0.8,0,0.8}
			},
	        cyrodilOnly = false,
	        hideCustomFrame = false,
	        barToShare = 1,
			UI = "Custom",
	    },
	    FD = {
		    rightClickMenu=true
		},
	    SOC = {
	        whitelistGuild = 366011,
	        radius = 25500,
	        offCrownTimer = 300,
	    },
	    Crown = {
	        markerType = "Crown",
	        showMarker = true,
	        cyrodilOnly = false,
	        showArrow = true,
	        markerColour = {0,1,1,0.5},
	        enabled = true,
	    },
	    Guild = {
	        transmitTo = "@M0R_Gaming",
	        phase = 0,
	        guildID = 366011,
	        listenTo = "@M0R_Gaming",
	        markerColour = {0,1,0,0.5}
	    },
	    Discord = {
	    	discordLink = "the link in the guild MOTD.",
	    	discordInvite = "Come join us in discord! Even if you don't have a mic, it still helps us coordinate attacks! Come join us at"
	    }
	}
}


local toCopy = {"Group", "FD", "SOC", "Crown", "Guild", "Discord"}

function AD.Profiles.set(name)
	if AD.profiles and AD.profiles[name] then
		--local varMeta = getmetatable(AD.vars)
		for i=1,#toCopy do
			AD.vars[toCopy[i]] = ZO_DeepTableCopy(AD.profiles[name][toCopy[i]])
		end
		--AD.vars = ZO_DeepTableCopy(AD.profiles[name], AD.vars)
		--CopyDefaults(AD.vars, AD.profiles[name])
		--setmetatable(AD.vars, varMeta)
		AD_Preset_Current:UpdateValue()
		ZO_Alert(UI_ALERT_CATEGORY_ALERT, SOUNDS.POSITIVE_CLICK, "|c00ff00Loaded Preset!|r")
	else
		ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, "|cff0000The specified preset does not exist!|r")
	end
end

function AD.Profiles.save(name)
	if name == "" then
		ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, "|cff0000No Preset Name was provided!|r")
		return
	end
	if AD.profiles then
		--AD.profiles[name] = ZO_DeepTableCopy(getmetatable(AD.vars)['__index'])
		AD.profiles[name] = {}
		for i=1,#toCopy do
			AD.profiles[name][toCopy[i]] = ZO_DeepTableCopy(AD.vars[toCopy[i]])
		end
		ZO_Alert(UI_ALERT_CATEGORY_ALERT, SOUNDS.POSITIVE_CLICK, "|c00ff00Saved Preset!|r")
		table.insert(AD.Settings.profileList,name)
		AD_Preset_List:UpdateChoices()
		AD_Preset_List:UpdateValue()
		AD_Preset_Current:UpdateValue()

	else
		ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, "|cff0000Failed to save preset!|r")
	end
end

function AD.Profiles.delete(name)
	if AD.profiles and AD.profiles[name] then
		--table.remove(AD.profiles,name)
		AD.profiles[name] = nil
		ZO_Alert(UI_ALERT_CATEGORY_ALERT, SOUNDS.NEGATIVE_CLICK, "|cff0000Deleted Preset!|r")
		for i=1,#AD.Settings.profileList do
			if AD.Settings.profileList[i] == name then
				table.remove(AD.Settings.profileList,i)
				break
			end
		end
		AD_Preset_List:UpdateChoices()
	else
		ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, "|cff0000Failed to delete preset!|r")
	end
end



-- The following was adapted from https://wiki.esoui.com/Circonians_Stamina_Bar_Tutorial#lua_Structure

-------------------------------------------------------------------------------------------------
--  OnAddOnLoaded  --
-------------------------------------------------------------------------------------------------
function AD.OnAddOnLoaded(event, addonName)

	if addonName == "RdKGroupTool" then AD.rdk = true end
	if addonName ~= AD.name then return end

	AD:Initialize()
end
 
-------------------------------------------------------------------------------------------------
--  Initialize Function --
-------------------------------------------------------------------------------------------------
function AD:Initialize()
	-- Addon Settings Menu
	AD.vars = ZO_SavedVars:NewAccountWide("ADVars", AD.varversion, nil, AD.Settings.DefaultSettings)
	AD.profiles = ZO_SavedVars:NewAccountWide("ADProfiles", 1, nil, AD.Profiles.DefaultSettings)
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