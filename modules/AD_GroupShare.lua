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


		group.protocols = {}

		-- between 3 and 3 bytes
		group.protocols.ping = handler:DeclareProtocol(90, "ArtaeumPing") -- only send on button press
		group.protocols.ping:AddField(LGB.CreateFlagField("ping"))
		group.protocols.ping:OnData(group.handlers.onPing)
		group.protocols.ping:Finalize({isRelevantInCombat = true})

		-- between 3 and 4 bytes
		group.protocols.sync = handler:DeclareProtocol(91, "ArtaeumDataSync")
		group.protocols.sync:AddField(LGB.CreateOptionalField(LGB.CreateFlagField("lock"))) -- ArtaeumCampLock (501), only when lock updates on/off
		group.protocols.sync:AddField(LGB.CreateOptionalField(LGB.CreatePercentageField("hammer"))) -- ArtaeumDaedricPower (502), only when holding
		group.protocols.sync:AddField(LGB.CreateOptionalField(LGB.CreateFlagField("requestSync"))) -- ArtaeumRequestSync (503), request resend
		group.protocols.sync:OnData(group.handlers.onSync)
		group.protocols.sync:Finalize({isRelevantInCombat = true, replaceQueuedMessages = false})



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

	group.protocols.ping:Send({
		ping = true
	})
	--group.handlers.onPing('player', {ping=true})
	-- TODO: maybe display ping locally too
end

function group.ping()
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


local function lgcsUpdate(unitTag)
	local realData = group.lgcs:GetUnitULT(unitTag)
	group.lgcsCallback(unitTag, realData)
end

local hammerWeilder = ''
function group.handlers.onHammerUpdate(unitTag, data)
	--data.hammer
	-- player also gets their own messages
	if AreUnitsEqual(unitTag,'player') then
		lgcsUpdate()
		return
	end

	if (data.hammer == 0) then
		if (hammerWeilder == unitTag) then
			if not HUD_DAEDRIC_ENERGY_METER:IsHidden() then HUD_DAEDRIC_ENERGY_METER:UpdateVisibility() end
			hammerWeilder = ''
		end
	else
		hammerWeilder = unitTag
		if HUD_DAEDRIC_ENERGY_METER:IsHidden() then
			HUD_DAEDRIC_ENERGY_METER:SetHiddenForReason("daedricArtifactInactive",false,SHOULD_FADE_OUT)
		end
		HUD_DAEDRIC_ENERGY_METER:UpdateEnergyValues(data.hammer,1)
	end
	lgcsUpdate()
end

function group.handlers.onSync(unitTag, data)
	--a = data
	--data.lock
	--data.hammer
	--data.requestSync
	if data.lock ~= nil then
		group.handlers.onCampLock(unitTag, data)
	end
	if data.hammer ~= nil then
		group.handlers.onHammerUpdate(unitTag, data)
	end
	if data.requestSync == true then
		-- send data
		group.sync()
	end
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



--group.protocols.ping
--group.protocols.sync

-- EVENT_FORWARD_CAMP_RESPAWN_TIMER_BEGINS
-- EVENT_POWER_UPDATE - add filter for POWERTYPE_DAEDRIC


-- on player activated:
--[[
update locally:
current camp lock (GetNextForwardCampRespawnTime() > GetGameTimeMilliseconds())

send:
current camp lock (GetNextForwardCampRespawnTime() > GetGameTimeMilliseconds())
hammer bar (GetUnitPower('player',POWERTYPE_DAEDRIC))
requestSync = true


/script ArtaeumGroupTool.Group.send(true,1,false)
/script ArtaeumGroupTool.Group.send(nil,nil,true)
]]


function group.send(campLock, hammerBar, requestSync)
	group.protocols.sync:Send({
		lock = campLock,
		hammer = hammerBar,
		requestSync = requestSync
	})
end

function group.sendHammer(_, unit, powerIndex, powerType, current, max)
	if max == 0 then max = 1 end
	local hammerBar = current/max
	group.send(nil, hammerBar, nil)
end

function group.sendLock()
	-- TODO: ALL OF THIS
end

function group.sync(requestSync)
	local hammerCurrent, hammerMax = GetUnitPower('player',POWERTYPE_DAEDRIC)
	if hammerMax == 0 then hammerMax = 1 end
	local hammerBar = hammerCurrent/hammerMax

	local campLock = GetNextForwardCampRespawnTime() > GetGameTimeMilliseconds()

	group.send(campLock, hammerBar, requestSync)
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

local ultIconLookup = {
	[0] = "/esoui/art/icons/heraldrycrests_misc_blank_01.dds", -- no ult
	[116096] = "/esoui/art/icons/ability_artifact_volendrung_006.dds", -- hammer ult
}
function group.lgcsCallback(unitTag, data)
	group.lgcsCallbackDebug[unitTag] = data --- DEBUG STUFF
	
	if hammerWeilder == unitTag then -- if unit has hammer
		data.ult1Cost = 250
		data.ult2Cost = 250
		data.ult1ID = 116096
		data.ult2ID = 116096
	end

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

-- TODO: Make all additional windows achor to window 1


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
		EVENT_MANAGER:UnregisterForEvent("AD Group Tool Group Daedric Power", EVENT_POWER_UPDATE)
		

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
		EVENT_MANAGER:RegisterForEvent("AD Group Tool Group Daedric Power", EVENT_POWER_UPDATE, group.sendHammer)
		EVENT_MANAGER:AddFilterForEvent("AD Group Tool Group Daedric Power", EVENT_POWER_UPDATE, REGISTER_FILTER_POWER_TYPE, COMBAT_MECHANIC_FLAGS_DAEDRIC)
		EVENT_MANAGER:AddFilterForEvent("AD Group Tool Group Daedric Power", EVENT_POWER_UPDATE, REGISTER_FILTER_UNIT_TAG, "player")
		
		
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
		group.sync(true)
	elseif group.running and sharing then
		group.groupLeadChange()
		group.groupUpdate()
		group.sync(true)
	end

end




function group.playerActivated(...)
	local active = (not vars.cyrodilOnly) or ((IsPlayerInAvAWorld() or IsActiveWorldBattleground()) and vars.cyrodilOnly) 
	group.updateSharing(active)

end



ZO_CreateStringId("SI_BINDING_NAME_ARTAEUMGROUPTOOL_REQUEST_PING", "Send a assist ping.")
SLASH_COMMANDS["/ping"] = group.ping

