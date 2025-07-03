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
	print("AD Initialized")

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
		group.protocols.sync:AddField(LGB.CreateOptionalField(LGB.CreateNumericField("ult1ID", {minValue=0, maxValue=175, trimValues=true})))
		group.protocols.sync:AddField(LGB.CreateOptionalField(LGB.CreateNumericField("ult2ID", {minValue=0, maxValue=175, trimValues=true})))
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

	---[[
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
			print("Recieved Sync Request from "..GetUnitDisplayName(unitTag))
			if syncQueued == false then group.sync(false) print("Starting Sync") end
			syncQueued = true
		end
		
	elseif data.requestSync == false then
		-- user just finished syncing
		if AreUnitsEqual(unitTag, 'player') then
			print("User Finished Syncing")
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
	print("Got data from "..playerName.." to have ult of "..data.ultValue)
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
for k,v in pairs(group.ultiIndexes) do
	group.ultiIndexes[v]=k
end














