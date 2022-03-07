local AD = ArtaeumGroupTool
AD.Frame = {}
local frameBase = AD.Frame
local frameObject = ZO_Object:Subclass()
local vanillaFrame = ZO_Object:Subclass()

local alliances = {
	"esoui/art/stats/alliancebadge_aldmeri.dds",
	"esoui/art/stats/alliancebadge_ebonheart.dds",
	"esoui/art/stats/alliancebadge_daggerfall.dds",
}
local roles = {
	[1] = "esoui/art/lfg/gamepad/lfg_roleicon_dps.dds",
	[2] = "esoui/art/lfg/gamepad/lfg_roleicon_tank.dds",
	[4] = "esoui/art/lfg/gamepad/lfg_roleicon_healer.dds",
}



local anchors = {}
function AD.initAnchors(topLevels)
	local amountCreated = 0
	for i=1,12 do
		local topLevelID = math.floor((i-1)*AD.vars.Group.amountOfWindows/12)+1
		local anchor = ZO_Anchor:New(TOPLEFT, topLevels[topLevelID], TOPLEFT, 0, 40 * (amountCreated%(12/AD.vars.Group.amountOfWindows)))
		anchors[i] = anchor
		amountCreated = amountCreated + 1
	end
end



function frameBase:new(unitTag, parent)
	if AD.vars.Group.UI == "Custom" then
		return frameObject:new(unitTag,parent)
	else
		return vanillaFrame:new(unitTag)
	end
end


function frameObject:new(unitTag, parent)
	local frame = ZO_Object.New(self)
	frame.frame = CreateControlFromVirtual("ART"..unitTag,parent,"AD_Group_Template")
	frame.bar = frame.frame:GetNamedChild("Ult")
	frame.image = frame.frame:GetNamedChild("UltIcon")
	frame.ultPercent = frame.frame:GetNamedChild("UltPercent")
	frame.name = frame.frame:GetNamedChild("Name")
	frame.health = frame.frame:GetNamedChild("Health")
	frame.backdrop = frame.frame:GetNamedChild("BG")
	frame.groupLead = frame.frame:GetNamedChild("Icon")

	frame.unitTag = unitTag
	frame.index = nil
	frame.unit = ""

	frame.frame:SetHidden(true)


	return frame
end




function frameObject:Update()
	self.index = GetGroupIndexByUnitTag(self.unitTag)
	if self.index > 12 then self.index = nil end
	if self.index then

		-- Unit Changed index
		if self.unit == GetUnitDisplayName(self.unitTag) then
			self:setAnchors()
			self.frame:SetHidden(false)

		else -- Unit Changed
			self.unit = GetUnitDisplayName(self.unitTag)
			local rgb = AD.vars.Group.colours.standardHealth
			self.health:SetColor(rgb[1],rgb[2],rgb[3],rgb[4])
			self:setName()
			self:setGroupLeader()
			self:SetOnline(IsUnitOnline(self.unitTag))
			local role = GetGroupMemberSelectedRole(self.unitTag)
			if role == 0 then
				local alliance = GetUnitAlliance(self.unitTag)
				self.image:SetTexture(alliances[alliance])
			else
				self.image:SetTexture(roles[role])
			end
			self.backdrop:SetEdgeColor(1,1,1,1)
			self.ultPercent:SetText("")

			self:setAnchors()
			self.frame:SetHidden(false)
		end

	else -- Unit Doesnt Exist anymore
		self.frame:SetHidden(true)
		self.unit = ""
	end
end



function frameObject:setAnchors()
	if self.index then
		anchors[self.index]:Set(self.frame)
	end
end
function frameObject:setName()
	self.name:SetText(self.unit)
end

function frameObject:SetEdgeColor(...)
	self.backdrop:SetEdgeColor(...)
end


function frameObject:setGroupLeader()
	local _,topl,parentframe,top,x,y,z = self.name:GetAnchor()
	if IsUnitGroupLeader(self.unitTag) then
		self.name:SetAnchor(topl, parentframe, top, 20, y)
		--self.name.setAnchor(self.frame.name.anchor)
		--self.name:SetTransformOffsetX(20*AD.vars.Group.scale)
		self.name:SetWidth(143)
		self.groupLead:SetHidden(false)
	else
		--self.name:SetTransformOffsetX(0)
		--self.name.anchorUntabbed:Set(self.name)
		self.name:SetAnchor(topl, parentframe, top, 0, y)
		self.name:SetWidth(163)
		self.groupLead:SetHidden(true)
	end
end

function frameObject:SetHealth(value,max)
	ZO_StatusBar_SmoothTransition(self.health,value,max)
end


function frameObject:SetDead(dead)
	local current, max = GetUnitPower(self.unitTag, POWERTYPE_HEALTH)
	if dead then
		self.name:SetColor(1,0,0,1)
		self:SetHealth(0,max)
		EVENT_MANAGER:RegisterForUpdate("AD Res "..self.unitTag, 100, function() self:DeathLoop() end)
	else
		self.name:SetColor(1,1,1,1)
		self:SetHealth(current,max)
		EVENT_MANAGER:UnregisterForUpdate("AD Res " .. self.unitTag)
	end
end

function frameObject:DeathLoop()
	local unitTag = self.unitTag
    if not DoesUnitExist(unitTag) then
    	EVENT_MANAGER:UnregisterForUpdate("AD Res " .. self.unitTag)
    	return
    end

    if IsUnitDead(unitTag) then
        if IsUnitBeingResurrected(unitTag) then
            self.name:SetColor(1,1,0,1)
        elseif DoesUnitHaveResurrectPending(unitTag) then
            self.name:SetColor(0,1,0,1)
        else
        	self.name:SetColor(1,0,0,1)
        end
    elseif IsUnitReincarnating(unitTag) then
        self.name:SetColor(0,0,1,1)
    else
    	local current, max = GetUnitPower(self.unitTag, POWERTYPE_HEALTH)
    	self.name:SetColor(1,1,1,1)
    	self:SetHealth(current,max)
        EVENT_MANAGER:UnregisterForUpdate("AD Res " .. self.unitTag)
    end
end




function frameObject:SetOnline(online)
	local current, max = GetUnitPower(self.unitTag, POWERTYPE_HEALTH)
	if online then
		self.name:SetColor(1,1,1,1)
		self:SetHealth(current,max)
		self.frame:SetAlpha(1)
		self.image:SetColor(1,1,1,1)
	else
		self.name:SetColor(1,1,1,0.5)
		self.frame:SetAlpha(0.7)
		self:SetHealth(0,max)

		local alliance = GetUnitAlliance(self.unitTag)
		self.image:SetTexture(alliances[alliance])
		self.image:SetColor(1,1,1,0.5)
		self.bar:SetMinMax(0,100)
		self.bar:SetValue(0)
	end
end

function frameObject:setUlt(percent, icon)
	self.bar:SetMinMax(0,100)
	self.bar:SetValue(100-percent)
	self.image:SetTexture(icon)
	self.ultPercent:SetText(""..percent.."%")
	if percent == 100 then
		local rgb = AD.vars.Group.colours.fullUlt
		self.health:SetColor(rgb[1],rgb[2],rgb[3],rgb[4])
	else
		local rgb = AD.vars.Group.colours.standardHealth
		self.health:SetColor(rgb[1],rgb[2],rgb[3],rgb[4])
	end
end





function vanillaFrame:new(unitTag)

	local baseFrame = UNIT_FRAMES:GetFrame(unitTag)

	local frame = ZO_Object.New(self)
	frame.frame = baseFrame.frame
	local width = frame.frame:GetWidth()
	frame.frame:SetWidth(width+40)


	frame.bar = CreateControl("ART"..unitTag.."Ult",frame.frame,CT_STATUSBAR)
	local ult = frame.bar
	ult:SetDimensions(40,40)
	ult:SetMinMax(0,20)
	ult:SetValue(0)
	ult:SetColor(0)
	ult:SetAlpha(0.8)
	ult:SetOrientation(0)
	ult:SetBarAlignment(1)
	ult:SetAnchor(8,nil,8,-4,0,0)
	ult:SetDrawLevel(6)


	frame.image = CreateControl("ART"..unitTag.."UltImage",frame.frame,CT_TEXTURE)
	local ulti = frame.image
	ulti:SetDimensions(40,40)
	ulti:SetDrawLevel(5)
	ulti:SetAnchor(8,nil,8,-4,0,0)

	local role = GetGroupMemberSelectedRole(unitTag)
	if role == 0 then
		local alliance = GetUnitAlliance(unitTag)
		ulti:SetTexture(alliances[alliance])
	else
		ulti:SetTexture(roles[role])
	end


	frame.health = baseFrame['healthBar']['barControls'][1]
	frame.backdrop = baseFrame.frame:GetNamedChild("BG")
	frame.status = baseFrame.frame:GetNamedChild("Status")
	frame.unitTag = unitTag
	frame.unit = ""

	frame.statusLock = false

	frame:Update()

	return frame
	
end


function vanillaFrame:Update()
	-- Unit Changed
	if not self.unit == GetUnitDisplayName(self.unitTag) then
		self.unit = GetUnitDisplayName(self.unitTag)
		local rgb = AD.vars.Group.colours.standardHealth
		self.health:SetColor(rgb[1],rgb[2],rgb[3],rgb[4])
		local role = GetGroupMemberSelectedRole(self.unitTag)
		if role == 0 then
			local alliance = GetUnitAlliance(self.unitTag)
			self.image:SetTexture(alliances[alliance])
		else
			self.image:SetTexture(roles[role])
		end

		self.bar:SetMinMax(0,100)
		self.bar:SetValue(0)
		--self.status:SetText("")
		--self.backdrop:SetEdgeColor(1,1,1,1)
		--self.ultPercent:SetText("")

		--self:setAnchors()
		--self.frame:SetHidden(false)
	end
end
-- backdrop
-- health
-- frame:setHidden
function vanillaFrame:setAnchors() end
function vanillaFrame:setGroupLeader() end
function vanillaFrame:SetOnline(online) end
function vanillaFrame:SetEdgeColor(...)
	self.backdrop:SetEdgeColor(...)
end


function vanillaFrame:setUlt(percent, icon)
	self.bar:SetMinMax(0,100)
	self.bar:SetValue(100-percent)
	self.image:SetTexture(icon)
	if not self.statusLock then
		self.status:SetText(""..percent.."%")
	end
	
	if percent == 100 then
		local rgb = AD.vars.Group.colours.fullUlt
		self.health:SetColor(rgb[1],rgb[2],rgb[3],rgb[4])
	else
		local rgb = AD.vars.Group.colours.standardHealth
		self.health:SetColor(rgb[1],rgb[2],rgb[3],rgb[4])
	end
	
end




function vanillaFrame:SetDead(dead)
	self.status:SetHidden(false)
	if dead then
		self.statusLock = true
		self.status:SetText(GetString(SI_UNIT_FRAME_STATUS_DEAD))
		self.status:SetColor(1,0,0,1)
		EVENT_MANAGER:RegisterForUpdate("AD Res "..self.unitTag, 100, function() self:DeathLoop() end)
	else
		self.statusLock = false
		--self.status:SetText("")
		self.status:SetColor(1,1,1,1)
		EVENT_MANAGER:UnregisterForUpdate("AD Res " .. self.unitTag)
	end
end

function vanillaFrame:DeathLoop()
	local unitTag = self.unitTag
    if not DoesUnitExist(unitTag) then
    	EVENT_MANAGER:UnregisterForUpdate("AD Res " .. self.unitTag)
    	return
    end

    if IsUnitDead(unitTag) then
        if IsUnitBeingResurrected(unitTag) then
            self.status:SetColor(1,1,0,1)
        elseif DoesUnitHaveResurrectPending(unitTag) then
            self.status:SetColor(0,1,0,1)
        else
        	self.status:SetColor(1,0,0,1)
        end
    elseif IsUnitReincarnating(unitTag) then
        self.status:SetColor(0,0,1,1)
    else
    	self.status:SetColor(1,1,1,1)
    	--self.status:SetText("")
    	self.statusLock = false
        EVENT_MANAGER:UnregisterForUpdate("AD Res " .. self.unitTag)
    end
end




--[[
function frameObject:Update(unitTag)
	self.unitTag = unitTag
	self.index = GetGroupIndexByUnitTag(unitTag)

	if self.index then

	else

		local rgb = AD.vars.Group.colours.standardHealth
		self.health:SetColor(rgb[1],rgb[2],rgb[3],rgb[4])
		--self.health:SetColor(0.8,26/255,26/255,0.8)
		self:setName()
		self:setGroupLeader()
		self:SetOnline(IsUnitOnline(unitTag))
		local role = GetGroupMemberSelectedRole(unitTag)
		if role == 0 then
			local alliance = GetUnitAlliance(unitTag)
			self.image:SetTexture(alliances[alliance])
		else
			self.image:SetTexture(roles[role])
		end
		self.backdrop:SetEdgeColor(1,1,1,1)
		self.frame:SetHidden(false)
		self.ultPercent:SetText("")
	end
end










--]]