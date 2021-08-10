local AD = ArtaeumGroupTool
AD.Frame = ZO_Object:Subclass()
local frameObject = AD.Frame

local amountCreated = 0

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

function frameObject:new(unitTag, topLevel)
	local frame = ZO_Object.New(self)
	frame.frame = CreateControlFromVirtual("ART"..unitTag,topLevel,"AD_Group_Template")
	frame.bar = frame.frame:GetNamedChild("Ult")
	frame.image = frame.frame:GetNamedChild("UltIcon")
	frame.ultPercent = frame.frame:GetNamedChild("UltPercent")
	frame.name = frame.frame:GetNamedChild("Name")
	frame.health = frame.frame:GetNamedChild("Health")
	frame.backdrop = frame.frame:GetNamedChild("BG")
	frame.groupLead = frame.frame:GetNamedChild("Icon")
	frame.unitTag = ''
	frame.index = unitTag

	local _,topl,parentframe,top,x,y,z = frame.frame:GetAnchor()
	frame.frame:ClearAnchors()
	frame.frame:SetAnchor(topl, parentframe, top, x, y+40 * (amountCreated%(12/AD.vars.Group.amountOfWindows)))
	amountCreated = amountCreated + 1

	--TODO: Replace this entire thing with transform scale next patch
	frame.anchors = {}
	local toIterate = {"frame","bar","ultPercent","name","health","backdrop","groupLead"}
	for i=1,#toIterate do
		frame.anchors[toIterate[i]] = {frame[toIterate[i]]:GetAnchor()}
	end

	return frame
end

function frameObject:setName()
	self.name:SetText(GetUnitDisplayName(self.unitTag))
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
		EVENT_MANAGER:RegisterForUpdate("AD Res "..self.index, 100, function() self:DeathLoop() end)
	else
		self.name:SetColor(1,1,1,1)
		self:SetHealth(current,max)
		EVENT_MANAGER:UnregisterForUpdate("AD Res " .. self.index)
	end
end

function frameObject:DeathLoop()
	local unitTag = self.unitTag
    if not DoesUnitExist(unitTag) then return end

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
        EVENT_MANAGER:UnregisterForUpdate("AD Res " .. self.index)
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

		local alliance = GetUnitAlliance(unitTag)
		self.image:SetTexture(alliances[alliance])
		self.image:SetColor(1,1,1,0.5)
	end
end




function frameObject:Update(unitTag)
	self.unitTag = unitTag
	self.health:SetColor(0.8,26/255,26/255,0.8)
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
	self.frame:SetHidden(false)
	self.ultPercent:SetText("")
end