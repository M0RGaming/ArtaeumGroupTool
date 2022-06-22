-- Group Ult Sharing Module
local AD = ArtaeumGroupTool
AD.Group = {}
local group = AD.Group
local vars = {}
local LMP = LibMapPing
local LGPS = LibGPS3


local toplevels = {}
local frameDB = {}


AD.last = {} -- TESTING
group.toSend = {
	assistPing = false
}
group.arrow = nil


group.running = false


group.units = {}




-- Data that is transfered: 
--[[
1 [free bit (true or false)] (previously verification)
1 camp lock
1 assist ping - if button pressed, beam of light is placed on user
4 hammer bar (possibly able to remove, depending on demand) GetUnitPower('player',POWERTYPE_DAEDRIC)

8 ult ID
1 [free bit (true or false)] (previously hammer)


7 ult bar
1 [free bit (true or false)] may implement proxy timer

4 mag bar
4 stam bar
]]



function group.init()
	vars = AD.vars.Group

	if vars.enabled then
		
		if vars.UI == "Custom" then

			--[[
			SecurePostHook(UNIT_FRAMES, "CreateFrame", function(_, unitTag, anchors, barTextMode, style)
				if style == "ZO_RaidUnitFrame" then --ZO_GroupUnitFrame --ZO_RaidUnitFrame
					if frameDB[unitTag] == nil then
						group.setupBox(unitTag)
					end
				end
			end)
			]]


			group.createTopLevels()
			AD.initAnchors(toplevels)
			--[[
			if vars.hideBaseUnitFrames then
				ZO_UnitFramesGroups:SetHidden(true)
			end
			]]
			
			group.fragments = {}
			for i=1,#toplevels do
				group.fragments[i] = ZO_HUDFadeSceneFragment:New(toplevels[i], DEFAULT_SCENE_TRANSITION_TIME, 0)
			end
			if vars.hideUI then
				for i=1,#toplevels do
					toplevels[i]:SetHidden(true)
				end
			else
				HUD_SCENE:AddFragmentGroup(group.fragments)
				HUD_UI_SCENE:AddFragmentGroup(group.fragments)
			end


			for i=1,12 do
				local topLevelID = math.floor((i-1)*AD.vars.Group.amountOfWindows/12)+1
				frameDB['group'..i] = AD.Frame:new('group'..i, toplevels[topLevelID])					
			end

			group.scaleWindow()

			if not vars.windowLocked then
				ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, "|cff0000Artaeum Group Tool's group UI has not been locked.|r")
				group.unlockWindow()
			end

			-- adapted from ZOS's Code
	    	ZO_MostRecentPowerUpdateHandler:New("AD_UnitFrames", group.PowerUpdateHandlerFunction)
		else
			SecurePostHook(UNIT_FRAMES, "CreateFrame", function(_, unitTag, anchors, barTextMode, style)
				if style == "ZO_RaidUnitFrame" then --ZO_GroupUnitFrame --ZO_RaidUnitFrame
					if frameDB[unitTag] == nil then
						frameDB[unitTag] = AD.Frame:new(unitTag, toplevels[topLevelID])
					end
				end
			end)
			group.moveBoxes()
		end

		EVENT_MANAGER:RegisterForEvent("AD Group Tool Group Activated", EVENT_PLAYER_ACTIVATED, group.playerActivated)
		group.createArrow()
		group.arrow:SetTarget(0, 0)

	    -- Mute all ping sounds.
		SOUNDS.MAP_PING = nil
		SOUNDS.MAP_PING_REMOVE = nil


		if AD.rdk then
			if RdKGTool.util.networking.state.isRunning then
				EVENT_MANAGER:UnregisterForUpdate("RdKGroupToolUtilNetworking")
				RdKGTool.util.networking.state.isRunning = false
			else
				LMP:RegisterCallback("BeforePingAdded", RdKGTool.util.networking.OnBeforePingAdded)
				LMP:RegisterCallback("AfterPingRemoved", RdKGTool.util.networking.OnAfterPingRemoved)
			end
		end


	end
end

function group.hideUI(value)
	if value then
		HUD_SCENE:RemoveFragmentGroup(group.fragments)
		HUD_UI_SCENE:RemoveFragmentGroup(group.fragments)
	else
		HUD_SCENE:AddFragmentGroup(group.fragments)
		HUD_UI_SCENE:AddFragmentGroup(group.fragments)
	end
	for i=1,#toplevels do
		toplevels[i]:SetHidden(value)
	end
end


function group.createTopLevels()
	for i=1,vars.amountOfWindows do
		toplevels[i] = CreateControlFromVirtual("AD_Group_TopLevel"..i,nil,"AD_Group_TopLevel")
		toplevels[i]:SetHeight(40*12/vars.amountOfWindows)
		if not vars.windowLocations[i] then
			vars.windowLocations[i] = {0,0}
		end
		WINDOW_MANAGER:GetControlByName("AD_Group_TopLevel"..i.."Name"):SetText("Group "..i)
		toplevels[i]:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, vars.windowLocations[i][1], vars.windowLocations[i][2])
	end
end


local directions = {
	["North"] = {-1/8,1/8},
	["North East"] = {1/8,3/8},
	["East"] = {3/8,5/8},
	["South East"] = {5/8,7/8},
	["South West"] = {-7/8,-5/8},
	["West"] = {-5/8,-3/8},
	["North West"] = {-3/8,-1/8}
}

function group.requestAssistPing()
	group.toSend.assistPing = true
	local playerX,playerY = GetMapPlayerPosition('player')
	local crownX,crownY = GetMapPlayerPosition(GetGroupLeaderUnitTag())
	local dir = math.atan2(playerX-crownX,crownY-playerY)/math.pi
	local direction = ""
	for key,value in pairs(directions) do
		if dir >= value[1] and dir < value[2] then
			direction = key
			break
		end
	end
	-- Do south seperatly cause pairs doesnt go in order
	if direction == "" and dir >= -9/8 and dir < 9/8 then direction = "South" end 
	if direction ~= "" then
		d("You are "..direction.." of crown.")
	end
end

function group.ping()
	group.toSend:send()
end


function group.createArrow()
	group.arrow = Lib3DArrow:CreateArrow({
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



--AD.hammer = 0
function group.toSend:send()
	local assistPing = self.assistPing and 1 or 0
	self.assistPing = false
	local campLock = (GetNextForwardCampRespawnTime() > GetGameTimeMilliseconds()) and 1 or 0
	local hammerCurrent, hammerMax = GetUnitPower('player',POWERTYPE_DAEDRIC)
	if hammerMax == 0 then hammerMax = 1 end
	local hammerBar = math.floor(hammerCurrent/hammerMax*15)
	--local hammerBar = AD.hammer
	local ult = {}
	local ultID = GetSlotBoundId(8, vars.barToShare)
	ult.id = group.ultiIndexes[ultID] or 255
	ult.current = GetUnitPower('player',POWERTYPE_ULTIMATE)
	ult.max = GetAbilityCost(ultID)
	ult.percent = math.floor(ult.current/ult.max*100)
	if ult.percent > 100 then ult.percent = 100 end
	if ult.max <= 0 then ult.percent = 0 end
	local magCurrent, magMax = GetUnitPower('player',POWERTYPE_MAGICKA)
	local magBar = math.floor(magCurrent/magMax*15)
	local stamCurrent, stamMax = GetUnitPower('player',POWERTYPE_STAMINA)
	local stamBar = math.floor(stamCurrent/stamMax*15)

	local x = group.writeStream(
		{0,campLock,assistPing,hammerBar,ult.id,0},
		{1,1,1,4,8,1}
	)
	local y = group.writeStream(
		{ult.percent,0,magBar,stamBar},
		{7,1,4,4}
	)
	LGPS:PushCurrentMap()
	if not LMP:IsPingSuppressed(MAP_PIN_TYPE_PING) then
		LMP:SuppressPing(MAP_PIN_TYPE_PING)
	end
	SetMapToMapId(group.mapID)
	LMP:SetMapPing(
		MAP_PIN_TYPE_PING,
		MAP_TYPE_LOCATION_CENTERED,
		x*group.stepSize,
		y*group.stepSize
	)
	LGPS:PopCurrentMap()
end


local hammerWeilder = ''

function group.pingCallback(pingType,pingTag,x,y,isLocalPlayerOwner)
	--d(""..x.." "..y.." "..pingTag)
	if(pingType == MAP_PIN_TYPE_PING) then
		if frameDB[pingTag] then
			LGPS:PushCurrentMap()
			SetMapToMapId(group.mapID)
			x, y = LMP:GetMapPing(pingType, pingTag)
			if(not LMP:IsPositionOnMap(x, y)) then
				SetMapToMapListIndex(group.rdkMap) -- RDK's location
				x, y = LMP:GetMapPing(pingType, pingTag)
				--d("RDK from "..GetUnitDisplayName(pingTag))
				--d(LMP:IsPositionOnMap(x, y))
				--d("")
				if (LMP:IsPositionOnMap(x, y)) then
					-- RDK is sending ping
					LGPS:PopCurrentMap()
					LMP:SuppressPing(pingType, pingTag)
					group.readFromRDK(pingTag,x,y)
					return
				else
					LGPS:PopCurrentMap()
					return
				end
			end
			LGPS:PopCurrentMap()
			LMP:SuppressPing(pingType, pingTag)

			
			--d(""..(x / group.stepSize + 0.5).." "..(y / group.stepSize + 0.5).." "..pingTag)
			x = zo_round(x / group.stepSize + 0.5)
			y = zo_round(y / group.stepSize + 0.5)

			local outstreamX = group.readStream(x,{1,1,1,4,8,1})
			local outstreamY = group.readStream(y,{7,1,4,4})
			--d(GetAbilityName(group.ultiIndexes[outstreamX[5]]))
			AD.last = {outstreamX, outstreamY}
			-- {0,campLock,assistPing,hammerBar,0,ult.id}
			-- {ult.percent,0,magBar,stamBar}

			local campLock = (outstreamX[2] == 1) and true or false
			if campLock then
				frameDB[pingTag]:SetEdgeColor(1,0,0,1)
			else
				--AD.last = frameDB[pingTag]
				frameDB[pingTag]:SetEdgeColor(1,1,1,1)
			end

			-- Set Ult
			local ultIcon = group.ultList[group.ultiIndexes[outstreamX[5]]]
			if ultIcon then
				frameDB[pingTag]:setUlt(outstreamY[1],ultIcon)
				frameDB[pingTag].image:SetColor(1,1,1)
			end

			-- Handle assist pings
			if (outstreamX[3] == 1) then
				local px, py = GetMapPlayerPosition(pingTag)
				group.arrow:SetTarget(px, py)
				zo_callLater(function() group.arrow:SetTarget(0, 0) end, 12500)
			end


			
			if (outstreamX[4] == 0) then
				if (hammerWeilder == pingTag) then
					if not HUD_DAEDRIC_ENERGY_METER:IsHidden() then HUD_DAEDRIC_ENERGY_METER:UpdateVisibility() end
					hammerWeilder = ''
				end
			else
				if (hammerWeilder == pingTag) then
					if HUD_DAEDRIC_ENERGY_METER:IsHidden() then
						HUD_DAEDRIC_ENERGY_METER:SetHiddenForReason("daedricArtifactInactive",false,SHOULD_FADE_OUT)
					end
					HUD_DAEDRIC_ENERGY_METER:UpdateEnergyValues(outstreamX[4],15)
				else
					hammerWeilder = pingTag
				end
			end
			

		else
			LMP:SuppressPing(pingType, pingTag)
		end
	end
end

-- Adapted from RdK Group Tool
function group.OnAfterPingRemoved(pingType, pingTag, x, y, isPingOwner)
	if (pingType == MAP_PIN_TYPE_PING) then
		LMP:UnsuppressPing(pingType, pingTag)
	end
end







function group.readFromRDK(pingTag,x,y)
	x = math.floor(x / group.rdkStep + 0.5) -- only x is needed, y contains mag + stam in a 7,1,7,1 bitstream
	local outstreamX = group.readStream(x,{8,1,7})
	local ultID = outstreamX[1]
	local ultPercent = outstreamX[3]
	--d(outstreamX)
	if ultID > #group.rdkUlts then return end
	local ultIcon = group.ultList[group.rdkUlts[ultID]]
	if ultIcon then
		frameDB[pingTag]:setUlt(ultPercent,ultIcon)
		frameDB[pingTag].image:SetColor(0.6,0.2,0.2)
	end
	
end








function group.updateDead(_, unitTag, isDead)
	if frameDB[unitTag] then
		frameDB[unitTag]:SetDead(isDead)
	end
end

function group.updateOnline(_, unitTag, isOnline)
	if frameDB[unitTag] then
		frameDB[unitTag]:SetOnline(isOnline)
	end
end


-- Adapted from zos
function group.PowerUpdateHandlerFunction(unitTag, powerPoolIndex, powerType, powerPool, powerPoolMax)
	if powerType == POWERTYPE_HEALTH and frameDB[unitTag] then
	    local unitFrame = frameDB[unitTag]
        local oldHealth = unitFrame.health:GetValue()
        if oldHealth == powerPool then return end

        if oldHealth ~= nil and oldHealth == 0 then
            -- Unit went from dead to non dead...update reaction
            unitFrame:SetDead(false)
            return
        end
        if powerPool == 0 then
        	unitFrame:SetDead(true)
        	return
        end
    	unitFrame:SetHealth(powerPool,powerPoolMax)
    end
end








--Need to find alternative
function group.unitCreate(_, unitTag)
	if not (unitTag:find("group") or IsUnitGrouped(unitTag)) then return end
	--d("Created "..unitTag)
	group.groupUpdate()
end

function group.unitDestroy(_, unitTag)
	if not (unitTag:find("group") or IsUnitGrouped(unitTag)) then return end
	--d("Destroyed "..unitTag)
	group.groupUpdate()
end









function group.groupLeadChange()
	for i=1,12 do
		if frameDB['group'..i] then
			frameDB['group'..i]:setGroupLeader()
		end
	end
end


-- Events that consider all possible group join/leave events and adapt the UI respectivly.
function group.groupJoinLeave(eventCode, _, _, isLocalPlayer)
	group.groupUpdate()
	if isLocalPlayer then
		if IsUnitGrouped('player') then
			EVENT_MANAGER:RegisterForUpdate("AD Group Tool Group Ping", vars.frequency, group.ping)
		else
			EVENT_MANAGER:UnregisterForUpdate("AD Group Tool Group Ping")
		end
	end
end

function group.groupUpdate()
	for i=1,12 do
		if frameDB['group'..i] then
			frameDB['group'..i]:Update()
		end
	end
	--[[
	if not IsUnitGrouped('player') then
		for i=1,12 do
			local frame = frameDB[i]
			if frame then frame.frame:SetHidden(true) end
		end
		return
	end
	for i=1,12 do
		local unitTag = GetGroupUnitTagByIndex(i)
		local frame = frameDB[i]
		if frame then
			if DoesUnitExist(unitTag) then 
				frame:Update(unitTag)
			else 
				frame.frame:SetHidden(true)
			end
		end
	end
	--]]
end







--TODO: Replace this entire thing with transform scale next patch
function group.scaleWindow()
	local scale = vars.scale
	for i=1,#toplevels do
		toplevels[i]:SetScale(scale)
	end
end


function group.showWindows()
	for i=1,#toplevels do
		toplevels[i]:SetHidden(false)
	end
end



function group.moveBoxes()

	local _,topl,frame,top,x,y,z = ZO_LargeGroupAnchorFrame2:GetAnchor()
	ZO_LargeGroupAnchorFrame2:SetAnchor(topl,frame,top,x+40,y,z)
	local _,topl,frame,top,x,y,z = ZO_LargeGroupAnchorFrame3:GetAnchor()
	ZO_LargeGroupAnchorFrame3:SetAnchor(topl,frame,top,x+80,y,z)

end



function group.updateColours()
	for i=1,12 do
		local frame = frameDB['group'..i]
		percentHidden = frame.bar:GetValue()
		if percentHidden == 0 then
			local rgb = vars.colours.fullUlt
			frame.health:SetColor(rgb[1],rgb[2],rgb[3],rgb[4])
		else
			local rgb = vars.colours.standardHealth
			frame.health:SetColor(rgb[1],rgb[2],rgb[3],rgb[4])
		end
	end
end





function group.unlockWindow()
	for i=1,#toplevels do
		local toplevel = toplevels[i]
		toplevel:SetMouseEnabled(true)
		WINDOW_MANAGER:GetControlByName("AD_Group_TopLevel"..i.."BG"):SetHidden(false)
		WINDOW_MANAGER:GetControlByName("AD_Group_TopLevel"..i.."Name"):SetHidden(false)
	end
	vars.windowLocked = false
end

function group.lockWindow()
	for i=1,#toplevels do
		local toplevel = toplevels[i]
		toplevel:SetMouseEnabled(false)
		WINDOW_MANAGER:GetControlByName("AD_Group_TopLevel"..i.."BG"):SetHidden(true)
		WINDOW_MANAGER:GetControlByName("AD_Group_TopLevel"..i.."Name"):SetHidden(true)

		if not vars.windowLocations[i] then
			vars.windowLocations[i] = {}
		end
		vars.windowLocations[i][1] = toplevel:GetLeft()
		vars.windowLocations[i][2] = toplevel:GetTop()
	end
	vars.windowLocked = true
end








--/script PingMap(MAP_PIN_TYPE_PLAYER_WAYPOINT, 1, 1 / 2^16, 1 / 2^16) StartChatInput(table.concat({GetMapPlayerWaypoint()}, ","))
-- Adapted from RdK group tool, who adapted it from lib group socket
-- 1.1058949894505e-05,1.1058949894505e-05
--group.stepSize = 1.333333329967e-05 -- For some reason cyro's step works, but artaeums doesnt? 
--group.mapID = 33
group.mapID = 1429
group.stepSize = 1.1058949894505e-05


group.rdkMap = 23
group.rdkStep = 1.4285034012573e-005

-- 1.1058949894505e-05 in Artaeum (ID = 33)
-- 1.333333329967e-05 in Cyro (ID = 14)
-- 1.4285034012573e-005 from LGS in Coldharbour

-- breakdownArray is in the form of [1,1,2,4] or something, where the number refer to how long to read
function group.readStream(stream, breakdownArray)
	local value = 0
	local outstream = {}
	local current = 0
	for i=#breakdownArray,1,-1 do
		value = 0
		for j=breakdownArray[i],1,-1 do
			current = (stream%2)
			value = value + current * 2^(breakdownArray[i]-j)
			stream = (stream-current)/2
		end
		outstream[i] = value
	end
	return outstream
end


-- Example inputs: {1,0,10} {1,1,4}, stream is a list of data points
function group.writeStream(stream, breakdownArray)
	local index = 0
	local outstream = 0
	for i=#breakdownArray,1,-1 do
		outstream = outstream + stream[i] * 2^(index)
		index = index + breakdownArray[i]
	end
	return outstream
end





function group.updateSharing(sharing)

	if group.running and not sharing then
		EVENT_MANAGER:UnregisterForUpdate("AD Group Tool Group Ping")
		LMP:UnregisterCallback('BeforePingAdded', group.pingCallback)
		LMP:UnregisterCallback('AfterPingRemoved', group.OnAfterPingRemoved)
		EVENT_MANAGER:UnregisterForEvent("AD Group Tool Unit Created", EVENT_UNIT_CREATED)
		EVENT_MANAGER:UnregisterForEvent("AD Group Tool Unit Destroyed", EVENT_UNIT_DESTROYED)
		EVENT_MANAGER:UnregisterForEvent("AD Group Tool Group Join", EVENT_GROUP_MEMBER_JOINED)
		EVENT_MANAGER:UnregisterForEvent("AD Group Tool Group Leave", EVENT_GROUP_MEMBER_LEFT)
		EVENT_MANAGER:UnregisterForEvent("AD Group Tool Group Change", EVENT_LEADER_UPDATE)
		EVENT_MANAGER:UnregisterForEvent("AD Group Tool Group Update", EVENT_GROUP_UPDATE)
		EVENT_MANAGER:UnregisterForEvent("AD Group Tool Group Death", EVENT_UNIT_DEATH_STATE_CHANGED)
		EVENT_MANAGER:UnregisterForEvent("AD Group Tool Group Connect", EVENT_GROUP_MEMBER_CONNECTED_STATUS)
		

		if vars.UI == "Custom" then
			for i=1,12 do
				frameDB['group'..i].frame:SetHidden(true)
			end
			ZO_UnitFramesGroups:SetHidden(false)
		end
		group.running = false
		

	elseif not group.running and sharing then
		LMP:RegisterCallback('BeforePingAdded', group.pingCallback)
		LMP:RegisterCallback('AfterPingRemoved', group.OnAfterPingRemoved)
		EVENT_MANAGER:RegisterForEvent("AD Group Tool Unit Created", EVENT_UNIT_CREATED, group.unitCreate)
		EVENT_MANAGER:RegisterForEvent("AD Group Tool Unit Destroyed", EVENT_UNIT_DESTROYED, group.unitDestroy)
		EVENT_MANAGER:RegisterForEvent("AD Group Tool Group Join", EVENT_GROUP_MEMBER_JOINED, group.groupJoinLeave)
		EVENT_MANAGER:RegisterForEvent("AD Group Tool Group Leave", EVENT_GROUP_MEMBER_LEFT, group.groupJoinLeave)
		EVENT_MANAGER:RegisterForEvent("AD Group Tool Group Change", EVENT_LEADER_UPDATE, group.groupLeadChange)
		EVENT_MANAGER:RegisterForEvent("AD Group Tool Group Update", EVENT_GROUP_UPDATE, group.groupUpdate)
		EVENT_MANAGER:RegisterForEvent("AD Group Tool Group Death", EVENT_UNIT_DEATH_STATE_CHANGED, group.updateDead)
		EVENT_MANAGER:RegisterForEvent("AD Group Tool Group Connect", EVENT_GROUP_MEMBER_CONNECTED_STATUS, group.updateOnline)	
		if IsUnitGrouped("player") then
			EVENT_MANAGER:RegisterForUpdate("AD Group Tool Group Ping", vars.frequency, group.ping)
		end

		if vars.UI == "Custom" then
			if vars.hideBaseUnitFrames then
				ZO_UnitFramesGroups:SetHidden(true)
			end
		end

		group.running = true
		group.groupLeadChange()
		group.groupUpdate()
	elseif group.running and sharing then
		group.groupLeadChange()
		group.groupUpdate()
	end

end




function group.playerActivated(...)
	--d(...)
	local active = (not vars.cyrodilOnly) or ((IsPlayerInAvAWorld() or IsActiveWorldBattleground()) and vars.cyrodilOnly) 
	group.updateSharing(active)
	--[[
	if IsActiveWorldBattleground() then
		--d("Player is in a BG")
		--d(GetCurrentMapId())
		group.updateSharing()
	elseif (not vars.cyrodilOnly) or (IsPlayerInAvAWorld() and vars.cyrodilOnly) then
		group.updateSharing()
	else
		EVENT_MANAGER:UnregisterForUpdate("AD Group Tool Group Ping")
	end


	--RDK uses the following
	if RdKGTool.group.ro.state.registredGlobalConsumers then
		EVENT_MANAGER:UnregisterForUpdate(RdKGroupToolResourceOverviewNetworking)
		EVENT_MANAGER:UnregisterForUpdate(RdKGroupToolResourceOverviewMessageUpdate)
	end

	]]

end



local function ADpopulate()
	for i=1,12 do
		frameDB['group'..i].index = i
		frameDB['group'..i]:setAnchors()
		frameDB['group'..i].frame:SetHidden(false)
	end
end








ZO_CreateStringId("SI_BINDING_NAME_ARTAEUMGROUPTOOL_REQUEST_PING", "Send a assist ping.")
SLASH_COMMANDS["/ping"] = group.ping
--[[

SLASH_COMMANDS["/adlistento"] = guild.setListento --
SLASH_COMMANDS["/adlisten"] = guild.toggleListen
SLASH_COMMANDS["/adtransmit"] = guild.toggleTransmit
SLASH_COMMANDS["/adnoteguild"] = guild.setGuild --
SLASH_COMMANDS["/admanual"] = guild.manualTransmit
SLASH_COMMANDS["/admarker"] = guild.toggleMarker



SecurePostHook(UnitFrame, "New", function(unitTag, anchors, barTextMode, style, templateName)
	if style == "ZO_RaidUnitFrame" then
		d("MAKING NEW RAID")
	else
		d("MAKING NEW GROUP")
	end
end)




/script CreateControl("group4ULT1",test.frame,8)
/script group4ULT1:SetDimensions(45,40)
/script d(group4ULT1:SetMinMax(0,20))
/script group4ULT1:SetValue(5)
/script d(group4ULT1:SetColor(0))
/script d(group4ULT1:SetAlpha(0.5))
/script d(group4ULT1:SetOrientation(0))
/script d(group4ULT1:SetBarAlignment(1))
/script group4ULT1:SetAnchor(8,nil,8,-4,0,0)

]]--



--[[

-- Code for getting this, done in a browser w/JS

httpGetAsync('esolog.uesp.net/exportJson.php?table=minedSkills',(x) => {
	test = JSON.parse(x)
	console.log(done)
})

test2 = []
test.minedSkills.forEach((x) => {if (x.mechanic == 10) {test2.push(x)}})
test3 = []
test4 = test2.filter((value) => {
	if (test3.includes(value.name)) {
		return false
	} else {
		test3.push(value.name)
		return true
	}
})

output = ''
test4.forEach((x) => {output += `[${x.id}] = '${x.texture}', -- ${x.name}\n`})

]]--

group.ultList = { -- Gives texture for in game skill ID
	[15957] = '/esoui/art/icons/ability_dragonknight_018.dds', -- Magma Armor
	[16536] = '/esoui/art/icons/ability_mageguild_005.dds', -- Meteor
	[16538] = '/esoui/art/icons/ability_debuff_knockback.dds', -- Meteor Knockback
	[17874] = '/esoui/art/icons/ability_dragonknight_018_a.dds', -- Magma Shell
	[17878] = '/esoui/art/icons/ability_dragonknight_018_b.dds', -- Corrosive Armor
	[20671] = '/esoui/art/icons/ability_warrior_027.dds', -- Molten Fury
	[20674] = '/esoui/art/icons/ability_mage_065.dds', -- Molten Fury Cooldowns
	[21752] = '/esoui/art/icons/ability_templar_nova.dds', -- Nova
	[21754] = '/esoui/art/icons/ability_debuff_major_maim.dds', -- Major Maim
	[21755] = '/esoui/art/icons/ability_templar_solar_prison.dds', -- Solar Prison
	[21758] = '/esoui/art/icons/ability_templar_solar_disturbance.dds', -- Solar Disturbance
	[22138] = '/esoui/art/icons/ability_templar_radial_sweep.dds', -- Radial Sweep
	[22139] = '/esoui/art/icons/ability_templar_crescent_sweep.dds', -- Crescent Sweep
	[22144] = '/esoui/art/icons/ability_templar_empowering_sweep.dds', -- Empowering Sweep
	[22223] = '/esoui/art/icons/ability_templar_rite_of_passage.dds', -- Rite of Passage
	[22226] = '/esoui/art/icons/ability_templar_practiced_incantation.dds', -- Practiced Incantation
	[22229] = '/esoui/art/icons/ability_templar_remembrance.dds', -- Remembrance
	[22233] = '/esoui/art/icons/ability_buff_major_protection.dds', -- Major Protection
	[23492] = '/esoui/art/icons/ability_sorcerer_greater_storm_atronach.dds', -- Greater Storm Atronach
	[23495] = '/esoui/art/icons/ability_sorcerer_endless_atronachs.dds', -- Summon Charged Atronach
	[23634] = '/esoui/art/icons/ability_sorcerer_storm_atronach.dds', -- Summon Storm Atronach
	[23659] = '/esoui/art/icons/ability_sorcerer_storm_atronach.dds', -- Storm Atronach Impact
	[23664] = '/esoui/art/icons/ability_sorcerer_greater_storm_atronach.dds', -- Greater Storm Atronach Impact
	[23667] = '/esoui/art/icons/ability_sorcerer_endless_atronachs.dds', -- Charged Atronach Impact
	[24785] = '/esoui/art/icons/ability_sorcerer_overload.dds', -- Overload
	[24792] = '/esoui/art/icons/ability_sorcerer_overload.dds', -- Light Attack (Overload)
	[24794] = '/esoui/art/icons/ability_sorcerer_overload.dds', -- Heavy Attack (Overload)
	[24799] = '/esoui/art/icons/ability_mage_065.dds', -- Overload End
	[24804] = '/esoui/art/icons/ability_sorcerer_energy_overload.dds', -- Energy Overload
	[24806] = '/esoui/art/icons/ability_sorcerer_power_overload.dds', -- Power Overload
	[24810] = '/esoui/art/icons/ability_sorcerer_power_overload.dds', -- Heavy Attack (Power Overload)
	[25091] = '/esoui/art/icons/ability_nightblade_018.dds', -- Soul Shred
	[25169] = '/esoui/art/icons/ability_rogue_021.dds', -- Soul Leech
	[25411] = '/esoui/art/icons/ability_nightblade_015.dds', -- Consuming Darkness
	[26111] = '/esoui/art/icons/ability_mage_065.dds', -- Shock Dummy
	[26112] = '/esoui/art/icons/ability_mage_065.dds', -- Remove
	[26380] = '/esoui/art/icons/ability_debuff_snare.dds', -- Rite of Passage Self Snare
	[27706] = '/esoui/art/icons/ability_sorcerer_monsoon.dds', -- Negate Magic
	[27786] = '/esoui/art/icons/ability_mage_065.dds', -- Overload Remover
	[28341] = '/esoui/art/icons/ability_sorcerer_crushing_monsoon.dds', -- Suppression Field
	[28348] = '/esoui/art/icons/ability_sorcerer_rushing_winds.dds', -- Absorption Field
	[28434] = '/esoui/art/icons/ability_mage_065.dds', -- Remove Overload
	[28988] = '/esoui/art/icons/ability_dragonknight_006.dds', -- Dragonknight Standard
	[29012] = '/esoui/art/icons/ability_dragonknight_009.dds', -- Dragon Leap
	[29230] = '/esoui/art/icons/ability_mage_065.dds', -- Major Defile
	[31537] = '/esoui/art/icons/ability_templar_nova.dds', -- Super Nova
	[32455] = '/esoui/art/icons/ability_werewolf_001.dds', -- Werewolf Transformation
	[32624] = '/esoui/art/icons/ability_u26_vampire_06.dds', -- Blood Scion
	[32715] = '/esoui/art/icons/ability_dragonknight_009_a.dds', -- Ferocious Leap
	[32719] = '/esoui/art/icons/ability_dragonknight_009_b.dds', -- Take Flight
	[32905] = '/esoui/art/icons/ability_dragonknight_006_b.dds', -- Shackle
	[32947] = '/esoui/art/icons/ability_dragonknight_006_b.dds', -- Standard of Might
	[32958] = '/esoui/art/icons/ability_dragonknight_006_a.dds', -- Shifting Standard
	[32963] = '/esoui/art/icons/ability_dragonknight_006_a.dds', -- Shift Standard
	[32965] = '/esoui/art/icons/ability_mage_065.dds', -- Major Deflie
	[33398] = '/esoui/art/icons/ability_nightblade_007.dds', -- Death Stroke
	[35460] = '/esoui/art/icons/ability_nightblade_018_a.dds', -- Soul Tether
	[35508] = '/esoui/art/icons/ability_nightblade_018_b.dds', -- Soul Siphon
	[35713] = '/esoui/art/icons/ability_fightersguild_005.dds', -- Dawnbreaker
	[36485] = '/esoui/art/icons/ability_nightblade_015_b.dds', -- Veil of Blades
	[36493] = '/esoui/art/icons/ability_nightblade_015_a.dds', -- Bolstering Darkness
	[36508] = '/esoui/art/icons/ability_nightblade_007_a.dds', -- Incapacitating Strike
	[36514] = '/esoui/art/icons/ability_nightblade_007_b.dds', -- Soul Harvest
	[38563] = '/esoui/art/icons/ability_ava_003.dds', -- War Horn
	[38573] = '/esoui/art/icons/ability_ava_006.dds', -- Barrier
	[38931] = '/esoui/art/icons/ability_u26_vampire_06_b.dds', -- Perfect Scion
	[38932] = '/esoui/art/icons/ability_u26_vampire_06_a.dds', -- Swarming Scion
	[39075] = '/esoui/art/icons/ability_werewolf_001_a.dds', -- Pack Leader
	[39076] = '/esoui/art/icons/ability_werewolf_001_b.dds', -- Werewolf Berserker
	[39270] = '/esoui/art/icons/ability_otherclass_002.dds', -- Soul Strike
	[40158] = '/esoui/art/icons/ability_fightersguild_005_b.dds', -- Dawnbreaker of Smiting
	[40161] = '/esoui/art/icons/ability_fightersguild_005_a.dds', -- Flawless Dawnbreaker
	[40220] = '/esoui/art/icons/ability_ava_003_b.dds', -- Sturdy Horn
	[40223] = '/esoui/art/icons/ability_ava_003_a.dds', -- Aggressive Horn
	[40225] = '/esoui/art/icons/ability_buff_major_force.dds', -- Major Force
	[40237] = '/esoui/art/icons/ability_ava_006_b.dds', -- Reviving Barrier
	[40238] = '/esoui/art/icons/ability_ava_006_b.dds', -- Reviving Barrier Heal
	[40239] = '/esoui/art/icons/ability_ava_006_a.dds', -- Replenishing Barrier
	[40414] = '/esoui/art/icons/ability_otherclass_002_a.dds', -- Shatter Soul
	[40420] = '/esoui/art/icons/ability_otherclass_002_b.dds', -- Soul Assault
	[40489] = '/esoui/art/icons/ability_mageguild_005_b.dds', -- Ice Comet
	[40493] = '/esoui/art/icons/ability_mageguild_005_a.dds', -- Shooting Star
	[48744] = '/esoui/art/icons/ability_templar_light_spear.dds', -- CC Immunity
	[48745] = '/esoui/art/icons/ability_mage_065.dds', -- Immunity Remover
	[49886] = '/esoui/art/icons/ability_sorcerer_hurricane.dds', -- Impenetrable Ward
	[49899] = '/esoui/art/icons/ability_mage_068.dds', -- Lightning Assault
	[50303] = '/esoui/art/icons/ability_healer_021.dds', -- Legendary Heal Other
	[50304] = '/esoui/art/icons/ability_healer_021.dds', -- Heal Other
	[50385] = '/esoui/art/icons/ability_healer_033.dds', -- Rapid Recovery
	[50468] = '/esoui/art/icons/ability_healer_006.dds', -- Drain Soul
	[50501] = '/esoui/art/icons/ability_mage_062.dds', -- Cataclysm
	[50544] = '/esoui/art/icons/ability_rogue_067.dds', -- Ice Armor
	[50570] = '/esoui/art/icons/ability_mage_050.dds', -- Hypothermia
	[50571] = '/esoui/art/icons/ability_mage_050.dds', -- Frostbite
	[50605] = '/esoui/art/icons/ability_healer_012.dds', -- Blood Thirsty Familiar
	[50663] = '/esoui/art/icons/ability_mage_010.dds', -- Ultimate Flame Atronach
	[50790] = '/esoui/art/icons/ability_mage_065.dds', -- Conjure Dremora Ruler
	[50791] = '/esoui/art/icons/quest_shield_001.dds', -- Conjured Dremora Lord
	[50792] = '/esoui/art/icons/ability_mage_065.dds', -- Conjure Familiar
	[50872] = '/esoui/art/icons/ability_healer_023.dds', -- Ebonyflesh
	[50873] = '/esoui/art/icons/ability_mage_065.dds', -- Oak Flesh
	[50898] = '/esoui/art/icons/ability_healer_017.dds', -- Magicka Invulnerability
	[50961] = '/esoui/art/icons/ability_healer_020.dds', -- Mass Paralysis
	[50981] = '/esoui/art/icons/ability_mage_001.dds', -- Encumber
	[51016] = '/esoui/art/icons/ability_healer_019.dds', -- Heroic Courage
	[51153] = '/esoui/art/icons/ability_healer_027.dds', -- Hushed Feet
	[51248] = '/esoui/art/icons/ability_mage_017.dds', -- Incite Frenzy
	[55214] = '/esoui/art/icons/ability_buff_major_empower.dds', -- Empower
	[61389] = '/esoui/art/icons/ability_nightblade_007_a.dds', -- Damage Taken Increased
	[63455] = '/esoui/art/icons/ability_debuff_knockback.dds', -- Ice Comet Knockback
	[63533] = '/esoui/art/icons/ability_buff_major_vitality.dds', -- Major Vitality
	[83216] = '/esoui/art/icons/ability_2handed_006.dds', -- Berserker Strike
	[83229] = '/esoui/art/icons/ability_2handed_006_a.dds', -- Onslaught
	[83238] = '/esoui/art/icons/ability_2handed_006_b.dds', -- Berserker Rage
	[83272] = '/esoui/art/icons/ability_1handed_006.dds', -- Shield Wall
	[83292] = '/esoui/art/icons/ability_1handed_006_a.dds', -- Spell Wall
	[83310] = '/esoui/art/icons/ability_1handed_006_b.dds', -- Shield Discipline
	[83465] = '/esoui/art/icons/ability_bow_006.dds', -- Rapid Fire
	[83552] = '/esoui/art/icons/ability_restorationstaff_006.dds', -- Panacea
	[83600] = '/esoui/art/icons/ability_dualwield_006.dds', -- Lacerate
	[83619] = '/esoui/art/icons/ability_destructionstaff_012.dds', -- Elemental Storm
	[83625] = '/esoui/art/icons/ability_destructionstaff_013.dds', -- Fire Storm
	[83628] = '/esoui/art/icons/ability_destructionstaff_014.dds', -- Ice Storm
	[83630] = '/esoui/art/icons/ability_destructionstaff_015.dds', -- Thunder Storm
	[83642] = '/esoui/art/icons/ability_destructionstaff_012_a.dds', -- Eye of the Storm
	[83682] = '/esoui/art/icons/ability_destructionstaff_013_a.dds', -- Eye of Flame
	[83684] = '/esoui/art/icons/ability_destructionstaff_014_a.dds', -- Eye of Frost
	[83686] = '/esoui/art/icons/ability_destructionstaff_015_a.dds', -- Eye of Lightning
	[83850] = '/esoui/art/icons/ability_restorationstaff_006_a.dds', -- Life Giver
	[84434] = '/esoui/art/icons/ability_destructionstaff_012_b.dds', -- Elemental Rage
	[85126] = '/esoui/art/icons/ability_destructionstaff_013_b.dds', -- Fiery Rage
	[85128] = '/esoui/art/icons/ability_destructionstaff_014_b.dds', -- Icy Rage
	[85130] = '/esoui/art/icons/ability_destructionstaff_015_b.dds', -- Thunderous Rage
	[85132] = '/esoui/art/icons/ability_restorationstaff_006_b.dds', -- Light's Champion
	[85179] = '/esoui/art/icons/ability_dualwield_006_b.dds', -- Thrive in Chaos
	[85187] = '/esoui/art/icons/ability_dualwield_006_a.dds', -- Rend
	[85257] = '/esoui/art/icons/ability_bow_006_b.dds', -- Toxic Barrage
	[85451] = '/esoui/art/icons/ability_bow_006_a.dds', -- Ballista
	[85532] = '/esoui/art/icons/ability_warden_012.dds', -- Secluded Grove
	[85804] = '/esoui/art/icons/ability_warden_012_a.dds', -- Enchanted Forest
	[85807] = '/esoui/art/icons/ability_warden_012_b.dds', -- Healing Thicket
	[85982] = '/esoui/art/icons/ability_warden_018.dds', -- Feral Guardian
	[85986] = '/esoui/art/icons/ability_warden_018_b.dds', -- Eternal Guardian
	[85990] = '/esoui/art/icons/ability_warden_018_c.dds', -- Wild Guardian
	[86109] = '/esoui/art/icons/ability_warden_006.dds', -- Sleet Storm
	[86113] = '/esoui/art/icons/ability_warden_006_a.dds', -- Northern Storm
	[86117] = '/esoui/art/icons/ability_warden_006_b.dds', -- Permafrost
	[90284] = '/esoui/art/icons/ability_warden_018_a.dds', -- Guardian's Wrath
	[92163] = '/esoui/art/icons/ability_warden_018_a.dds', -- Guardian's Savagery
	[95094] = '/esoui/art/icons/ability_ava_003.dds', -- Sturdy
	[103478] = '/esoui/art/icons/ability_psijic_001.dds', -- Undo
	[103557] = '/esoui/art/icons/ability_psijic_001_a.dds', -- Precognition
	[103564] = '/esoui/art/icons/ability_psijic_001_b.dds', -- Temporal Guard
	[113187] = '/esoui/art/icons/ability_sorcerer_overload.dds', -- Arc Lightning
	[113505] = '/esoui/art/icons/ability_skeevatonjolt.dds', -- Discharge Energy
	[114769] = '/esoui/art/icons/ability_sorcerer_overload.dds', -- Light Attack (Power Overload)
	[114773] = '/esoui/art/icons/ability_sorcerer_overload.dds', -- Light Attack (Energy Overload)
	[114797] = '/esoui/art/icons/ability_sorcerer_energy_overload.dds', -- Heavy Attack (Energy Overload)
	[115001] = '/esoui/art/icons/ability_necromancer_012.dds', -- Bone Goliath Transformation
	[115361] = '/esoui/art/icons/ability_skeevatonshockfield.dds', -- Shock Field
	[115410] = '/esoui/art/icons/ability_necromancer_018.dds', -- Reanimate
	[116096] = '/esoui/art/icons/ability_artifact_volendrung_006.dds', -- Ruinous Cyclone
	[118279] = '/esoui/art/icons/ability_necromancer_012_b.dds', -- Ravenous Goliath
	[118367] = '/esoui/art/icons/ability_necromancer_018_a.dds', -- Renewing Animation
	[118379] = '/esoui/art/icons/ability_necromancer_018_b.dds', -- Animate Blastbones
	[118664] = '/esoui/art/icons/ability_necromancer_012_a.dds', -- Pummeling Goliath
	[120020] = '/esoui/art/icons/achievement_031.dds', -- Minor Toughness
	[122174] = '/esoui/art/icons/ability_necromancer_006.dds', -- Frozen Colossus
	[122388] = '/esoui/art/icons/ability_necromancer_006_a.dds', -- Glacial Colossus
	[122395] = '/esoui/art/icons/ability_necromancer_006_b.dds', -- Pestilent Colossus
	[122908] = '/esoui/art/icons/ability_necromancer_012_b.dds', -- Super Pummeling Goliath
	[129375] = '/esoui/art/icons/achievement_thievesguild_038.dds', -- Vampire Lord
	[133507] = '/esoui/art/icons/ability_u27_bestialannihilation1.dds', -- Lead the Pack
	[157016] = '/esoui/art/icons/ability_companion_ultimate_bastian_001.dds', -- Unleashed Rage
	[157259] = '/esoui/art/icons/ability_companion_ultimate_mirri_001.dds' -- Impeccable Shot
}


group.ultiIndexes = {
	[1] = 15957, -- Magma Armor
	[2] = 16536, -- Meteor
	[3] = 16538, -- Meteor Knockback
	[4] = 17874, -- Magma Shell
	[5] = 17878, -- Corrosive Armor
	[6] = 20671, -- Molten Fury
	[7] = 20674, -- Molten Fury Cooldowns
	[8] = 21752, -- Nova
	[9] = 21754, -- Major Maim
	[10] = 21755, -- Solar Prison
	[11] = 21758, -- Solar Disturbance
	[12] = 22138, -- Radial Sweep
	[13] = 22139, -- Crescent Sweep
	[14] = 22144, -- Empowering Sweep
	[15] = 22223, -- Rite of Passage
	[16] = 22226, -- Practiced Incantation
	[17] = 22229, -- Remembrance
	[18] = 22233, -- Major Protection
	[19] = 23492, -- Greater Storm Atronach
	[20] = 23495, -- Summon Charged Atronach
	[21] = 23634, -- Summon Storm Atronach
	[22] = 23659, -- Storm Atronach Impact
	[23] = 23664, -- Greater Storm Atronach Impact
	[24] = 23667, -- Charged Atronach Impact
	[25] = 24785, -- Overload
	[26] = 24792, -- Light Attack (Overload)
	[27] = 24794, -- Heavy Attack (Overload)
	[28] = 24799, -- Overload End
	[29] = 24804, -- Energy Overload
	[30] = 24806, -- Power Overload
	[31] = 24810, -- Heavy Attack (Power Overload)
	[32] = 25091, -- Soul Shred
	[33] = 25169, -- Soul Leech
	[34] = 25411, -- Consuming Darkness
	[35] = 26111, -- Shock Dummy
	[36] = 26112, -- Remove
	[37] = 26380, -- Rite of Passage Self Snare
	[38] = 27706, -- Negate Magic
	[39] = 27786, -- Overload Remover
	[40] = 28341, -- Suppression Field
	[41] = 28348, -- Absorption Field
	[42] = 28434, -- Remove Overload
	[43] = 28988, -- Dragonknight Standard
	[44] = 29012, -- Dragon Leap
	[45] = 29230, -- Major Defile
	[46] = 31537, -- Super Nova
	[47] = 32455, -- Werewolf Transformation
	[48] = 32624, -- Blood Scion
	[49] = 32715, -- Ferocious Leap
	[50] = 32719, -- Take Flight
	[51] = 32905, -- Shackle
	[52] = 32947, -- Standard of Might
	[53] = 32958, -- Shifting Standard
	[54] = 32963, -- Shift Standard
	[55] = 32965, -- Major Deflie
	[56] = 33398, -- Death Stroke
	[57] = 35460, -- Soul Tether
	[58] = 35508, -- Soul Siphon
	[59] = 35713, -- Dawnbreaker
	[60] = 36485, -- Veil of Blades
	[61] = 36493, -- Bolstering Darkness
	[62] = 36508, -- Incapacitating Strike
	[63] = 36514, -- Soul Harvest
	[64] = 38563, -- War Horn
	[65] = 38573, -- Barrier
	[66] = 38931, -- Perfect Scion
	[67] = 38932, -- Swarming Scion
	[68] = 39075, -- Pack Leader
	[69] = 39076, -- Werewolf Berserker
	[70] = 39270, -- Soul Strike
	[71] = 40158, -- Dawnbreaker of Smiting
	[72] = 40161, -- Flawless Dawnbreaker
	[73] = 40220, -- Sturdy Horn
	[74] = 40223, -- Aggressive Horn
	[75] = 40225, -- Major Force
	[76] = 40237, -- Reviving Barrier
	[77] = 40238, -- Reviving Barrier Heal
	[78] = 40239, -- Replenishing Barrier
	[79] = 40414, -- Shatter Soul
	[80] = 40420, -- Soul Assault
	[81] = 40489, -- Ice Comet
	[82] = 40493, -- Shooting Star
	[83] = 48744, -- CC Immunity
	[84] = 48745, -- Immunity Remover
	[85] = 49886, -- Impenetrable Ward
	[86] = 49899, -- Lightning Assault
	[87] = 50303, -- Legendary Heal Other
	[88] = 50304, -- Heal Other
	[89] = 50385, -- Rapid Recovery
	[90] = 50468, -- Drain Soul
	[91] = 50501, -- Cataclysm
	[92] = 50544, -- Ice Armor
	[93] = 50570, -- Hypothermia
	[94] = 50571, -- Frostbite
	[95] = 50605, -- Blood Thirsty Familiar
	[96] = 50663, -- Ultimate Flame Atronach
	[97] = 50790, -- Conjure Dremora Ruler
	[98] = 50791, -- Conjured Dremora Lord
	[99] = 50792, -- Conjure Familiar
	[100] = 50872, -- Ebonyflesh
	[101] = 50873, -- Oak Flesh
	[102] = 50898, -- Magicka Invulnerability
	[103] = 50961, -- Mass Paralysis
	[104] = 50981, -- Encumber
	[105] = 51016, -- Heroic Courage
	[106] = 51153, -- Hushed Feet
	[107] = 51248, -- Incite Frenzy
	[108] = 55214, -- Empower
	[109] = 61389, -- Damage Taken Increased
	[110] = 63455, -- Ice Comet Knockback
	[111] = 63533, -- Major Vitality
	[112] = 83216, -- Berserker Strike
	[113] = 83229, -- Onslaught
	[114] = 83238, -- Berserker Rage
	[115] = 83272, -- Shield Wall
	[116] = 83292, -- Spell Wall
	[117] = 83310, -- Shield Discipline
	[118] = 83465, -- Rapid Fire
	[119] = 83552, -- Panacea
	[120] = 83600, -- Lacerate
	[121] = 83619, -- Elemental Storm
	[122] = 83625, -- Fire Storm
	[123] = 83628, -- Ice Storm
	[124] = 83630, -- Thunder Storm
	[125] = 83642, -- Eye of the Storm
	[126] = 83682, -- Eye of Flame
	[127] = 83684, -- Eye of Frost
	[128] = 83686, -- Eye of Lightning
	[129] = 83850, -- Life Giver
	[130] = 84434, -- Elemental Rage
	[131] = 85126, -- Fiery Rage
	[132] = 85128, -- Icy Rage
	[133] = 85130, -- Thunderous Rage
	[134] = 85132, -- Light's Champion
	[135] = 85179, -- Thrive in Chaos
	[136] = 85187, -- Rend
	[137] = 85257, -- Toxic Barrage
	[138] = 85451, -- Ballista
	[139] = 85532, -- Secluded Grove
	[140] = 85804, -- Enchanted Forest
	[141] = 85807, -- Healing Thicket
	[142] = 85982, -- Feral Guardian
	[143] = 85986, -- Eternal Guardian
	[144] = 85990, -- Wild Guardian
	[145] = 86109, -- Sleet Storm
	[146] = 86113, -- Northern Storm
	[147] = 86117, -- Permafrost
	[148] = 90284, -- Guardian's Wrath
	[149] = 92163, -- Guardian's Savagery
	[150] = 95094, -- Sturdy
	[151] = 103478, -- Undo
	[152] = 103557, -- Precognition
	[153] = 103564, -- Temporal Guard
	[154] = 113187, -- Arc Lightning
	[155] = 113505, -- Discharge Energy
	[156] = 114769, -- Light Attack (Power Overload)
	[157] = 114773, -- Light Attack (Energy Overload)
	[158] = 114797, -- Heavy Attack (Energy Overload)
	[159] = 115001, -- Bone Goliath Transformation
	[160] = 115361, -- Shock Field
	[161] = 115410, -- Reanimate
	[162] = 116096, -- Ruinous Cyclone
	[163] = 118279, -- Ravenous Goliath
	[164] = 118367, -- Renewing Animation
	[165] = 118379, -- Animate Blastbones
	[166] = 118664, -- Pummeling Goliath
	[167] = 120020, -- Minor Toughness
	[168] = 122174, -- Frozen Colossus
	[169] = 122388, -- Glacial Colossus
	[170] = 122395, -- Pestilent Colossus
	[171] = 122908, -- Super Pummeling Goliath
	[172] = 129375, -- Vampire Lord
	[173] = 133507, -- Lead the Pack
	[174] = 157016, -- Unleashed Rage
	[175] = 157259, -- Impeccable Shot
}

for k,v in pairs(group.ultiIndexes) do
   group.ultiIndexes[v]=k
end


group.rdkUlts = {
	[1] = 28341, -- negate
	[32] = 28341, -- offensive negate
	[33] = 28341, -- counter negate
	[2] = 23634, -- atro
	[3] = 24785, -- overload
	[4] = 22138, -- sweep
	[5] = 21752, -- nova
	[6] = 22223, -- templar heal
	[7] = 32958, -- standard
	[8] = 29012, -- leap
	[9] = 15957, -- magma
	[10] = 33398, -- stroke
	[11] = 25411, -- darkness
	[12] = 25091, -- soul
	[37] = 35508, -- soul siphon
	[38] = 35460, -- soul tether
	[13] = 86109, -- storm
	[35] = 86113, -- northern storm
	[36] = 86117, -- permafrost
	[14] = 85532, -- warden heal
	[31] = 85982, -- guardian
	[29] = 122174, -- colo
	[28] = 115001, -- goliath
	[30] = 115410, -- reanimate
	[15] = 83619, -- destro
	[16] = 83552, -- resto
	[17] = 83216, -- 2h
	[18] = 83272, -- s&b
	[19] = 83600, -- dw
	[20] = 83465, -- bow
	[21] = 39270, -- soul magick
	[22] = 32455, -- ww
	[23] = 32624, -- vamp
	[24] = 16536, -- metor
	[25] = 35713, -- fighters
	[34] = 103478, -- psijic
	[26] = 38573, -- barrier
	[27] = 38563, -- horn

}