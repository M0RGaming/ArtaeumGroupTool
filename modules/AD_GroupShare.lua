-- Group Ult Sharing Module
local AD = ArtaeumGroupTool
AD.Group = {}
local group = AD.Group
local vars = {}
local LMP = LibMapPing
local LGPS = LibGPS3


local toplevels = {}
group.frameDB = {}
local frameDB = group.frameDB


AD.last = {} -- TESTING
group.toSend = {
	assistPing = false
}
group.arrow = nil


group.running = false


group.units = {}
group.handlers = {}




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
			group.createTopLevels()
			AD.initAnchors(toplevels)

			
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
				--if vars.showMagStam then
				--	frameDB['group'..i]:SetMagStamHidden(false)
				--end
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



		group.lgcs = LibGroupCombatStats.RegisterAddon("ArtaeumGroupTool", {"ULT"})

		local LGB = LibGroupBroadcast
		local handler = LGB:RegisterHandler("ArtaeumGroupToolHandler")
		handler:SetDisplayName("Artaeum Group Tool")
		handler:SetDescription("Group Tool for Coordination in Cyrodiil!")

		-- protocols to insert: assist Ping, camp Lock, hammer bar, ult bar

		group.protocols = {}

		group.protocols.ping = handler:DeclareProtocol(500, "ArtaeumPing") -- only send on button press
		group.protocols.ping:AddField(LGB.CreateFlagField("ping"))
		group.protocols.ping:OnData(group.handlers.onPing)
		group.protocols.ping:Finalize({isRelevantInCombat = true})

		group.protocols.lock = handler:DeclareProtocol(501, "ArtaeumCampLock") -- only send when camp updates to be locked or unlocked
		group.protocols.lock:AddField(LGB.CreateFlagField("lock"))
		group.protocols.lock:OnData(group.handlers.onCampLock)
		group.protocols.lock:Finalize({isRelevantInCombat = true})

		group.protocols.hammerBar = handler:DeclareProtocol(502, "ArtaeumDaedricPower") -- only send when holding artifact, if not holding say 0%
		group.protocols.hammerBar:AddField(LGB.CreatePercentageField("percent")) -- should be between 0 and 1
		group.protocols.hammerBar:OnData(group.handlers.onHammerUpdate)
		group.protocols.hammerBar:Finalize({isRelevantInCombat = true})

		group.protocols.requestSync = handler:DeclareProtocol(503, "ArtaeumRequestSync") -- run when joining a group to obtain info
		group.protocols.requestSync:AddField(LGB.CreateFlagField("requested"))
		group.protocols.requestSync:OnData(group.handlers.onSyncRequested)
		group.protocols.requestSync:Finalize()

		group.protocols.sync = handler:DeclareProtocol(504, "ArtaeumSync")
		group.protocols.sync:AddField(LGB.CreateFlagField("lock"))
		group.protocols.sync:AddField(LGB.CreatePercentageField("percent"))
		group.protocols.sync:AddField(LGB.CreateFlagField("shareFB")) -- share Front Bar
		group.protocols.sync:OnData(group.handlers.onSync)
		group.protocols.sync:Finalize()

		group.protocols.sharingBar = handler:DeclareProtocol(505, "ArtaeumSharingBar") -- Might remove, idk
		group.protocols.sharingBar:AddField(LGB.CreateFlagField("shareFB"))
		group.protocols.sharingBar:OnData(group.handlers.onSharingBarUpdate)
		group.protocols.sharingBar:Finalize()


		local GroupResources = LibGroupBroadcast:GetHandlerApi("GroupResources")
		GroupResources:RegisterForStaminaChanges(group.handlers.onStamUpdate)
		GroupResources:RegisterForMagickaChanges(group.handlers.onMagUpdate)



		EVENT_MANAGER:RegisterForEvent("AD Group Tool Group Activated", EVENT_PLAYER_ACTIVATED, group.playerActivated)
		group.createArrow()
		group.arrow:SetTarget(0, 0)


		


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

function group.addExternalHook(bitId, sendfunc, recievefunc, axis)
	d("Note: ArtaeumGroupTool has removed externalHooks as LibGroupBroadcast is now released. Please update to using LibGroupBroadcast instead.")
end













-- HANDLERS
function group.handlers.onPing(unitTag, data)
	--data.ping
	if data.ping == false then return end
	local px, py = GetMapPlayerPosition(unitTag)
	group.arrow:SetTarget(px, py)
	zo_callLater(function() group.arrow:SetTarget(0, 0) end, 12500)
end

function group.handlers.onCampLock(unitTag, data)
	--data.lock
	if data.lock then
		frameDB[unitTag]:SetEdgeColor(1,0,0,1)
	else
		frameDB[unitTag]:SetEdgeColor(1,1,1,1)
	end
end

local hammerWeilder = ''
function group.handlers.onHammerUpdate(unitTag, data)
	--data.percent
	-- idk if the handler comes back if the player is the one who sent. I'm assuming no, but ill put a check anyways
	if AreUnitsEqual(unitTag,'player') then d("Artaeum: PLAYER GOT PING") end
	if (data.percent == 0) then
		if (hammerWeilder == unitTag) then
			if not HUD_DAEDRIC_ENERGY_METER:IsHidden() then HUD_DAEDRIC_ENERGY_METER:UpdateVisibility() end
			hammerWeilder = ''
		end
	else
		if (hammerWeilder == unitTag) then
			if HUD_DAEDRIC_ENERGY_METER:IsHidden() then
				HUD_DAEDRIC_ENERGY_METER:SetHiddenForReason("daedricArtifactInactive",false,SHOULD_FADE_OUT)
			end
			HUD_DAEDRIC_ENERGY_METER:UpdateEnergyValues(data.percent,1)
		else
			hammerWeilder = unitTag
		end
	end
end

function group.handlers.onSyncRequested(unitTag, data)
	--data.requested
	if data.requested then
		-- send Sync
	end
end

function group.handlers.onSync(unitTag, data)
	--data.lock
	--data.percent
	--data.shareFB
	group.handlers.onCampLock(unitTag, data)
	group.handlers.onHammerUpdate(unitTag, data)
	group.handlers.onSharingBarUpdate(unitTag, data)
end

function group.handlers.onSharingBarUpdate(unitTag, data)
	--data.shareFB
	-- TODO: DO THIS ENTIRE FUNCTION
end

function group.handlers.onStamUpdate(unitTag, unitName, current, max, percent)
	if vars.UI == "Custom" and vars.showMagStam then
		if frameDB[unitTag].magStamHidden then frameDB[unitTag]:SetMagStamHidden(false) end
		frameDB[unitTag]:SetStam(percent,1)
	end
end

function group.handlers.onMagUpdate(unitTag, unitName, current, max, percent)
	if vars.UI == "Custom" and vars.showMagStam then
		if frameDB[unitTag].magStamHidden then frameDB[unitTag]:SetMagStamHidden(false) end
		frameDB[unitTag]:SetMag(percent,1)
	end
end


--AD.hammer = 0
function group.toSend:send()
	if true then return end

	local assistPing = self.assistPing and 1 or 0
	self.assistPing = false
	local campLock = (GetNextForwardCampRespawnTime() > GetGameTimeMilliseconds()) and 1 or 0
	local hammerCurrent, hammerMax = GetUnitPower('player',POWERTYPE_DAEDRIC)
	if hammerMax == 0 then hammerMax = 1 end
	local hammerBar = math.floor(hammerCurrent/hammerMax*15)
	--local hammerBar = AD.hammer



--[[

	local magCurrent, magMax = GetUnitPower('player',POWERTYPE_MAGICKA)
	local magBar = math.floor(magCurrent/magMax*15)
	local stamCurrent, stamMax = GetUnitPower('player',POWERTYPE_STAMINA)
	local stamBar = math.floor(stamCurrent/stamMax*15)
--]]
	local xstream = {0,campLock,assistPing,hammerBar,ult.id,0}
	local ystream = {ult.percent,0,magBar,stamBar}


	local x = group.writeStream(
		xstream,
		{1,1,1,4,8,1}
	)
	local y = group.writeStream(
		ystream,
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







-- Adapted from RdK Group Tool
function group.OnAfterPingRemoved(pingType, pingTag, x, y, isPingOwner)
	if (pingType == MAP_PIN_TYPE_PING) then
		LMP:UnsuppressPing(pingType, pingTag)
	end
end



function group.lgcsPlayerCallback(player, data)
	local playerTag = GetGroupUnitTagByIndex(GetGroupIndexByUnitTag('player'))
	if playerTag ~= nil then
		group.lgcsCallback(playerTag, data)
	end
end

group.lgcsCallbackDebug = {}

local ultIconLookup = {}
function group.lgcsCallback(unitTag, data)
	group.lgcsCallbackDebug[unitTag] = data --- DEBUG STUFF
	
	local ult1Id = data.ult1ID
	local ult1Icon = ultIconLookup[ult1Id]
	if ult1Icon == nil then
		ult1Icon = GetAbilityIcon(ult1Id)
		ultIconLookup[ult1Id] = ult1Icon
	end

	local ult2Id = data.ult2ID
	local ult2Icon = ultIconLookup[ult2Id]
	if ult2Icon == nil then
		ult2Icon = GetAbilityIcon(ult2Id)
		ultIconLookup[ult2Id] = ult2Icon
	end

	frameDB[unitTag]:setUlt(data.ultValue, data.ult1Cost, ult1Icon, data.ult2Cost, ult2Icon)
	frameDB[unitTag].image:SetColor(1,1,1)
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


function group.updateRange(_, unitTag, nearby)
	if frameDB[unitTag] then
		frameDB[unitTag]:SetInGroupRange(nearby)
	end
end

function group.updateRole(_, unitTag, role)
	if frameDB[unitTag] then
		frameDB[unitTag]:SetRole(role)
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

function group.hideAllMagStam()
	for i=1,12 do
		frameDB['group'..i]:SetMagStamHidden(true)
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
			--EVENT_MANAGER:RegisterForUpdate("AD Group Tool Group Ping", vars.frequency, group.ping)
		else
			--EVENT_MANAGER:UnregisterForUpdate("AD Group Tool Group Ping")
		end
	end
end

function group.groupUpdate()
	for i=1,12 do
		if frameDB['group'..i] then
			frameDB['group'..i]:Update()
		end
	end
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






-- Legacy Stuff (Keeping read/write stream since I may still use it later)

--/script PingMap(MAP_PIN_TYPE_PLAYER_WAYPOINT, 1, 1 / 2^16, 1 / 2^16) StartChatInput(table.concat({GetMapPlayerWaypoint()}, ","))
-- Adapted from RdK group tool, who adapted it from lib group socket
-- 1.1058949894505e-05,1.1058949894505e-05
--group.stepSize = 1.333333329967e-05 -- For some reason cyro's step works, but artaeums doesnt? 
--group.mapID = 33
--group.mapID = 1429
--group.stepSize = 1.1058949894505e-05


--group.rdkMap = 23
--group.rdkStep = 1.4285034012573e-005

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
		--EVENT_MANAGER:UnregisterForUpdate("AD Group Tool Group Ping")
		--LMP:UnregisterCallback('BeforePingAdded', group.pingCallback)
		--LMP:UnregisterCallback('AfterPingRemoved', group.OnAfterPingRemoved)
		group.lgcs:UnregisterForEvent(LibGroupCombatStats.EVENT_GROUP_ULT_UPDATE, group.lgcsCallback)
		group.lgcs:UnregisterForEvent(LibGroupCombatStats.EVENT_PLAYER_ULT_UPDATE, group.lgcsPlayerCallback)

		EVENT_MANAGER:UnregisterForEvent("AD Group Tool Unit Created", EVENT_UNIT_CREATED)
		EVENT_MANAGER:UnregisterForEvent("AD Group Tool Unit Destroyed", EVENT_UNIT_DESTROYED)
		EVENT_MANAGER:UnregisterForEvent("AD Group Tool Group Join", EVENT_GROUP_MEMBER_JOINED)
		EVENT_MANAGER:UnregisterForEvent("AD Group Tool Group Leave", EVENT_GROUP_MEMBER_LEFT)
		EVENT_MANAGER:UnregisterForEvent("AD Group Tool Group Change", EVENT_LEADER_UPDATE)
		EVENT_MANAGER:UnregisterForEvent("AD Group Tool Group Update", EVENT_GROUP_UPDATE)
		EVENT_MANAGER:UnregisterForEvent("AD Group Tool Group Death", EVENT_UNIT_DEATH_STATE_CHANGED)
		EVENT_MANAGER:UnregisterForEvent("AD Group Tool Group Connect", EVENT_GROUP_MEMBER_CONNECTED_STATUS)
		EVENT_MANAGER:UnregisterForEvent("AD Group Tool Group Range", EVENT_GROUP_SUPPORT_RANGE_UPDATE)
		EVENT_MANAGER:UnregisterForEvent("AD Group Tool Group Role", EVENT_GROUP_MEMBER_ROLE_CHANGED)
		EVENT_MANAGER:UnregisterForEvent("AD Group Tool Group Frames Activated", EVENT_PLAYER_ACTIVATED)
		

		if vars.UI == "Custom" then
			for i=1,12 do
				frameDB['group'..i].frame:SetHidden(true)
			end
			ZO_UnitFramesGroups:SetHidden(false)
		end
		group.running = false
		

	elseif not group.running and sharing then
		--LMP:RegisterCallback('BeforePingAdded', group.pingCallback)
		--LMP:RegisterCallback('AfterPingRemoved', group.OnAfterPingRemoved)
		group.lgcs:RegisterForEvent(LibGroupCombatStats.EVENT_GROUP_ULT_UPDATE, group.lgcsCallback)
		group.lgcs:RegisterForEvent(LibGroupCombatStats.EVENT_PLAYER_ULT_UPDATE, group.lgcsPlayerCallback)
		
		EVENT_MANAGER:RegisterForEvent("AD Group Tool Unit Created", EVENT_UNIT_CREATED, group.unitCreate)
		EVENT_MANAGER:RegisterForEvent("AD Group Tool Unit Destroyed", EVENT_UNIT_DESTROYED, group.unitDestroy)
		EVENT_MANAGER:RegisterForEvent("AD Group Tool Group Join", EVENT_GROUP_MEMBER_JOINED, group.groupJoinLeave)
		EVENT_MANAGER:RegisterForEvent("AD Group Tool Group Leave", EVENT_GROUP_MEMBER_LEFT, group.groupJoinLeave)
		EVENT_MANAGER:RegisterForEvent("AD Group Tool Group Change", EVENT_LEADER_UPDATE, group.groupLeadChange)
		EVENT_MANAGER:RegisterForEvent("AD Group Tool Group Update", EVENT_GROUP_UPDATE, group.groupUpdate)
		EVENT_MANAGER:RegisterForEvent("AD Group Tool Group Death", EVENT_UNIT_DEATH_STATE_CHANGED, group.updateDead)
		EVENT_MANAGER:RegisterForEvent("AD Group Tool Group Connect", EVENT_GROUP_MEMBER_CONNECTED_STATUS, group.updateOnline)
		EVENT_MANAGER:RegisterForEvent("AD Group Tool Group Range", EVENT_GROUP_SUPPORT_RANGE_UPDATE, group.updateRange)
		EVENT_MANAGER:RegisterForEvent("AD Group Tool Group Role", EVENT_GROUP_MEMBER_ROLE_CHANGED, group.updateRole)
		EVENT_MANAGER:RegisterForEvent("AD Group Tool Group Frames Activated", EVENT_PLAYER_ACTIVATED, group.groupUpdate)
		
		
		--if IsUnitGrouped("player") then
		--	EVENT_MANAGER:RegisterForUpdate("AD Group Tool Group Ping", vars.frequency, group.ping)
		--end

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
	local active = (not vars.cyrodilOnly) or ((IsPlayerInAvAWorld() or IsActiveWorldBattleground()) and vars.cyrodilOnly) 
	group.updateSharing(active)

end



ZO_CreateStringId("SI_BINDING_NAME_ARTAEUMGROUPTOOL_REQUEST_PING", "Send a assist ping.")
SLASH_COMMANDS["/ping"] = group.ping




group.ultLookup = {

}
group.ultiIndexes = {
	[1] = 15957, -- Magma Armor
	[2] = 16536, -- Meteor
	[3] = 17874, -- Magma Shell
	[4] = 17878, -- Corrosive Armor
	[5] = 20671, -- Molten Fury
	[6] = 20679, -- Blood Fury
	[7] = 20689, -- Controlled Fury
	[8] = 21752, -- Nova
	[9] = 21755, -- Solar Prison
	[10] = 21758, -- Solar Disturbance
	[11] = 22138, -- Radial Sweep
	[12] = 22139, -- Crescent Sweep
	[13] = 22144, -- Everlasting Sweep
	[14] = 22223, -- Rite of Passage
	[15] = 22226, -- Practiced Incantation
	[16] = 22229, -- Remembrance
	[17] = 23492, -- Greater Storm Atronach
	[18] = 23495, -- Summon Charged Atronach
	[19] = 23634, -- Summon Storm Atronach
	[20] = 24785, -- Overload
	[21] = 24804, -- Energy Overload
	[22] = 24806, -- Power Overload
	[23] = 25091, -- Soul Shred
	[24] = 25411, -- Consuming Darkness
	[25] = 26598, -- Arm Wabbajack
	[26] = 27706, -- Negate Magic
	[27] = 28341, -- Suppression Field
	[28] = 28348, -- Absorption Field
	[29] = 28988, -- Dragonknight Standard
	[30] = 29012, -- Dragon Leap
	[31] = 32455, -- Werewolf Transformation
	[32] = 32624, -- Blood Scion
	[33] = 32715, -- Ferocious Leap
	[34] = 32719, -- Take Flight
	[35] = 32947, -- Standard of Might
	[36] = 32958, -- Shifting Standard
	[37] = 32963, -- Shift Standard
	[38] = 33398, -- Death Stroke
	[39] = 35460, -- Soul Tether
	[40] = 35508, -- Soul Siphon
	[41] = 35713, -- Dawnbreaker
	[42] = 36485, -- Veil of Blades
	[43] = 36493, -- Bolstering Darkness
	[44] = 36508, -- Incapacitating Strike
	[45] = 36514, -- Soul Harvest
	[46] = 38563, -- War Horn
	[47] = 38573, -- Barrier
	[48] = 38931, -- Perfect Scion
	[49] = 38932, -- Swarming Scion
	[50] = 39075, -- Pack Leader
	[51] = 39076, -- Werewolf Berserker
	[52] = 39270, -- Soul Strike
	[53] = 40158, -- Dawnbreaker of Smiting
	[54] = 40161, -- Flawless Dawnbreaker
	[55] = 40220, -- Sturdy Horn
	[56] = 40223, -- Aggressive Horn
	[57] = 40237, -- Reviving Barrier
	[58] = 40239, -- Replenishing Barrier
	[59] = 40414, -- Shatter Soul
	[60] = 40420, -- Soul Assault
	[61] = 40489, -- Ice Comet
	[62] = 40493, -- Shooting Star
	[63] = 49886, -- Impenetrable Ward
	[64] = 49899, -- Lightning Assault
	[65] = 50303, -- Legendary Heal Other
	[66] = 50385, -- Rapid Recovery
	[67] = 50468, -- Drain Soul
	[68] = 50501, -- Cataclysm
	[69] = 50544, -- Ice Armor
	[70] = 50570, -- Hypothermia
	[71] = 50605, -- Blood Thirsty Familiar
	[72] = 50663, -- Ultimate Flame Atronach
	[73] = 50790, -- Conjure Dremora Ruler
	[74] = 50872, -- Ebonyflesh
	[75] = 50898, -- Magicka Invulnerability
	[76] = 50961, -- Mass Paralysis
	[77] = 50981, -- Encumber
	[78] = 51016, -- Heroic Courage
	[79] = 51153, -- Hushed Feet
	[80] = 51248, -- Incite Frenzy
	[81] = 52897, -- Standard of Might
	[82] = 53875, -- Heroic Courage
	[83] = 54118, -- Remembrance
	[84] = 55090, -- Devouring Swarm
	[85] = 61090, -- Standard of Might
	[86] = 79064, -- Veil of Blades
	[87] = 83216, -- Berserker Strike
	[88] = 83229, -- Onslaught
	[89] = 83238, -- Berserker Rage
	[90] = 83272, -- Shield Wall
	[91] = 83292, -- Spell Wall
	[92] = 83310, -- Shield Discipline
	[93] = 83465, -- Rapid Fire
	[94] = 83552, -- Panacea
	[95] = 83600, -- Lacerate
	[96] = 83619, -- Elemental Storm
	[97] = 83625, -- Fire Storm
	[98] = 83628, -- Ice Storm
	[99] = 83630, -- Thunder Storm
	[100] = 83642, -- Eye of the Storm
	[101] = 83682, -- Eye of Flame
	[102] = 83684, -- Eye of Frost
	[103] = 83686, -- Eye of Lightning
	[104] = 83850, -- Life Giver
	[105] = 83867, -- Live Giver
	[106] = 84434, -- Elemental Rage
	[107] = 85126, -- Fiery Rage
	[108] = 85128, -- Icy Rage
	[109] = 85130, -- Thunderous Rage
	[110] = 85132, -- Light's Champion
	[111] = 85156, -- Lacerate
	[112] = 85179, -- Thrive in Chaos
	[113] = 85187, -- Rend
	[114] = 85257, -- Toxic Barrage
	[115] = 85451, -- Ballista
	[116] = 85532, -- Secluded Grove
	[117] = 85804, -- Enchanted Forest
	[118] = 85807, -- Healing Thicket
	[119] = 85982, -- Feral Guardian
	[120] = 85986, -- Eternal Guardian
	[121] = 85990, -- Wild Guardian
	[122] = 86109, -- Sleet Storm
	[123] = 86113, -- Northern Storm
	[124] = 86117, -- Permafrost
	[125] = 88158, -- Materialize
	[126] = 90284, -- Guardian's Wrath
	[127] = 92163, -- Guardian's Savagery
	[128] = 94625, -- Guardian's Wrath
	[129] = 103478, -- Undo
	[130] = 103557, -- Precognition
	[131] = 103564, -- Temporal Guard
	[132] = 113105, -- Incapacitating Strike
	[133] = 113505, -- Discharge Energy
	[134] = 115001, -- Bone Goliath Transformation
	[135] = 115361, -- Shock Field
	[136] = 115410, -- Reanimate
	[137] = 116096, -- Ruinous Cyclone
	[138] = 118279, -- Ravenous Goliath
	[139] = 118367, -- Renewing Animation
	[140] = 118379, -- Animate Blastbones
	[141] = 118664, -- Pummeling Goliath
	[142] = 122174, -- Frozen Colossus
	[143] = 122388, -- Glacial Colossus
	[144] = 122395, -- Pestilent Colossus
	[145] = 122908, -- Super Pummeling Goliath
	[146] = 126489, -- Berserker Strike
	[147] = 126492, -- Berserker Rage
	[148] = 126497, -- Onslaught
	[149] = 129375, -- Vampire Lord
	[150] = 133507, -- Lead the Pack
	[151] = 157016, -- Unleashed Rage
	[152] = 157259, -- Impeccable Shot
	[153] = 160715, -- Scurry
	[154] = 163763, -- Baneslayer
	[155] = 164191, -- Raging Storm
	[156] = 164413, -- Channel the Storm
	[157] = 164881, -- Overcharge
	[158] = 165208, -- Unstable Shield
	[159] = 165281, -- Arcane Wards
	[160] = 165412, -- Cyclone
	[161] = 165810, -- Spell Conversion
	[162] = 165875, -- Forced Sacrifice
	[163] = 166037, -- Time Tear
	[164] = 183676, -- Gibbering Shield
	[165] = 183709, -- Vitalizing Glyphic
	[166] = 186488, -- Gore
	[167] = 189791, -- The Unblinking Eye
	[168] = 189837, -- The Tide King's Gaze
	[169] = 189867, -- The Languid Eye
	[170] = 192372, -- Sanctum of the Abyssal Sea
	[171] = 192380, -- Gibbering Shelter
	[172] = 193558, -- Resonating Glyphic
	[173] = 193794, -- Glyphic of the Tides
	[174] = 195103, -- Vigorous Tentacular Eruption
	[175] = 196782, -- Rite of Passage
}
group.ultList = {}
for k,v in pairs(group.ultiIndexes) do
	group.ultList[v] = GetAbilityIcon(v)
	group.ultiIndexes[v]=k
end