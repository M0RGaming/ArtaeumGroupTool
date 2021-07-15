-- Stay on Crown Module
local AD = ArtaeumGroupTool
AD.SOC = {}
local SOC = AD.SOC
local vars = {}


function SOC.init()
	vars = AD.vars.SOC
end

SOC.groupList = {}
SOC.toggle = false

-- The range of a forward camp is 25500 units

function SOC.setTimer(minutes) -- set the kick timer
	if not minutes then
		d("Please provide a valid amount of time (in minutes)")
	else
		local offCrownTimerMin = tonumber(minutes)
		vars.offCrownTimer = 60*offCrownTimerMin
		d("Pugs will be kicked after "..minutes.." minutes of not being on crown")
	end
end

function SOC.startTimer() -- Toggle to enable/disable the stay on crown module
	if SOC.toggle then
		EVENT_MANAGER:UnregisterForUpdate("AD Group Tool SOC")
		EVENT_MANAGER:UnregisterForEvent("AD Group Tool SOC DC", EVENT_GROUP_MEMBER_LEFT)
		d("|cFFD700AD Group Tool|r: [Stay On Crown] module |cFF0000deactivated|r.")
		SOC.toggle = false
		SOC.groupList = {}
	else
		EVENT_MANAGER:RegisterForUpdate("AD Group Tool SOC", 1000, SOC.groupTimer) --Run groupTimer
		EVENT_MANAGER:RegisterForEvent("AD Group Tool SOC DC", EVENT_GROUP_MEMBER_LEFT, SOC.leaveGroup)
		d("|cFFD700AD Group Tool|r: [Stay On Crown] module |c00FF00activated|r.")
		SOC.toggle = true
	end
end



-------------------------------------------
--                                       --
--               Main Loop               --
--                                       --
-------------------------------------------

function SOC.groupTimer()

	local crown = GetGroupLeaderUnitTag()
	local crownWorld,crownX,crownY,crownZ = GetUnitWorldPosition(crown) -- Get group leader's position


	for i = 1,GetGroupSize() do -- For each group member
		local unit = GetGroupUnitTagByIndex(i)
		local displayName = GetUnitDisplayName(unit)

		-- Calculate distance between crown and group member
		local unitWorld,unitX,unitY,unitZ = GetUnitWorldPosition(unit)
		local distance = math.sqrt( (crownX-unitX)^2 + (crownZ-unitZ)^2 )

		

		if distance > vars.radius then
			-- If the distance is greater than the specified maximum, add them to the list

			if SOC.groupList[displayName] == nil then
				SOC.groupList[displayName] = 0 -- if they arn't in the list already, add them
			else
				-- If they are already in the list, raise their time off crown by 1 second
				SOC.groupList[displayName] = SOC.groupList[displayName] + 1

				-- If they are past the specified max time off crown, then kick them (or notify user)
				if SOC.groupList[displayName] > vars.offCrownTimer then
					SOC.groupList[displayName] = nil


					if GetGuildMemberIndexFromDisplayName(vars.whitelistGuild, displayName) == nil then 

						if IsUnitGroupLeader('player') then
							GroupKick(unit)
							d("Kicked user "..displayName.." for not being on crown.")
							break
						else
							d("User "..displayName.." should be kicked for not being on crown.")
							break
						end

					else
						d("Guild Member "..displayName.." has not on crown for more than ".. vars.offCrownTimer/60 .." minutes.")
					end
					
				end

			end
		else
			SOC.groupList[displayName] = nil
		end
	end

end

-- Remove someone from the group list when they leave the group
function SOC.leaveGroup(eventCode, characterName, reason, isLocalPlayer, isLeader, displayName, actionRequiredVote)
	--d("User "..displayName.." has left the group")
	if SOC.groupList[displayName] ~= nil then
		SOC.groupList[displayName] = nil
	end
end


-- Register slash commands and keybinds
ZO_CreateStringId("SI_BINDING_NAME_ARTAEUMGROUPTOOL_TOGGLE_SOC", "Toggle [Stay On Crown] Module")
SLASH_COMMANDS["/stayoncrown"] = SOC.startTimer
SLASH_COMMANDS["/adtimerset"] = SOC.setTimer