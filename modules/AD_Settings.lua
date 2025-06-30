local AD = ArtaeumGroupTool
local settings = AD.Settings

function settings.createSettings()
	
	local GroupFrameTextOptions = { -- Ult Number, Ult Percent, Health
		"Ult Number",
		"Ult Percent",
		"Health"
	}

	local vars = AD.vars

	local panelName = "ArtaeumGroupToolSettingsPanel"
	local panelData = {
		type = "panel",
		name = "|cFFD700Artaeum Group Tool|r",
		author = "|c0DC1CF@M0R_Gaming|r",
		slashCommand = "/ad"
	}


	local selectedWindow = 1

	local optionsTable = {
		
		{
			type = "description",
			title = "|cFFD700[Artaeum Group Tool]|r",
			text = "Hello, and thank you for using Artaeum Group Tool! If you have any errors or complaints, please reach out to me either on discord (@m0r) or at the link below! "..
				"When disabling or enabling the Group Ultiamte Share, you will need to reload your UI to fully enable/disable it.",
			width = "full",
		},
		{
			type = "button",
			name = "Report Bug/Contact Me\n(QR Code)",
			tooltip = "Click this button to be directed to a QR Code which opens the ArtaeumGroupTool forums where you can reach out to me!",
			width = "full",
			func = function() RequestOpenUnsafeURL("https://m0rgaming.github.io/create-qr-code/?url=https://www.esoui.com/downloads/info3012-ArtaeumGroupTool2.0.html#comments") end,
		},
		{
			type = "button",
			name = "Report Bug/Contact Me\n(Direct Link)",
			tooltip = "Click this button to be directed to the ArtaeumGroupTool forums where you can reach out to me!",
			width = "full",
			func = function() RequestOpenUnsafeURL("https://www.esoui.com/downloads/info3012-ArtaeumGroupTool2.0.html#comments") end,
		},
		{
			type = "button",
			name = "Reload UI",
			tooltip = "Click here to reload your UI! (Will result in a load screen)",
			width = "full",
			func = function() ReloadUI() end,
		},
		-- Group ULT share
		{
			type = "submenu",
			name = "|cFFD700[Group Ultimate Share Module]|r",
			controls = {
				{
					type = "description",
					title = "",
					text = 'To edit the visuals of this (colours, etc), please scroll down until you reach the section labelled "Colours"',
					width = "full",
				},
				{
					type = "checkbox",
					name = "Enable Module",
					tooltip = "If this is enabled, your ultimate will be shared with the group.",
					getFunc = function() return vars.Group.enabled end,
					setFunc = function(value) vars.Group.enabled = value end,
					requiresReload = true
				},
				
				{
					type = "checkbox",
					name = "PvP Only",
					tooltip = "If this is enabled, this module will only run in Cyrodiil and Imperial City",
					getFunc = function() return vars.Group.cyrodilOnly end,
					setFunc = function(value) vars.Group.cyrodilOnly = value end,
				},

				{
					type = "checkbox",
					name = "Hide Base Game Healthbars",
					tooltip = "If this is enabled, the default group healthbars will be hidden.",
					getFunc = function() return vars.Group.hideBaseUnitFrames end,
					setFunc = function(value) vars.Group.hideBaseUnitFrames = value; ZO_UnitFramesGroups:SetHidden(value) end,
				},
				{
					type = "checkbox",
					name = "Hide Custom Healthbars",
					tooltip = "If this is enabled, the group healthbars from this addon will be hidden.",
					getFunc = function() return vars.Group.hideUI end,
					setFunc = function(value) vars.Group.hideUI = value; AD.Group.hideUI(value) end,
				},
				{
					type = "checkbox",
					name = "Show Magicka and Stamina Bars",
					tooltip = "If this is enabled, the you will be able to see your group's magicka and stamina bars on the UI.",
					getFunc = function() return vars.Group.showMagStam end,
					setFunc = function(value) vars.Group.showMagStam = value; if not value then AD.Group.hideAllMagStam() end end,
				},

				{
					type = "dropdown",
					name = "UI Mode",
					choices = GroupFrameTextOptions,
					getFunc = function() return vars.Group.groupFrameText end,
					setFunc = function(value) vars.Group.groupFrameText = value end,
				},
				{
			        type = "slider",
			        name = "Window Scale",
			        tooltip = "This sets the size of the window.",
			        min = 0,
			        max = 2,
			        step = 0.1,	--(optional)
			        getFunc = function() return vars.Group.scale end,
			        setFunc = function(scale) vars.Group.scale = scale; AD.Group.scaleWindow() end,
			       	width = "half",
			    },
				{
			        type = "slider",
			        name = "Amount of group windows",
			        tooltip = "This sets the amount of windows to display. If set to 2, it will display 2 windows of 6 people each. You will need to reload UI to apply this change.",
			        min = 1,
			        max = 12,
			        step = 1,	--(optional)
			        getFunc = function() return vars.Group.amountOfWindows end,
			        setFunc = function(amount) vars.Group.amountOfWindows = amount end,
			        requiresReload = true,
			       	width = "half",
			    },
			    {
					type = "button",
					name = "Show Window Outlines",
					tooltip = "Click here to show the red outlines of windows (for moving them around).",
					width = "half",
					func = AD.Group.unlockWindow,
				},
				{
					type = "button",
					name = "Hide Window Outlines",
					tooltip = "Click here to hide the red outlines of windows (for moving them around).",
					width = "half",
					func = AD.Group.lockWindow,
				},
				{
			        type = "slider",
			        name = "Selected Window (for moving)",
			        tooltip = "This selects a window for moving via the below sliders",
			        min = 1,
			        max = vars.Group.amountOfWindows,
			        step = 1,
			        getFunc = function() return selectedWindow end,
			        setFunc = function(number) selectedWindow = number end,
			        requiresReload = true,
			       	width = "half",
			    },
				{
			        type = "slider",
			        name = "Window X Location",
			        tooltip = "This sets the location of the selected window in the horizontal direction, originating from the left.",
			        min = 0,
			        max = GuiRoot:GetWidth(),
			        step = 1,
			        getFunc = function() return vars.Group.windowLocations[selectedWindow][1] end,
			        setFunc = function(x) AD.Group.saveWindowLocationX(selectedWindow, x) end,
			       	width = "half",
			    },

				{
			        type = "slider",
			        name = "Window Y Location",
			        tooltip = "This sets the location of the selected window in the vertical direction, originating from the top.",
			        min = 0,
			        max = GuiRoot:GetHeight(),
			        step = 1,
			        getFunc = function() return vars.Group.windowLocations[selectedWindow][2] end,
			        setFunc = function(y) AD.Group.saveWindowLocationY(selectedWindow, y) end,
			       	width = "half",
			    },

				{
					type = "button",
					name = "Show Windows",
					tooltip = "Click here to show the Windows on this page",
					width = "full",
					func = AD.Group.showWindows,
				},
			}
		},
		-- Crown Arrow Module
		{
			type = "submenu",
			name = "|cFFD700[Crown Arrow Module]|r",
			controls = {
				{
					type = "description",
					title = "",
					text = "This module will only work in non Trial/Dungeon environments until Update 47.",
					width = "full",
				},
				{
					type = "checkbox",
					name = "Enable Module",
					tooltip = "If this is enabled, an arrow will point towards the group leader.",
					getFunc = function() return vars.Crown.enabled end,
					setFunc = function(value) vars.Crown.enabled = value; AD.Crown.updateToggle(value) end
				},
				
				{
					type = "checkbox",
					name = "PvP Only",
					tooltip = "If this is enabled, this module will only run in Cyrodiil and Imperial City",
					getFunc = function() return vars.Crown.cyrodilOnly end,
					setFunc = function(value) vars.Crown.cyrodilOnly = value; AD.Crown.toggleCyroOnly() end
				},
				
				{
					type = "checkbox",
					name = "Show Marker",
					tooltip = "If this is enabled, a crown/beam of light will be placed on the group leader (Beam Requires High Subsampling Quality)",
					getFunc = function() return vars.Crown.showMarker end,
					setFunc = AD.Crown.toggleMarker
				},
				{
					type = "dropdown",
					name = "Marker Type",
					tooltip = "Allows you to choose if you prefer a beam of light or a simple crown icon above the leader.",
					choices = {"Crown", "Beam", "Arrow"},
					getFunc = function() return vars.Crown.markerType end,
					setFunc = function(value)
						vars.Crown.markerType = value
						AD.Crown.pin:updateMarkerData(AD.Crown.markerTypes[value])
					end
				}
			}
		},
		{
			type = "submenu",
			name = "|cff0000C|cff2a00h|cff5500a|cff7f00n|cffbf00g|cffff00e|caaff00 |c55ff00C|c00ff00o|c00ff80l|c00ffffo|c00aaffu|c0055ffr|c0000ffs|r",
			controls = {
				{
					type = "description",
					title = "|cFFD700[Group Share Module]|r",
					text = "The Following will edit the colours from the Group Ult Share Module",
					width = "full",
				},
				{
	                type = "colorpicker",
	                name = "Assist Ping Colour",
	                tooltip = "This sets the colour of the arrow and/or marker of the assist ping.",
	                getFunc = function() local rgb = vars.Group.colours.marker; return rgb[1], rgb[2], rgb[3] end,	--(alpha is optional)
	                setFunc = function(r,g,b) local rgb = vars.Group.colours.marker; rgb[1] = r; rgb[2] = g; rgb[3] = b; AD.Group.updateColours() end,	--(alpha is optional)
	            	width = "half",
	            },
	            {
			        type = "slider",
			        name = "Assist Ping Opacity",
			        tooltip = "This sets the opacity of the marker of the assist ping.",
			        min = 0,
			        max = 100,
			        step = 1,	--(optional)
			        getFunc = function() return vars.Group.colours.marker[4]*100 end,
			        setFunc = function(a) vars.Group.colours.marker[4] = a/100; AD.Group.updateColours() end,
			        width = "half",	--or "full" (optional)
			    },
			    {
	                type = "colorpicker",
	                name = "Standard Health Colour",
	                tooltip = "This sets the colour of players whos ultimate is not full.",
	                getFunc = function() local rgb = vars.Group.colours.standardHealth; return rgb[1], rgb[2], rgb[3], rgb[4] end,	--(alpha is optional)
	                setFunc = function(r,g,b,a) local rgb = vars.Group.colours.standardHealth; rgb[1] = r; rgb[2] = g; rgb[3] = b; rgb[4] = a; AD.Group.updateColours() end,	--(alpha is optional)
	            	width = "half",
	            },
	            {
	                type = "colorpicker",
	                name = "Full Ult Health Colour",
	                tooltip = "This sets the colour of players whos ultimate is full.",
	                getFunc = function() local rgb = vars.Group.colours.fullUlt; return rgb[1], rgb[2], rgb[3], rgb[4] end,	--(alpha is optional)
	                setFunc = function(r,g,b,a) local rgb = vars.Group.colours.fullUlt; rgb[1] = r; rgb[2] = g; rgb[3] = b; rgb[4] = a; AD.Group.updateColours() end,	--(alpha is optional)
	            	width = "half",
	            },
			    {
					type = "divider",
				},
				{
					type = "description",
					title = "|cFFD700[Crown Module]|r",
					text = "The Following will edit the colours from the Crown Arrow Module",
					width = "full",
				},
				{
	                type = "colorpicker",
	                name = "Arrow/Marker Colour",
	                tooltip = "This sets the colour of the arrow and/or marker. The alpha only affects the marker.",
	                getFunc = function() local rgb = vars.Crown.markerColour; return rgb[1], rgb[2], rgb[3] end,	--(alpha is optional)
	                setFunc = function(r,g,b) local rgb = vars.Crown.markerColour; rgb[1] = r; rgb[2] = g; rgb[3] = b; AD.Crown.updateColours() end,	--(alpha is optional)
	            	width = "half",
	            },
	            {
			        type = "slider",
			        name = "Marker Opacity",
			        tooltip = "This sets the opacity of the marker.",
			        min = 0,
			        max = 100,
			        step = 1,	--(optional)
			        getFunc = function() return vars.Crown.markerColour[4]*100 end,
			        setFunc = function(a) vars.Crown.markerColour[4] = a/100; AD.Crown.updateColours() end,
			        width = "half",	--or "full" (optional)
			    },
	            {
			        type = "slider",
			        name = "Marker Scale",
			        tooltip = "This sets the scale of the marker. 100% is the original size.",
			        min = 0,
			        max = 300,
			        step = 5,
			        getFunc = function() return vars.Crown.scale*100 end,
			        setFunc = function(scale) vars.Crown.scale = scale/100; AD.Crown.pin:setScale(scale/100) end,
			        width = "half",
			    },
	            {
			        type = "slider",
			        name = "Marker Offset",
			        tooltip = "This sets the vertical offset of the marker. 0 is the original offset.",
			        min = -50,
			        max = 50,
			        step = 1,
			        getFunc = function() return vars.Crown.userOffset*10 end,
			        setFunc = function(offset) vars.Crown.userOffset = offset/10; AD.Crown.pin:setUserOffset(offset/10) end,
			        width = "half",
			    },
			}
		},
	}


	local panel = LibAddonMenu2:RegisterAddonPanel(panelName, panelData)
	LibAddonMenu2:RegisterOptionControls(panelName, optionsTable)

end