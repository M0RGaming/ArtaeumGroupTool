-- Guild Note Data Sharing Module
local AD = ArtaeumGroupTool
AD.Guild = {}
local guild = AD.Guild
local vars = {}
local LMP = LibMapPins

local function pinCreateCallback()
	if not LMP:IsEnabled("Group Share Pin") then return end
	local zone, subzone = LMP:GetZoneAndSubzone()
	if not (zone == "cyrodiil") then return end
	if not (subzone == "ava_whole") then return end
	LMP:CreatePin("Group Share Pin", "main pin", guild.lastPos.x, guild.lastPos.y)
end

local function rallyCreateCallback()
	if not LMP:IsEnabled("Group Rally Pin") then return end
	local zone, subzone = LMP:GetZoneAndSubzone()
	if not (zone == "cyrodiil") then return end
	if not (subzone == "ava_whole") then return end
	LMP:CreatePin("Group Rally Pin", "rally pin", guild.lastRally.x, guild.lastRally.y)
end



local pinLayoutData  = {
   level = 150,
   texture = "esoui/art/icons/mapkey/mapkey_groupleader.dds",
   tint = ZO_ColorDef:New(0,1,0),
}
local rallyPinData  = {
    level = 161, minSize = 100, texture = "EsoUI/Art/MapPins/MapRallyPoint.dds", isAnimated = true, framesWide = 32, framesHigh = 1, framesPerSecond = 32,
    tint = ZO_ColorDef:New(0,1,0),
}

function guild.init()
	vars = AD.vars.Guild
	guild.createArrow()
	--[[
	local editBox = ZO_AutoComplete:New(WINDOW_MANAGER:GetControlByName(AD_Settings_Listen))
	editBox:SetIncludeFlags({AUTO_COMPLETE_FLAG_GUILD})
	editBox:SetExcludeFlags({})
	editBox:SetOnlineOnly(AUTO_COMPLETION_ONLINE_OR_OFFLINE)
	editBox:SetMaxResults(MAX_AUTO_COMPLETION_RESULTS)
	]]
	LMP:AddPinType("Group Share Pin", pinCreateCallback, nil, pinLayoutData, "Group Share Location")
	LMP:AddPinType("Group Rally Pin", rallyCreateCallback, nil, rallyPinData, "Group Share Rally")
end


guild.lastPos = {x=0,y=0}
guild.lastRally = {x=0,y=0}

--guild.listenTo = ""
guild.transmitTo = nil
--guild.guildID = -1 --Guild ID
guild.listening = false
guild.transmitting = false
guild.arrow = nil
guild.oldNote = ""
guild.phaseSeek = false
guild.markerShown = true



local encoding = {
48,49,50,51,52,53,54,55,56,57, -- ASCII digits
65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85, -- ASCII uppercase
86,87,88,89,90,
97,98,99,100,101,102,103,104,105,106,107,108,109,110,111,112,113, -- ASCII lowercase
114,115,116,117,118,119,120,121,122,
192,193,194,195,196,197,198,199,200,201,202,203,204,205,206,207, -- Latin 1
208,209,210,211,212,213,214,215,216,217,218,219,220,221,222,223, -- Umlauts
224,225,226,227,228,229,230,231,232,233,234,235,236,237,238,239,
240,241,242,243,244,245,246,247,248,249,250,251,252,253,254,255,
256,257,258,259,260,261,262,263,264,265,266,267,268,269,270,271,
272,273,274,275,276,277,278,279,280,281,282,283,284,285,286,287,
288,289,290,291,292,293,294,295,296,297,298,299,300,301,302,303,
304,305,306,307,308,309,310,311,312,313,314,315,316,317,318,319,
320,321,322,323,324,325,326,327,328,329,330,331,332,333,334,335,
336,337,338,339,340,341,342,343,344,345,346,347,348,349,350,351,
352,353,354,355,356,357,358,359,360,361,362,363,364,365,366,367,
368,369,370,371,372,373,374,375,376,377,378,379,380,381,382,383,
384,385
}

-- utf8.char()



function guild.setListento(displayName)
	vars.listenTo = displayName
end

function guild.toggleListen()
	if guild.listening then
		EVENT_MANAGER:UnregisterForEvent("AD Group Tool Note Listen", EVENT_GUILD_MEMBER_NOTE_CHANGED)
		d("Stopped Listening to the specified person")
		guild.listening = false
		guild.arrow:SetTarget(0, 0)
		LMP:Disable("Group Share Pin")
		LMP:Disable("Group Rally Pin")
	else
		if vars.guildID == -1 then
			d('No guild specified, please run /adnoteguild guildID')
			return
		else
			EVENT_MANAGER:RegisterForEvent("AD Group Tool Note Listen", EVENT_GUILD_MEMBER_NOTE_CHANGED, guild.noteCallback)
			d("Listening for guild note updates from "..vars.listenTo.." in the guild "..GetGuildName(vars.guildID))
			guild.listening = true
			LMP:Enable("Group Share Pin")
			LMP:Enable("Group Rally Pin")
		end
	end
end

function guild.noteCallback(event, guildID, displayName, note)
	--d("Incoming guild note from "..displayName.." in guild "..guildID..": "..note)
	if displayName == vars.listenTo and tonumber(guildID) == tonumber(vars.guildID) then


		-- Incoming data will be in the form of "x,y"
		local x, y = note:match("([^,]+),([^,]+)\n")
		if x and y then
			guild.lastPos = {x=tonumber(x),y=tonumber(y)}
			guild.arrow:SetTarget(guild.lastPos.x, guild.lastPos.y)
			local pin = LMP:FindCustomPin("Group Share Pin", "main pin")
			if pin then
				pin:SetLocation(guild.lastPos.x, guild.lastPos.y)
			end
		end

		local rallyX, rallyY = note:match("\n([^,]+)|([^,]+)")
		if rallyX and rallyY then
			guild.lastRally = {x=tonumber(rallyX),y=tonumber(rallyY)}
			local rallyPin = LMP:FindCustomPin("Group Rally Pin", "rally pin")
			if rallyPin then
				rallyPin:SetLocation(guild.lastRally.x, guild.lastRally.y)
			end
		end

	end
end



local function getTransmitData()
	local crown = GetGroupLeaderUnitTag()
	local crownX,crownY = GetMapPlayerPosition(crown) -- Get group leader's position
	local rallyX,rallyY = GetMapRallyPoint() -- Get group rally marker
	return crownX..","..crownY.."\n"..rallyX.."|"..rallyY
end


function guild.manualTransmit(displayName)
	if vars.guildID == -1 then
		d('No guild specified, please run /adnoteguild guildID')
		return
	else
		local transmitTo = GetGuildMemberIndexFromDisplayName(vars.guildID, guild.transmitTo)		
		SetGuildMemberNote(vars.guildID, transmitTo, getTransmitData())
	end
end








function guild.autoTransmit()
	local crown = GetGroupLeaderUnitTag()
	local crownX,crownY = GetMapPlayerPosition(crown) -- Get group leader's position
	SetGuildMemberNote(vars.guildID, guild.transmitTo, getTransmitData())
end


function guild.seekPhase()
	local t = os.time()
	if t % 10 == vars.phase then
		guild.transmitTo = GetGuildMemberIndexFromDisplayName(vars.guildID, vars.transmitTo)
		EVENT_MANAGER:RegisterForUpdate("AD Group Tool Note Transmit", 10000, guild.autoTransmit)
		guild.autoTransmit()
		EVENT_MANAGER:UnregisterForUpdate("AD Group Tool Phase Seek")
		guild.phaseSeek = false
		d("Phase found, beginning transmition on phase "..vars.phase.." to user "..vars.transmitTo)
	end
end








function guild.createArrow()
	guild.arrow = Lib3DArrow:CreateArrow({
		depthBuffer = false,
		arrowMagnitude = 3,
		arrowScale = 1,
		arrowHeight = 1,
		arrowColour = "00FF00",

		distanceDigits = 4,
		distanceScale = 25,
		distanceMagnitude = 3,
		distanceHeight = 1,
		distanceColour = "FFFFFF",

		markerColour = "00FF00",
		markerScale = 1,
	})
end






function guild.toggleTransmit()
	if guild.transmitting then
		if guild.phaseSeek then
			EVENT_MANAGER:UnregisterForUpdate("AD Group Tool Phase Seek")
		else
			EVENT_MANAGER:UnregisterForUpdate("AD Group Tool Note Transmit")
		end
		d("Stopped transmitting to the specified person")
		guild.transmitting = false
	else
		if vars.guildID == -1 then
			d('No guild specified, please run /adnoteguild guildID')
			return
		else
			EVENT_MANAGER:RegisterForUpdate("AD Group Tool Phase Seek", 1000, guild.seekPhase)
			--d("Transmitting group leader position in the guild "..GetGuildName(vars.guildID))
			guild.transmitting = true
			guild.phaseSeek = true
		end
	end
end

function guild.updateColours()
	local rgb = vars.markerColour
	guild.arrow.arrow.chevron:SetColor(rgb[1],rgb[2],rgb[3])
	guild.arrow.marker.pillar:SetColor(rgb[1],rgb[2],rgb[3],rgb[4])
end


function guild.toggleMarker()
	if guild.markerShown then
		guild.arrow.marker:SetHidden(true)
		guild.markerShown = false
	else
		guild.arrow.marker:SetHidden(false)
		guild.markerShown = true
	end
end


SLASH_COMMANDS["/adlistento"] = guild.setListento --
SLASH_COMMANDS["/adlisten"] = guild.toggleListen
SLASH_COMMANDS["/adtransmit"] = guild.toggleTransmit
SLASH_COMMANDS["/adnoteguild"] = guild.setGuild --
SLASH_COMMANDS["/admanual"] = guild.manualTransmit
SLASH_COMMANDS["/admarker"] = guild.toggleMarker