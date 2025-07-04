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


group.running = false


group.units = {}
group.handlers = {}


function group.init()
	--print("AD Initialized")

	vars = AD.vars.Group

	if vars.enabled then
		
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



		--group.lgcs = LibGroupCombatStats.RegisterAddon("ArtaeumGroupTool", {"ULT"})
		-- TODO: GET RID OF LGCS






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

		group.protocols.sync:AddField(LGB.CreateOptionalField(LGB.CreateNumericField("ult1Cost", {minValue=0, maxValue=500, trimValues=true}))) -- LGCS emulation until it is updated for console
		group.protocols.sync:AddField(LGB.CreateOptionalField(LGB.CreateNumericField("ult2Cost", {minValue=0, maxValue=500, trimValues=true})))
		group.protocols.sync:AddField(LGB.CreateOptionalField(LGB.CreateNumericField("ult1ID", {minValue=0, maxValue=237, trimValues=true})))
		group.protocols.sync:AddField(LGB.CreateOptionalField(LGB.CreateNumericField("ult2ID", {minValue=0, maxValue=237, trimValues=true})))
		group.protocols.sync:AddField(LGB.CreateOptionalField(LGB.CreateNumericField("ultValue", {minValue=0, maxValue=500, trimValues=true})))

		group.protocols.sync:OnData(group.handlers.onSync)
		group.protocols.sync:Finalize({isRelevantInCombat = false, replaceQueuedMessages = false})

		group.protocols.hammer = handler:DeclareProtocol(92, "ArtaeumDaedricArtifact") -- create seperate channel for artifact power, as it should replace queued messages
		group.protocols.hammer:AddField(LGB.CreatePercentageField("hammer")) -- ArtaeumDaedricPower (502), only when holding
		group.protocols.hammer:OnData(group.handlers.onHammerUpdate)
		group.protocols.hammer:Finalize({isRelevantInCombat = true, replaceQueuedMessages = true})


		group.protocols.ult = handler:DeclareProtocol(93, "ArtaeumUlt")
		group.protocols.ult:AddField(LGB.CreateNumericField("ultValue"))
		group.protocols.ult:OnData(group.handlers.onUlt)
		group.protocols.ult:Finalize({isRelevantInCombat = true, replaceQueuedMessages = true})




		--[[
		-- 3 to 7 bytes
		local firstsync = handler:DeclareProtocol(94, "ArtaeumDataSyncTestFirst")
		firstsync:AddField(LGB.CreateOptionalField(LGB.CreateFlagField("lock"))) -- ArtaeumCampLock (501), only when lock updates on/off
		firstsync:AddField(LGB.CreateOptionalField(LGB.CreatePercentageField("hammer", {numBits=5}))) -- ArtaeumDaedricPower (502), only when holding
		firstsync:AddField(LGB.CreateOptionalField(LGB.CreateFlagField("requestSync"))) -- ArtaeumRequestSync (503), request resend
		firstsync:AddField(LGB.CreateOptionalField(LGB.CreateNumericField("ult1Cost", {minValue=0, maxValue=500, trimValues=true}))) -- LGCS emulation until it is updated for console
		firstsync:AddField(LGB.CreateOptionalField(LGB.CreateNumericField("ult2Cost", {minValue=0, maxValue=500, trimValues=true})))
		firstsync:AddField(LGB.CreateOptionalField(LGB.CreateNumericField("ultValue", {minValue=0, maxValue=500, trimValues=true})))
		firstsync:OnData(function() d("Data recieved sync 1") end)
		firstsync:Finalize({isRelevantInCombat = false, replaceQueuedMessages = false})

	
		-- 3 to 8 bytes
		local secondsync = handler:DeclareProtocol(95, "ArtaeumDataSyncTestSecond")
		secondsync:AddField(LGB.CreateOptionalField(LGB.CreateNumericField("ult1ID", {numBits=20})))
		secondsync:AddField(LGB.CreateOptionalField(LGB.CreateNumericField("ult2ID", {numBits=20})))
		secondsync:OnData(function() d("Data recieved sync 1") end)
		secondsync:Finalize({isRelevantInCombat = false, replaceQueuedMessages = false})
		--]]
		


		local GroupResources = LibGroupBroadcast:GetHandlerApi("GroupResources")
		if GroupResources then
			--TEMP: ADD POWERTYPE ALIASES SINCE LGB STILL USES THEM
			POWERTYPE_MAGICKA = COMBAT_MECHANIC_FLAGS_MAGICKA
			POWERTYPE_STAMINA = COMBAT_MECHANIC_FLAGS_STAMINA
			GroupResources:RegisterForStaminaChanges(group.handlers.onStamUpdate)
			GroupResources:RegisterForMagickaChanges(group.handlers.onMagUpdate)
		end



		EVENT_MANAGER:RegisterForEvent("AD Group Tool Group Activated", EVENT_PLAYER_ACTIVATED, group.playerActivated)
		group.createArrow() -- todo: replace with pin


		


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








local playerUltLookup = {}


local pingMarkerData = {
	texture = "ArtaeumGroupTool/Textures/pillar.dds",
	scaleX = 1,
	scaleY = 100,
	X = 0,
	Y = 50,
	Z = 0,
	depthBuffer = true,
	facePlayer = true,
}


function group.createArrow()
	group.arrow = AD.AD3D.create3D(AD.AD3D.toplevel, pingMarkerData)
	group.arrow:setColour(unpack(vars.colours.marker))
	group.arrow:disable()
end



-- HANDLERS
function group.handlers.onPing(unitTag, data)
	--print("PING Recieved")
	if data.ping == false then return end	
	-- NO MORE 3D ARROW: TODO: REPLACE WITH AD3D PIN
	local _,Xw,Yw,Zw = GetUnitWorldPosition(unitTag)
	local X,Y,Z = WorldPositionToGuiRender3DPosition(Xw,Yw,Zw)

	group.arrow:enable()
	group.arrow:show()
	group.arrow:setPos(X,Y,Z)

	zo_callLater(function()
		group.arrow:disable()
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

	--[[
	local syncData = ""
	for i,v in pairs(data) do
		syncData = syncData..i..", "
	end
	print("Recieved data from "..GetUnitDisplayName(unitTag)..": "..syncData)
	
	--]]


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



	if data.ult1Cost or data.ult2Cost or data.ult1ID or data.ult2ID then
		local playerName = GetUnitName(unitTag)

		if playerName and playerUltLookup[playerName] then
			if data.ult1Cost ~= nil then playerUltLookup[playerName].ult1Cost = data.ult1Cost end
			if data.ult2Cost ~= nil then playerUltLookup[playerName].ult2Cost = data.ult2Cost end
			if data.ult1ID ~= nil then playerUltLookup[playerName].ult1ID = group.ultiIndexes[data.ult1ID] or 0 end
			if data.ult2ID ~= nil then playerUltLookup[playerName].ult2ID = group.ultiIndexes[data.ult2ID] or 0 end
			if data.ultValue ~= nil then playerUltLookup[playerName].ultValue = data.ultValue end
		else
			playerUltLookup[playerName] = {
				ult1Cost=data.ult1Cost or 0,
				ult2Cost=data.ult2Cost or 0,
				ult1ID=group.ultiIndexes[data.ult1ID or 0] or 0,
				ult2ID=group.ultiIndexes[data.ult2ID or 0] or 0,
				ultValue=data.ultValue or 0
			}
		end
		group.lgcsCallback(unitTag, playerUltLookup[playerName])
	end

end

function group.handlers.onStamUpdate(unitTag, unitName, current, max, percent)
	if vars.showMagStam then
		if frameDB[unitTag].magStamHidden then frameDB[unitTag]:SetMagStamHidden(false) end
		frameDB[unitTag]:SetStam(percent,1)
	end
end

function group.handlers.onMagUpdate(unitTag, unitName, current, max, percent)
	if vars.showMagStam then
		if frameDB[unitTag].magStamHidden then frameDB[unitTag]:SetMagStamHidden(false) end
		frameDB[unitTag]:SetMag(percent,1)
	end
end


function group.handlers.onUlt(unitTag, data)
	--data.ultValue
	local playerName = GetUnitName(unitTag)
	--print("Got data from "..playerName.." to have ult of "..data.ultValue)
	if playerName and playerUltLookup[playerName] then
		playerUltLookup[playerName].ultValue = data.ultValue

		group.lgcsCallback(unitTag, playerUltLookup[playerName])
	end
end





function group.send(campLock, hammerBar, requestSync, ult1Cost, ult2Cost, ult1ID, ult2ID, ultValue)
	group.protocols.sync:Send({
		lock = campLock,
		hammer = hammerBar,
		requestSync = requestSync,
		ult1Cost = ult1Cost,
		ult2Cost = ult2Cost,
		ult1ID = ult1ID,
		ult2ID = ult2ID,
		ultValue = ultValue
	})
end

function group.sendHammer(_, unit, powerIndex, powerType, current, max)
	if max == 0 then max = 1 end
	local hammerBar = current/max
	group.protocols.hammer:Send({
		hammer = hammerBar
	})
end



function group.sendUlt(_, unit, powerIndex, powerType, current)
	group.protocols.ult:Send({
		ultValue = current
	})
end

local playerUlt1ID = 0
local playerUlt2ID = 0
local playerUlt1Cost = 0
local playerUlt2Cost = 0


function group.hotbarChanged(onlyUpdate)
	local ult1ID = GetSlotBoundId(ACTION_BAR_ULTIMATE_SLOT_INDEX + 1, HOTBAR_CATEGORY_PRIMARY)
	local ult2ID = GetSlotBoundId(ACTION_BAR_ULTIMATE_SLOT_INDEX + 1, HOTBAR_CATEGORY_BACKUP)
	local ult1Cost = GetAbilityCost(ult1ID, COMBAT_MECHANIC_FLAGS_ULTIMATE, nil, localPlayer)
	local ult2Cost = GetAbilityCost(ult2ID, COMBAT_MECHANIC_FLAGS_ULTIMATE, nil, localPlayer)

	if ult1ID == playerUlt1ID then ult1ID = nil else playerUlt1ID = ult1ID end
	if ult2ID == playerUlt2ID then ult2ID = nil else playerUlt2ID = ult2ID end
	if ult1Cost == playerUlt1Cost then ult1Cost = nil else playerUlt1Cost = ult1Cost end
	if ult2Cost == playerUlt2Cost then ult2Cost = nil else playerUlt2Cost = ult2Cost end

	if onlyUpdate == true then return end

	if ult1Cost or ult2Cost or ult1ID or ult2ID then
		--group.send(nil, nil, nil, ult1Cost, ult2Cost, ult1ID, ult2ID, ultValue)
		group.send(nil, nil, nil, ult1Cost, ult2Cost, nil, nil, ultValue)
		group.send(nil, nil, nil, nil, nil, group.ultiIndexes[ult1ID or -1], group.ultiIndexes[ult2ID or -1], nil) -- intentionally send nils
	end
	
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


	group.hotbarChanged(true)
	local ultValue = GetUnitPower('player',COMBAT_MECHANIC_FLAGS_ULTIMATE)

	--group.send(campLock, hammerBar, requestSync, playerUlt1Cost, playerUlt2Cost, playerUlt1ID, playerUlt2ID, ultValue)
	group.send(campLock, hammerBar, nil, playerUlt1Cost, playerUlt2Cost, nil, nil, nil)
	group.send(nil, nil, nil, nil, nil, group.ultiIndexes[playerUlt1ID or 0] or 0, group.ultiIndexes[playerUlt2ID or 0] or 0, ultValue)
	group.send(nil, nil, requestSync)
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
		frameDB[unitTag]:Update()
		lgcsUpdate(unitTag)
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
	--local groupStats = group.lgcs:GetGroupStats()
	for i=1,12 do
		local unitTag = 'group'..i
		if frameDB[unitTag] then
			frameDB[unitTag]:Update()
			lgcsUpdate(unitTag)
		end
	end
end





function group.groupLeadChange()
	for i=1,12 do
		if frameDB['group'..i] then
			frameDB['group'..i]:setGroupLeader()
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







function group.updateSharing(sharing)

	if group.running and not sharing then

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
		EVENT_MANAGER:UnregisterForEvent("AD Group Tool Group Ult Power", EVENT_POWER_UPDATE)
		EVENT_MANAGER:UnregisterForEvent("AD Group Tool Group Camp", EVENT_FORWARD_CAMP_RESPAWN_TIMER_BEGINS)

		EVENT_MANAGER:UnregisterForEvent("AD Group Tool Group Hotbars Changed", EVENT_ACTION_SLOTS_ALL_HOTBARS_UPDATED)
		

		for i=1,12 do
			frameDB['group'..i].frame:SetHidden(true)
		end
		ZO_UnitFramesGroups:SetHidden(false)
		group.running = false
		

	elseif not group.running and sharing then
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

		EVENT_MANAGER:RegisterForEvent("AD Group Tool Group Ult Power", EVENT_POWER_UPDATE, group.sendUlt)
		EVENT_MANAGER:AddFilterForEvent("AD Group Tool Group Ult Power", EVENT_POWER_UPDATE, REGISTER_FILTER_POWER_TYPE, COMBAT_MECHANIC_FLAGS_ULTIMATE)
		EVENT_MANAGER:AddFilterForEvent("AD Group Tool Group Ult Power", EVENT_POWER_UPDATE, REGISTER_FILTER_UNIT_TAG, "player")

		EVENT_MANAGER:RegisterForEvent("AD Group Tool Group Camp", EVENT_FORWARD_CAMP_RESPAWN_TIMER_BEGINS, group.newLock)
		

		EVENT_MANAGER:RegisterForEvent("AD Group Tool Group Hotbars Changed", EVENT_ACTION_SLOTS_ALL_HOTBARS_UPDATED, group.hotbarChanged)
		
		


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
		group.sync(true)
	end

end




function group.playerActivated(...)
	local active = (not vars.cyrodilOnly) or ((IsPlayerInAvAWorld() or IsActiveWorldBattleground()) and vars.cyrodilOnly) 
	group.updateSharing(active)

end



ZO_CreateStringId("SI_BINDING_NAME_ARTAEUMGROUPTOOL_REQUEST_PING", "Send a assist ping.")


























--[[

-- Code for getting this, done ingame

/script
o = {}
for i=1,1000000 do
	if IsAbilityUltimate(i) then o[#o+1] = {i,GetAbilityName(i)} end
end

]]--



group.ultiIndexes = {
	[0] = 0, -- no ult
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
	[21] = 24799, -- Overload
	[22] = 24804, -- Energy Overload
	[23] = 24805, -- Energy Overload
	[24] = 24806, -- Power Overload
	[25] = 24808, -- Power Overload
	[26] = 25091, -- Soul Shred
	[27] = 25411, -- Consuming Darkness
	[28] = 26598, -- Arm Wabbajack
	[29] = 27706, -- Negate Magic
	[30] = 28341, -- Suppression Field
	[31] = 28348, -- Absorption Field
	[32] = 28434, -- Heavy Attack (Power Overload)
	[33] = 28988, -- Dragonknight Standard
	[34] = 29012, -- Dragon Leap
	[35] = 29740, -- Energy Overload
	[36] = 32455, -- Werewolf Transformation
	[37] = 32624, -- Blood Scion
	[38] = 32715, -- Ferocious Leap
	[39] = 32719, -- Take Flight
	[40] = 32947, -- Standard of Might
	[41] = 32958, -- Shifting Standard
	[42] = 32963, -- Shifting Standard
	[43] = 33398, -- Death Stroke
	[44] = 35460, -- Soul Tether
	[45] = 35508, -- Soul Siphon
	[46] = 35713, -- Dawnbreaker
	[47] = 36485, -- Veil of Blades
	[48] = 36493, -- Bolstering Darkness
	[49] = 36508, -- Incapacitating Strike
	[50] = 36514, -- Soul Harvest
	[51] = 38563, -- War Horn
	[52] = 38573, -- Barrier
	[53] = 38931, -- Perfect Scion
	[54] = 38932, -- Swarming Scion
	[55] = 39075, -- Pack Leader
	[56] = 39076, -- Werewolf Berserker
	[57] = 39270, -- Soul Strike
	[58] = 40158, -- Dawnbreaker of Smiting
	[59] = 40161, -- Flawless Dawnbreaker
	[60] = 40220, -- Sturdy Horn
	[61] = 40223, -- Aggressive Horn
	[62] = 40237, -- Reviving Barrier
	[63] = 40239, -- Replenishing Barrier
	[64] = 40414, -- Shatter Soul
	[65] = 40420, -- Soul Assault
	[66] = 40489, -- Ice Comet
	[67] = 40493, -- Shooting Star
	[68] = 49886, -- Impenetrable Ward
	[69] = 49899, -- Lightning Assault
	[70] = 50303, -- Legendary Heal Other
	[71] = 50385, -- Rapid Recovery
	[72] = 50468, -- Drain Soul
	[73] = 50501, -- Cataclysm
	[74] = 50544, -- Ice Armor
	[75] = 50570, -- Hypothermia
	[76] = 50663, -- Ultimate Flame Atronach
	[77] = 50790, -- Conjure Dremora Ruler
	[78] = 50872, -- Ebonyflesh
	[79] = 50898, -- Magicka Invulnerability
	[80] = 50961, -- Mass Paralysis
	[81] = 50981, -- Encumber
	[82] = 51016, -- Heroic Courage
	[83] = 51153, -- Hushed Feet
	[84] = 51248, -- Incite Frenzy
	[85] = 52897, -- Standard of Might
	[86] = 53875, -- Heroic Courage
	[87] = 54118, -- Remembrance
	[88] = 55090, -- Devouring Swarm
	[89] = 61090, -- Standard of Might
	[90] = 79064, -- Veil of Blades
	[91] = 83216, -- Berserker Strike
	[92] = 83229, -- Onslaught
	[93] = 83238, -- Berserker Rage
	[94] = 83272, -- Shield Wall
	[95] = 83292, -- Spell Wall
	[96] = 83310, -- Shield Discipline
	[97] = 83465, -- Rapid Fire
	[98] = 83552, -- Panacea
	[99] = 83600, -- Lacerate
	[100] = 83619, -- Elemental Storm
	[101] = 83625, -- Fire Storm
	[102] = 83628, -- Ice Storm
	[103] = 83630, -- Thunder Storm
	[104] = 83642, -- Eye of the Storm
	[105] = 83682, -- Eye of Flame
	[106] = 83684, -- Eye of Frost
	[107] = 83686, -- Eye of Lightning
	[108] = 83850, -- Life Giver
	[109] = 83867, -- Live Giver
	[110] = 84434, -- Elemental Rage
	[111] = 85126, -- Fiery Rage
	[112] = 85128, -- Icy Rage
	[113] = 85130, -- Thunderous Rage
	[114] = 85132, -- Light's Champion
	[115] = 85156, -- Lacerate
	[116] = 85179, -- Thrive in Chaos
	[117] = 85187, -- Rend
	[118] = 85257, -- Toxic Barrage
	[119] = 85451, -- Ballista
	[120] = 85532, -- Secluded Grove
	[121] = 85804, -- Enchanted Forest
	[122] = 85807, -- Healing Thicket
	[123] = 85982, -- Feral Guardian
	[124] = 85986, -- Eternal Guardian
	[125] = 85990, -- Wild Guardian
	[126] = 86109, -- Sleet Storm
	[127] = 86113, -- Northern Storm
	[128] = 86117, -- Permafrost
	[129] = 88158, -- Materialize
	[130] = 90284, -- Guardian's Wrath
	[131] = 92163, -- Guardian's Savagery
	[132] = 94625, -- Guardian's Wrath
	[133] = 103478, -- Undo
	[134] = 103557, -- Precognition
	[135] = 103564, -- Temporal Guard
	[136] = 113105, -- Incapacitating Strike
	[137] = 113505, -- Discharge Energy
	[138] = 114759, -- Overload
	[139] = 114760, -- Power Overload
	[140] = 114761, -- Energy Overload
	[141] = 114985, -- Overload
	[142] = 114986, -- Power Overload
	[143] = 114987, -- Energy Overload
	[144] = 115001, -- Bone Goliath Transformation
	[145] = 115361, -- Shock Field
	[146] = 115410, -- Reanimate
	[147] = 116096, -- Ruinous Cyclone
	[148] = 118279, -- Ravenous Goliath
	[149] = 118367, -- Renewing Animation
	[150] = 118379, -- Animate Blastbones
	[151] = 118664, -- Pummeling Goliath
	[152] = 122174, -- Frozen Colossus
	[153] = 122388, -- Glacial Colossus
	[154] = 122395, -- Pestilent Colossus
	[155] = 126489, -- Berserker Strike
	[156] = 126492, -- Berserker Rage
	[157] = 126497, -- Onslaught
	[158] = 129375, -- Vampire Lord
	[159] = 132866, -- Heavy Attack (Power Overload)
	[160] = 133507, -- Lead the Pack
	[161] = 140517, -- Overload
	[162] = 140518, -- Energy Overload
	[163] = 140519, -- Power Overload
	[164] = 157016, -- Unleashed Rage
	[165] = 157259, -- Impeccable Shot
	[166] = 160715, -- Scurry
	[167] = 163763, -- Baneslayer
	[168] = 164191, -- Raging Storm
	[169] = 164413, -- Channel the Storm
	[170] = 164881, -- Overcharge
	[171] = 165208, -- Unstable Shield
	[172] = 165281, -- Arcane Wards
	[173] = 165412, -- Cyclone
	[174] = 165810, -- Spell Conversion
	[175] = 165875, -- Forced Sacrifice
	[176] = 166037, -- Time Tear
	[177] = 175666, -- Energy Overload
	[178] = 180983, -- Light Attack (Overload)
	[179] = 183676, -- Gibbering Shield
	[180] = 183709, -- Vitalizing Glyphic
	[181] = 186488, -- Gore
	[182] = 189182, -- Overload
	[183] = 189791, -- The Unblinking Eye
	[184] = 189837, -- The Tide King's Gaze
	[185] = 189867, -- The Languid Eye
	[186] = 192372, -- Sanctum of the Abyssal Sea
	[187] = 192380, -- Gibbering Shelter
	[188] = 192927, -- Headbutt
	[189] = 193558, -- Resonating Glyphic
	[190] = 193794, -- Glyphic of the Tides
	[191] = 195103, -- Vigorous Tentacular Eruption
	[192] = 196782, -- Rite of Passage
	[193] = 212005, -- Lead the Pack
	[194] = 213168, -- Azura's Champion
	[195] = 213169, -- Blade of the Crossing
	[196] = 215215, -- Ruinous Outburst
	[197] = 215668, -- Tanlorin Avatar Form
	[198] = 217049, -- Waves of Power
	[199] = 230457, -- Vampire's Leap
	[200] = 230523, -- Lead the Pack
	[201] = 237017, -- DPS Ultimate
	[202] = 237025, -- Tank Damage Limit Cyrodiil Champions
	[203] = 237060, -- Resurrect
	[204] = 237619, -- Vengeance Death Stroke
	[205] = 237627, -- Vengeance Dragonknight Standard
	[206] = 237648, -- Vengeance Dragon Leap
	[207] = 237702, -- Vengeance Bolstering Darkness
	[208] = 237722, -- Vengeance Soul Shred
	[209] = 237790, -- Vengeance Magma Armor
	[210] = 237811, -- Vengeance Radial Sweep
	[211] = 237856, -- Vengeance Negate Magic
	[212] = 237933, -- Vengeance Storm Atronach
	[213] = 237942, -- Vengeance Nova
	[214] = 237994, -- Vengeance Rite of Passage
	[215] = 237998, -- Vengeance Overload
	[216] = 238043, -- Vengeance Feral Guardian
	[217] = 238074, -- Vengeance Secluded Grove
	[218] = 238098, -- Vengeance Sleet Storm
	[219] = 238129, -- Vengeance Frozen Colossus
	[220] = 238228, -- Vengeance The Unblinking Eye
	[221] = 238236, -- Vengeance Bone Goliath Transformation
	[222] = 238274, -- Vengeance Gibbering Shield
	[223] = 238316, -- Reanimate
	[224] = 238549, -- Vengeance Vitalizing Glyphic
	[225] = 240494, -- Vengeance Berserker Strike
	[226] = 240572, -- Vengeance Shield Wall
	[227] = 241236, -- Vengeance Lacerate
	[228] = 241278, -- Vengeance Rapid Fire
	[229] = 241485, -- Vengeance Elemental Storm
	[230] = 241487, -- Vengeance Fire Storm
	[231] = 241489, -- Vengeance Ice Storm
	[232] = 241491, -- Vengeance Thunder Storm
	[233] = 241586, -- Vengeance Panacea
	[234] = 244644, -- Vengeance War Horn
	[235] = 244725, -- Vengeance Barrier
}

group.ultiIndexes[236] = 195031 -- Crypt Transfer
group.ultiIndexes[237] = 0 -- assume no ult if something fucked up


for k,v in pairs(group.ultiIndexes) do
	group.ultiIndexes[v]=k
end