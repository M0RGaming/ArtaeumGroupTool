-- Group Ult Sharing Module
local AD = ArtaeumGroupTool
AD.Group = {}
local group = AD.Group
local vars = {}

local frameDB = {}


function group.init()
	--vars = AD.vars.Guild
	--guild.createArrow()
	group.moveBoxes()

	--[[
	if IsUnitGrouped('player') then
		zo_callLater(group.updateBoxes,500)
	end
	EVENT_MANAGER:RegisterForEvent("AD Group Tool Group Join", EVENT_GROUP_MEMBER_JOINED, group.groupJoin)
	]]--


	SecurePostHook(UNIT_FRAMES, "CreateFrame", function(_, unitTag, anchors, barTextMode, style)
		if style == "ZO_GroupUnitFrame" then --ZO_GroupUnitFrame --ZO_RaidUnitFrame
			if frameDB[unitTag] == nil then
				group.setupBox(unitTag)
			end
		end
	end)
end



function group.setUlt(unitTag, percent)

	if frameDB[unitTag] == nil then
		return
	end

	frameDB[unitTag]['bar']:SetMinMax(0,1)
	frameDB[unitTag]['bar']:SetValue(1-percent)

end


--[[
function group.groupJoin(eventCode, _, name, isLocalPlayer)
	if GetGroupSize() < 5 then
		return
	end
	if isLocalPlayer then
		zo_callLater(group.updateBoxes,500)
		return
	end
	for i=1,GetGroupSize() do
		if GetUnitDisplayName('group'..i) == name then
			if frameDB[i] == nil then
				group.setupBox(i)
			end
			return
		end
	end
end

function group.updateBoxes()
	if GetGroupSize() < 5 then
		return
	end
	for i=1,GetGroupSize() do
		if frameDB[i] == nil then
			group.setupBox(i)
		end
	end
end
]]--



function group.setupBox(unitTag)
	local frame = UNIT_FRAMES:GetFrame(unitTag).frame
	local width = frame:GetWidth()
	frame:SetWidth(width+45)


	local ult = CreateControl("ART"..unitTag.."Ult",frame,CT_STATUSBAR)
	ult:SetDimensions(45,40)
	ult:SetMinMax(0,20)
	ult:SetValue(0)
	ult:SetColor(0)
	ult:SetAlpha(0.8)
	ult:SetOrientation(0)
	ult:SetBarAlignment(1)
	ult:SetAnchor(8,nil,8,-4,0,0)
	ult:SetDrawLevel(6)


	local ulti = CreateControl("ART"..unitTag.."UltImage",frame,CT_TEXTURE)
	ulti:SetDimensions(45,40)
	ulti:SetDrawLevel(5)
	ulti:SetAnchor(8,nil,8,-4,0,0)
	ulti:SetTexture("esoui/art/stats/alliancebadge_aldmeri.dds")
	frameDB[unitTag] = {['frame']=frame,['bar']=ult,['image']=ulti}
	
end




function group.moveBoxes()

	local _,topl,frame,top,x,y,z = ZO_LargeGroupAnchorFrame2:GetAnchor()
	ZO_LargeGroupAnchorFrame2:SetAnchor(topl,frame,top,x+45,y,z)
	local _,topl,frame,top,x,y,z = ZO_LargeGroupAnchorFrame3:GetAnchor()
	ZO_LargeGroupAnchorFrame3:SetAnchor(topl,frame,top,x+90,y,z)

end


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