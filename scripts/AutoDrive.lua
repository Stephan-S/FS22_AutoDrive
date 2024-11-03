AutoDrive = {}
AutoDrive.version = "2.0.1.7-RC4"

AutoDrive.directory = g_currentModDirectory

g_autoDriveUIFilename = AutoDrive.directory .. "textures/GUI_Icons.dds"
g_autoDriveDebugUIFilename = AutoDrive.directory .. "textures/gui_debug_Icons.dds"
g_autoDriveIconFilename = g_iconsUIFilename

AutoDrive.experimentalFeatures = {}
AutoDrive.experimentalFeatures.redLinePosition = false
-- AutoDrive.experimentalFeatures.telemetryOutput = false
AutoDrive.experimentalFeatures.enableRoutesManagerOnDediServer = false
AutoDrive.experimentalFeatures.detectSwath = true
AutoDrive.experimentalFeatures.colorAssignmentMode = false
AutoDrive.experimentalFeatures.UTurn = true
AutoDrive.experimentalFeatures.FoldImplements = true
AutoDrive.experimentalFeatures.RefuelOnlyAtValidStations = true
AutoDrive.experimentalFeatures.RecordWhileNotInVehicle = false
AutoDrive.experimentalFeatures.NewPathfinder = true

AutoDrive.dynamicChaseDistance = true
AutoDrive.smootherDriving = true
AutoDrive.developmentControls = false

AutoDrive.mapHotspotsBuffer = {}

AutoDrive.drawHeight = 0.3
AutoDrive.drawDistance = getViewDistanceCoeff() * 50

-- AutoDrive.STAT_NAMES = {"driversTraveledDistance", "driversHired"}
-- for _, statName in pairs(AutoDrive.STAT_NAMES) do
	-- table.insert(FarmStats.STAT_NAMES, statName)
-- end

AutoDrive.MODE_DRIVETO = 1
AutoDrive.MODE_PICKUPANDDELIVER = 2
AutoDrive.MODE_DELIVERTO = 3
AutoDrive.MODE_LOAD = 4
AutoDrive.MODE_UNLOAD = 5
AutoDrive.MODE_BGA = 6

AutoDrive.DC_NONE = 0
AutoDrive.DC_VEHICLEINFO = 1
AutoDrive.DC_COMBINEINFO = 2
AutoDrive.DC_TRAILERINFO = 4
AutoDrive.DC_DEVINFO = 8
AutoDrive.DC_PATHINFO = 16
AutoDrive.DC_SENSORINFO = 32
AutoDrive.DC_NETWORKINFO = 64
AutoDrive.DC_EXTERNALINTERFACEINFO = 128
AutoDrive.DC_RENDERINFO = 256
AutoDrive.DC_ROADNETWORKINFO = 512
AutoDrive.DC_BGA_MODE = 1024
AutoDrive.DC_TRAINS = 2048
AutoDrive.DC_ALL = 65535

AutoDrive.currentDebugChannelMask = AutoDrive.DC_NONE

-- rotate target modes
AutoDrive.RT_NONE = 1
AutoDrive.RT_ONLYPICKUP = 2
AutoDrive.RT_ONLYDELIVER = 3
AutoDrive.RT_PICKUPANDDELIVER = 4

AutoDrive.EDITOR_OFF = 1
AutoDrive.EDITOR_ON = 2
AutoDrive.EDITOR_EXTENDED = 3
AutoDrive.EDITOR_SHOW = 4

AutoDrive.SCAN_DIALOG_NONE = 0
AutoDrive.SCAN_DIALOG_OPEN = 1
AutoDrive.SCAN_DIALOG_RESULT_YES = 2
AutoDrive.SCAN_DIALOG_RESULT_NO = 3
AutoDrive.SCAN_DIALOG_RESULT_DONE = 4
AutoDrive.scanDialogState = AutoDrive.SCAN_DIALOG_NONE

AutoDrive.foldTimeout = 30000 -- 30 s time to fold all implements
AutoDrive.MAX_BUNKERSILO_LENGTH = 100 -- length of bunker silo where speed should be lowered

-- number of frames for performance modulo operation
AutoDrive.PERF_FRAMES = 20
AutoDrive.PERF_FRAMES_HIGH = 4

AutoDrive.toggleSphrere = true
AutoDrive.enableSphrere = true

AutoDrive.FLAG_NONE = 0
AutoDrive.FLAG_SUBPRIO = 1
AutoDrive.FLAG_TRAFFIC_SYSTEM = 2
AutoDrive.FLAG_TRAFFIC_SYSTEM_CONNECTION = 4

-- add this to measured size of vehicles
AutoDrive.DIMENSION_ADDITION = 0.2

-- AD invoked by which type of user
AutoDrive.USER_PLAYER = 1
AutoDrive.USER_GIANTS = 2
AutoDrive.USER_CP = 3

AutoDrive.colors = {
	ad_color_singleConnection = {0, 1, 0, 1},
	ad_color_dualConnection = {0, 0, 1, 1},
	ad_color_reverseConnection = {0, 0.569, 0.835, 1},
	ad_color_default = {1, 0, 0, 0.3},
	ad_color_subPrioSingleConnection = {1, 0.531, 0.14, 1},
	ad_color_subPrioDualConnection = {0.389, 0.177, 0, 1},
	ad_color_subPrioNode = {1, 0.531, 0.14, 0.3},
	ad_color_hoveredNode = {0, 0, 1, 0.15},
	ad_color_previousNode = {1, 0.2195, 0.6524, 0.5}, --GOLDHOFER_PINK1
	ad_color_nextNode = {1, 0.7, 0, 0.5},
	ad_color_selectedNode = {0, 1, 0, 0.15},
	ad_color_currentConnection = {1, 1, 1, 1},
	ad_color_closestLine = {1, 0, 0, 1},
	ad_color_editorHeightLine = {1, 1, 1, 1},
	ad_color_previewSingleConnection = {0.3, 0.9, 0, 1},
	ad_color_previewDualConnection = {0, 0, 0.9, 1},
	ad_color_previewSubPrioSingleConnection = {0.9, 0.4, 0.1, 1},
	ad_color_previewSubPrioDualConnection = {0.3, 0.15, 0, 1},
	ad_color_previewOk = {0.3, 0.9, 0, 1},
	ad_color_previewNotOk = {1, 0.1, 0, 1},
	ad_color_textInputBackground = {0.0227, 0.5346, 0.8519, 1} -- Giants original
}

AutoDrive.currentColors = {} -- this will hold the current colors, derived from default colors above, overwritten by local settings

AutoDrive.fuelFillTypes = {
    "DIESEL",
    "METHANE",
    "ELECTRICCHARGE",
    "DEF",
    "AIR"
}

AutoDrive.nonFillableFillTypes = { -- these fillTypes should not be transported
    "AIR"
}

AutoDrive.seedFillTypes = {
    'SEEDS',
    'FERTILIZER',
    'LIQUIDFERTILIZER'
}

AutoDrive.modesToStartFromCP = {
    -- AutoDrive.MODE_DRIVETO, not allowed
    AutoDrive.MODE_PICKUPANDDELIVER,
    -- AutoDrive.MODE_DELIVERTO, not allowed
    AutoDrive.MODE_LOAD,
    AutoDrive.MODE_UNLOAD
    -- AutoDrive.MODE_BGA not allowed
}

function AutoDrive:onAllModsLoaded()
	-- ADThirdPartyModsManager:load()
end

function AutoDrive:restartMySavegame()
	if g_server then
		restartApplication(true, " -autoStartSavegameId 1")
	end
end

function AutoDrive:loadMap(name)
	Logging.info("[AD] Start register later loaded mods...")
    --ADThirdPartyModsManager:load()
	-- second iteration to register AD to vehicle types which where loaded after AD
    AutoDriveRegister.register()
    AutoDriveRegister.registerVehicleData()
	Logging.info("[AD] Start register later loaded mods end")

	addConsoleCommand('restartMySavegame', 'Restart my savegame', 'restartMySavegame', self)

	if g_server ~= nil then
		AutoDrive.AutoDriveSync = AutoDriveSync.new(g_server ~= nil, g_client ~= nil)
		AutoDrive.AutoDriveSync:register(false)
	end

	AutoDrive:loadGUI()

	Logging.info("[AD] Map title: %s", g_currentMission.missionInfo.map.title)

	AutoDrive.loadedMap = g_currentMission.missionInfo.map.title
	AutoDrive.loadedMap = string.gsub(AutoDrive.loadedMap, " ", "_")
	AutoDrive.loadedMap = string.gsub(AutoDrive.loadedMap, "%.", "_")
	AutoDrive.loadedMap = string.gsub(AutoDrive.loadedMap, ",", "_")
	AutoDrive.loadedMap = string.gsub(AutoDrive.loadedMap, ":", "_")
	AutoDrive.loadedMap = string.gsub(AutoDrive.loadedMap, ";", "_")
	AutoDrive.loadedMap = string.gsub(AutoDrive.loadedMap, "'", "_")

	Logging.info("[AD] Parsed map title: %s", AutoDrive.loadedMap)

	-- That's probably bad, but for the moment I can't find another way to know if development controls are enabled
	local gameXmlFilePath = getUserProfileAppPath() .. "game.xml"
	if fileExists(gameXmlFilePath) then
		local gameXmlFile = loadXMLFile("game_XML", gameXmlFilePath)
		if gameXmlFile ~= nil then
			if hasXMLProperty(gameXmlFile, "game.development.controls") then
				AutoDrive.developmentControls = Utils.getNoNil(getXMLBool(gameXmlFile, "game.development.controls"), AutoDrive.developmentControls)
			end
		end
	end

    -- calculate the collision masks only once
    AutoDrive.collisionMaskFS19 = ADCollSensor.getMaskFS19()
    AutoDrive.collisionMaskTerrain = ADCollSensor.getMaskTerrain()
    AutoDrive.collisionMaskSplines = ADCollSensor.getMaskSplines()

	ADGraphManager:load()

	AutoDrive.loadStoredXML()

    AutoDrive:resetColorAssignment(0, true)     -- set default colors

    AutoDrive.readLocalSettingsFromXML()

	ADUserDataManager:load()

	AutoDrive.Hud = AutoDriveHud:new()

	if g_server ~= nil then
		ADUserDataManager:loadFromXml()
	end

	AutoDrive.Hud:loadHud()

	-- Save Configuration when saving savegame
	FSBaseMission.saveSavegame = Utils.appendedFunction(FSBaseMission.saveSavegame, AutoDrive.saveSavegame)

	LoadTrigger.onActivateObject = Utils.overwrittenFunction(LoadTrigger.onActivateObject, AutoDrive.onActivateObject)

	LoadTrigger.getIsActivatable = Utils.overwrittenFunction(LoadTrigger.getIsActivatable, AutoDrive.getIsActivatable)

	LoadTrigger.onFillTypeSelection = Utils.appendedFunction(LoadTrigger.onFillTypeSelection, AutoDrive.onFillTypeSelection)

	VehicleCamera.zoomSmoothly = Utils.overwrittenFunction(VehicleCamera.zoomSmoothly, AutoDrive.zoomSmoothly)

	LoadTrigger.load = Utils.overwrittenFunction(LoadTrigger.load, ADTriggerManager.loadTriggerLoad)

	LoadTrigger.delete = Utils.overwrittenFunction(LoadTrigger.delete, ADTriggerManager.loadTriggerDelete)

	Placeable.onBuy = Utils.appendedFunction(Placeable.onBuy, ADTriggerManager.onPlaceableBuy)

	MapHotspot.getIsVisible = Utils.overwrittenFunction(MapHotspot.getIsVisible, AutoDrive.MapHotspot_getIsVisible)

	IngameMapElement.mouseEvent = Utils.overwrittenFunction(IngameMapElement.mouseEvent, AutoDrive.ingameMapElementMouseEvent)

	-- FarmStats.getStatisticData = Utils.overwrittenFunction(FarmStats.getStatisticData, AutoDrive.FarmStats_getStatisticData)

	FSBaseMission.removeVehicle = Utils.prependedFunction(FSBaseMission.removeVehicle, AutoDrive.preRemoveVehicle)

	ADRoutesManager:load()

	ADDrawingManager:load()

	ADMessagesManager:load()

	ADHarvestManager:load()

    ADScheduler:load()

	ADInputManager:load()

	ADMultipleTargetsManager:load()
	-- AutoDrive.initTelemetry()
	ADBunkerSiloManager:load()

	InGameMenuAIFrame.onFrameOpen = Utils.appendedFunction(InGameMenuAIFrame.onFrameOpen, AutoDrive.onAIFrameOpen)
	InGameMenuAIFrame.onFrameClose = Utils.appendedFunction(InGameMenuAIFrame.onFrameClose, AutoDrive.onAIFrameClose)
	InGameMenuAIFrame.refreshContextInput = Utils.appendedFunction(InGameMenuAIFrame.refreshContextInput, AutoDrive.refreshContextInputAIFrame)
	BaseMission.draw = Utils.appendedFunction(BaseMission.draw, AutoDrive.drawBaseMission)
	PlaceableHotspot.getCategory = Utils.overwrittenFunction(PlaceableHotspot.getCategory, AutoDrive.PlaceableHotspotGetCategory)
	InGameMenuAIFrame.setMapSelectionItem = Utils.overwrittenFunction(InGameMenuAIFrame.setMapSelectionItem, AutoDrive.InGameMenuAIFrameSetMapSelectionItem)
	MapHotspot.getRenderLast = Utils.overwrittenFunction(MapHotspot.getRenderLast, AutoDrive.MapHotspotGetRenderLast)
end

function AutoDrive:onAIFrameOpen()
	AutoDrive.aiFrameOpen = true
	AutoDrive.aiFrame = self
	AutoDrive.aiFrameVehicle = g_currentMission.controlledVehicle
end

function AutoDrive:onAIFrameClose()
	AutoDrive.aiFrameOpen = false
	AutoDrive.aiFrame = nil
	AutoDrive.aiFrameVehicle = nil
end

function AutoDrive:refreshContextInputAIFrame()
	if AutoDrive.aiFrameOpen then
		local hotspot = self.currentHotspot
		if hotspot ~= nil then
			local vehicle = InGameMenuMapUtil.getHotspotVehicle(hotspot)
			local allowed = g_currentMission.accessHandler:canPlayerAccess(vehicle, g_currentMission.player)
			if vehicle ~= nil and vehicle.ad ~= nil and vehicle.ad.stateModule ~= nil and allowed then
                AutoDrive.aiFrameVehicle = vehicle
                AutoDrive.Hud.lastUIScale = 0
            end
		end
	end
end

function AutoDrive:drawBaseMission()
	if AutoDrive.aiFrameOpen then
		AutoDrive:drawRouteOnMap()
		AutoDrive.drawNetworkOnMap()
		if AutoDrive.aiFrameVehicle ~= nil then
            if AutoDrive.aiFrameVehicle.ad and AutoDrive.aiFrameVehicle.ad.stateModule then
                if AutoDrive.Hud ~= nil then
                    if AutoDrive.getSetting("showHUD") then
                        AutoDrive.Hud:drawHud(AutoDrive.aiFrameVehicle)
                    end
                end
            end
		end
	end
end

function AutoDrive:PlaceableHotspotGetCategory()
	if self.isADMarker then
		return MapHotspot.CATEGORY_STEERABLE--MapHotspot.CATEGORY_PLAYER
	end
	return PlaceableHotspot.CATEGORY_MAPPING[self.placeableType]
end

function AutoDrive:InGameMenuAIFrameSetMapSelectionItem(superFunc, hotspot)
	if hotspot ~= nil and hotspot.isADMarker and AutoDrive.aiFrameOpen then
		if AutoDrive.getSetting("showMarkersOnMap") and AutoDrive.getSetting("switchToMarkersOnMap") then
            local vehicle = AutoDrive.getADFocusVehicle()
			if vehicle ~= nil then
				AutoDriveHudInputEventEvent:sendFirstMarkerEvent(vehicle, hotspot.markerID)
				return
			end
		end
	end
	return superFunc(self, hotspot)
end

function AutoDrive:MapHotspotGetRenderLast(superFunc)
	if self.isADMarker then
		return true
	end
	return superFunc(self)
end

function AutoDrive.drawRouteOnMap()
	if AutoDrive.aiFrame == nil then
		return
	end
	local vehicle = AutoDrive.getADFocusVehicle()
	if vehicle == nil then
		return
	end

	if AutoDrive.courseOverlayId == nil then
		AutoDrive.courseOverlayId = createImageOverlay('data/shared/default_normal.dds')
	end

	local dx, dz, dx2D, dy2D, width, rotation, r, g, b

	local WPs, currentWp = vehicle.ad.drivePathModule:getWayPoints()
	if WPs ~= nil then
		local lastWp = nil
		local skips = 0
		for index, wp in pairs(WPs) do
			if skips == 0 then
				if lastWp ~= nil and index >= currentWp then
					local startX, startY, _, _ = AutoDrive.getScreenPosFromWorldPos(lastWp.x, lastWp.z)
					local endX, endY, _, _ = AutoDrive.getScreenPosFromWorldPos(wp.x, wp.z)

					if startX and startY and endX and endY then
						dx2D = endX - startX;
						dy2D = ( endY - startY ) / g_screenAspectRatio;
						width = MathUtil.vector2Length(dx2D, dy2D);

						dx = wp.x - lastWp.x;
						dz = wp.z - lastWp.z;
						rotation = MathUtil.getYRotationFromDirection(dx, dz) - math.pi * 0.5;

						local lineThickness = 2 / g_screenHeight
						setOverlayColor( AutoDrive.courseOverlayId, 0.3, 0.5, 0.56, 1)
						setOverlayRotation( AutoDrive.courseOverlayId, rotation, 0, 0)

						renderOverlay( AutoDrive.courseOverlayId, startX, startY, width, lineThickness )
					end
					setOverlayRotation( AutoDrive.courseOverlayId, 0, 0, 0 ) -- reset overlay rotation
				end
				lastWp = wp
			end
			skips = (skips + 1) % 1
		end
	end
end

function AutoDrive.drawNetworkOnMap()
	if AutoDrive.aiFrame == nil then
		return
	end

	if not AutoDrive.isEditorModeEnabled() then
		return
	end

	if AutoDrive.courseOverlayId == nil then
		AutoDrive.courseOverlayId = createImageOverlay('data/shared/default_normal.dds')
	end

	local dx, dz, dx2D, dy2D, width, rotation, r, g, b

	local isSubPrio = function(pointToTest)
        return bitAND(pointToTest.flags, AutoDrive.FLAG_SUBPRIO) > 0
    end

	local network = ADGraphManager:getWayPoints()
	if network ~= nil then
		for index, node in pairs(network) do
			if node.out ~= nil then
				for _, outNodeId in pairs(node.out) do
					local outNode = network[outNodeId]
					local startX, startY, _, _ = AutoDrive.getScreenPosFromWorldPos(node.x, node.z)
					local endX, endY, _, _ = AutoDrive.getScreenPosFromWorldPos(outNode.x, outNode.z)

					if startX and startY and endX and endY then
						dx2D = endX - startX;
						dy2D = ( endY - startY ) / g_screenAspectRatio;
						width = MathUtil.vector2Length(dx2D, dy2D);

						dx = outNode.x - node.x;
						dz = outNode.z - node.z;
						rotation = MathUtil.getYRotationFromDirection(dx, dz) - math.pi * 0.5;

						local lineThickness = 2 / g_screenHeight
						local r, g, b, a = unpack(AutoDrive.currentColors.ad_color_singleConnection)

						if isSubPrio(outNode) then
							r, g, b, a = unpack(AutoDrive.currentColors.ad_color_subPrioSingleConnection)
						end

						if ADGraphManager:isDualRoad(node, outNode) then
							r, g, b, a = unpack(AutoDrive.currentColors.ad_color_dualConnection)
							if isSubPrio(outNode) then
								r, g, b, a = unpack(AutoDrive.currentColors.ad_color_subPrioDualConnection)
							end
						elseif ADGraphManager:isReverseRoad(node, outNode) then
							r, g, b, a = unpack(AutoDrive.currentColors.ad_color_reverseConnection)
						end
						setOverlayColor( AutoDrive.courseOverlayId,  r, g, b, a)
						setOverlayRotation( AutoDrive.courseOverlayId, rotation, 0, 0)

						renderOverlay( AutoDrive.courseOverlayId, startX, startY, width, lineThickness )
					end
					setOverlayRotation( AutoDrive.courseOverlayId, 0, 0, 0 ) -- reset overlay rotation
				end
			end
		end
	end
end

function AutoDrive.getScreenPosFromWorldPos(worldX, worldZ)
	local objectX = (worldX + AutoDrive.aiFrame.ingameMapBase.worldCenterOffsetX) / AutoDrive.aiFrame.ingameMapBase.worldSizeX * 0.5 + 0.25
	local objectZ = (worldZ + AutoDrive.aiFrame.ingameMapBase.worldCenterOffsetZ) / AutoDrive.aiFrame.ingameMapBase.worldSizeZ * 0.5 + 0.25
	local x, y, _, _ = AutoDrive.aiFrame.ingameMapBase.layout:getMapObjectPosition(objectX, objectZ, 0, 0, 0, true)

	return x, y
end

function AutoDrive:init()

    -- AutoDrive.debugMsg(nil, "[AD] AutoDrive:init start...")

	if g_server == nil then
		-- Here we could ask to server the initial sync
		AutoDriveUserConnectedEvent.sendEvent()
	else
		ADGraphManager:checkYPositionIntegrity()
	end
	AutoDrive.updateDestinationsMapHotspots()
	AutoDrive:registerDestinationListener(AutoDrive, AutoDrive.updateDestinationsMapHotspots)

	if AutoDrive.notificationSample == nil then
		local fileName = Utils.getFilename( "sounds/notification_ok.ogg", AutoDrive.directory)
		AutoDrive.notificationSample = createSample("AutoDrive_Notification_ok")
		loadSample(AutoDrive.notificationSample, fileName, false)

		fileName = Utils.getFilename( "sounds/notification_warning.ogg", AutoDrive.directory)
		AutoDrive.notificationWarningSample = createSample("AutoDrive_Notification_warning")
		loadSample(AutoDrive.notificationWarningSample, fileName, false)

		fileName = Utils.getFilename( "sounds/click_up.ogg", AutoDrive.directory)
		AutoDrive.mouseClickSample = createSample("AutoDrive_mouseClick")
		loadSample(AutoDrive.mouseClickSample, fileName, false)

		fileName = Utils.getFilename( "sounds/recordWaypoint.ogg", AutoDrive.directory)
		AutoDrive.recordWaypointSample = createSample("AutoDrive_recordWaypoint")
		loadSample(AutoDrive.recordWaypointSample, fileName, false)

		fileName = Utils.getFilename( "sounds/selectedWayPoint.ogg", AutoDrive.directory)
		AutoDrive.selectedWayPointSample = createSample("AutoDrive_selectedWayPoint")
		loadSample(AutoDrive.selectedWayPointSample, fileName, false)
	end
end

function AutoDrive:saveSavegame()
--    Logging.info("[AD] AutoDrive:saveSavegame start")
	if g_server ~= nil then
--        Logging.info("[AD] AutoDrive:saveSavegame g_server ~= nil start")
--[[
		if ADGraphManager:hasChanges() or AutoDrive.HudChanged then
            Logging.info("[AD] AutoDrive:saveSavegame hasChanges or HudChanged")
			AutoDrive.saveToXML(AutoDrive.adXml)
			ADGraphManager:resetChanges()
			AutoDrive.HudChanged = false
		else
            Logging.info("[AD] AutoDrive:saveSavegame else hasChanges or HudChanged")
			if AutoDrive.adXml ~= nil then
                Logging.info("[AD] AutoDrive:saveSavegame AutoDrive.adXml ~= nil -> saveXMLFile")
				saveXMLFile(AutoDrive.adXml)
			end
		end
]]
        AutoDrive.saveToXML()
		ADUserDataManager:saveToXml()
--        Logging.info("[AD] AutoDrive:saveSavegame g_server ~= nil end")
	end
--    Logging.info("[AD] AutoDrive:saveSavegame end")
end

function AutoDrive:deleteMap()
	-- this function is called even befor the game is compeltely started in case you insert a wrong password for mp game, so we need to check that "mapHotspotsBuffer" and "unRegisterDestinationListener" are not nil
	if AutoDrive.mapHotspotsBuffer ~= nil then
		-- Removing and deleting all map hotspots
		for _, mh in pairs(AutoDrive.mapHotspotsBuffer) do
			-- g_currentMission:removeMapHotspot(mh)
			-- mh:delete()
		end
	end
	AutoDrive.mapHotspotsBuffer = {}
	AutoDrive.mapHotspotsBuffer = nil

	if (AutoDrive.unRegisterDestinationListener ~= nil) then
		AutoDrive:unRegisterDestinationListener(AutoDrive)
	end
	ADRoutesManager:delete()
end

function AutoDrive:keyEvent(unicode, sym, modifier, isDown)
	AutoDrive.leftCTRLmodifierKeyPressed = bitAND(modifier, Input.MOD_LCTRL) > 0
	AutoDrive.leftALTmodifierKeyPressed = bitAND(modifier, Input.MOD_LALT) > 0
	AutoDrive.leftLSHIFTmodifierKeyPressed = bitAND(modifier, Input.MOD_LSHIFT) > 0
	AutoDrive.isCAPSKeyActive = bitAND(modifier, Input.MOD_CAPS) > 0
	AutoDrive.rightCTRLmodifierKeyPressed = bitAND(modifier, Input.MOD_RCTRL) > 0
	AutoDrive.rightSHIFTmodifierKeyPressed = bitAND(modifier, Input.MOD_RSHIFT) > 0

    if AutoDrive.isInExtendedEditorMode() then
        if (AutoDrive.rightCTRLmodifierKeyPressed and AutoDrive.toggleSphrere == true) then
            AutoDrive.toggleSphrere = false
        elseif (AutoDrive.rightCTRLmodifierKeyPressed and AutoDrive.toggleSphrere == false) then
            AutoDrive.toggleSphrere = true
        end

        if (AutoDrive.leftCTRLmodifierKeyPressed or AutoDrive.leftALTmodifierKeyPressed) then
            AutoDrive.enableSphrere = true
        else
            AutoDrive.enableSphrere = AutoDrive.toggleSphrere
        end
    end
end

function AutoDrive:mouseEvent(posX, posY, isDown, isUp, button)
    local vehicle = AutoDrive.getADFocusVehicle()
	local mouseActiveForAutoDrive = (g_gui.currentGui == nil or AutoDrive.aiFrameOpen) and (g_inputBinding:getShowMouseCursor() == true)

	if not mouseActiveForAutoDrive then
		AutoDrive.lastButtonDown = nil
		return
	end

	if vehicle ~= nil and vehicle.ad ~= nil and vehicle.ad.nToolTipWait ~= nil then
		if vehicle.ad.sToolTip ~= "" then
			if vehicle.ad.nToolTipWait <= 0 then
				vehicle.ad.sToolTip = ""
			else
				vehicle.ad.nToolTipWait = vehicle.ad.nToolTipWait - 1
			end
		end
	end

	if (isDown or AutoDrive.lastButtonDown == button) or button == 0 or button > 3 then
        if vehicle and vehicle.ad and vehicle.ad.stateModule then
            if AutoDrive.getSetting("showHUD") then
                -- pass event to vehicle with active HUD
                AutoDrive.Hud:mouseEvent(vehicle, posX, posY, isDown, isUp, button)
            end
		end

		ADMessagesManager:mouseEvent(posX, posY, isDown, isUp, button)
	end

	if button > 0 and button <= 3 and isDown then
		AutoDrive.lastButtonDown = button
	elseif button > 0 and isUp and AutoDrive.lastButtonDown == button then
		AutoDrive.lastButtonDown = nil
	end
end

function AutoDrive:update(dt)
    if AutoDrive.scanDialogState == AutoDrive.SCAN_DIALOG_NONE and ADGraphManager:getWayPointsCount() == 0 then
        if g_server ~= nil and g_dedicatedServer == nil then
            -- open dialog
			if g_gui.currentGui == nil then
				-- AutoDrive.debugMsg(nil, "[AD] AutoDrive:update SCAN_DIALOG_OPEN")
				AutoDrive.onOpenScanConfirmation()
				AutoDrive.scanDialogState = AutoDrive.SCAN_DIALOG_OPEN
			end
			return
        else
            -- AutoDrive.debugMsg(nil, "[AD] AutoDrive:update dedi -> SCAN_DIALOG_RESULT_NO")
            AutoDrive.scanDialogState = AutoDrive.SCAN_DIALOG_RESULT_NO
        end
    end

    if AutoDrive.scanDialogState == AutoDrive.SCAN_DIALOG_OPEN then
        -- dialog still open
        return
    end

    if AutoDrive.scanDialogState == AutoDrive.SCAN_DIALOG_RESULT_YES then
        AutoDrive.scanDialogState = AutoDrive.SCAN_DIALOG_RESULT_DONE
        -- dialog closed with yes
        -- AutoDrive.debugMsg(nil, "[AD] AutoDrive:update SCAN_DIALOG_RESULT_YES")
        AutoDrive:adParseSplines()
        AutoDrive:createJunctionCommand()
    end

    if AutoDrive.scanDialogState == AutoDrive.SCAN_DIALOG_RESULT_NO then
        AutoDrive.scanDialogState = AutoDrive.SCAN_DIALOG_RESULT_DONE
        -- dialog closed with no
        -- AutoDrive.debugMsg(nil, "[AD] AutoDrive:update SCAN_DIALOG_RESULT_NO")
        AutoDrive.loadStoredXML(true)
    end

	if AutoDrive.isFirstRun == nil then
		AutoDrive.isFirstRun = false
		self:init()
                if AutoDrive.devAutoDriveInit ~= nil then
                    AutoDrive.devAutoDriveInit()
                end
	end

	if AutoDrive.getDebugChannelIsSet(AutoDrive.DC_NETWORKINFO) then
		if AutoDrive.debug.lastSentEvent ~= nil then
			AutoDrive.renderTable(0.3, 0.9, 0.009, AutoDrive.debug.lastSentEvent)
		end
	end
	if AutoDrive.getDebugChannelIsSet(AutoDrive.DC_SENSORINFO) and AutoDrive.getDebugChannelIsSet(AutoDrive.DC_VEHICLEINFO) then
		AutoDrive.debugDrawBoundingBoxForVehicles()
	end

    if AutoDrive.getSetting("showHUD") then
        AutoDrive.Hud:update(dt)
    end

	if g_server ~= nil then
		ADHarvestManager:update(dt)
		ADScheduler:update(dt)
		ADBunkerSiloManager:update(dt)
	end

	ADMessagesManager:update(dt)
	ADTriggerManager:update(dt)
	ADRoutesManager:update(dt)

	-- AutoDrive.handleTelemetry(dt)
end

function AutoDrive:draw()
	ADDrawingManager:draw()
	ADMessagesManager:draw()
end

function AutoDrive:preRemoveVehicle(vehicle)
	if vehicle.ad ~= nil and vehicle.ad.stateModule ~= nil then
        if vehicle.ad.stateModule:isActive() then
            vehicle:stopAutoDrive()
        end
        vehicle.ad.stateModule:disableCreationMode()
	end
end

function AutoDrive:FarmStats_saveToXMLFile(xmlFile, key)
    if not xmlFile:hasProperty(key) then
        return
    end
	-- key = key .. ".statistics"
	-- if self.statistics.driversTraveledDistance ~= nil then
		-- setXMLFloat(xmlFile, key .. ".driversTraveledDistance", self.statistics.driversTraveledDistance.total)
	-- end
end

function AutoDrive:FarmStats_loadFromXMLFile(xmlFileName, key)
	local xmlFile = XMLFile.load("TempXML", xmlFileName)
    if xmlFile == nil then
        return false
    end

	key = key .. ".statistics"
	-- self.statistics["driversTraveledDistance"].total = Utils.getNoNil(getXMLFloat(xmlFile, key .. ".driversTraveledDistance"), 0)

	-- self.statistics["driversTraveledDistance"].total = xmlFile:getFloat(key .. ".driversTraveledDistance", 0)
end

function AutoDrive:FarmStats_getStatisticData(superFunc)
	if superFunc ~= nil then
		superFunc(self)
	end
	if not g_currentMission.missionDynamicInfo.isMultiplayer or not g_currentMission.missionDynamicInfo.isClient then
		local firstCall = self.statisticDataRev["driversHired"] == nil or self.statisticDataRev["driversTraveledDistance"] == nil
		self:addStatistic("driversHired", nil, self:getSessionValue("driversHired"), nil, "%s")
		self:addStatistic("driversTraveledDistance", g_i18n:getMeasuringUnit(), g_i18n:getDistance(self:getSessionValue("driversTraveledDistance")), g_i18n:getDistance(self:getTotalValue("driversTraveledDistance")), "%.2f")
		if firstCall then
			-- Moving position of our stats
			local statsLength = #self.statisticData
			local dTdPosition = 14
			-- Backup of our new stats
			local driversHired = self.statisticData[statsLength - 1]
			local driversTraveledDistance = self.statisticData[statsLength]
			-- Moving 'driversHired' one position up
			self.statisticData[statsLength - 1] = self.statisticData[statsLength - 2]
			self.statisticData[statsLength - 2] = driversHired
			-- Moving 'driversTraveledDistance' to 14th position
			for i = statsLength - 1, dTdPosition, -1 do
				self.statisticData[i + 1] = self.statisticData[i]
			end
			self.statisticData[dTdPosition] = driversTraveledDistance
		end
	end
	return Utils.getNoNil(self.statisticData, {})
end
