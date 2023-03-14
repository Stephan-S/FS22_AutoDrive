AutoDriveHud = {}
AutoDrive.FONT_SCALE = 0.0115
AutoDrive.PULLDOWN_ITEM_COUNT = 20

AutoDrive.ItemFilterList = {}

AutoDrive.pullDownListExpanded = 0
AutoDrive.pullDownListDirection = 0
AutoDrive.mouseWheelActive = false

AutoDriveHud.debug = false

AutoDriveHud.defaultHeaderHeight = 0.016
AutoDriveHud.extendedHeaderHeight = 0.180

function AutoDriveHud:new()
	local o = {}
	setmetatable(o, self)
	self.__index = self
	-- not allowed fillTypes in HUD
	AutoDrive.ItemFilterList = {
		g_fillTypeManager:getFillTypeIndexByName("AIR"),
		g_fillTypeManager:getFillTypeIndexByName("CHICKEN_TYPE_BLACK"),
		g_fillTypeManager:getFillTypeIndexByName("CHICKEN_TYPE_WHITE"),
		g_fillTypeManager:getFillTypeIndexByName("CHICKEN_TYPE_BROWN"),
		g_fillTypeManager:getFillTypeIndexByName("CHICKEN_TYPE_ROOSTER"),
		g_fillTypeManager:getFillTypeIndexByName("COW_TYPE_BROWN"),
		g_fillTypeManager:getFillTypeIndexByName("COW_TYPE_BROWN_WHITE"),
		g_fillTypeManager:getFillTypeIndexByName("COW_TYPE_BLACK"),
		g_fillTypeManager:getFillTypeIndexByName("COW_TYPE_BLACK_WHITE"),
		g_fillTypeManager:getFillTypeIndexByName("COW_TYPE_BRAHMAN_BROWN"),
		g_fillTypeManager:getFillTypeIndexByName("COW_TYPE_BRAHMAN_WHITE"),
		g_fillTypeManager:getFillTypeIndexByName("COW_TYPE_BRAHMAN_LIGHT_BROWN"),
		g_fillTypeManager:getFillTypeIndexByName("COW_TYPE_BRAHMAN_GREY"),
		g_fillTypeManager:getFillTypeIndexByName("EGG"),
		g_fillTypeManager:getFillTypeIndexByName("HORSE_TYPE_BEIGE"),
		g_fillTypeManager:getFillTypeIndexByName("HORSE_TYPE_BLACK"),
		g_fillTypeManager:getFillTypeIndexByName("HORSE_TYPE_BROWN"),
		g_fillTypeManager:getFillTypeIndexByName("HORSE_TYPE_BROWN_WHITE"),
		g_fillTypeManager:getFillTypeIndexByName("HORSE_TYPE_DARK_BROWN"),
		g_fillTypeManager:getFillTypeIndexByName("HORSE_TYPE_GREY"),
		g_fillTypeManager:getFillTypeIndexByName("HORSE_TYPE_LIGHT_BROWN"),
		g_fillTypeManager:getFillTypeIndexByName("HORSE_TYPE_RED_BROWN"),
		g_fillTypeManager:getFillTypeIndexByName("OILSEEDRADISH"),
		g_fillTypeManager:getFillTypeIndexByName("PIG_TYPE_RED"),
		g_fillTypeManager:getFillTypeIndexByName("PIG_TYPE_WHITE"),
		g_fillTypeManager:getFillTypeIndexByName("PIG_TYPE_BLACK_WHITE"),
		g_fillTypeManager:getFillTypeIndexByName("PIG_TYPE_BLACK"),
		g_fillTypeManager:getFillTypeIndexByName("ROUNDBALE"),
		g_fillTypeManager:getFillTypeIndexByName("ROUNDBALE_GRASS"),
		g_fillTypeManager:getFillTypeIndexByName("ROUNDBALE_DRYGRASS"),
		g_fillTypeManager:getFillTypeIndexByName("ROUNDBALE_WHEAT"),
		g_fillTypeManager:getFillTypeIndexByName("ROUNDBALE_BARLEY"),
		g_fillTypeManager:getFillTypeIndexByName("SHEEP_TYPE_WHITE"),
		g_fillTypeManager:getFillTypeIndexByName("SHEEP_TYPE_BROWN"),
		g_fillTypeManager:getFillTypeIndexByName("SHEEP_TYPE_BLACK_WHITE"),
		g_fillTypeManager:getFillTypeIndexByName("SHEEP_TYPE_BLACK"),
		g_fillTypeManager:getFillTypeIndexByName("SQUAREBALE"),
		g_fillTypeManager:getFillTypeIndexByName("SQUAREBALE_WHEAT"),
		g_fillTypeManager:getFillTypeIndexByName("SQUAREBALE_BARLEY"),
		g_fillTypeManager:getFillTypeIndexByName("TARP"),
		g_fillTypeManager:getFillTypeIndexByName("TREESAPLINGS"),
		g_fillTypeManager:getFillTypeIndexByName("UNKNOWN"),
		g_fillTypeManager:getFillTypeIndexByName("WEED"),
		g_fillTypeManager:getFillTypeIndexByName("WOOL")
	}
	return o
end

function AutoDriveHud:loadHud()
	if AutoDrive.HudX == nil or AutoDrive.HudY == nil then
		local uiScale = g_gameSettings:getValue("uiScale")
		if AutoDrive.getSetting("guiScale") ~= 0 then
			uiScale = AutoDrive.getSetting("guiScale")
		end

		local numButtons = 7
		local numButtonRows = 2
		local buttonSize = 32
		local iconSize = 32
		local gapSize = 3

		self.width, self.height = getNormalizedScreenValues((numButtons * (gapSize + buttonSize) + gapSize) * uiScale, ((numButtonRows * (gapSize + buttonSize)) + (3 * (gapSize + iconSize)) + 30) * uiScale)
		self.gapWidth, self.gapHeight = getNormalizedScreenValues(uiScale * gapSize, uiScale * gapSize)
		self.posX = 1 - self.width - self.gapWidth
		self.posY = 0.31
		AutoDrive.HudX = self.posX
		AutoDrive.HudY = self.posY
	else
		self.posX = AutoDrive.HudX
		self.posY = AutoDrive.HudY
	end
	self.isMoving = false
	self.isShowingTips = false
	self.stateHud = 0
	self.statesHud = 0
end

function AutoDriveHud:createHudAt(hudX, hudY)
    local vehicle = AutoDrive.getADFocusVehicle()
	local uiScale = g_gameSettings:getValue("uiScale")
	if AutoDrive.getSetting("guiScale") ~= 0 then
		uiScale = AutoDrive.getSetting("guiScale")
	end
	local numButtons = 7
	local numButtonRows = 2
	local buttonSize = 32
	local iconSize = 32
	local gapSize = 3
	local listItemSize = 20
	
	self.headerHeight = AutoDriveHud.defaultHeaderHeight * uiScale
	self.headerExtensionHeight = (AutoDriveHud.extendedHeaderHeight - AutoDriveHud.defaultHeaderHeight) * uiScale

	if self.isShowingTips then
		self.headerHeight = AutoDriveHud.extendedHeaderHeight * uiScale
	end

	self.Background = {}
	self.Buttons = {}
	self.buttonCounter = 0
	self.rows = 1
	self.rowCurrent = 1
	self.cols = 7
	self.colCurrent = 1
	self.buttonCollOffset = 0
	self.pullDownRowOffset = 2

	if AutoDrive.getSetting("wideHUD") then
		self.buttonCollOffset = 7
		self.pullDownRowOffset = 0
		numButtonRows = 0
	end

	self.borderX, self.borderY = getNormalizedScreenValues(uiScale * gapSize, uiScale * gapSize)
	self.buttonWidth, self.buttonHeight = getNormalizedScreenValues(uiScale * buttonSize, uiScale * buttonSize)
	self.width, self.height = getNormalizedScreenValues(((numButtons + self.buttonCollOffset) * (gapSize + buttonSize) + gapSize) * uiScale, ((numButtonRows * (gapSize + buttonSize)) + (3 * (gapSize + iconSize)) + gapSize) * uiScale + self.headerHeight)
	self.gapWidth, self.gapHeight = getNormalizedScreenValues(uiScale * gapSize, uiScale * gapSize)
	self.iconWidth, self.iconHeight = getNormalizedScreenValues(uiScale * iconSize, uiScale * iconSize)
	self.listItemWidth, self.listItemHeight = getNormalizedScreenValues(uiScale * listItemSize, uiScale * listItemSize)

	self.posX = MathUtil.clamp(hudX, 0, 1 - self.width)
	self.posY = MathUtil.clamp(hudY, 2 * self.gapHeight, 1 - (self.height + 3 * self.gapHeight + self.headerHeight))

	AutoDrive.HudX = self.posX
	AutoDrive.HudY = self.posY
	AutoDrive.HudChanged = true

	self.hudElements = {}

	self.Speed = "50"
	self.Target = "Not Ready"
    -- AutoDrive.setSettingState("showHUD", 2)
	self.stateHud = 0
	self.statesHud = 0

	-- TODO: deactivated until PR #1862 solved with issue #1886
	self.statesHud = 0

	if ADGraphManager:getMapMarkerById(1) ~= nil then
		self.Target = ADGraphManager:getMapMarkerById(1).name
	end

	self.row2 = self.posY + (self.pullDownRowOffset + 1) * self.borderY + (self.pullDownRowOffset + 0) * self.buttonHeight
	self.row3 = self.posY + (self.pullDownRowOffset + 2) * self.borderY + (self.pullDownRowOffset + 1) * self.buttonHeight
	self.row4 = self.posY + (self.pullDownRowOffset + 3) * self.borderY + (self.pullDownRowOffset + 2) * self.buttonHeight
	self.rowHeader = self.posY + (self.pullDownRowOffset + 4) * self.borderY + (self.pullDownRowOffset + 3) * self.buttonHeight

	table.insert(self.hudElements, ADHudIcon:new(self.posX, self.posY - 0 * self.gapHeight, self.width, self.height + 5 * self.gapHeight, AutoDrive.directory .. "textures/Background.dds", 0, "background"))

	table.insert(self.hudElements, ADHudIcon:new(self.posX, self.rowHeader, self.width, self.headerHeight, AutoDrive.directory .. "textures/Header.dds", 1, "header"))

	local closeHeight = AutoDriveHud.defaultHeaderHeight * uiScale --0.0177 * uiScale;
	local closeWidth = closeHeight * (g_screenHeight / g_screenWidth)
	self.headerIconWidth = closeWidth
	local posX = self.posX + self.width - (closeWidth * 1.1)
	local posY = self.rowHeader
	-- close crossing
	table.insert(self.hudElements, ADHudButton:new(posX, posY, closeWidth, closeHeight, "input_toggleHud", nil, nil, nil, "", 1, true))

	posX = posX - closeWidth - self.gapWidth
	table.insert(self.hudElements, ADHudButton:new(posX, posY, closeWidth, closeHeight, "input_toggleHudExtension", nil, nil, nil, "", 1, true))

	
	table.insert(self.hudElements, ADHudButton:new(self.posX + self.gapWidth, self.row4, self.iconWidth, self.iconHeight, "input_toggleAutomaticPickupTarget", nil, nil, nil, "input_ADToggleAutomaticPickupTarget", 1, true))
	--table.insert(self.hudElements, ADHudIcon:new(self.posX, self.row4, self.iconWidth, self.iconHeight, AutoDrive.directory .. "textures/destination.dds", 1, "destinationOverlay"))
	-- 1st destination
	self.targetPullDownList = ADPullDownList:new(self.posX + 2 * self.gapWidth + self.buttonWidth, self.row4, self.iconWidth * 6 + self.gapWidth * 5, self.listItemHeight, ADPullDownList.TYPE_TARGET, 1)
	table.insert(self.hudElements, self.targetPullDownList)

	table.insert(self.hudElements, ADHudButton:new(self.posX + self.gapWidth, self.row3, self.iconWidth, self.iconHeight, "input_toggleAutomaticUnloadTarget", nil, nil, nil, "input_ADToggleAutomaticUnloadTarget", 1, true))
	--table.insert(self.hudElements, ADHudIcon:new(self.posX + self.gapWidth, self.row3, self.iconWidth, self.iconHeight, AutoDrive.directory .. "textures/tipper_overlay.dds", 1, "unloadOverlay"))

	table.insert(self.hudElements, ADPullDownList:new(self.posX + 2 * self.gapWidth + self.buttonWidth, self.row3, self.iconWidth * 6 + self.gapWidth * 5, self.listItemHeight, ADPullDownList.TYPE_UNLOAD, 1))
	
	table.insert(self.hudElements, ADHudIcon:new(self.posX + self.gapWidth, self.row2, self.iconWidth, self.iconHeight, AutoDrive.directory .. "textures/fruit_overlay.dds", 1, "fruitOverlay"))

	table.insert(
		self.hudElements,
		ADPullDownList:new(
			self.posX + 2 * self.gapWidth + self.buttonWidth, --+ self.iconWidth * 5 + self.gapWidth*5
			self.row2,
			self.iconWidth * 6 + self.gapWidth * 5,
			self.listItemHeight,
			ADPullDownList.TYPE_FILLTYPE,
			1
		)
	)
	table.insert(self.hudElements, HudHarvesterInfo:new(self.posX + 2 * self.gapWidth + self.buttonWidth, self.row2, self.iconWidth * 6 + self.gapWidth * 5, self.listItemHeight))


	-------- BASE ROW BUTTONS --------------
	self:AddButton("input_start_stop", nil, nil, nil, "input_ADEnDisable", 1, true)
	self:AddButton("input_silomode", "input_previousMode", nil, nil, "input_ADSilomode", 1, true)
	self:AddButton("input_continue", nil, nil, nil, "input_AD_continue", 1, true)
	self:AddButton("input_parkVehicle", "input_setParkDestination", nil, nil, "input_ADParkVehicle", 1, true)
	if vehicle == nil or vehicle.ad.stateModule:getMode() ~= AutoDrive.MODE_BGA then
		self:AddButton("input_incLoopCounter", "input_decLoopCounter", nil, nil, "input_ADIncLoopCounter", 1, true)
	else
		self:AddButton("input_bunkerUnloadType", nil, nil, nil, "input_ADbunkerUnloadType", 1, true)
	end

	local speedX = self.posX + (self.cols - 1 + self.buttonCollOffset) * self.borderX + (self.cols - 2 + self.buttonCollOffset) * self.buttonWidth
	local speedY = self.posY + (1) * self.borderY + (0) * self.buttonHeight
	table.insert(self.hudElements, ADHudSpeedmeter:new(speedX, speedY, self.buttonWidth, self.buttonHeight, false))
	self.buttonCounter = self.buttonCounter + 1

	self:AddButton("input_debug", "input_displayMapPoints", nil, nil, "input_ADActivateDebug", 1, true)
	--------------------------------------------------

	---------- SECOND ROW BUTTONS ---------------------
	if AutoDrive.getSetting("wideHUD") then
		if AutoDrive.getSetting("addSettingsToHUD") then
			self:AddSettingsButton("enableTrafficDetection", "gui_ad_enableTrafficDetection", 1, true)
			self:AddSettingsButton("rotateTargets", "gui_ad_rotateTargets", 1, true)
			self:AddSettingsButton("exitField", "gui_ad_exitField", 1, true)
			self:AddSettingsButton("restrictToField", "gui_ad_restrictToField", 1, true)
			self:AddSettingsButton("avoidFruit", "gui_ad_avoidFruit", 1, true)
		else
			self:AddEditModeButtons()
			if vehicle ~= nil and vehicle.cpStartStopDriver ~= nil then
				self.buttonCounter = self.buttonCounter - 1
				self:AddButton("input_startCp", "input_toggleCP_AIVE", nil, nil, "hud_startCp", 1, true)
			elseif (vehicle ~= nil and vehicle.acParameters ~= nil) then
				self.buttonCounter = self.buttonCounter - 1
				self:AddButton("input_startCp", "input_toggleCP_AIVE", nil, nil, "hud_startCp", 3, true)
			end
		end

		speedX = self.posX + (self.cols - 1 + self.buttonCollOffset) * self.borderX + (self.cols - 2 + self.buttonCollOffset) * self.buttonWidth
		speedY = self.posY + (2) * self.borderY + (1) * self.buttonHeight
		table.insert(self.hudElements, ADHudSpeedmeter:new(speedX, speedY, self.buttonWidth, self.buttonHeight, true))
		self.buttonCounter = self.buttonCounter + 1

		self:AddButton("input_openGUI", nil, nil, nil, "input_ADOpenGUI", 1, true)
	else
		self:AddEditModeButtons()
		if AutoDrive.getSetting("addSettingsToHUD") then
			self.buttonCounter = self.buttonCounter - 5

			if vehicle ~= nil and vehicle.cpStartStopDriver ~= nil then
				self:AddButton("input_startCp", "input_toggleCP_AIVE", nil, nil, "hud_startCp", 1, true)
			elseif (vehicle ~= nil and vehicle.acParameters ~= nil) then
				self:AddButton("input_startCp", "input_toggleCP_AIVE", nil, nil, "hud_startCp", 3, true)
			else
				self:AddSettingsButton("enableTrafficDetection", "gui_ad_enableTrafficDetection", 1, true)
			end

			self:AddSettingsButton("rotateTargets", "gui_ad_rotateTargets", 1, true)
			self:AddSettingsButton("exitField", "gui_ad_exitField", 1, true)
			self:AddSettingsButton("restrictToField", "gui_ad_restrictToField", 1, true)
			self:AddSettingsButton("avoidFruit", "gui_ad_avoidFruit", 1, true)
		else
			if vehicle ~= nil and vehicle.cpStartStopDriver ~= nil then
				self.buttonCounter = self.buttonCounter - 1
				self:AddButton("input_startCp", "input_toggleCP_AIVE", nil, nil, "hud_startCp", 1, true)
			elseif (vehicle ~= nil and vehicle.acParameters ~= nil) then
				self.buttonCounter = self.buttonCounter - 1
				self:AddButton("input_startCp", "input_toggleCP_AIVE", nil, nil, "hud_startCp", 3, true)
			end
		end

		speedX = self.posX + (self.cols - 1 + self.buttonCollOffset) * self.borderX + (self.cols - 2 + self.buttonCollOffset) * self.buttonWidth
		speedY = self.posY + (2) * self.borderY + (1) * self.buttonHeight
		table.insert(self.hudElements, ADHudSpeedmeter:new(speedX, speedY, self.buttonWidth, self.buttonHeight, true))
		self.buttonCounter = self.buttonCounter + 1

		self:AddButton("input_openGUI", nil, nil, nil, "input_ADOpenGUI", 1, true)
	end
	--------------------------------------------------

	---------- THIRD ROW BUTTONS ---------------------
	if AutoDrive.getSetting("wideHUD") and AutoDrive.getSetting("addSettingsToHUD") then
		self:AddEditModeButtons()

		if vehicle ~= nil and vehicle.cpStartStopDriver ~= nil then
			self:AddButton("input_startCp", "input_toggleCP_AIVE", nil, nil, "hud_startCp", 1, true)
		elseif (vehicle ~= nil and vehicle.acParameters ~= nil) then
			self:AddButton("input_startCp", "input_toggleCP_AIVE", nil, nil, "hud_startCp", 3, true)
		end
	end

	-- Refreshing layer sequence must be called, after all elements have been added
	self:refreshHudElementsLayerSequence()
end

function AutoDriveHud:AddEditModeButtons()
	self:AddButton("input_record", "input_record_dual", "input_record_subPrio", "input_record_subPrioDual", "input_ADRecord", 1, false)
	self:AddButton("input_routesManager", nil, nil, nil, "input_AD_routes_manager", 1, false)
	self:AddButton("input_createMapMarker", nil, nil, nil, "input_ADDebugCreateMapMarker", 1, false)
	self:AddButton("input_removeWaypoint", "input_removeMapMarker", nil, nil, "input_ADDebugDeleteWayPoint", 1, false)
	self:AddButton("input_editMapMarker", nil, nil, nil, "input_ADRenameMapMarker", 1, false)
	if AutoDrive.getSetting("wideHUD") and AutoDrive.getSetting("addSettingsToHUD") then
		self:AddButton("input_removeMapMarker", nil, nil, nil, "input_ADDebugDeleteDestination", 1, false)
	end
end

function AutoDriveHud:AddButton(primaryAction, secondaryAction, tertiaryAction, quatenaryAction, toolTip, state, visible)
	self.buttonCounter = self.buttonCounter + 1
	self.colCurrent = self.buttonCounter % self.cols
	if self.colCurrent == 0 then
		self.colCurrent = self.cols
	end
	self.rowCurrent = math.ceil(self.buttonCounter / self.cols)
	self.colCurrent = self.colCurrent + self.buttonCollOffset

	local posX = self.posX + self.colCurrent * self.borderX + (self.colCurrent - 1) * self.buttonWidth
	local posY = self.posY + (self.rowCurrent) * self.borderY + (self.rowCurrent - 1) * self.buttonHeight
	--toolTip = string.sub(g_i18n:getText(toolTip), 4, string.len(g_i18n:getText(toolTip)))
	table.insert(self.hudElements, ADHudButton:new(posX, posY, self.buttonWidth, self.buttonHeight, primaryAction, secondaryAction, tertiaryAction, quatenaryAction, toolTip, state, visible))
end

function AutoDriveHud:AddSettingsButton(setting, toolTip, state, visible)
	self.buttonCounter = self.buttonCounter + 1
	self.colCurrent = self.buttonCounter % self.cols
	if self.colCurrent == 0 then
		self.colCurrent = self.cols
	end
	self.rowCurrent = math.ceil(self.buttonCounter / self.cols)
	self.colCurrent = self.colCurrent + self.buttonCollOffset

	local posX = self.posX + self.colCurrent * self.borderX + (self.colCurrent - 1) * self.buttonWidth
	local posY = self.posY + (self.rowCurrent) * self.borderY + (self.rowCurrent - 1) * self.buttonHeight
	--toolTip = string.sub(g_i18n:getText(toolTip), 4, string.len(g_i18n:getText(toolTip)))
	table.insert(self.hudElements, ADHudSettingsButton:new(posX, posY, self.buttonWidth, self.buttonHeight, setting, toolTip, state, visible))
end

function AutoDriveHud:refreshHudElementsLayerSequence()
	-- Sort the elements by their layer index, for optimizing drawHud and mouseEvent methods
	if self.hudElements ~= nil then
		table.sort(
			self.hudElements,
			function(a, b)
				return a.layer < b.layer
			end
		)
	end
end

function AutoDriveHud:drawHud(vehicle)
	if (vehicle ~= nil and vehicle == g_currentMission.controlledVehicle) or AutoDrive.aiFrameOpen then
		local uiScale = g_gameSettings:getValue("uiScale")
		if AutoDrive.getSetting("guiScale") ~= 0 then
			uiScale = AutoDrive.getSetting("guiScale")
		end

		if self.lastUIScale == nil then
			self.lastUIScale = uiScale
		end

		if self.lastUIScale ~= uiScale then
			self:createHudAt(self.posX, self.posY)
		end
		self.lastUIScale = uiScale

        if self.hudElements ~= nil then
            for _, element in ipairs(self.hudElements) do -- `ipairs` is important, as we want "index-value pairs", not "key-value pairs". https://stackoverflow.com/a/55109411
                element:onDraw(vehicle, uiScale)
            end
        end
	end
end

function AutoDriveHud:update(dt)
    if self.hudElements ~= nil then
        for _, element in ipairs(self.hudElements) do -- `ipairs` is important, as we want "index-value pairs", not "key-value pairs". https://stackoverflow.com/a/55109411
            element:update(dt)
        end
    end
end

function AutoDriveHud:toggleHudExtension(vehicle)
	self.isShowingTips = not self.isShowingTips	
	self:createHudAt(self.posX, self.posY)
end

function AutoDriveHud:toggleHud(vehicle)
    if not AutoDrive.getSetting("showHUD") then
        AutoDrive.setSettingState("showHUD", 2)
    else
        AutoDrive.setSettingState("showHUD", 1)
    end
end

function AutoDriveHud:isMouseOverHud( x, y)
	--- Checks if a hud element was hit.
    local focusVehicle = AutoDrive.getADFocusVehicle()
	if focusVehicle ~= nil then
        if focusVehicle.ad and focusVehicle.ad.stateModule then
            if AutoDrive.getSetting("showHUD") then
                if AutoDrive.Hud and AutoDrive.Hud.hudElements then
                    for i= 1,#AutoDrive.Hud.hudElements do 
                        if AutoDrive.Hud.hudElements[i]:hit(x, y, 0) then 
                            return true
                        end
                    end
                end
            end
        end
    end
end

function AutoDriveHud:mouseEvent(vehicle, posX, posY, isDown, isUp, button)
	local mouseActiveForAutoDrive = (g_gui.currentGui == nil or AutoDrive.aiFrameOpen) and (g_inputBinding:getShowMouseCursor() == true)
	
	if mouseActiveForAutoDrive then
		local mouseEventHandled = false
		if AutoDrive.splineInterpolation ~= nil then			
			AutoDrive.splineInterpolation.valid = false
		end
		AutoDrive.mouseWheelActive = false
        if self.hudElements ~= nil then
            -- Start with highest layer value (last in array), and then iterate backwards.
            for i = #self.hudElements, 1, -1 do
                local element = self.hudElements[i]
                local layer = element.layer
                mouseEventHandled, silent = element:mouseEvent(vehicle, posX, posY, isDown, isUp, button, layer)
                if mouseEventHandled then
                    -- Maybe a PullDownList have been expanded/collapsed, so need to refresh layer sequence
                    self:refreshHudElementsLayerSequence()
                    if silent == nil or silent == false then
                        AutoDrive.playSample(AutoDrive.mouseClickSample, 0.45)
                    end
                    break
                end
            end
        end
		if (not mouseEventHandled) and (AutoDrive.pullDownListExpanded > 0) and (button >= 1 and button <= 3 and isUp) then
			AutoDrive.Hud:closeAllPullDownLists(vehicle)
		end

		if self.isMoving then
			if button == 1 and isUp then
				self:stopMovingHud()
			else
				self:moveHud(posX, posY)
			end
			mouseEventHandled = true
		end

        if g_gui.currentGui ~= nil then
            -- do not allow waypoint manipulation if any GUI is open
            AutoDrive.resetMouseSelections(vehicle)
        end

		vehicle.ad.hoveredNodeId = nil
        vehicle.ad.sectionWayPoints = {}
		local adjustedPaths = false
		if (not mouseEventHandled) and AutoDrive.isInExtendedEditorMode() and g_gui.currentGui == nil then
            if
                not AutoDrive.leftLSHIFTmodifierKeyPressed
                and not AutoDrive.leftCTRLmodifierKeyPressed
                and not AutoDrive.leftALTmodifierKeyPressed 
                and not AutoDrive.rightSHIFTmodifierKeyPressed
                and vehicle.ad.newcreated ~= nil and vehicle.ad.selectedNodeId == vehicle.ad.newcreated
                then
				-- if LCTRL is not pressed - no auto-connect to previous created new point, disable selected point
				AutoDriveHud.debugMsg(vehicle, "AutoDriveHud:mouseEvent selectedNodeId = nil")
				vehicle.ad.selectedNodeId = nil
				vehicle.ad.newcreated = nil
			end

			-- 1st or 2nd Editor Mode enabled
			-- try to get a waypoint in mouse range
			for _, point in pairs(vehicle:getWayPointsInRange(0, AutoDrive.drawDistance)) do
				if AutoDrive.mouseIsAtPos(point, 0.01) then
					vehicle.ad.hoveredNodeId = point.id
					break
				end
			end
			if vehicle.ad.nodeToMoveId ~= nil then
				-- move point at mouse position
				AutoDriveHud.debugMsg(vehicle, "AutoDriveHud:mouseEvent moveNodeToMousePos nodeToMoveId %d", vehicle.ad.nodeToMoveId)
				AutoDrive.moveNodeToMousePos(vehicle.ad.nodeToMoveId)
			end
			if vehicle.ad.hoveredNodeId ~= nil then
				if vehicle.ad.selectedNodeId ~= nil then
					AutoDrive:createSplineInterpolationBetween(ADGraphManager:getWayPointById(vehicle.ad.selectedNodeId), ADGraphManager:getWayPointById(vehicle.ad.hoveredNodeId))
				end

				-- waypoint at mouse position
                if button == 1 and isUp
                    and not AutoDrive.leftLSHIFTmodifierKeyPressed
                    and not AutoDrive.leftCTRLmodifierKeyPressed
                    and not AutoDrive.leftALTmodifierKeyPressed 
                    --and AutoDrive.rightSHIFTmodifierKeyPressed   -- see below !!!
                    then
					-- left mouse button to select point / connect to already selected point
					if vehicle.ad.selectedNodeId ~= nil then
						if vehicle.ad.selectedNodeId ~= vehicle.ad.hoveredNodeId then
							if not table.contains(ADGraphManager:getWayPointById(vehicle.ad.selectedNodeId).out, vehicle.ad.hoveredNodeId) then
								-- connect selected point with hovered point

								if AutoDrive.splineInterpolation ~= nil and AutoDrive.splineInterpolation.valid and AutoDrive.splineInterpolation.waypoints ~= nil and #AutoDrive.splineInterpolation.waypoints > 2 then								
									local waypoints = {}
									local lastHeight = ADGraphManager:getWayPointById(vehicle.ad.selectedNodeId).y
									for wpId, wp in pairs(AutoDrive.splineInterpolation.waypoints) do
										if wpId ~= 1 and wpId < (#AutoDrive.splineInterpolation.waypoints - 1) then
											if math.abs(wp.y - lastHeight) > 1 then -- prevent point dropping into the ground in case of bridges etc
												wp.y = lastHeight
											end
											table.insert(waypoints, {x=wp.x, y=wp.y, z=wp.z})
											lastHeight = wp.y
										end
									end

									ADGraphManager:createSplineConnection(vehicle.ad.selectedNodeId, waypoints, vehicle.ad.hoveredNodeId)
								else
									AutoDriveHud.debugMsg(vehicle, "AutoDriveHud:mouseEvent toggleConnectionBetween 1 vehicle.ad.selectedNodeId %d vehicle.ad.hoveredNodeId %d", vehicle.ad.selectedNodeId, vehicle.ad.hoveredNodeId)
									ADGraphManager:toggleConnectionBetween(ADGraphManager:getWayPointById(vehicle.ad.selectedNodeId), ADGraphManager:getWayPointById(vehicle.ad.hoveredNodeId), AutoDrive.rightSHIFTmodifierKeyPressed)
									if AutoDrive.leftLSHIFTmodifierKeyPressed then
										AutoDriveHud.debugMsg(vehicle, "AutoDriveHud:mouseEvent toggleWayPointAsSubPrio 1 selectedNodeId %d", vehicle.ad.selectedNodeId)
										ADGraphManager:toggleWayPointAsSubPrio(vehicle.ad.selectedNodeId)
									end
								end

								AutoDrive.splineInterpolationUserCurvature = nil
							else
								AutoDriveHud.debugMsg(vehicle, "AutoDriveHud:mouseEvent toggleConnectionBetween 1 vehicle.ad.selectedNodeId %d vehicle.ad.hoveredNodeId %d", vehicle.ad.selectedNodeId, vehicle.ad.hoveredNodeId)
								ADGraphManager:toggleConnectionBetween(ADGraphManager:getWayPointById(vehicle.ad.selectedNodeId), ADGraphManager:getWayPointById(vehicle.ad.hoveredNodeId), AutoDrive.rightSHIFTmodifierKeyPressed)
							end
						end
							
						AutoDrive.playSample(AutoDrive.selectedWayPointSample, 0.75)
						-- unselect point
						AutoDriveHud.debugMsg(vehicle, "AutoDriveHud:mouseEvent unselect point selectedNodeId = nil")
						vehicle.ad.selectedNodeId = nil
						adjustedPaths = true	
					else
						-- select point
						-- no selectedNodeId: hoveredNodeId is now selectedNodeId
                        vehicle.ad.selectedNodeId = vehicle.ad.hoveredNodeId
                        AutoDrive.splineInterpolationUserCurvature = nil
                        AutoDriveHud.debugMsg(vehicle, "AutoDriveHud:mouseEvent select point selectedNodeId %d", vehicle.ad.selectedNodeId)
						
						AutoDrive.playSample(AutoDrive.selectedWayPointSample, 0.75)

                        -- color assignment goes in here
                        if AutoDrive.experimentalFeatures.colorAssignmentMode and g_server ~= nil and g_client ~= nil and g_dedicatedServer == nil then
                            local colorPoint = ADGraphManager:getWayPointById(vehicle.ad.selectedNodeId)
                            if colorPoint ~= nil and colorPoint.colors ~= nil then
                                AutoDriveHud.debugMsg(vehicle, "AutoDriveHud:mouseEvent point.colors %.3f %.3f %.3f", colorPoint.colors[1], colorPoint.colors[2], colorPoint.colors[3])
                                vehicle.ad.selectedColorNodeId = vehicle.ad.selectedNodeId
                                    -- only allowed in single player game
                                ADInputManager:input_openColorSettings()
							end
                        end
					end
				end

				if (button == 2 or button == 3) and isDown 
                    and not AutoDrive.leftLSHIFTmodifierKeyPressed
                    and not AutoDrive.leftCTRLmodifierKeyPressed
                    and not AutoDrive.leftALTmodifierKeyPressed 
                    and not AutoDrive.rightSHIFTmodifierKeyPressed
                    then
					-- middle or right mouse button to move points - waypoint at mouse position selected to move
					if vehicle.ad.nodeToMoveId == nil then
						vehicle.ad.nodeToMoveId = vehicle.ad.hoveredNodeId
					end
				end
			end

			if (button == 2 or button == 3) and isUp 
                -- and not AutoDrive.leftLSHIFTmodifierKeyPressed -- leftLSHIFT needed to be checked in changeWayPointPosition
                and not AutoDrive.leftCTRLmodifierKeyPressed
                and not AutoDrive.leftALTmodifierKeyPressed 
                and not AutoDrive.rightSHIFTmodifierKeyPressed
                then
				if vehicle.ad.nodeToMoveId ~= nil then
					-- middle or right mouse button to move points - end of move -> change waypoint coordinates now
					ADGraphManager:changeWayPointPosition(vehicle.ad.nodeToMoveId)
					vehicle.ad.nodeToMoveId = nil
				end
			end

			-- if LCTRL is pressed, you can select a waypoint so that when you will create a new one they will be connected (auto connection to existing waypoint)
            if button == 1 and isUp
                and not AutoDrive.leftLSHIFTmodifierKeyPressed
                and AutoDrive.leftCTRLmodifierKeyPressed
                and not AutoDrive.leftALTmodifierKeyPressed
                and not AutoDrive.rightSHIFTmodifierKeyPressed
                and vehicle.ad.selectedNodeId == nil
                and vehicle.ad.hoveredNodeId ~= nil
                then
				vehicle.ad.newcreated = vehicle.ad.hoveredNodeId
				vehicle.ad.selectedNodeId = vehicle.ad.newcreated
				AutoDriveHud.debugMsg(vehicle, "AutoDriveHud:mouseEvent auto connection 1 selectedNodeId %d", vehicle.ad.selectedNodeId)
			end

            if button == 1 and isUp 
                and AutoDrive.leftLSHIFTmodifierKeyPressed
                and not AutoDrive.leftCTRLmodifierKeyPressed
                and not AutoDrive.leftALTmodifierKeyPressed
                and not AutoDrive.rightSHIFTmodifierKeyPressed
                and vehicle.ad.hoveredNodeId ~= nil
                and vehicle.ad.selectedNodeId == nil
                and not adjustedPaths
                then
				ADGraphManager:toggleWayPointAsSubPrio(vehicle.ad.hoveredNodeId)
				AutoDriveHud.debugMsg(vehicle, "AutoDriveHud:mouseEvent toggleWayPointAsSubPrio 2 hoveredNodeId %d", vehicle.ad.hoveredNodeId)
			end

			--If no node is hovered / moved - create new node
			if vehicle.ad.nodeToMoveId == nil and vehicle.ad.hoveredNodeId == nil then
                if button == 1 and isUp
                    -- and not AutoDrive.leftLSHIFTmodifierKeyPressed -- see below !!!
                    and AutoDrive.leftCTRLmodifierKeyPressed
                    and not AutoDrive.leftALTmodifierKeyPressed
                    -- and not AutoDrive.rightSHIFTmodifierKeyPressed -- see below !!!
                    then
					--For rough depth assertion, we use the closest nodes location as this is roughly in the screen's center
					local closest = vehicle:getClosestWayPoint()
					closest = ADGraphManager:getWayPointById(closest)
					if closest ~= nil then
						local _, _, depth = project(closest.x, closest.y, closest.z)

						local x, y, z = unProject(g_lastMousePosX, g_lastMousePosY, depth)
						-- And just to correct for slope changes, we now set the height to the terrain height
						y = AutoDrive:getTerrainHeightAtWorldPos(x, z)

						local screenX, screenY, depthNew = project(x, y + AutoDrive.drawHeight + AutoDrive.getSetting("lineHeight"), z)

						local maxLoops = 1000
						local minDistance = MathUtil.vector2Length(g_lastMousePosX - screenX, g_lastMousePosY - screenY)
						local minX, minY, minZ = x, y, z
						while minDistance > 0.002 and maxLoops > 0 do
							maxLoops = maxLoops - 1
							if screenY > g_lastMousePosY then
								depth = depth - 0.0001
							else
								depth = depth + 0.0001
							end

							x, y, z = unProject(g_lastMousePosX, g_lastMousePosY, depth)
							y = AutoDrive:getTerrainHeightAtWorldPos(x, z)

							screenX, screenY, depthNew = project(x, y + AutoDrive.drawHeight + AutoDrive.getSetting("lineHeight"), z)

							local distance = MathUtil.vector2Length(g_lastMousePosX - screenX, g_lastMousePosY - screenY)
							if distance < minDistance then
								minX = x
								minY = y
								minZ = z
								minDistance = distance
							end
						end

                        if AutoDrive.experimentalFeatures.colorAssignmentMode and g_server ~= nil and g_client ~= nil and g_dedicatedServer == nil then
                            -- only allowed in single player game to create the color selection
                            AutoDrive.createColorSelectionWayPoints(vehicle)
                        else
                            ADGraphManager:createWayPoint(minX, minY, minZ)
                        end
						-- auto connect to previous created point not working proper in MP, so deactivated at all
						if g_server ~= nil and g_client ~= nil then -- this will be true on dedi servers !!!
							-- auto connect only working in single player properly !
							local createdId = ADGraphManager:getWayPointsCount()
							
							if AutoDrive.leftLSHIFTmodifierKeyPressed and not AutoDrive.rightSHIFTmodifierKeyPressed then
								ADGraphManager:toggleWayPointAsSubPrio(createdId)
								AutoDriveHud.debugMsg(vehicle, "AutoDriveHud:mouseEvent toggleWayPointAsSubPrio 3 createdId %d", createdId)
							end

							if vehicle.ad.newcreated ~= nil and vehicle.ad.selectedNodeId == vehicle.ad.newcreated then
								-- connect only if previous created point is selected and newcreated ~= nil
								AutoDriveHud.debugMsg(vehicle, "AutoDriveHud:mouseEvent toggleConnectionBetween 2 vehicle.ad.selectedNodeId %d to %d", vehicle.ad.selectedNodeId, createdId)
								ADGraphManager:toggleConnectionBetween(ADGraphManager:getWayPointById(vehicle.ad.selectedNodeId), ADGraphManager:getWayPointById(createdId), AutoDrive.rightSHIFTmodifierKeyPressed)
							end
							vehicle.ad.newcreated = createdId
							vehicle.ad.selectedNodeId = vehicle.ad.newcreated
							AutoDriveHud.debugMsg(vehicle, "AutoDriveHud:mouseEvent auto connection 2 selectedNodeId %d", vehicle.ad.selectedNodeId)
						end
					end
				end
			end

			if vehicle.ad.hoveredNodeId ~= nil and vehicle.ad.nodeToMoveId == nil and vehicle.ad.selectedNodeId == nil and not adjustedPaths then
                if button == 1 and isUp
                    and not AutoDrive.leftLSHIFTmodifierKeyPressed
                    and not AutoDrive.leftCTRLmodifierKeyPressed
                    and AutoDrive.leftALTmodifierKeyPressed
                    and not AutoDrive.rightSHIFTmodifierKeyPressed
                    then
					-- Left alt for deleting the currently hovered node
					AutoDriveHud.debugMsg(vehicle, "AutoDriveHud:mouseEvent removeWayPoint hoveredNodeId %d", vehicle.ad.hoveredNodeId)
					ADGraphManager:removeWayPoint(vehicle.ad.hoveredNodeId)
				end
			end

           AutoDrive.handleWayPointSection(vehicle, button, isUp)
		else
			AutoDrive.resetMouseSelections(vehicle)
		end
	else
		AutoDrive.resetMouseSelections(vehicle)
	end

	AutoDrive.mouseWheelActive = AutoDrive.mouseWheelActive or (AutoDrive.pullDownListExpanded ~= 0)
end

function AutoDrive.resetMouseSelections(vehicle)
	if vehicle ~= nil and vehicle.ad ~= nil then
		vehicle.ad.selectedNodeId = nil
		vehicle.ad.nodeToMoveId = nil
		vehicle.ad.hoveredNodeId = nil
		vehicle.ad.newcreated = nil
		vehicle.ad.sectionWayPoints = {}
	end
end

function AutoDrive.handleWayPointSection(vehicle, button, isUp)
	-- AutoDriveHud.debugMsg(vehicle, "AutoDrive.handleWayPointSection vehicle.ad.selectedNodeId %s vehicle.ad.hoveredNodeId %s", tostring(vehicle.ad.selectedNodeId), tostring(vehicle.ad.hoveredNodeId))
    if vehicle.ad.selectedNodeId ~= nil and vehicle.ad.hoveredNodeId ~= nil and vehicle.ad.selectedNodeId ~= vehicle.ad.hoveredNodeId then
        local wayPointsDirection = ADGraphManager:getIsWayPointJunction(vehicle.ad.selectedNodeId, vehicle.ad.hoveredNodeId)
        if wayPointsDirection > 0 and  wayPointsDirection < 4 then
            vehicle.ad.sectionWayPoints = ADGraphManager:getWayPointsInSection(vehicle.ad.selectedNodeId, vehicle.ad.hoveredNodeId, wayPointsDirection)
			-- AutoDriveHud.debugMsg(vehicle, "AutoDrive.handleWayPointSection button %d isUp %s AutoDrive.leftCTRLmodifierKeyPressed %s", button, tostring(isUp), tostring(AutoDrive.leftCTRLmodifierKeyPressed))
            if button == 1 and isUp
                and not AutoDrive.leftLSHIFTmodifierKeyPressed
                and AutoDrive.leftCTRLmodifierKeyPressed
                and not AutoDrive.leftALTmodifierKeyPressed
                and not AutoDrive.rightSHIFTmodifierKeyPressed
                then
                wayPointsDirection = wayPointsDirection + 1
                if wayPointsDirection > 3 then
                    wayPointsDirection = 1
                end
                ADGraphManager:setConnectionBetweenWayPointsInSection(vehicle, wayPointsDirection)
                vehicle.ad.selectedNodeId = nil -- unselect the current node after action done
            end

            if button == 1 and isUp
                and AutoDrive.leftLSHIFTmodifierKeyPressed
                and not AutoDrive.leftCTRLmodifierKeyPressed
                and not AutoDrive.leftALTmodifierKeyPressed
                and not AutoDrive.rightSHIFTmodifierKeyPressed
                then
                if vehicle.ad.sectionWayPoints ~= nil and #vehicle.ad.sectionWayPoints > 2 then
                    local sectionPrio = ADGraphManager:getIsPointSubPrio(vehicle.ad.sectionWayPoints[2])   -- 2nd WayPoint is the 1st in section and has the actual Prio
                    local flags = 0
                    if sectionPrio then
                        flags = AutoDrive.FLAG_NONE
                    else
                        flags = AutoDrive.FLAG_SUBPRIO
                    end
                    ADGraphManager:setWayPointsFlagsInSection(vehicle, flags)
                    vehicle.ad.selectedNodeId = nil -- unselect the current node after action done
                end
            end

            if button == 1 and isUp
                and AutoDrive.leftLSHIFTmodifierKeyPressed
                and AutoDrive.leftCTRLmodifierKeyPressed
                and AutoDrive.leftALTmodifierKeyPressed
                and not AutoDrive.rightSHIFTmodifierKeyPressed
                then
                ADGraphManager:deleteWayPointsInSection(vehicle)
                vehicle.ad.selectedNodeId = nil -- unselect the current node to prevent further deletions nearby by mouse clicks
            end
        end
    end
end

function AutoDrive.moveNodeToMousePos(nodeID)
	local node = ADGraphManager:getWayPointById(nodeID)

	-- First I use project to get a proper depth value for the unproject funtion
	local _, _, depth = project(node.x, node.y + AutoDrive.drawHeight + AutoDrive.getSetting("lineHeight"), node.z)

	if node ~= nil and g_lastMousePosX ~= nil and g_lastMousePosY ~= nil then
		node.x, _, node.z = unProject(g_lastMousePosX, g_lastMousePosY, depth)
		if not AutoDrive.leftLSHIFTmodifierKeyPressed then
			node.y = AutoDrive:getTerrainHeightAtWorldPos(node.x, node.z)
		end
		ADGraphManager:markChanges()
	end
end

function AutoDriveHud:startMovingHud(mouseX, mouseY)
	self.isMoving = true
	self.lastMousePosX = mouseX
	self.lastMousePosY = mouseY
end

function AutoDriveHud:moveHud(posX, posY)
	if self.isMoving then
		local diffX = posX - self.lastMousePosX
		local diffY = posY - self.lastMousePosY
		self:createHudAt(self.posX + diffX, self.posY + diffY)
		self.lastMousePosX = posX
		self.lastMousePosY = posY
	end
end

function AutoDriveHud:stopMovingHud()
	self.isMoving = false
	ADUserDataManager:sendToServer()
end

function AutoDriveHud:getModeName(vehicle)
	if vehicle.ad.stateModule:getMode() == AutoDrive.MODE_DRIVETO then
		return g_i18n:getText("AD_MODE_DRIVETO")
	elseif vehicle.ad.stateModule:getMode() == AutoDrive.MODE_DELIVERTO then
		return g_i18n:getText("AD_MODE_DELIVERTO")
	elseif vehicle.ad.stateModule:getMode() == AutoDrive.MODE_PICKUPANDDELIVER then
		return g_i18n:getText("AD_MODE_PICKUPANDDELIVER")
	elseif vehicle.ad.stateModule:getMode() == AutoDrive.MODE_UNLOAD then
		return g_i18n:getText("AD_MODE_UNLOAD")
	elseif vehicle.ad.stateModule:getMode() == AutoDrive.MODE_LOAD then
		return g_i18n:getText("AD_MODE_LOAD")
	elseif vehicle.ad.stateModule:getMode() == AutoDrive.MODE_BGA then
		return g_i18n:getText("AD_MODE_BGA")
	end

	return ""
end

function AutoDriveHud:has_value(tab, val)
	for _, value in ipairs(tab) do
		if value == val then
			return true
		end
	end

	return false
end

function AutoDriveHud:closeAllPullDownLists(vehicle)
	if self.hudElements ~= nil then
		for _, hudElement in pairs(self.hudElements) do
			if hudElement.collapse ~= nil and hudElement.state ~= nil and hudElement.state == ADPullDownList.STATE_EXPANDED then
				hudElement:collapse(vehicle, false)
			end
		end
	end
	-- PullDownList(s) have been collapsed, so need to refresh layer sequence
	self:refreshHudElementsLayerSequence()
end

function AutoDriveHud:createMapHotspot(vehicle)
	local _, textOffsetY = getNormalizedScreenValues(0, -5)
	
	vehicle.ad.mapHotspot = AIHotspot.new()
	vehicle.ad.mapHotspot:setAIHelperName("AD: " .. vehicle.ad.stateModule:getName())
	vehicle.ad.mapHotspot:setVehicle(vehicle)
	if vehicle.getOwnerFarmId ~= nil then
		vehicle.ad.mapHotspot:setOwnerFarmId(vehicle:getOwnerFarmId())
	end
	vehicle.ad.mapHotspot.textOffsetY = textOffsetY

	vehicle.ad.mapHotspot.icon = Overlay.new(AIHotspot.FILENAME, 0, 0, getNormalizedScreenValues(40, 40))
	vehicle.ad.mapHotspot.icon:setUVs(AIHotspot.UVS)

	g_currentMission:addMapHotspot(vehicle.ad.mapHotspot)
end

function AutoDriveHud:deleteMapHotspot(vehicle)
	if vehicle ~= nil and vehicle.ad ~= nil and vehicle.ad.mapHotspot ~= nil then
		g_currentMission:removeMapHotspot(vehicle.ad.mapHotspot)
		vehicle.ad.mapHotspot:delete()
		vehicle.ad.mapHotspot = nil
	end
end

function AutoDrive:ingameMapElementMouseEvent(superFunc, posX, posY, isDown, isUp, button, eventUsed)
	eventUsed = superFunc(self, posX, posY, isDown, isUp, button, eventUsed)

    if isUp and button == Input.MOUSE_BUTTON_LEFT then
        local hotspot = g_currentMission.hud.ingameMap.selectedHotspot
        if hotspot ~= nil and hotspot.isADMarker then
            local targetVehicle = AutoDrive.getADFocusVehicle()
            if targetVehicle ~= nil and AutoDrive.getSetting("showMarkersOnMap") and AutoDrive.getSetting("switchToMarkersOnMap") then
                AutoDriveHudInputEventEvent:sendFirstMarkerEvent(targetVehicle, hotspot.markerID)
                return
            end
        end
    end

    if isUp and button == Input.MOUSE_BUTTON_RIGHT then
        for _, hotspot in pairs(self.ingameMap.hotspots) do
            if hotspot.isADMarker then
                local hotspotPosX, hotspotPosY =  hotspot.icon:getPosition()
                if GuiUtils.checkOverlayOverlap(posX, posY, hotspotPosX, hotspotPosY, hotspot:getWidth(), hotspot:getHeight(), nil) then
                    local targetVehicle = AutoDrive.getADFocusVehicle()
                    if targetVehicle ~= nil and AutoDrive.getSetting("showMarkersOnMap") and AutoDrive.getSetting("switchToMarkersOnMap") then
                        AutoDriveHudInputEventEvent:sendSecondMarkerEvent(targetVehicle, hotspot.markerID)
                    end
                    break
                end
            end
        end
    end

	return eventUsed
end

function AutoDrive:MapHotspot_getIsVisible(superFunc)
	local superReturn = true
	if superFunc ~= nil then
		superReturn = superFunc(self)
	end
	return superReturn and ((not self.isADMarker) or AutoDrive.getSetting("showMarkersOnMap"))
end

function AutoDrive.getPlayerHotspot()
--[[
    spec.playerHotspot = PlayerHotspot.new()
    spec.playerHotspot:setVehicle(self)

    g_currentMission:addInteractiveVehicle(self)
    g_currentMission:addEnterableVehicle(self)

    if spec.playerHotspot ~= nil then
        spec.playerHotspot:setOwnerFarmId(self:getActiveFarm())
        g_currentMission:addMapHotspot(spec.playerHotspot)
    end
]]
        local mapHotspot = PlayerHotspot.new()

        -- mapHotspot:setOwnerFarmId(self:getActiveFarm())
        -- mapHotspot:setOwnerFarmId(0) -- all, visitor etc. ???

--[[
        mapHotspot.ownerFarmId = g_currentMission.player.farmId
        mapHotspot.clickArea.area[1] = 0.13
        mapHotspot.clickArea.area[2] = 0.13
        mapHotspot.clickArea.area[3] = 0.74
        mapHotspot.clickArea.area[4] = 0.74
]]

        -- mapHotspot.isHotspotSelectionActive = true ???
    return mapHotspot
end

function AutoDrive.getTourHotspot()
--[[
    if self.mapHotspot == nil then
        self.mapHotspot = TourHotspot.new()
        g_currentMission:addMapHotspot(self.mapHotspot)
    end

    self.mapHotspot:setWorldPosition(x, z)

    -- Find 'hidden' icon used internally only
    local h = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x,y,z)
    if y > h then
        g_currentMission:setMapTargetHotspot(self.mapHotspot)
        g_currentMission.disableMapTargetHotspotHiding = true
    else
        g_currentMission:setMapTargetHotspot(nil)
        g_currentMission.disableMapTargetHotspotHiding = false
    end
]]
        local mapHotspot = TourHotspot.new()

--[[
        mapHotspot.ownerFarmId = g_currentMission.player.farmId
        mapHotspot.clickArea.area[1] = 0.13
        mapHotspot.clickArea.area[2] = 0.13
        mapHotspot.clickArea.area[3] = 0.74
        mapHotspot.clickArea.area[4] = 0.74
]]
        -- mapHotspot.isHotspotSelectionActive = true ???
    return mapHotspot
end

function AutoDrive.getPlaceableHotspot()
--[[
        local hotspot = PlaceableHotspot.new()
        hotspot:setPlaceable(self)

        local hotspotTypeName = self.xmlFile:getValue(key .. "#type", "UNLOADING")
        local hotspotType = PlaceableHotspot.getTypeByName(hotspotTypeName)
        if hotspotType == nil then
            Logging.xmlWarning(self.xmlFile, "Unknown placeable hotspot type '%s'. Falling back to type 'UNLOADING'\nAvailable types: %s", hotspotTypeName, table.concatKeys(PlaceableHotspot.TYPE, " "))
            hotspotType = PlaceableHotspot.TYPE.UNLOADING
        end
        hotspot:setPlaceableType(hotspotType)

        local linkNode = self.xmlFile:getValue(key .. "#linkNode", nil, self.components, self.i3dMappings) or self.rootNode
        if linkNode ~= nil then
            local x, _, z = getWorldTranslation(linkNode)
            hotspot:setWorldPosition(x, z)
        end

        local teleportNode = self.xmlFile:getValue(key .. "#teleportNode", nil, self.components, self.i3dMappings)
        if teleportNode ~= nil then
            local x, y, z = getWorldTranslation(teleportNode)
            hotspot:setTeleportWorldPosition(x, y, z)
        end

        local worldPositionX, worldPositionZ = self.xmlFile:getValue(key .. "#worldPosition", nil)
        if worldPositionX ~= nil then
            hotspot:setWorldPosition(worldPositionX, worldPositionZ)
        end

        local teleportX, teleportY, teleportZ = self.xmlFile:getValue(key .. "#teleportWorldPosition", nil)
        if teleportX ~= nil then
            if g_currentMission ~= nil then
                teleportY = math.max(teleportY, getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, teleportX, 0, teleportZ))
            end
            hotspot:setTeleportWorldPosition(teleportX, teleportY, teleportZ)
        end

        local text = self.xmlFile:getValue(key.."#text", nil)
        if text ~= nil then
            text = g_i18n:convertText(text, self.customEnvironment)
            hotspot:setName(text)
        end
]]
        local mapHotspot = PlaceableHotspot.new()

--[[
        mapHotspot.ownerFarmId = g_currentMission.player.farmId
        mapHotspot.clickArea.area[1] = 0.13
        mapHotspot.clickArea.area[2] = 0.13
        mapHotspot.clickArea.area[3] = 0.74
        mapHotspot.clickArea.area[4] = 0.74
]]
        -- mapHotspot.isHotspotSelectionActive = true ???

        mapHotspot:setPlaceableType(PlaceableHotspot.TYPE.UNLOADING)
        -- mapHotspot:setTeleportWorldPosition(x, y, z)


    return mapHotspot
end

function AutoDrive.updateDestinationsMapHotspots()
    AutoDrive.debugPrint(nil, AutoDrive.DC_DEVINFO, "AutoDrive.updateDestinationsMapHotspots()")

    local width, height = getNormalizedScreenValues(9, 9)

    if AutoDrive.mapHotspotsBuffer ~= nil then
        -- Removing all old map hotspots
        for _, mapHotspot in pairs(AutoDrive.mapHotspotsBuffer) do
            g_currentMission:removeMapHotspot(mapHotspot)
            mapHotspot:delete()
        end
    end
    AutoDrive.mapHotspotsBuffer = {}

    -- Updating and adding hotspots
    for index, marker in ipairs(ADGraphManager:getMapMarkers()) do
        -- local mapHotspot = TourHotspot.new()
        local mapHotspot = PlaceableHotspot.new()
        -- local mapHotspot = AutoDrive.getPlayerHotspot()

        mapHotspot.width, mapHotspot.height = getNormalizedScreenValues(40, 40)
        mapHotspot.isVisible = true
        mapHotspot.icon = Overlay.new(g_autoDriveUIFilename, 0, 0, mapHotspot.width, mapHotspot.height )
        mapHotspot.icon:setUVs(GuiUtils.getUVs({0, 512, 128, 128}))
		mapHotspot.iconSmall = Overlay.new(g_autoDriveUIFilename, 0, 0, mapHotspot.width, mapHotspot.height)
		mapHotspot.iconSmall:setUVs(GuiUtils.getUVs({0, 512, 128, 128}))

        if marker.isADDebug == true then
            -- map hotspot debug
            mapHotspot.isADDebug = true
            -- mh = MapHotspot:new("mapMarkerHotSpot", MapHotspot.CATEGORY_MISSION)
			mapHotspot.icon:setUVs(GuiUtils.getUVs({780, 780, 234, 234}))			
        end

        mapHotspot.isADMarker = true
        mapHotspot.markerID = index
        
        local wp = ADGraphManager:getWayPointById(marker.id)
        if wp ~= nil then
            g_currentMission:addMapHotspot(mapHotspot)
            table.insert(AutoDrive.mapHotspotsBuffer, mapHotspot)

            mapHotspot:setWorldPosition(wp.x, wp.z)

            mapHotspot:setTeleportWorldPosition(wp.x, wp.y + 2, wp.z)

            mapHotspot:setName(marker.name)
        end
    end
end

function AutoDrive.createColorSelectionWayPoints(vehicle)
    if vehicle ~= nil and vehicle.ad ~= nil  then
        local startNode = vehicle.ad.frontNode
        local x1, _, z1 = getWorldTranslation(startNode)
        local y1 = AutoDrive:getTerrainHeightAtWorldPos(x1, z1)
        local z= 19
        for blue = 0, z do
            for red = 1, 2*blue+1 do
                local b = 1-(blue/z)
                local r = 0
                if b < 1 then
                    r = (red-1)/(2*blue+1-1) * (1-b)
                    if r > (1-b) then
                        r = (1-b)
                    end
                end
                local g = 0
                if (b + r) < 1 then
                    g = 1 - (b + r)
                end
                
                local colors = {r, g, b}
                local rx, _, rz = localDirectionToWorld(startNode, blue-red, 0, blue+2)
                ADGraphManager:createWayPointColored(x1 + rx, y1 + 1, z1 + rz, colors)
            end
        end
    end
end

function AutoDriveHud.debugMsg(vehicle, debugText, ...)
    if AutoDriveHud.debug == true then
        AutoDrive.debugMsg(vehicle, debugText, ...)
    end
end
