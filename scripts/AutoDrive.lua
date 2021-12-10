AutoDrive = {}
AutoDrive.version = "2.0.0.0-RC1"

AutoDrive.directory = g_currentModDirectory

g_autoDriveUIFilename = AutoDrive.directory .. "textures/GUI_Icons.dds"
g_autoDriveDebugUIFilename = AutoDrive.directory .. "textures/gui_debug_Icons.dds"
g_autoDriveDebugUIFilename_BC7 = AutoDrive.directory .. "textures/gui_debug_Icons_BC7.dds"

AutoDrive.experimentalFeatures = {}
AutoDrive.experimentalFeatures.redLinePosition = false
AutoDrive.experimentalFeatures.telemetryOutput = false
AutoDrive.experimentalFeatures.enableRoutesManagerOnDediServer = false
AutoDrive.experimentalFeatures.detectGrasField = true
AutoDrive.experimentalFeatures.colorAssignmentMode = false
AutoDrive.experimentalFeatures.DrawAlternativ = false

AutoDrive.dynamicChaseDistance = true
AutoDrive.smootherDriving = true
AutoDrive.developmentControls = false

AutoDrive.mapHotspotsBuffer = {}

AutoDrive.drawHeight = 0.3
AutoDrive.drawDistance = getViewDistanceCoeff() * 50

AutoDrive.STAT_NAMES = {"driversTraveledDistance", "driversHired"}
for _, statName in pairs(AutoDrive.STAT_NAMES) do
	table.insert(FarmStats.STAT_NAMES, statName)
end

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

AutoDrive.actions = {
	{"ADToggleMouse", true, 1},
	{"ADToggleHud", true, 1},
	{"ADEnDisable", true, 1},
	{"ADSelectTarget", false, 0},
	{"ADSelectPreviousTarget", false, 0},
	{"ADSelectTargetUnload", false, 0},
	{"ADSelectPreviousTargetUnload", false, 0},
	{"ADActivateDebug", false, 0},
	{"ADDebugSelectNeighbor", false, 0},
	{"ADDebugChangeNeighbor", false, 0},
	{"ADDebugCreateConnection", false, 0},
	{"ADDebugCreateMapMarker", false, 0},
	{"ADDebugDeleteWayPoint", false, 0},
	{"ADDebugDeleteDestination", false, 3},
	{"ADSilomode", false, 0},
	{"ADOpenGUI", true, 2},
	{"ADCallDriver", false, 3},
	{"ADSelectNextFillType", false, 0},
	{"ADSelectPreviousFillType", false, 0},
	{"ADRecord", false, 0},
	{"AD_routes_manager", false, 0},
	{"ADGoToVehicle", false, 3},
	{"ADNameDriver", false, 0},
	{"ADRenameMapMarker", false, 0},
	{"ADSwapTargets", false, 0},
	{"AD_open_notification_history", false, 0},
	-- {"AD_open_colorSettings", false, 0},
	{"AD_continue", false, 3},
	{"ADParkVehicle", false, 0},
	{"AD_devAction", false, 0},
	{"ADRefuelVehicle", false, 0},
	{"ADToggleHudExtension", true, 1}
}

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
	ad_color_previewOk = {0.3, 0.9, 0, 1},
	ad_color_previewNotOk = {1, 0.1, 0, 1}
}

AutoDrive.currentColors = {} -- this will hold the current colors, derived from default colors above, overwritten by local settings

AutoDrive.fuelFillTypes = {
    "DIESEL",
    "DEF",
    "AIR",
    "ELECTRICCHARGE",
    "METHANE"
}

AutoDrive.nonFillableFillTypes = {
    "AIR" -- this fillType should not be transported
}

function AutoDrive:onAllModsLoaded()
	-- ADThirdPartyModsManager:load()
end

function AutoDrive:restartMySavegame()
	if g_server then
		restartApplication(" -autoStartSavegameId 1", true)
	end
end

function AutoDrive:loadMap(name)
	local index = 0
	Logging.info("[AD] Start register later loaded mods...")
    --ADThirdPartyModsManager:load()
	-- second iteration to register AD to vehicle types which where loaded after AD
    AutoDriveRegister.register()
    AutoDriveRegister.registerVehicleData()
	Logging.info("[AD] Start register later loaded mods end")
	index = index + 1
	Logging.info("[AutoDrive] Index: %d",index)

	addConsoleCommand('restartMySavegame', 'Restart my savegame', 'restartMySavegame', self)

	if g_server ~= nil then
		AutoDrive.AutoDriveSync = AutoDriveSync.new(g_server ~= nil, g_client ~= nil)
		AutoDrive.AutoDriveSync:register(false)
	end
	index = index + 1
	Logging.info("[AD] Index: %d",index)

	AutoDrive:loadGUI()

	Logging.info("[AD] Map title: %s", g_currentMission.missionInfo.map.title)

	AutoDrive.loadedMap = g_currentMission.missionInfo.map.title
	AutoDrive.loadedMap = string.gsub(AutoDrive.loadedMap, " ", "_")
	AutoDrive.loadedMap = string.gsub(AutoDrive.loadedMap, "%.", "_")
	AutoDrive.loadedMap = string.gsub(AutoDrive.loadedMap, ",", "_")
	AutoDrive.loadedMap = string.gsub(AutoDrive.loadedMap, ":", "_")
	AutoDrive.loadedMap = string.gsub(AutoDrive.loadedMap, ";", "_")
	AutoDrive.loadedMap = string.gsub(AutoDrive.loadedMap, "'", "_")
	index = index + 1
	Logging.info("[AD] Index: %d",index)


	Logging.info("[AD] Parsed map title: %s", AutoDrive.loadedMap)
	index = index + 1
	Logging.info("[AD] Index: %d",index)


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
	index = index + 1
	Logging.info("[AD] Index: %d",index)


	ADGraphManager:load()
	index = index + 1
	Logging.info("[AD] Index: %d",index)


	AutoDrive.loadStoredXML()
	index = index + 1
	Logging.info("[AD] Index: %d",index)


    AutoDrive:resetColorAssignment(0, true)     -- set default colors
	index = index + 1
	Logging.info("[AD] Index: %d",index)

    AutoDrive.readLocalSettingsFromXML()
	index = index + 1
	Logging.info("[AD] Index: %d",index)

    
	ADUserDataManager:load()
	if g_server ~= nil then
		ADUserDataManager:loadFromXml()
	end
	index = index + 1
	Logging.info("[AD] Index: %d",index)


	AutoDrive.Hud = AutoDriveHud:new()
	index = index + 1
	Logging.info("[AD] Index: %d",index)

	AutoDrive.Hud:loadHud()
	index = index + 1
	Logging.info("[AD] Index: %d",index)



	-- Save Configuration when saving savegame
	FSBaseMission.saveSavegame = Utils.appendedFunction(FSBaseMission.saveSavegame, AutoDrive.saveSavegame)
	index = index + 1
	Logging.info("[AD] Index: %d",index)

	LoadTrigger.onActivateObject = Utils.overwrittenFunction(LoadTrigger.onActivateObject, AutoDrive.onActivateObject)
	index = index + 1
	Logging.info("[AD] Index: %d",index)

	--AIDriveStrategyCombine.getDriveData = Utils.overwrittenFunction(AIDriveStrategyCombine.getDriveData, AutoDrive.getDriveData)
	index = index + 1
	Logging.info("[AD] Index: %d",index)

	LoadTrigger.getIsActivatable = Utils.overwrittenFunction(LoadTrigger.getIsActivatable, AutoDrive.getIsActivatable)
	index = index + 1
	Logging.info("[AD] Index: %d",index)

	LoadTrigger.onFillTypeSelection = Utils.appendedFunction(LoadTrigger.onFillTypeSelection, AutoDrive.onFillTypeSelection)
	index = index + 1
	Logging.info("[AD] Index: %d",index)

	VehicleCamera.zoomSmoothly = Utils.overwrittenFunction(VehicleCamera.zoomSmoothly, AutoDrive.zoomSmoothly)
	index = index + 1
	Logging.info("[AD] Index: %d",index)

	LoadTrigger.load = Utils.overwrittenFunction(LoadTrigger.load, ADTriggerManager.loadTriggerLoad)
    --LoadTrigger.load = Utils.appendedFunction(LoadTrigger.load, ADTriggerManager.loadTriggerLoad)
	index = index + 1
	Logging.info("[AD] Index: %d",index)

	LoadTrigger.delete = Utils.overwrittenFunction(LoadTrigger.delete, ADTriggerManager.loadTriggerDelete)
    -- LoadTrigger.delete = Utils.prependedFunction(LoadTrigger.delete, ADTriggerManager.loadTriggerDelete)
	index = index + 1
	Logging.info("[AD] Index: %d",index)

	Placeable.onBuy = Utils.appendedFunction(Placeable.onBuy, ADTriggerManager.onPlaceableBuy)
	index = index + 1
	Logging.info("[AD] Index: %d",index)

	MapHotspot.getIsVisible = Utils.overwrittenFunction(MapHotspot.getIsVisible, AutoDrive.MapHotspot_getIsVisible)
	index = index + 1
	Logging.info("[AD] Index: %d",index)
	IngameMapElement.mouseEvent = Utils.overwrittenFunction(IngameMapElement.mouseEvent, AutoDrive.ingameMapElementMouseEvent)
	index = index + 1
	Logging.info("[AD] Index: %d",index)


	--FarmStats.saveToXMLFile = Utils.appendedFunction(FarmStats.saveToXMLFile, AutoDrive.FarmStats_saveToXMLFile)
	--index = index + 1
	--Logging.info("[AD] Index: %d",index)

	--FarmStats.loadFromXMLFile = Utils.appendedFunction(FarmStats.loadFromXMLFile, AutoDrive.FarmStats_loadFromXMLFile)
	--index = index + 1
	--Logging.info("[AD] Index: %d",index)

	FarmStats.getStatisticData = Utils.overwrittenFunction(FarmStats.getStatisticData, AutoDrive.FarmStats_getStatisticData)
	index = index + 1
	Logging.info("[AD] Index: %d",index)

	FSBaseMission.removeVehicle = Utils.prependedFunction(FSBaseMission.removeVehicle, AutoDrive.preRemoveVehicle)
	index = index + 1
	Logging.info("[AD] Index: %d",index)

	ADRoutesManager:load()
	index = index + 1
	Logging.info("[AD] Index: %d",index)

	ADDrawingManager:load()
	index = index + 1
	Logging.info("[AD] Index: %d",index)

	ADMessagesManager:load()
	index = index + 1
	Logging.info("[AD] Index: %d",index)

	ADHarvestManager:load()
	index = index + 1
	Logging.info("[AD] Index: %d",index)

        ADScheduler:load()
	index = index + 1
	Logging.info("[AD] Index: %d",index)

	ADInputManager:load()
	index = index + 1
	Logging.info("[AD] Index: %d",index)

	ADMultipleTargetsManager:load()
	index = index + 1
	Logging.info("[AD] Index: %d",index)

	AutoDrive.initTelemetry()

	Logging.info("[AD] load map end: %d",index)
end

function AutoDrive:init()

    AutoDrive.debugMsg(nil, "[AD] AutoDrive:init start...")

	if g_server == nil then
		-- Here we could ask to server the initial sync
		AutoDriveUserConnectedEvent.sendEvent()
	else
		ADGraphManager:checkYPositionIntegrity()
	end

	AutoDrive.updateDestinationsMapHotspots()
	AutoDrive:registerDestinationListener(AutoDrive, AutoDrive.updateDestinationsMapHotspots)
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
			g_currentMission:removeMapHotspot(mh)
			mh:delete()
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
	local vehicle = g_currentMission.controlledVehicle
	local mouseActiveForAutoDrive = (g_gui.currentGui == nil) and (g_inputBinding:getShowMouseCursor() == true)
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

	if (isDown or AutoDrive.lastButtonDown == button) or button == 0 then
		if vehicle ~= nil and vehicle.ad ~= nil and vehicle.ad.stateModule ~= nil and AutoDrive.Hud.showHud == true then
			AutoDrive.Hud:mouseEvent(vehicle, posX, posY, isDown, isUp, button)
		end

		ADMessagesManager:mouseEvent(posX, posY, isDown, isUp, button)
	end

	if button > 0 and isDown then
		AutoDrive.lastButtonDown = button
	elseif button > 0 and isUp and AutoDrive.lastButtonDown == button then
		AutoDrive.lastButtonDown = nil
	end
end

function AutoDrive:update(dt)	
    if AutoDrive.scanDialogState == AutoDrive.SCAN_DIALOG_NONE and ADGraphManager:getWayPointsCount() == 0 then
        AutoDrive.scanDialogState = AutoDrive.SCAN_DIALOG_OPEN
        if g_server ~= nil and g_dedicatedServer == nil then
            -- open dialog
            AutoDrive.debugMsg(nil, "[AD] AutoDrive:update SCAN_DIALOG_OPEN")
            AutoDrive.onOpenScanConfirmation()
            return
        else
            AutoDrive.debugMsg(nil, "[AD] AutoDrive:update dedi -> SCAN_DIALOG_RESULT_YES")
            AutoDrive.scanDialogState = AutoDrive.SCAN_DIALOG_RESULT_YES
        end
    end

    if AutoDrive.scanDialogState == AutoDrive.SCAN_DIALOG_OPEN then
        -- dialog still open
        return
    end

    if AutoDrive.scanDialogState == AutoDrive.SCAN_DIALOG_RESULT_YES then
        AutoDrive.scanDialogState = AutoDrive.SCAN_DIALOG_RESULT_DONE
        -- dialog closed with yes
        AutoDrive.debugMsg(nil, "[AD] AutoDrive:update SCAN_DIALOG_RESULT_YES")
        AutoDrive:adParseSplines()
        AutoDrive:createJunctionCommand()
    end

    if AutoDrive.scanDialogState == AutoDrive.SCAN_DIALOG_RESULT_NO then
        AutoDrive.scanDialogState = AutoDrive.SCAN_DIALOG_RESULT_DONE
        -- dialog closed with no
        AutoDrive.debugMsg(nil, "[AD] AutoDrive:update SCAN_DIALOG_RESULT_NO")
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

	if AutoDrive.Hud ~= nil then
		if AutoDrive.Hud.showHud == true then
			AutoDrive.Hud:update(dt)
		end
	end

	if g_server ~= nil then
		ADHarvestManager:update(dt)
		ADScheduler:update(dt)
	end

	ADMessagesManager:update(dt)
	ADTriggerManager:update(dt)
	ADRoutesManager:update(dt)

	AutoDrive.handleTelemetry(dt)
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
    
	self.statistics["driversTraveledDistance"].total = xmlFile:getFloat(key .. ".driversTraveledDistance", 0)
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

addModEventListener(AutoDrive)
