local AD = ArtaeumGroupTool
AD.Frame = ZO_Object:Subclass()
local frameObject = AD.Frame

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

	

	--TODO: Replace this entire thing with transform scale next patch
	frame.anchors = {}
	local toIterate = {"frame","bar","ultPercent","name","health","backdrop","groupLead"}
	for i=1,#toIterate do
		frame.anchors[toIterate[i]] = {frame[toIterate[i]]:GetAnchor()}
	end

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

function frameObject:setGroupLeader()
	if IsUnitGroupLeader(self.unitTag) then
		self.name:SetTransformOffsetX(20*AD.vars.Group.scale)
		self.name:SetWidth(143)
		self.groupLead:SetHidden(false)
	else
		self.name:SetTransformOffsetX(0)
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









function group.setupBox(unitTag)
	local frame = UNIT_FRAMES:GetFrame(unitTag).frame
	local width = frame:GetWidth()
	frame:SetWidth(width+40)


	local ult = CreateControl("ART"..unitTag.."Ult",frame,CT_STATUSBAR)
	ult:SetDimensions(40,40)
	ult:SetMinMax(0,20)
	ult:SetValue(0)
	ult:SetColor(0)
	ult:SetAlpha(0.8)
	ult:SetOrientation(0)
	ult:SetBarAlignment(1)
	ult:SetAnchor(8,nil,8,-4,0,0)
	ult:SetDrawLevel(6)


	local ulti = CreateControl("ART"..unitTag.."UltImage",frame,CT_TEXTURE)
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
	frameDB[unitTag] = {['frame']=frame,['bar']=ult,['image']=ulti}
	
end
--]]