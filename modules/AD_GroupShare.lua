-- Group Ult Sharing Module
local AD = ArtaeumGroupTool
AD.Group = {}
local group = AD.Group
local vars = {}

local print = AD.print


local toplevels = {}
group.frameDB = {}
local frameDB = group.frameDB


AD.last = {} -- TESTING
group.arrow = nil


group.running = false


group.units = {}
group.handlers = {}


function group.init()
	--print("AD Initialized")

	vars = AD.vars.Group

	if vars.enabled then
		
		group.createTopLevels()
		AD.initAnchors(toplevels, vars.dackUIEnabled)

		
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
			frameDB['group'..i] = AD.Frame:new('group'..i, toplevels[topLevelID], vars.dackUIEnabled)
			--if vars.showMagStam then
			--	frameDB['group'..i]:SetMagStamHidden(false)
			--end
		end

		group.scaleWindow()
		if vars.dackUIEnabled then
			group.setAllVisType()
		end

		if not vars.windowLocked then
			ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, "|cff0000Artaeum Group Tool's group UI has not been locked.|r")
			group.unlockWindow()
		end

		-- adapted from ZOS's Code
    	ZO_MostRecentPowerUpdateHandler:New("AD_UnitFrames", group.PowerUpdateHandlerFunction)



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
		group.protocols.sync:AddField(LGB.CreateOptionalField(LGB.CreatePercentageField("hammer", {numBits=5}))) -- ArtaeumDaedricPower (502), only when holding
		group.protocols.sync:AddField(LGB.CreateOptionalField(LGB.CreateFlagField("requestSync"))) -- ArtaeumRequestSync (503), request resend
		group.protocols.sync:OnData(group.handlers.onSync)
		group.protocols.sync:Finalize({isRelevantInCombat = false, replaceQueuedMessages = false})

		group.protocols.hammer = handler:DeclareProtocol(92, "ArtaeumDaedricArtifact") -- create seperate channel for artifact power, as it should replace queued messages
		group.protocols.hammer:AddField(LGB.CreatePercentageField("hammer")) -- ArtaeumDaedricPower (502), only when holding
		group.protocols.hammer:OnData(group.handlers.onHammerUpdate)
		group.protocols.hammer:Finalize({isRelevantInCombat = true, replaceQueuedMessages = true})



		local GroupResources = LibGroupBroadcast:GetHandlerApi("GroupResources")
		if GroupResources then
			--TEMP: ADD POWERTYPE ALIASES SINCE LGB STILL USES THEM
			POWERTYPE_MAGICKA = COMBAT_MECHANIC_FLAGS_MAGICKA
			POWERTYPE_STAMINA = COMBAT_MECHANIC_FLAGS_STAMINA
			GroupResources:RegisterForStaminaChanges(group.handlers.onStamUpdate)
			GroupResources:RegisterForMagickaChanges(group.handlers.onMagUpdate)
		end



		EVENT_MANAGER:RegisterForEvent("AD Group Tool Group Activated", EVENT_PLAYER_ACTIVATED, group.playerActivated)
		group.createArrow()
		group.setArrowColours()
		group.arrow:SetTarget(0, 0, 0)


		if IsPlayerActivated() then
			group.playerActivated()
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
		toplevels[i]:SetTransformNormalizedOriginPoint(0,0)
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
	--LGB pings also display locally so not needed 
end

function group.ping()
end


function group.createArrow()
	local beamProperties = {
		texture = "ArtaeumGroupTool/Textures/Pillar.dds",
		scaleX = 1,
		scaleY = 100,
		X = 0,
		Y = 50,
		Z = 0,
		depthBuffer = true
	}

	group.arrow = AD.AD3D.createArrow()
	group.pin = AD.AD3D.create3D(AD.AD3D.toplevel, beamProperties)
end

function group.setArrowColours()
	local rgb = vars.colours.marker
	group.arrow:SetColour(rgb[1],rgb[2],rgb[3])
	group.pin:setColour(rgb[1],rgb[2],rgb[3],rgb[4])
end







local playerUltLookup = {}






-- HANDLERS
function group.handlers.onPing(unitTag, data)
	--data.ping
	if data.ping == false then return end
	local _, Xw, Yw, Zw = GetUnitRawWorldPosition(unitTag)
	group.pin:show()
	local X,Y,Z = WorldPositionToGuiRender3DPosition(Xw,Yw,Zw)
	group.pin:setPos(X, Y, Z)
	group.arrow:StartUpdating()
	group.arrow:SetTarget(Xw, Yw, Zw)
	EVENT_MANAGER:RegisterForUpdate("ADGroupToolGroupSharePingFaceCamera", 50, function() group.pin:turnToFace() end)

	zo_callLater(function()
		EVENT_MANAGER:UnregisterForUpdate("ADGroupToolGroupSharePingFaceCamera")
		group.pin:hide()
		group.arrow:SetTarget(0, 0, 0)
		group.arrow:StopUpdating()
	end, 12500)
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
	local playerName = GetUnitName(unitTag)
	if playerName and playerUltLookup[playerName] then
		group.lgcsCallback(unitTag, playerUltLookup[playerName])
	end
	--local realData = group.lgcs:GetUnitULT(unitTag)
	--a = realData
	--if realData and realData._data then
		--group.lgcsCallback(unitTag, realData._data)
	--end
end

local hammerWeilder = ''
function group.handlers.onHammerUpdate(unitTag, data)
	--data.hammer
	-- player also gets their own messages
	if AreUnitsEqual(unitTag,'player') then
		lgcsUpdate(unitTag)
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
	lgcsUpdate(unitTag)
end


local syncQueued = false


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
		if not AreUnitsEqual(unitTag, 'player') then -- dont sync off of own sync request
			--print("Recieved Sync Request from "..GetUnitDisplayName(unitTag))
			if syncQueued == false then
				group.sync(false)
				--print("Starting Sync")
			end
			syncQueued = true
		end
		
	elseif data.requestSync == false then
		-- user just finished syncing
		if AreUnitsEqual(unitTag, 'player') then
			--print("User Finished Syncing")
			syncQueued = false
		end
	end
end

function group.handlers.onStamUpdate(unitTag, unitName, current, max, percent)
	if vars.showMagStam or vars.dackUIEnabled then
		if frameDB[unitTag].magStamHidden then frameDB[unitTag]:SetMagStamHidden(false) end
		frameDB[unitTag]:SetStam(percent,1)
	end
end

function group.handlers.onMagUpdate(unitTag, unitName, current, max, percent)
	if vars.showMagStam or vars.dackUIEnabled then
		if frameDB[unitTag].magStamHidden then frameDB[unitTag]:SetMagStamHidden(false) end
		frameDB[unitTag]:SetMag(percent,1)
	end
end






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
	group.protocols.hammer:Send({
		hammer = hammerBar
	})
end


local activeLockUpdate = false

function group.updateLock()
	-- run every 10 seconds
	if (GetNextForwardCampRespawnTime() <= GetGameTimeMilliseconds()) then
		group.send(false)
		EVENT_MANAGER:UnregisterForUpdate("AD Group Tool Camp Lock Check")
		activeLockUpdate = false
	end
end

function group.newLock()
	group.send(true)
	EVENT_MANAGER:RegisterForUpdate("AD Group Tool Camp Lock Check", 10000, group.updateLock)
	activeLockUpdate = true
end



function group.sync(requestSync)
	local hammerCurrent, hammerMax = GetUnitPower('player',COMBAT_MECHANIC_FLAGS_DAEDRIC)
	if hammerMax == 0 then hammerMax = 1 end
	local hammerBar = hammerCurrent/hammerMax

	local campLock = GetNextForwardCampRespawnTime() > GetGameTimeMilliseconds()
	if (not activeLockUpdate) and campLock then
		EVENT_MANAGER:RegisterForUpdate("AD Group Tool Camp Lock Check", 10000, group.updateLock)
		activeLockUpdate = true
	end

	group.send(campLock, hammerBar, requestSync)
end




function group.lgcsPlayerCallback(player, data)
	local playerTag = GetGroupUnitTagByIndex(GetGroupIndexByUnitTag('player'))
	if playerTag ~= nil then
		group.lgcsCallback(playerTag, data)
	end
end




local ultIconLookup = {
	[0] = "/esoui/art/icons/heraldrycrests_misc_blank_01.dds", -- no ult
	[116096] = "/esoui/art/icons/ability_artifact_volendrung_006.dds", -- hammer ult
}


function group.lgcsCallback(unitTag, data)
	--print("Unit "..tostring(GetUnitDisplayName(unitTag)).."("..unitTag..") has ults "..data.ult1ID.." and "..data.ult2ID)



	local noUlt = false
	if data.ult1ID == 0 and data.ult2ID == 0 then noUlt = true end
	
	if hammerWeilder == unitTag then -- if unit has hammer
		data.ult1Cost = 250
		data.ult2Cost = 250
		data.ult1ID = 116096
		data.ult2ID = 116096
	end


	local playerName = GetUnitName(unitTag)
	if playerName then
		playerUltLookup[playerName] = data
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




	frameDB[unitTag]:setUlt(data.ultValue, data.ult1Cost, ult1Icon, data.ult2Cost, ult2Icon, noUlt)
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
	if powerType == COMBAT_MECHANIC_FLAGS_HEALTH and frameDB[unitTag] then
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




latest = {}

function group.unitCreate(_, unitTag)
	--d("Unit created "..unitTag)
	--if true then return end

	if ZO_Group_IsGroupUnitTag(unitTag) and frameDB[unitTag] then
		print("Unit created with tag "..unitTag)
		frameDB[unitTag]:Update()
		lgcsUpdate(unitTag)
		print("")
    end
    --d("")
end

function group.unitDestroy(_, unitTag)
	--d("Actually, unit destroyed")
	if frameDB[unitTag] then
		frameDB[unitTag]:Update()
	end
	--group.unitCreate(_, unitTag)
end
-- https://github.com/esoui/esoui/blob/440a96c7883305fe0001bc3ce07319efa26e42e7/esoui/ingame/unitframes/unitframes.lua#L2766

-- Events that consider all possible group join/leave events and adapt the UI respectivly.
function group.groupJoinLeave(eventCode, _, _, isLocalPlayer)
    group.groupUpdate()
end

-- RUN THIS AFTER LIKE 100 MS

-- TODO: FIGURE OUT WHY THIS IS RUNNING ALOT
function group.groupUpdate()
	print("STARTING GROUP UPDATE")
	local groupStats = group.lgcs:GetGroupStats()
	for i=1,12 do
		local unitTag = 'group'..i
		if frameDB[unitTag] then
			frameDB[unitTag]:Update()
			lgcsUpdate(unitTag)
		end
	end
	print("ENDED")
end





function group.groupLeadChange()
	for i=1,12 do
		if frameDB['group'..i] then
			frameDB['group'..i]:setGroupLeader()
		end
	end
end

function group.setAllVisType()
	for i=1,12 do
		if frameDB['group'..i] then
			frameDB['group'..i]:SetVisType(vars.dackVisType)
		end
	end
end





function group.scaleWindow()
	local scale = vars.scale
	for i=1,#toplevels do
		toplevels[i]:SetTransformScale(scale)
	end
end

-- TODO: Make all additional windows achor to window 1


function group.showWindows()
	for i=1,#toplevels do
		toplevels[i]:SetHidden(false)
	end
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
	group.showWindows()
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


function group.saveWindowLocationX(i, x)
	local toplevel = toplevels[i]
	if not vars.windowLocations[i] then
		vars.windowLocations[i] = {0,0}
	end
	vars.windowLocations[i][1] = x
	toplevel:ClearAnchors()
	toplevel:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, vars.windowLocations[i][1], vars.windowLocations[i][2])	
end
function group.saveWindowLocationY(i, y)
	local toplevel = toplevels[i]
	if not vars.windowLocations[i] then
		vars.windowLocations[i] = {0,0}
	end
	vars.windowLocations[i][2] = y
	toplevel:ClearAnchors()
	toplevel:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, vars.windowLocations[i][1], vars.windowLocations[i][2])	
end



local lastZone = 0


function group.updateSharing(sharing)

	if group.running and not sharing then
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
		EVENT_MANAGER:UnregisterForEvent("AD Group Tool Group Camp", EVENT_FORWARD_CAMP_RESPAWN_TIMER_BEGINS)
		

		for i=1,12 do
			frameDB['group'..i].frame:SetHidden(true)
		end
		ZO_UnitFramesGroups:SetHidden(false)
		group.running = false
		

		group.pin:disable()
		group.arrow:SetTarget(0,0,0)
		group.arrow:StopUpdating()


	elseif not group.running and sharing then
		group.lgcs:RegisterForEvent(LibGroupCombatStats.EVENT_GROUP_ULT_UPDATE, group.lgcsCallback)
		group.lgcs:RegisterForEvent(LibGroupCombatStats.EVENT_PLAYER_ULT_UPDATE, group.lgcsPlayerCallback)
		EVENT_MANAGER:RegisterForEvent("AD Group Tool Unit Created", EVENT_UNIT_CREATED, group.unitCreate)
		EVENT_MANAGER:AddFilterForEvent("AD Group Tool Unit Created", EVENT_UNIT_CREATED, REGISTER_FILTER_UNIT_TAG_PREFIX, "group")
		EVENT_MANAGER:RegisterForEvent("AD Group Tool Unit Destroyed", EVENT_UNIT_DESTROYED, group.unitDestroy)
		EVENT_MANAGER:AddFilterForEvent("AD Group Tool Unit Destroyed", EVENT_UNIT_DESTROYED, REGISTER_FILTER_UNIT_TAG_PREFIX, "group")
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
		EVENT_MANAGER:RegisterForEvent("AD Group Tool Group Camp", EVENT_FORWARD_CAMP_RESPAWN_TIMER_BEGINS, group.newLock)
		
		
		group.pin:enable()
		--group.arrow:StartUpdating()
		


		if vars.hideBaseUnitFrames then
			ZO_UnitFramesGroups:SetHidden(true)
		end

		group.running = true
		group.groupLeadChange()
		group.groupUpdate()
		group.sync(true)
	elseif group.running and sharing then
		group.groupLeadChange()
		group.groupUpdate()

		local currentZone = GetUnitWorldPosition('player')
		if currentZone ~= lastZone then
			--d("Loaded into a new zone: "..currentZone..", last zone was: "..lastZone)
			group.sync(true) -- Only sync when changing zones
		end
		lastZone = currentZone
	end

end




function group.playerActivated(...)
	local active = (not vars.cyrodilOnly) or ((IsPlayerInAvAWorld() or IsActiveWorldBattleground()) and vars.cyrodilOnly) 
	group.updateSharing(active)
	EVENT_MANAGER:UnregisterForUpdate("ADGroupToolGroupSharePingFaceCamera") -- if this got through the call later, just shut it off
end



ZO_CreateStringId("SI_BINDING_NAME_ARTAEUMGROUPTOOL_REQUEST_PING", "Send a assist ping.")

