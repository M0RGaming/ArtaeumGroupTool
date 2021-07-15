-- Guild Note Data Sharing Module
local AD = ArtaeumGroupTool
AD.Guild = {}
local guild = AD.Guild
local vars = {}


function guild.init()
	vars = AD.vars.Guild
	guild.createArrow()
end


guild.lastPos = {x=0,y=0}
--guild.listenTo = ""
guild.transmitTo = nil
--guild.guildID = -1 --Guild ID
guild.listening = false
guild.transmitting = false
guild.arrow = nil
guild.oldNote = ""
guild.phaseSeek = false
guild.markerShown = true










function guild.setListento(displayName)
	vars.listenTo = displayName
end
function guild.setGuild(guildID)
	vars.guildID = guildID
	guild.transmitTo = GetPlayerGuildMemberIndex(guildID)
end

function guild.toggleListen()
	if guild.listening then
		EVENT_MANAGER:UnregisterForEvent("AD Group Tool Note Listen", EVENT_GUILD_MEMBER_NOTE_CHANGED)
		d("Stopped Listening to the specified person")
		guild.listening = false
		guild.arrow:SetTarget(0, 0)
	else
		if vars.guildID == -1 then
			d('No guild specified, please run /adnoteguild guildID')
			return
		else
			EVENT_MANAGER:RegisterForEvent("AD Group Tool Note Listen", EVENT_GUILD_MEMBER_NOTE_CHANGED, guild.noteCallback)
			d("Listening for guild note updates from "..vars.listenTo.." in the guild "..GetGuildName(vars.guildID))
			guild.listening = true
		end
	end
end

function guild.noteCallback(event, guildID, displayName, note)
	--d("Incoming guild note from "..displayName.." in guild "..guildID..": "..note)
	if displayName == vars.listenTo and tonumber(guildID) == tonumber(vars.guildID) then
		--d("Data Correct")
		-- Incoming data will be in the form of "x,y"
		local x, y = note:match("([^,]+),([^,]+)")
		guild.lastPos = {x=tonumber(x),y=tonumber(y)}
		--d(guild.lastPos)
		guild.arrow:SetTarget(guild.lastPos.x, guild.lastPos.y)
	end
end


function guild.manualTransmit(displayName)
	if vars.guildID == -1 then
		d('No guild specified, please run /adnoteguild guildID')
		return
	else
		local transmitTo = GetGuildMemberIndexFromDisplayName(vars.guildID, displayName)
		local crown = GetGroupLeaderUnitTag()
		local crownX,crownY = GetMapPlayerPosition(crown) -- Get group leader's position
		SetGuildMemberNote(vars.guildID, transmitTo, crownX..","..crownY)
	end
end








function guild.autoTransmit()
	local crown = GetGroupLeaderUnitTag()
	local crownX,crownY = GetMapPlayerPosition(crown) -- Get group leader's position
	SetGuildMemberNote(vars.guildID, guild.transmitTo, crownX..","..crownY)
end


function guild.seekPhase()
	local t = os.time()
	if t % 10 == vars.phase then
		guild.transmitTo = GetGuildMemberIndexFromDisplayName(vars.guildID, vars.transmitTo)
		EVENT_MANAGER:RegisterForUpdate("AD Group Tool Note Transmit", 10000, guild.autoTransmit)
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
		arrowColour = "FF0000",

		distanceDigits = 4,
		distanceScale = 25,
		distanceMagnitude = 3,
		distanceHeight = 1,
		distanceColour = "FFFFFF",

		markerColour = "FF0000",
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