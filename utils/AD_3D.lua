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

	beam:Create3DRenderSpace()
	beam:SetDrawLevel(1) --3
	beam:Set3DRenderSpaceOrigin(0, 0, 0)
	beam:updateMarkerData(data)
	beam:SetHidden(true)

	


	function beam:setPos(X,Y,Z)
		if not self.enabled then return end

		if self.facePlayer then
			local heading = GetPlayerCameraHeading()
			if heading > math.pi then 
				heading = heading - 2 * math.pi
			end
			self:Set3DRenderSpaceOrientation(0, heading, 0)
		end
		self:Set3DRenderSpaceOrigin(X+self.offset.X, Y+self.offset.Y, Z+self.offset.Z)
	end

	function beam:setColour(r,g,b,a)
		self:SetColor(r,g,b,a)
	end



	function beam:show()
		if self.enabled then
			self:SetHidden(false)
		end
	end
	function beam:hide()
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
	end

	function beam:setScale(scale)
		self.scale = scale
		self:updateSize()
	end

	

	return beam
end
