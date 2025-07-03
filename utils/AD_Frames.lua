local AD = ArtaeumGroupTool
AD.Frame = {}
local frames = AD.Frame
--local frameObject = ZO_Object:Subclass()
--local vanillaFrame = ZO_Object:Subclass()

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
local parents = {}
function AD.initAnchors(topLevels)
	local amountCreated = 0
	for i=1,12 do
		local topLevelID = math.floor((i-1)*AD.vars.Group.amountOfWindows/12)+1
		local anchor = ZO_Anchor:New(TOPLEFT, topLevels[topLevelID], TOPLEFT, 0, 40 * (amountCreated%(12/AD.vars.Group.amountOfWindows)))
		anchors[i] = anchor
		parents[i] = topLevels[topLevelID]
		amountCreated = amountCreated + 1
	end
end







local frameBase = ZO_Object:Subclass()


function frameBase:Update()
	-- To be overwritten, runs whenever the group changes to identify new unitTags
end
function frameBase:setGroupLeader()
	-- (optional) runs for everyone when crown changes
end
function frameBase:SetOnline(online)
	-- (optional) runs when someone changes online/offline states
end
function frameBase:SetEdgeColor(...)
	-- To be overwritten, indicates Camplocked
end
function frameBase:setUlt(value, cost1, icon1, cost2, icon2)
	-- To be overwritten, runs every time a data point comes in, sets the ult and percent
end
function frameBase:SetDead(dead)
	-- (optional) runs when someone dies
end
function frameBase:SetMag(value, max)
	-- (optional) tells what the current mag/stam is
end
function frameBase:SetStam(value, max)
	-- (optional) tells what the current mag/stam is
end
function frameBase:SetInGroupRange(value)
	-- (optional) tells when someone is out of range
end
function frameBase:SetRole(value)
	-- (optional) sets the role icon of the unit
end


frames.frameBase = frameBase





local classIcons = {
	"esoui/art/icons/class/gamepad/gp_class_dragonknight.dds",
	"esoui/art/icons/class/gamepad/gp_class_sorcerer.dds",
	"esoui/art/icons/class/gamepad/gp_class_nightblade.dds",
	"esoui/art/icons/class/gamepad/gp_class_warden.dds",
	"esoui/art/icons/class/gamepad/gp_class_necromancer.dds",
	"esoui/art/icons/class/gamepad/gp_class_templar.dds"
}

classIcons[117] = "esoui/art/icons/class/gamepad/gp_class_arcanist.dds"
classIcons[0] = "/esoui/art/icons/heraldrycrests_misc_blank_01.dds"





local frameObject = frameBase:Subclass()

function frameObject:new(unitTag, parent)
	local frame = frameBase.New(self)
	frame.frame = CreateControlFromVirtual("ART"..unitTag,parent,"AD_Group_Template")
	frame.bar = frame.frame:GetNamedChild("Ult")
	frame.bar2 = frame.frame:GetNamedChild("Ult2")
	frame.image = frame.frame:GetNamedChild("UltIcon")
	frame.image2 = frame.frame:GetNamedChild("Ult2Icon")
	frame.ultPercent = frame.frame:GetNamedChild("UltPercent")
	frame.name = frame.frame:GetNamedChild("Name")
	frame.health = frame.frame:GetNamedChild("Health")
	frame.backdrop = frame.frame:GetNamedChild("BG")
	frame.groupLead = frame.frame:GetNamedChild("Icon")
	frame.stam = frame.frame:GetNamedChild("Stam")
	frame.mag = frame.frame:GetNamedChild("Mag")


	frame.unitTag = unitTag
	frame.index = nil
	frame.unit = ""
	frame.displayName = ""
	frame.originalHealthHeight = frame.health:GetHeight()
	frame.magStamHidden = true

	frame.hasUlt = false


	frame.health.barControls = {frame.health}
	frame.visualizer = ZO_UnitAttributeVisualizer:New(unitTag, nil, frame.health)
	local rgb = AD.vars.Group.colours.standardHealth
	local grad = ZO_ColorDef:New(unpack(rgb))

	local VISUALIZER_POWER_SHIELD_LAYOUT_DATA =
	{
		barLeftOverlayTemplate = "AD_Group_ShieldBarTemplate",
		fakeHealthGradientOverride = {grad,grad},
		--noHealingGradientOverride = { ZO_ColorDef:New(0,0,0,1), ZO_ColorDef:New(0,0,0,1) },
	}

	frame.shieldVis = ZO_UnitVisualizer_PowerShieldModule:New(VISUALIZER_POWER_SHIELD_LAYOUT_DATA)
	frame.visualizer:AddModule(frame.shieldVis)

	frame.shieldVis:InitializeBarValues()


	-- THIS IS WEIRD, TODO: REPLACE LATER

	---aaaa = frame
	--frame.health.barControls = {}
	--a = frame
	--aa = ZO_ShallowTableCopy(frame.shieldVis)
	--aaa = ZO_ShallowTableCopy(frame.shieldVis.attributeInfo)
	--aaaa = ZO_ShallowTableCopy(frame.shieldVis.attributeBarControls)
	frame.shieldVis:ShowOverlay(frame.shieldVis.attributeBarControls[ATTRIBUTE_HEALTH], frame.shieldVis.attributeInfo[ATTRIBUTE_HEALTH])

	frame.healthEffects = {}
	frame:GetHealthEffects()

	frame.frame:SetHidden(true)


	return frame
end


function frameObject:GetHealthEffects() -- might replace these conditionals with a func to get/check (or just always reassign)
	if self.healthEffects.shield == nil then
		self.healthEffects.shield = self.health:GetNamedChild("PowerShieldLeftOverlay")
	end
	if self.healthEffects.shield ~= nil then
		if self.healthEffects.trauma == nil then
			self.healthEffects.trauma = self.healthEffects.shield:GetNamedChild("Trauma")
		end
		if self.healthEffects.fakeHealth == nil then
			self.healthEffects.fakeHealth = self.healthEffects.shield:GetNamedChild("FakeHealth")
		end
		if self.healthEffects.noHealingInner == nil then
			self.healthEffects.noHealingInner = self.healthEffects.shield:GetNamedChild("NoHealingInner")
		end
		if self.healthEffects.fakeNoHealingInner == nil then
			self.healthEffects.fakeNoHealingInner = self.healthEffects.shield:GetNamedChild("FakeNoHealingInner")
		end
	end
	return self.healthEffects
end




function frameObject:Update(hasUlt)
	self.index = GetGroupIndexByUnitTag(self.unitTag)
	--self.index = tonumber(self.unitTag:sub(6, 7))
	--d(self.index)
	--d(self.unitTag:sub(5, 5))
	--d(self.unitTag)
	if self.index > 12 then self.index = nil end
	if self.index then

		-- Unit Changed index
		if self.unit == GetUnitName(self.unitTag) then
			self:setAnchors()
			self.frame:SetHidden(false)
			
			self:SetOnline(IsUnitOnline(self.unitTag))

			-- NOTE TO SELF: RUN A FUNCTION THAT SETS TEXTURES IF ULT IS WRONG

		else -- Unit Changed
			self.unit = GetUnitName(self.unitTag)
			self.displayName = GetUnitDisplayName(self.unitTag)
			local rgb = AD.vars.Group.colours.standardHealth
			self.health:SetColor(unpack(rgb))
			--local healthEffects = self:GetHealthEffects()
			if self.healthEffects.fakeHealth ~= nil then
				self.healthEffects.fakeHealth:SetColor(unpack(rgb))
			end

			self.hasUlt = false

			self:SetMag(0,1)
			self:SetStam(0,1)
			self:SetMagStamHidden(true)

			self:setName()
			self:setGroupLeader()
			
			self:SetOnline(IsUnitOnline(self.unitTag))

			self.backdrop:SetEdgeColor(1,1,1,1)
			self.bar:SetValue(0)
			self.bar2:SetValue(0)
			self.ultPercent:SetText("")
			self:setAnchors()
			self.frame:SetHidden(false)
		end

	else -- Unit Doesnt Exist anymore
		self.frame:SetHidden(true)
		self.unit = ""
		self.hasUlt = false
		self.displayName = ""
	end
end



function frameObject:setAnchors()
	if self.index then
		anchors[self.index]:Set(self.frame)
		self.frame:SetParent(parents[self.index]) -- have to set parent too because of scale
	end
end
function frameObject:setName()
	--self.name:SetText(self.unit)
	self.name:SetText(self.displayName)
end

function frameObject:SetEdgeColor(...)
	self.backdrop:SetEdgeColor(...)
end


function frameObject:setGroupLeader()
	local _,topl,parentframe,top,x,y,z = self.name:GetAnchor()
	if IsUnitGroupLeader(self.unitTag) then
		self.name:SetAnchor(topl, parentframe, top, 20, y)
		self.name:SetWidth(143) -- 143 originally
		self.groupLead:SetHidden(false)
	else
		self.name:SetAnchor(topl, parentframe, top, 0, y)
		self.name:SetWidth(163) -- 163 originally
		self.groupLead:SetHidden(true)
	end
end

function frameObject:SetHealth(value,max)
	ZO_StatusBar_SmoothTransition(self.health,value,max)
	if AD.vars.Group.groupFrameText == "Health" then
		self.ultPercent:SetText(ZO_FormatResourceBarCurrentAndMax(value, max))
	end
end

function frameObject:SetMag(value,max)
	ZO_StatusBar_SmoothTransition(self.mag,value,max)
end

function frameObject:SetStam(value,max)
	ZO_StatusBar_SmoothTransition(self.stam,value,max)
end

function frameObject:SetMagStamHidden(value)
	self.mag:SetHidden(value)
	self.stam:SetHidden(value)
	self.magStamHidden = value
	local newHeight = self.originalHealthHeight

	if not value then
		self.health:SetHeight(self.originalHealthHeight-8)
	end
	self.health:SetHeight(newHeight)
	--local healthEffects = self:GetHealthEffects()
	for i,v in pairs(self.healthEffects) do
		v:SetHeight(newHeight)
	end
end

function frameObject:SetDead(dead)
	local current, max = GetUnitPower(self.unitTag, COMBAT_MECHANIC_FLAGS_HEALTH)
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

		if self.health:GetValue() ~= 0 then -- hypotentically fixes the bug where dead people show health bars, prob should find a better way
			local min, max = self.health:GetMinMax()
			self:SetHealth(0,max)
		end

		if IsUnitBeingResurrected(unitTag) then
			self.name:SetColor(1,1,0,1)
		elseif DoesUnitHaveResurrectPending(unitTag) then
			self.name:SetColor(0,1,0,1)
		else
			self.name:SetColor(1,0,0,1)
		end
	else
		local current, max = GetUnitPower(self.unitTag, COMBAT_MECHANIC_FLAGS_HEALTH)
		self.name:SetColor(1,1,1,1)
		self:SetHealth(current,max)
		EVENT_MANAGER:UnregisterForUpdate("AD Res " .. self.unitTag)
	end
end




function frameObject:SetOnline(online)
	local current, max = GetUnitPower(self.unitTag, COMBAT_MECHANIC_FLAGS_HEALTH)
	if online then
		self.name:SetColor(1,1,1,1)
		self:SetHealth(current,max)
		--self.frame:SetAlpha(1)
		self:SetInGroupRange(IsUnitInGroupSupportRange(self.unitTag))
		self.image:SetColor(1,1,1,1)
		self.image2:SetColor(1,1,1,1)
		if not self.hasUlt then
			local role = GetGroupMemberSelectedRole(self.unitTag)
			if role == 0 then
				local alliance = GetUnitAlliance(self.unitTag)
				self.image:SetTexture(alliances[alliance])
			else
				self.image:SetTexture(roles[role])
			end
			local class = GetUnitClassId(self.unitTag)
			self.image2:SetTexture(classIcons[class])
		end
	else
		self.name:SetColor(1,1,1,0.5)
		self.frame:SetAlpha(0.7)
		self:SetHealth(0,max)
		self:SetMag(0,1)
		self:SetStam(0,1)
		self:SetMagStamHidden(true)

		local alliance = GetUnitAlliance(self.unitTag)
		self.image:SetTexture(alliances[alliance])
		self.image:SetColor(1,1,1,0.5)
		self.bar:SetMinMax(0,100)
		self.bar:SetValue(0)

		local class = GetUnitClassId(self.unitTag)
		self.image2:SetTexture(classIcons[class])
		self.image2:SetColor(1,1,1,0.5)
		self.bar2:SetMinMax(0,100)
		self.bar2:SetValue(0)

		self.hasUlt = false
		self.ultPercent:SetText("")
	end
end

function frameObject:SetInGroupRange(nearby)
	if nearby then
		self.frame:SetAlpha(1)
	else
		self.frame:SetAlpha(0.4)
	end
end

function frameObject:SetRole(role)
	if not self.hasUlt then
		if role == 0 then
			local alliance = GetUnitAlliance(self.unitTag)
			self.image:SetTexture(alliances[alliance])
		else
			self.image:SetTexture(roles[role])
		end
		local class = GetUnitClassId(self.unitTag)
		self.image2:SetTexture(classIcons[class])
	end
end

function frameObject:setUlt(ultValue, ult1Cost, icon1, ult2Cost, icon2, noUlt)

	if noUlt then -- libgroupcombatstats sometimes sends ult a couple ms after actual changes so this maybe might fix it
		self.hasUlt = false
		self.bar:SetValue(0)
		self.bar2:SetValue(0)
		if AD.vars.Group.groupFrameText ~= "Health" then
			self.ultPercent:SetText("")
		end
		self:SetOnline(IsUnitOnline(self.unitTag))
		return
	end

	local percent1
	local percent2
	if ult1Cost == 0 then percent1 = 100 else
		percent1 = ultValue / ult1Cost * 100
	end
	if ult2Cost == 0 then percent2 = 100 else
		percent2 = ultValue / ult2Cost * 100
	end

	self.bar:SetMinMax(0,100)
	self.bar:SetValue(100-percent1)
	self.image:SetTexture(icon1)
	self.bar2:SetMinMax(0,100)
	self.bar2:SetValue(100-percent2)
	self.image2:SetTexture(icon2)

	if AD.vars.Group.groupFrameText == "Ult Number" then
		self.ultPercent:SetText(""..ultValue.." ") -- add   to add padding
	elseif AD.vars.Group.groupFrameText == "Ult Percent" then
		if ultValue == 500 then
			self.ultPercent:SetText("|cE0B0FFMaxed |r")
		else
			self.ultPercent:SetText(""..zo_floor(percent1).."/"..zo_floor(percent2).."%")
		end
	end

	local maxedUlt = false
	if (ult1Cost >= ult2Cost) and (percent1 >= 100) then
		maxedUlt = true
	elseif (ult2Cost >= ult1Cost) and (percent2 >= 100) then
		maxedUlt = true
	end


	local rgb = AD.vars.Group.colours.standardHealth
	if maxedUlt then
		rgb = AD.vars.Group.colours.fullUlt
	end
	self.health:SetColor(unpack(rgb))
	--local healthEffects = self:GetHealthEffects()
	if self.healthEffects.fakeHealth ~= nil then
		self.healthEffects.fakeHealth:SetColor(unpack(rgb))
	end
	self.hasUlt = true
end















-- removing vanilla frames since it is a pain to work with and just isnt supported really.
-- for future note to revert, go back and look at artaeum group tool v2









function frames:new(unitTag, parent)
	return frameObject:new(unitTag,parent)
end