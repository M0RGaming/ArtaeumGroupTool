local AD = ArtaeumGroupTool
AD.AD3D = {}
local AD3D = AD.AD3D

AD3D.toplevel = WINDOW_MANAGER:CreateTopLevelWindow("ArtaeumTopLevel")
AD3D.toplevel:SetDrawLayer(0)



function AD3D.create3D(toplevel, data)
	local beam = WINDOW_MANAGER:CreateControl(nil, toplevel, CT_TEXTURE)

	function beam:updateSize()
		self:Set3DLocalDimensions(self.size.X * self.scale, self.size.Y * self.scale)
	end

	function beam:updateMarkerData(data)
		self.offset = {
			X=data.X or 0,
			Y=data.Y or 0,
			Z=data.Z or 0
		}
		self.size = {
			X=data.scaleX or 1,
			Y=data.scaleY or 1
		}
		self.texture = data.texture or ""

		if data.depthBuffer == nil then self.depthBuffer = true else self.depthBuffer = data.depthBuffer end
		if data.facePlayer == nil then self.facePlayer = true else self.facePlayer = data.facePlayer end

		self:Set3DRenderSpaceUsesDepthBuffer(self.depthBuffer)
		self:SetTexture(self.texture)
		--self:Set3DLocalDimensions(self.size.X, self.size.Y)
		self:updateSize()
	end
	
	beam.scale = 1

	beam.userOffset = 0

	beam:Create3DRenderSpace()
	beam:SetDrawLevel(1) --3
	beam:Set3DRenderSpaceOrigin(0, 0, 0)
	beam:updateMarkerData(data)
	beam:SetHidden(true)

	


	function beam:setPos(X,Y,Z)
		if not self.enabled then return end

		self:turnToFace()
		self:Set3DRenderSpaceOrigin(X+self.offset.X, Y+self.offset.Y+self.userOffset, Z+self.offset.Z)
	end

	function beam:turnToFace()
		if not self.enabled then return end

		if self.facePlayer then
			local heading = GetPlayerCameraHeading()
			if heading > math.pi then 
				heading = heading - 2 * math.pi
			end
			self:Set3DRenderSpaceOrientation(0, heading, 0)
		end
	end


	function beam:setColour(r,g,b,a)
		self:SetColor(r,g,b,a)
	end

	function beam:setUserOffset(offset)
		self.userOffset = offset
	end


	function beam:show()
		if self.enabled then
			self:SetTexture(self.texture)
			self:SetHidden(false)
		end
	end
	function beam:hide()
		self:SetTexture("")
		if self.enabled then
			self:SetHidden(true)
		end
	end

	function beam:enable()
		self.enabled = true
	end
	function beam:disable()
		self.enabled = false
		self:SetHidden(true)
		self:SetTexture("")
	end

	function beam:setScale(scale)
		self.scale = scale
		self:updateSize()
	end

	

	return beam
end




local iterator = 0
function AD3D.createArrow()
	local arrow = WINDOW_MANAGER:CreateControlFromVirtual("ADArrow"..tostring(iterator), AD3D.toplevel, "ADArrowTemplate")

	arrow.container = arrow:GetNamedChild("Div")
	arrow.chevron = arrow.container:GetNamedChild("Chevron")
	arrow.textDiv = arrow.container:GetNamedChild("Div")
	arrow.text = arrow.textDiv:GetNamedChild("Text")

	arrow:SetAnchor(CENTER,GuiRoot,CENTER)
	arrow:SetTransformNormalizedOriginPoint(0.5,0.5)
	arrow:SetScale(1/100)

	arrow:SetTransformRotation(-math.pi/2)

	arrow.container:SetTransformOffset(0,-1,0)

	arrow.textDiv:SetTransformRotation(math.pi/2) -- text Div should always be the anti angle of the main control
	--local cp, cy, cr = arrow:GetTransformRotation()
	--arrow.textDiv:SetTransformRotation(-cp,-cy,-cr)


	arrow.verticalOffset = 50+iterator*10
	arrow.enabled = false

	arrow.chevron:SetTransformOffset(0,0,-0.25)

	arrow:SetHidden(true)

	--[[
	local sx, sy, sz = GuiRender3DPositionToWorldPosition(0,0,0)
	local _, vx,vy,vz = GetUnitRawWorldPosition('player')
	local x = (vx - sx)/100
	local y = (vy+arrow.verticalOffset)/100
	local z = (vz - sz)/100
	arrow:SetTransformOffset(x,y,z)
	--]]

	function arrow:SetTarget(x, y, z)
		self.targetX = x
		self.targetY = y
		self.targetZ = z

		if (x == 0) and (y == 0) and (z == 0) then
			self.enabled = false
			self:SetHidden(true)
		else
			self.enabled = true
			self:SetHidden(false)
		end
	end

	function arrow:UpdateRotation()
		--local yaw = math.pi/8*math.random(16)
		local yaw = math.atan2(self.targetX - self.x, self.targetZ-self.z)
		self.yaw = yaw
		self:SetTransformRotation(-math.pi/2, yaw, 0)
		self.textDiv:SetTransformRotation(math.pi/2, 0, -yaw)
	end
	function arrow:UpdateText(distance)
		local fX, fY, fZ = GetCameraForward(SPACE_WORLD)
		local yaw = zo_atan2(fX, fZ) - math.pi
		local pitch = zo_atan2(fY, zo_sqrt(fX * fX + fZ * fZ))
		self.text:SetTransformRotation(pitch,yaw,0)

		
		self.text:SetText(string.format("%dm",distance/100))
	end

	function arrow:UpdateLocation(sx, sy, sz)
		if self.enabled == false then return end

		if sx == nil then
			sx, sy, sz = GuiRender3DPositionToWorldPosition(0,0,0)
		end

		_, self.x, self.y, self.z = GetUnitRawWorldPosition('player')
		local x = (self.x - sx)/100
		local y = (self.y+self.verticalOffset)/100
		local z = (self.z - sz)/100

		local distance = zo_distance3D(self.x, self.y, self.z, self.targetX, self.targetY, self.targetZ)

		self:SetTransformOffset(x,y,z)
		self:UpdateRotation()
		self:UpdateText(distance)


		local opacity = zo_clamp(distance/700-3/7,0,1)
		self:SetAlpha(opacity)
		local size = zo_clamp(distance/4000+0.5, 0, 1)
		self.chevron:SetTransformScale(size)

	end

	function arrow:SetColour(r,g,b)
		self.chevron:SetColor(r,g,b)
	end


	arrow.registered = false
	function arrow:StartUpdating()
		if not registered then
			EVENT_MANAGER:RegisterForUpdate("ADArrow"..tostring(iterator), 0, function() self:UpdateLocation() end)
			self.registered = true
		end
	end

	function arrow:StopUpdating()
		EVENT_MANAGER:UnregisterForUpdate("ADArrow"..tostring(iterator))
		self.registered = false
		self:SetTarget(0,0,0)
	end


	iterator = iterator + 1

	return arrow
end

SLASH_COMMANDS['/adtest'] = function()
	a = AD3D.createArrow()
	local _, vx, vy, vz = GetUnitRawWorldPosition("player")
	a:SetTarget(vx, vy, vz)
	a:SetColour(0, 1, 1)
	a:StartUpdating()
end