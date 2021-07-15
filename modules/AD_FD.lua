-- Front Door Module
local AD = ArtaeumGroupTool
AD.FD = {}
local FD = AD.FD


-- Map Pins Module, some of the base code was taken from the sample code in LibMapPins-1.0.lua
--local fd = {}
local LMP = LibMapPins

local fds = {
	{name="Castle Bloodmayne",x=0.57472223043442,y=0.76157778501511},
	{name="Castle Black Boot",x=0.40770667791367,y=0.76615333557129},
	{name="Castle Faregyl",x=0.49927777051926,y=0.67549556493759},
	{name="Castle Alessia",x=0.57074224948883,y=0.557148873806},
	{name="Castle Roebeck",x=0.41256666183472,y=0.56352001428604},
	{name="Castle Brindle",x=0.23523999750614,y=0.56775331497192},
	{name="Fort Ash",x=0.33939111232758,y=0.4275244474411},
	{name="Fort Aleswell",x=0.40584889054298,y=0.28369554877281},
	{name="Fort Dragonclaw",x=0.4911622107029,y=0.11816889047623},
	{name="Fort Glademist",x=0.27427554130554,y=0.28450667858124},
	{name="Fort Rayles",x=0.18475778400898,y=0.3272599875927},
	{name="Fort Warden",x=0.23156222701073,y=0.16500222682953},
	{name="Drakelow Keep",x=0.76734441518784,y=0.58292669057846},
	{name="Chalman Keep",x=0.58080667257309,y=0.28856220841408},
	{name="Blue Road Keep",x=0.65319108963013,y=0.42893776297569},
	{name="Farragut Keep",x=0.8454577922821,y=0.3380266726017},
	{name="Kingscrest Keep",x=0.72241109609604,y=0.19056667387486},
	{name="Arrius Keep",x=0.70240890979767,y=0.31248000264168},

}








local function setRally(pin)
	local _, pinTag = pin:GetPinTypeAndTag()
	local x = pinTag.x
	local y = pinTag.y
	LibMapPing:SetMapPing(MAP_PIN_TYPE_RALLY_POINT,MAP_TYPE_LOCATION_CENTERED,x,y)
end


local RightClickMenu = {
	{
		name = "Set Rally to Front Door",
		callback = setRally,
		show = function(pin) return AD.vars.FD.rightClickMenu end,
	}
}


local pinLayoutData  = {
   level = 5,
   texture = "esoui/art/icons/mapkey/mapkey_ava_milegate_passable.dds",
   size = 10,
}

--tooltip creator
local pinTooltipCreator = {
	creator = function(pin)
		local _, pinTag = pin:GetPinTypeAndTag()
		InformationTooltip:AddLine(pinTag.name.." Front Door")
	end,
	tooltip = ZO_MAP_TOOLTIP_MODE.INFORMATION,
}

--[[

function ADGroupTool.disableDoors()
	LibMapPins:Disable("Front Doors")
end
EVENT_MANAGER:RegisterForEvent("Cyro Transis Active FD", EVENT_START_FAST_TRAVEL_KEEP_INTERACTION, ADGroupTool.disableDoors)


function ADGroupTool.enableDoors()
	LibMapPins:Enable("Front Doors")
end
EVENT_MANAGER:RegisterForEvent("Cyro Transis Deactive FD", EVENT_END_FAST_TRAVEL_KEEP_INTERACTION, ADGroupTool.enableDoors)

--]]

local function createDoors()
	for _, pinInfo in ipairs(fds) do
		LMP:CreatePin("Front Doors", pinInfo, pinInfo.x, pinInfo.y)
	end
end


local function fdcallback()
	if not LMP:IsEnabled("Front Doors") then return end
	local zone, subzone = LMP:GetZoneAndSubzone()
	if not (zone == "cyrodiil") then return end
	if not (subzone == "ava_whole") then return end
	--d("IN CYRO!")
	createDoors()
end













function FD.getCoords(Name)
	local channel = CHAT_CHANNEL_PARTY
	local target = nil
	local x, y, map = GetMapPlayerPosition('player')
	local message = "{name=\""..Name.."\",x="..x..",y="..y.."},"
	CHAT_SYSTEM:StartTextEntry(message, channel, target)
end



function FD.init()
	LibMapPins:AddPinType("Front Doors", fdcallback, nil, pinLayoutData, pinTooltipCreator)
	LibMapPins:AddPinFilter("Front Doors")
	LibMapPins:SetClickHandlers("Front Doors", nil, RightClickMenu)
end

SLASH_COMMANDS["/getcoords"] = FD.getCoords

--LMP:AddPinFilter(FDPinType)
