-- Guild Note Data Sharing Module
local AD = ArtaeumGroupTool
AD.Crown = {}
local crown = AD.Crown
local vars = {}


local toplevel = nil


function crown.init()
	vars = AD.vars.Crown
	toplevel = AD.AD3D.toplevel
	crown.createArrow()
	crown.updateToggle(vars.enabled)
	crown.toggleMarker(vars.showMarker)
	crown.toggleCyroOnly()
end

crown.updateInterval = 10
crown.crown = nil
crown.running = false


crown.markerTypes = {
	Beam = {
		texture = "ArtaeumGroupTool/Textures/pillar.dds",
		scaleX = 1,
    	scaleY = 100,
    	X = 0,
    	Y = 50,
    	Z = 0,
    	depthBuffer = true
	},
	Crown = {
		texture = "ArtaeumGroupTool/Textures/Crown.dds",
		scaleX = 3,
		scaleY = 3,
		X = 0,
		Y = 4,
		Z = 0,
		depthBuffer = false
	},
	Arrow = {
		texture = "ArtaeumGroupTool/Textures/Arrow.dds",
		scaleX = 3,
		scaleY = 3,
		X = 0,
		Y = 4,
		Z = 0,
		depthBuffer = false
	}
}



function crown.createArrow()
	crown.pin = AD.AD3D.create3D(toplevel, crown.markerTypes[vars.markerType])
	crown.pin:setUserOffset(vars.userOffset)
	crown.pin:setScale(vars.scale)
	crown.updateColours()
end

function crown.updateColours()
	local rgb = vars.markerColour
	crown.pin:setColour(rgb[1],rgb[2],rgb[3],rgb[4])
end


-- Main toggle that turns this module on and off
function crown.updateToggle(enable)

	local pvpCheck = true
	if vars.cyrodilOnly then
		pvpCheck = IsInAvAZone()
	end

	if IsActiveWorldBattleground() then
		pvpCheck = false
	end


	if enable and pvpCheck then
		EVENT_MANAGER:RegisterForEvent("AD Group Tool Crown Join", EVENT_GROUP_MEMBER_JOINED, crown.groupJoin)
		EVENT_MANAGER:RegisterForEvent("AD Group Tool Crown Leave", EVENT_GROUP_MEMBER_LEFT, crown.groupLeave)
		EVENT_MANAGER:RegisterForEvent("AD Group Tool Crown Change", EVENT_LEADER_UPDATE, crown.groupLeadChange)
		EVENT_MANAGER:RegisterForEvent("AD Group Tool Crown Group Update", EVENT_GROUP_UPDATE, crown.groupUpdate)
		if IsUnitGrouped("player") then -- If the user is already in a group when module is toggled,
			crown.groupJoin(nil, nil, nil, true) -- run the group join event
		end
	else
		EVENT_MANAGER:UnregisterForEvent("AD Group Tool Crown Join")
		EVENT_MANAGER:UnregisterForEvent("AD Group Tool Crown Leave")
		EVENT_MANAGER:UnregisterForEvent("AD Group Tool Crown Change")
		EVENT_MANAGER:UnregisterForEvent("AD Group Tool Crown Group Update")
		EVENT_MANAGER:UnregisterForUpdate("AD Group Tool Crown Update")
		crown.pin:hide()
	end
end








-- Events that consider all possible group join/leave events and adapt the marker respectivly.
-- Goal is to only run the marker update loop when the player is in a group and is not the leader.
function crown.groupJoin(eventCode, _, _, isLocalPlayer)
	if not isLocalPlayer then
		return
	end
	if not IsUnitGroupLeader("player") then
		crown.crown = GetGroupLeaderUnitTag()
		crown.pin:show()
		EVENT_MANAGER:RegisterForUpdate("AD Group Tool Crown Update", crown.updateInterval, crown.updateMarker)
		crown.running = true
	end
end

function crown.groupLeave(eventCode, _, _, isLocalPlayer, _, _)
	if not isLocalPlayer then
		return
	end
	--if not IsUnitGrouped("player") then
	EVENT_MANAGER:UnregisterForUpdate("AD Group Tool Crown Update")
	crown.crown = nil
	crown.running = false
	crown.pin:hide()
	--end
end

function crown.groupLeadChange(eventCode, leaderTag)
	if IsUnitGroupLeader('player') then
		EVENT_MANAGER:UnregisterForUpdate("AD Group Tool Crown Update")
		crown.running = false
		crown.pin:hide()
	else
		crown.crown = leaderTag
		if not crown.running then
			crown.pin:show()
			EVENT_MANAGER:RegisterForUpdate("AD Group Tool Crown Update", crown.updateInterval, crown.updateMarker)
			crown.running = true
		end
	end

end

function crown.groupUpdate(eventCode)
	crown.groupLeadChange(nil, GetGroupLeaderUnitTag())
end







function crown.updateMarker()
	if vars.showMarker then
		local _,Xw,Yw,Zw = GetUnitWorldPosition(crown.crown)
		local X,Y,Z = WorldPositionToGuiRender3DPosition(Xw,Yw,Zw)
		crown.pin:setPos(X,Y,Z)
	end
end

function crown.toggleMarker(value)
	vars.showMarker = value
	if value then
		crown.pin:enable()
		if crown.running then crown.pin:SetHidden(false) end
	else
		crown.pin:disable()
	end
end


function crown.toggleCyroOnly()
	local value = vars.cyrodilOnly
	if value then
		EVENT_MANAGER:UnregisterForEvent("AD Group Tool Crown Change Zone")
	else
		EVENT_MANAGER:RegisterForEvent("AD Group Tool Crown Change Zone", EVENT_ZONE_CHANGED, crown.changeZoneEvent)
	end
end

function crown.changeZoneEvent(eventCode, zoneName, subZoneName, newSubzone, zoneId, subZoneId)
	crown.updateToggle(vars.enabled)
end








-- TESTING
function crown.quickTest()
	crown.crown = 'player'
	crown.groupJoin(nil,nil,nil,true)
	crown.crown = 'player'
end
function crown.stopTest()
	crown.groupLeave(nil,nil,nil,true)
end



--[[

function crown.setcrownpos()
	--local _,X,Y,Z = WorldPositionToGuiRender3DPosition(GetUnitWorldPosition(GetGroupLeaderUnitTag()))
	local _,Xw,Yw,Zw = GetUnitWorldPosition('player')
	local X,Y,Z = WorldPositionToGuiRender3DPosition(Xw,Yw,Zw)
	crown.toplevel.beam:setPos(X,Y+5,Z)
end
SLASH_COMMANDS["/beamcrown"] = crown.setcrownpos

]]--