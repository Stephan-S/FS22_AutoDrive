function AutoDrive.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(AIVehicle, specializations) and SpecializationUtil.hasSpecialization(Motorized, specializations) and SpecializationUtil.hasSpecialization(Drivable, specializations) and
        SpecializationUtil.hasSpecialization(Enterable, specializations)
end

function AutoDrive.registerEventListeners(vehicleType)
    for _, n in pairs(
        {
            "onUpdate",
            "onRegisterActionEvents",
            "onDelete",
            "onDraw",
            "onPreLoad",
            "onPostLoad",
            "onLoad",
            "saveToXMLFile",
            "onReadStream",
            "onWriteStream",
            "onReadUpdateStream",
            "onWriteUpdateStream",
            "onUpdateTick",
            "onStartAutoDrive",
            "onStopAutoDrive",
            "onPostAttachImplement",
            "onPreDetachImplement",
            "onEnterVehicle",
            "onLeaveVehicle"
        }
    ) do
        SpecializationUtil.registerEventListener(vehicleType, n, AutoDrive)
    end
end

function AutoDrive.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanMotorRun",                       AutoDrive.getCanMotorRun)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "leaveVehicle",                         AutoDrive.leaveVehicle)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsAIActive",                        AutoDrive.getIsAIActive)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsVehicleControlledByPlayer",       AutoDrive.getIsVehicleControlledByPlayer)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getActiveFarm",                        AutoDrive.getActiveFarm)
end

function AutoDrive.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "startAutoDrive", AutoDrive.startAutoDrive)
    SpecializationUtil.registerFunction(vehicleType, "stopAutoDrive", AutoDrive.stopAutoDrive)
    SpecializationUtil.registerFunction(vehicleType, "toggleMouse", AutoDrive.toggleMouse)
    SpecializationUtil.registerFunction(vehicleType, "updateWayPointsDistance", AutoDrive.updateWayPointsDistance)
    SpecializationUtil.registerFunction(vehicleType, "resetClosestWayPoint", AutoDrive.resetClosestWayPoint)
    SpecializationUtil.registerFunction(vehicleType, "resetWayPointsDistance", AutoDrive.resetWayPointsDistance)
    SpecializationUtil.registerFunction(vehicleType, "getWayPointsDistance", AutoDrive.getWayPointsDistance)
    SpecializationUtil.registerFunction(vehicleType, "getClosestWayPoint", AutoDrive.getClosestWayPoint)
    SpecializationUtil.registerFunction(vehicleType, "getClosestNotReversedWayPoint", AutoDrive.getClosestNotReversedWayPoint)
    SpecializationUtil.registerFunction(vehicleType, "getWayPointsInRange", AutoDrive.getWayPointsInRange)
    SpecializationUtil.registerFunction(vehicleType, "getWayPointIdsInRange", AutoDrive.getWayPointIdsInRange)
    SpecializationUtil.registerFunction(vehicleType, "onDrawEditorMode", AutoDrive.onDrawEditorMode)
    SpecializationUtil.registerFunction(vehicleType, "onDrawPreviews", AutoDrive.onDrawPreviews)
    SpecializationUtil.registerFunction(vehicleType, "updateClosestWayPoint", AutoDrive.updateClosestWayPoint)
end

function AutoDrive.registerEvents(vehicleType)
    SpecializationUtil.registerEvent(vehicleType, "onStartAutoDrive")
    SpecializationUtil.registerEvent(vehicleType, "onStopAutoDrive")
end

function AutoDrive:onRegisterActionEvents(_, isOnActiveVehicle)
    local registerEvents = isOnActiveVehicle
    if self.ad ~= nil then
        registerEvents = registerEvents or self == g_currentMission.controlledVehicle
    end

    -- only in active vehicle
    if registerEvents then
        -- attach our actions
        local _, eventName
        local toggleButton = false
        local showF1Help = AutoDrive.getSetting("showHelp")
        for _, action in pairs(AutoDrive.actions) do
            _, eventName = InputBinding.registerActionEvent(g_inputBinding, action[1], self, ADInputManager.onActionCall, toggleButton, true, false, true)
            g_inputBinding:setActionEventTextVisibility(eventName, action[2] and showF1Help)
            if showF1Help then
                g_inputBinding:setActionEventTextPriority(eventName, action[3])
            end
        end
    end
end

function AutoDrive.initSpecialization()
    -- print("Calling AutoDrive initSpecialization")
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("AutoDrive")

    schema:register(XMLValueType.FLOAT, "vehicle.AutoDrive#followDistance", "Follow distance for harveste unloading", 1)
    schema:setXMLSpecializationType()

    
    local schemaSavegame = Vehicle.xmlSchemaSavegame

    for settingName, setting in pairs(AutoDrive.settings) do
        if setting.isVehicleSpecific then
            schemaSavegame:register(XMLValueType.INT, "vehicles.vehicle(?).AutoDrive#" .. settingName, setting.text, setting.default)
        end
    end
    
    schemaSavegame:register(XMLValueType.STRING, "vehicles.vehicle(?).AutoDrive#groups", "groups")
    schemaSavegame:register(XMLValueType.INT, "vehicles.vehicle(?).AutoDrive#mode", "mode")
    schemaSavegame:register(XMLValueType.INT, "vehicles.vehicle(?).AutoDrive#firstMarker", "firstMarker")
    schemaSavegame:register(XMLValueType.INT, "vehicles.vehicle(?).AutoDrive#secondMarker", "secondMarker")
    schemaSavegame:register(XMLValueType.INT, "vehicles.vehicle(?).AutoDrive#fillType", "fillType")
    schemaSavegame:register(XMLValueType.INT, "vehicles.vehicle(?).AutoDrive#loopCounter", "loopCounter")
    schemaSavegame:register(XMLValueType.INT, "vehicles.vehicle(?).AutoDrive#speedLimit", "speedLimit")
    schemaSavegame:register(XMLValueType.INT, "vehicles.vehicle(?).AutoDrive#fieldSpeedLimit", "fieldSpeedLimit")
    schemaSavegame:register(XMLValueType.STRING, "vehicles.vehicle(?).AutoDrive#driverName", "driverName")
    schemaSavegame:register(XMLValueType.BOOL, "vehicles.vehicle(?).AutoDrive#lastActive", "lastActive")
    schemaSavegame:register(XMLValueType.BOOL, "vehicles.vehicle(?).AutoDrive#AIVElastActive", "AIVElastActive")
    schemaSavegame:register(XMLValueType.INT, "vehicles.vehicle(?).AutoDrive#parkDestination", "parkDestination")
    schemaSavegame:register(XMLValueType.INT, "vehicles.vehicle(?).AutoDrive#bunkerUnloadType", "bunkerUnloadType")
    schemaSavegame:register(XMLValueType.BOOL, "vehicles.vehicle(?).AutoDrive#automaticUnloadTarget", "automaticUnloadTarget")
    schemaSavegame:register(XMLValueType.BOOL, "vehicles.vehicle(?).AutoDrive#automaticPickupTarget", "automaticPickupTarget")   
end

function AutoDrive:onPreLoad(savegame)
    if self.spec_autodrive == nil then
        self.spec_autodrive = AutoDrive
        -- AutoDrive.debugMsg(self, "AutoDrive:onPreLoad")
        -- AutoDriveRegister.addModTranslations(g_i18n)
    end
end

function AutoDrive:onLoad(savegame)
    -- This will run before initial MP sync
    if self.ad == nil then
        self.ad = {}
    end
    self.ad.dirtyFlag = self:getNextDirtyFlag()
    self.ad.smootherDriving = {}
    self.ad.smootherDriving.lastMaxSpeed = 0
    self.ad.groups = {}

    self.ad.distances = {}
    self.ad.distances.wayPoints = nil
    self.ad.distances.closest = {}
    self.ad.distances.closest.wayPoint = -1
    self.ad.distances.closest.distance = 0
    self.ad.distances.closestNotReverse = {}
    self.ad.distances.closestNotReverse.wayPoint = -1
    self.ad.distances.closestNotReverse.distance = 0

    self.ad.lastDrawPosition = {x = 0, z = 0}

    self.ad.stateModule = ADStateModule:new(self)
    self.ad.recordingModule = ADRecordingModule:new(self)
    self.ad.trailerModule = ADTrailerModule:new(self)
    self.ad.taskModule = ADTaskModule:new(self)
    self.ad.drivePathModule = ADDrivePathModule:new(self)
    self.ad.specialDrivingModule = ADSpecialDrivingModule:new(self)
    self.ad.collisionDetectionModule = ADCollisionDetectionModule:new(self)
    self.ad.pathFinderModule = PathFinderModule:new(self)

    self.ad.modes = {}
    self.ad.modes[AutoDrive.MODE_DRIVETO] = DriveToMode:new(self)
    self.ad.modes[AutoDrive.MODE_DELIVERTO] = UnloadAtMode:new(self)
    self.ad.modes[AutoDrive.MODE_PICKUPANDDELIVER] = PickupAndDeliverMode:new(self)
    self.ad.modes[AutoDrive.MODE_LOAD] = LoadMode:new(self)
    self.ad.modes[AutoDrive.MODE_BGA] = BGAMode:new(self)
    self.ad.modes[AutoDrive.MODE_UNLOAD] = CombineUnloaderMode:new(self)

    self.ad.onRouteToPark = false
    self.ad.onRouteToRefuel = false
    self.ad.isStoppingWithError = false

    self.ad.selectedNodeId = nil
    self.ad.nodeToMoveId = nil
    self.ad.hoveredNodeId = nil
    self.ad.newcreated = nil
    self.ad.sectionWayPoints = {}
end

function AutoDrive:onPostLoad(savegame)
    -- This will run before initial MP sync
    --print("Running post load for vehicle: " .. self:getName())
    if self.ad == nil then
        return
    end

    for groupName, _ in pairs(ADGraphManager:getGroups()) do
        self.ad.groups[groupName] = false
    end

    if self.isServer then
        if savegame ~= nil then

-- Logging.info("[AD] AutoDrive:onPostLoad savegame.xmlFile ->%s<-", tostring(savegame.xmlFile))
            local xmlFile = savegame.xmlFile
            -- local xmlFile = loadXMLFile("vehicleXML", savegame.xmlFile)
            local key = savegame.key .. ".AutoDrive"
-- Logging.info("[AD] AutoDrive:onPostLoad key ->%s<-", tostring(key))
            -- print("Trying to load xml keys from: " .. key)

            self.ad.stateModule:readFromXMLFile(xmlFile, key)
            AutoDrive.readVehicleSettingsFromXML(self, xmlFile, key)

            if xmlFile:hasProperty(key) then
                local groupString = xmlFile:getValue(key .. "#groups")
                if groupString ~= nil then
                    local groupTable = groupString:split(";")
                    for _, groupCombined in pairs(groupTable) do
                        local groupNameAndBool = groupCombined:split(",")
                        if tonumber(groupNameAndBool[2]) >= 1 then
                            self.ad.groups[groupNameAndBool[1]] = true
                        else
                            self.ad.groups[groupNameAndBool[1]] = false
                        end
                    end
                end
            end            
        end

        self.ad.noMovementTimer = AutoDriveTON:new()
        self.ad.driveForwardTimer = AutoDriveTON:new()
    end

    if self.spec_pipe ~= nil and self.spec_enterable ~= nil and self.spec_combine ~= nil then
        ADHarvestManager:registerHarvester(self)
    end

    if self.ad.settings == nil then
        AutoDrive.copySettingsToVehicle(self)
    end

    -- Pure client side state
    self.ad.nToolTipWait = 300
    self.ad.sToolTip = ""
    self.ad.destinationFilterText = ""

    if AutoDrive.showingHud ~= nil then
        self.ad.showingHud = AutoDrive.showingHud
    else
        self.ad.showingHud = true
    end
    self.ad.showingMouse = false

    self.ad.lastMouseState = false

    -- Creating a new transform on front of the vehicle
    self.ad.frontNode = createTransformGroup(self:getName() .. "_frontNode")
    link(self.components[1].node, self.ad.frontNode)
    setTranslation(self.ad.frontNode, 0, 0, self.size.length / 2 + self.size.lengthOffset + 0.75)
    self.ad.frontNodeGizmo = DebugGizmo:new()
    self.ad.debug = RingQueue:new()
    local x, y, z = getWorldTranslation(self.components[1].node)
    self.ad.lastDrawPosition = {x = x, z = z}

    if self.spec_enterable ~= nil and self.spec_enterable.cameras ~= nil then
        for _, camera in pairs(self.spec_enterable.cameras) do
            camera.storedIsRotatable = camera.isRotatable
        end
    end
end

function AutoDrive:onWriteStream(streamId, connection)
    if self.ad == nil then
        return
    end

    local count = 0
    for _, setting in pairs(AutoDrive.settings) do
        if setting ~= nil and setting.isVehicleSpecific and not setting.isUserSpecific then
            count = count + 1
        end
    end

    streamWriteUInt16(streamId, count)

    for settingName, setting in pairs(AutoDrive.settings) do
        if setting ~= nil and setting.isVehicleSpecific and not setting.isUserSpecific then
            streamWriteString(streamId, settingName)
            streamWriteUInt16(streamId, AutoDrive.getSettingState(settingName, self))
        end
    end

    self.ad.stateModule:writeStream(streamId)
end

function AutoDrive:onReadStream(streamId, connection)
    if self.ad == nil then
        return
    end

    local count = streamReadUInt16(streamId)
    for i = 1, count do
        local settingName = streamReadString(streamId)
        local value = streamReadUInt16(streamId)
        self.ad.settings[settingName].current = value
        self.ad.settings[settingName].new = value
    end

    self.ad.stateModule:readStream(streamId)
end

function AutoDrive:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
    -- waypoints distances are updated once every ~2 frames
    -- self:resetClosestWayPoint()
    -- if we want to update distances every frame, when lines drawing is enabled, we can move this at the end of onDraw function

    if AutoDrive.isEditorShowEnabled() then
        local x, y, z = getWorldTranslation(self.components[1].node)
        local distance = MathUtil.vector2Length(x - self.ad.lastDrawPosition.x, z - self.ad.lastDrawPosition.z)
        if distance > AutoDrive.drawDistance / 2 then
            self.ad.lastDrawPosition = {x = x, z = z}
            self:resetWayPointsDistance()
        end
    else
        self:resetWayPointsDistance()
    end

    if self.isServer then
        self.ad.recordingModule:updateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)

        local spec = self.spec_aiVehicle
        if self:getIsAIActive() and spec.startedFarmId ~= nil and spec.startedFarmId > 0 and self.ad.stateModule:isActive() then
            local driverWages = AutoDrive.getSetting("driverWages")
            local difficultyMultiplier = g_currentMission.missionInfo.buyPriceMultiplier
            local price = -dt * difficultyMultiplier * (driverWages) * 0.001 --spec.pricePerMS
            --price = price + (dt * difficultyMultiplier * 0.001)   -- add the price which AI internal already substracted - no longer required for FS22
            g_currentMission:addMoney(price, spec.startedFarmId, MoneyType.AI, true)
        end
    end

    if self.ad.lastMouseState ~= g_inputBinding:getShowMouseCursor() then
        self:toggleMouse()
    end
end

function AutoDrive:onReadUpdateStream(streamId, timestamp, connection)
    if self.ad == nil then
        return
    end
    if connection:getIsServer() then
        if streamReadBool(streamId) then
            self.ad.stateModule:readUpdateStream(streamId)
        end
    end
end

function AutoDrive:onWriteUpdateStream(streamId, connection, dirtyMask)
    if self.ad == nil then
        return
    end
    if not connection:getIsServer() then
        if streamWriteBool(streamId, bitAND(dirtyMask, self.ad.dirtyFlag) ~= 0) then
            self.ad.stateModule:writeUpdateStream(streamId)
        end
    end
end

function AutoDrive:onUpdate(dt)
    if self.isServer and self.ad.stateModule:isActive() then
        self.ad.recordingModule:update(dt)
        self.ad.taskModule:update(dt)
        if self.lastMovedDistance > 0 then
            g_currentMission:farmStats(self:getOwnerFarmId()):updateStats("driversTraveledDistance", self.lastMovedDistance * 0.001)
        end
    end

    self.ad.stateModule:update(dt)

    ADSensor:handleSensors(self, dt)

    if not self.ad.stateModule:isActive() and self.ad.taskModule:getNumberOfTasks() > 0 then
        self.ad.taskModule:abortAllTasks()
    end

    AutoDrive.updateAutoDriveLights(self)

    --For 'legacy' purposes, this value should be kept since other mods already test for this:
    self.ad.mapMarkerSelected = self.ad.stateModule:getFirstMarkerId()
    self.ad.mapMarkerSelected_Unload = self.ad.stateModule:getSecondMarkerId()

    if self.ad.isCombine then
        AutoDrive.getLengthOfFieldInFront(self)
    end
end

function AutoDrive:saveToXMLFile(xmlFile, key, usedModNames)
    if self.ad == nil then
        return
    end
    local adKey = string.gsub(key, "FS22_AutoDrive.AutoDrive", "AutoDrive")
    
    --if not xmlFile:hasProperty(key) then
        --xmlFile:setValue(adKey, {})
        --return
    --end
    
    self.ad.stateModule:saveToXMLFile(xmlFile, adKey)

    for settingName, setting in pairs(AutoDrive.settings) do
        if setting.isVehicleSpecific and self.ad.settings ~= nil and self.ad.settings[settingName] ~= nil then
            xmlFile:setValue(adKey .. "#" .. settingName, self.ad.settings[settingName].current)
        end
    end

    if self.ad.groups ~= nil then
        local combinedString = ""
        for groupName, _ in pairs(ADGraphManager:getGroups()) do
            for myGroupName, value in pairs(self.ad.groups) do
                if groupName == myGroupName then
                    if string.len(combinedString) > 0 then
                        combinedString = combinedString .. ";"
                    end
                    if value == true then
                        combinedString = combinedString .. myGroupName .. ",1"
                    else
                        combinedString = combinedString .. myGroupName .. ",0"
                    end
                end
            end
        end
        xmlFile:setValue(adKey .. "#groups", combinedString)
    end
end

function AutoDrive:onDraw()
    if self.ad.showingHud ~= AutoDrive.Hud.showHud then
        AutoDrive.Hud:toggleHud(self)
    end

    if AutoDrive.Hud ~= nil then
        if AutoDrive.Hud.showHud == true then
            AutoDrive.Hud:drawHud(self)
        end
    end

    if AutoDrive.getSetting("showNextPath") == true then
        local sWP = self.ad.stateModule:getCurrentWayPoint()
        local eWP = self.ad.stateModule:getNextWayPoint()
        if sWP ~= nil and eWP ~= nil then
            --draw line with direction markers (arrow)
            ADDrawingManager:addLineTask(sWP.x, sWP.y, sWP.z, eWP.x, eWP.y, eWP.z, unpack(AutoDrive.currentColors.ad_color_currentConnection))
            ADDrawingManager:addArrowTask(sWP.x, sWP.y, sWP.z, eWP.x, eWP.y, eWP.z, ADDrawingManager.arrows.position.start, unpack(AutoDrive.currentColors.ad_color_currentConnection))
        end
    end

    if (AutoDrive.isEditorModeEnabled() or AutoDrive.isEditorShowEnabled()) then
        self:onDrawEditorMode()
        if AutoDrive.splineInterpolation ~= nil and AutoDrive.splineInterpolation.valid then
            self:onDrawPreviews()
        end
    end    

    if AutoDrive.experimentalFeatures.redLinePosition and AutoDrive.getDebugChannelIsSet(AutoDrive.DC_VEHICLEINFO) and self.ad.frontNodeGizmo ~= nil then
        self.ad.frontNodeGizmo:createWithNode(self.ad.frontNode, getName(self.ad.frontNode), false)
        self.ad.frontNodeGizmo:draw()
    end

    local x, y, z = getWorldTranslation(self.components[1].node)
    if AutoDrive.getDebugChannelIsSet(AutoDrive.DC_PATHINFO) then
        for _, otherVehicle in pairs(g_currentMission.vehicles) do
            if otherVehicle ~= nil and otherVehicle.ad ~= nil and otherVehicle.ad.drivePathModule ~= nil and otherVehicle.ad.drivePathModule:getWayPoints() ~= nil and not otherVehicle.ad.drivePathModule:isTargetReached() then
                local currentIndex = otherVehicle.ad.drivePathModule:getCurrentWayPointIndex()

                local lastPoint = nil
                for index, point in ipairs(otherVehicle.ad.drivePathModule:getWayPoints()) do
                    if point.isPathFinderPoint and index >= currentIndex and lastPoint ~= nil and MathUtil.vector2Length(x - point.x, z - point.z) < 160 then
                        ADDrawingManager:addLineTask(lastPoint.x, lastPoint.y, lastPoint.z, point.x, point.y, point.z, 1, 0.09, 0.09)
                        ADDrawingManager:addArrowTask(lastPoint.x, lastPoint.y, lastPoint.z, point.x, point.y, point.z, ADDrawingManager.arrows.position.start, 1, 0.09, 0.09)

                        if AutoDrive.getSettingState("lineHeight") == 1 then
                            local gy = point.y - AutoDrive.drawHeight + 4
                            local ty = lastPoint.y - AutoDrive.drawHeight + 4
                            ADDrawingManager:addLineTask(point.x, gy, point.z, point.x, point.y, point.z, 1, 0.09, 0.09)
                            ADDrawingManager:addSphereTask(point.x, gy, point.z, 3, 1, 0.09, 0.09, 0.15)
                            ADDrawingManager:addLineTask(lastPoint.x, ty, lastPoint.z, point.x, gy, point.z, 1, 0.09, 0.09)
                            ADDrawingManager:addArrowTask(lastPoint.x, ty, lastPoint.z, point.x, gy, point.z, ADDrawingManager.arrows.position.start, 1, 0.09, 0.09)
                        else
                            local gy = point.y - AutoDrive.drawHeight - 4
                            local ty = lastPoint.y - AutoDrive.drawHeight - 4
                            ADDrawingManager:addLineTask(point.x, gy, point.z, point.x, point.y, point.z, 1, 0.09, 0.09)
                            ADDrawingManager:addSphereTask(point.x, gy, point.z, 3, 1, 0.09, 0.09, 0.15)
                            ADDrawingManager:addLineTask(lastPoint.x, ty, lastPoint.z, point.x, gy, point.z, 1, 0.09, 0.09)
                            ADDrawingManager:addArrowTask(lastPoint.x, ty, lastPoint.z, point.x, gy, point.z, ADDrawingManager.arrows.position.start, 1, 0.09, 0.09)
                        end
                    end
                    lastPoint = point
                end
            end
        end

        for _, otherVehicle in pairs(g_currentMission.vehicles) do
            if otherVehicle ~= nil and otherVehicle.ad ~= nil and otherVehicle.ad.drivePathModule ~= nil and otherVehicle.ad.modes[AutoDrive.MODE_UNLOAD]:getBreadCrumbs() ~= nil then
                local lastPoint = nil
                for index, point in ipairs(otherVehicle.ad.modes[AutoDrive.MODE_UNLOAD]:getBreadCrumbs().items) do
                    if lastPoint ~= nil and MathUtil.vector2Length(x - point.x, z - point.z) < 80 then
                        ADDrawingManager:addLineTask(lastPoint.x, lastPoint.y, lastPoint.z, point.x, point.y, point.z, 1.0, 0.769, 0.051)
                        ADDrawingManager:addArrowTask(lastPoint.x, lastPoint.y, lastPoint.z, point.x, point.y, point.z, ADDrawingManager.arrows.position.start, 1.0, 0.769, 0.051)

                        if AutoDrive.getSettingState("lineHeight") == 1 then
                            local gy = point.y - AutoDrive.drawHeight + 4
                            local ty = lastPoint.y - AutoDrive.drawHeight + 4
                            ADDrawingManager:addLineTask(point.x, gy, point.z, point.x, point.y, point.z, 1.0, 0.769, 0.051)
                            ADDrawingManager:addSphereTask(point.x, gy, point.z, 3, 1.0, 0.769, 0.051, 0.15)
                            ADDrawingManager:addLineTask(lastPoint.x, ty, lastPoint.z, point.x, gy, point.z, 1.0, 0.769, 0.051)
                            ADDrawingManager:addArrowTask(lastPoint.x, ty, lastPoint.z, point.x, gy, point.z, ADDrawingManager.arrows.position.start, 1.0, 0.769, 0.051)
                        else
                            local gy = point.y - AutoDrive.drawHeight - 4
                            local ty = lastPoint.y - AutoDrive.drawHeight - 4
                            ADDrawingManager:addLineTask(point.x, gy, point.z, point.x, point.y, point.z, 1.0, 0.769, 0.051)
                            ADDrawingManager:addSphereTask(point.x, gy, point.z, 3, 1.0, 0.769, 0.051, 0.15)
                            ADDrawingManager:addLineTask(lastPoint.x, ty, lastPoint.z, point.x, gy, point.z, 1.0, 0.769, 0.051)
                            ADDrawingManager:addArrowTask(lastPoint.x, ty, lastPoint.z, point.x, gy, point.z, ADDrawingManager.arrows.position.start, 1.0, 0.769, 0.051)
                        end
                    end
                    lastPoint = point
                end
            end
        end
    end
end

function AutoDrive:onDrawPreviews()    
    --if AutoDrive:checkForCollisionOnSpline() then
    local lastHeight = AutoDrive.splineInterpolation.startNode.y
    local lastWp = AutoDrive.splineInterpolation.startNode
    local arrowPosition = ADDrawingManager.arrows.position.middle
    local collisionFree = AutoDrive:checkForCollisionOnSpline()
    for wpId, wp in pairs(AutoDrive.splineInterpolation.waypoints) do
        if wpId ~= 1 and wpId < (#AutoDrive.splineInterpolation.waypoints - 1) then
            if math.abs(wp.y - lastHeight) > 1 then -- prevent point dropping into the ground in case of bridges etc
                wp.y = lastHeight
            end	
            
            if collisionFree then
                ADDrawingManager:addLineTask(lastWp.x, lastWp.y, lastWp.z, wp.x, wp.y, wp.z, unpack(AutoDrive.currentColors.ad_color_previewOk))
                ADDrawingManager:addArrowTask(lastWp.x, lastWp.y, lastWp.z, wp.x, wp.y, wp.z, arrowPosition, unpack(AutoDrive.currentColors.ad_color_previewOk))
            else
                ADDrawingManager:addLineTask(lastWp.x, lastWp.y, lastWp.z, wp.x, wp.y, wp.z, unpack(AutoDrive.currentColors.ad_color_previewNotOk))
                ADDrawingManager:addArrowTask(lastWp.x, lastWp.y, lastWp.z, wp.x, wp.y, wp.z, arrowPosition, unpack(AutoDrive.currentColors.ad_color_previewNotOk))
            end

            lastWp = {x = wp.x, y = wp.y, z = wp.z}
            lastHeight = wp.y
        end
    end

    local targetWp = AutoDrive.splineInterpolation.endNode
    if collisionFree then
        ADDrawingManager:addLineTask(lastWp.x, lastWp.y, lastWp.z, targetWp.x, targetWp.y, targetWp.z, unpack(AutoDrive.currentColors.ad_color_previewOk))
        ADDrawingManager:addArrowTask(lastWp.x, lastWp.y, lastWp.z, targetWp.x, targetWp.y, targetWp.z, arrowPosition, unpack(AutoDrive.currentColors.ad_color_previewOk))
    else
        ADDrawingManager:addLineTask(lastWp.x, lastWp.y, lastWp.z, targetWp.x, targetWp.y, targetWp.z, unpack(AutoDrive.currentColors.ad_color_previewNotOk))
        ADDrawingManager:addArrowTask(lastWp.x, lastWp.y, lastWp.z, targetWp.x, targetWp.y, targetWp.z, arrowPosition, unpack(AutoDrive.currentColors.ad_color_previewNotOk))
    end
end

function AutoDrive:onPostAttachImplement(attachable, inputJointDescIndex, jointDescIndex)
    if attachable["spec_FS19_addon_strawHarvest.strawHarvestPelletizer"] ~= nil then
        attachable.isPremos = true
        -- attachable.getIsBufferCombine = function()
            -- return false
        -- end
    end
    if (attachable.spec_pipe ~= nil and attachable.spec_combine ~= nil) or attachable.isPremos then
        attachable.isTrailedHarvester = true
        attachable.trailingVehicle = self
        ADHarvestManager:registerHarvester(attachable)
        self.ad.isCombine = true
        self.ad.attachableCombine = attachable
        attachable.ad = self.ad
    end

    if attachable ~= nil and AutoDrive:hasAL(attachable) then
        -- AutoLoad
        local currentFillType = AutoDrive:getALCurrentFillType(attachable)
        if currentFillType ~= nil then
            self.ad.stateModule:setFillType(currentFillType)
            if g_currentMission.controlledVehicle ~= nil and g_currentMission.controlledVehicle.ad ~= nil and g_currentMission.controlledVehicle == self then
                AutoDrive.Hud.lastUIScale = 0
            end
        end
    else
        local supportedFillTypes = {}
        local trailers, trailerCount = AutoDrive.getAllUnits(self)
        for index, trailer in ipairs(trailers) do
            if trailer.getFillUnits ~= nil then
                for fillUnitIndex, _ in pairs(trailer:getFillUnits()) do
                    if trailer.getFillUnitSupportedFillTypes ~= nil then
                        for fillType, supported in pairs(trailer:getFillUnitSupportedFillTypes(fillUnitIndex)) do
                            if index == 1 then -- hide fuel types for 1st vehicle
                                local fillTypeName = g_fillTypeManager:getFillTypeNameByIndex(fillType)
                                if table.contains(AutoDrive.fuelFillTypes, fillTypeName) then
                                    supported = false
                                end
                            end
                            if supported then
                                table.insert(supportedFillTypes, fillType)
                            end
                        end
                    end
                end
            end
        end

        local storedSelectedFillType = self.ad.stateModule:getFillType()
        if #supportedFillTypes > 0 and not table.contains(supportedFillTypes, storedSelectedFillType) then
            self.ad.stateModule:setFillType(supportedFillTypes[1])
            if g_currentMission.controlledVehicle ~= nil and g_currentMission.controlledVehicle.ad ~= nil and g_currentMission.controlledVehicle == self then
                AutoDrive.Hud.lastUIScale = 0
            end
        end
    end
    AutoDrive.getFrontToolWidth(self, true)
end

function AutoDrive:onPreDetachImplement(implement)
    local attachable = implement.object
    if attachable.isTrailedHarvester and attachable.trailingVehicle == self then
        attachable.ad = nil
        self.ad.isCombine = false
        self.ad.attachableCombine = nil
        ADHarvestManager:unregisterHarvester(attachable)
        attachable.isTrailedHarvester = false
        attachable.trailingVehicle = nil
        if attachable.isPremos then
            -- attachable.getIsBufferCombine = nil
        end
    end
    if self.ad ~= nil then
        self.ad.frontToolWidth = nil
        self.ad.frontToolLength = nil
    end
end

function AutoDrive:onEnterVehicle()
    local trailers, trailerCount = AutoDrive.getAllUnits(self)
    -- AutoDrive.debugMsg(object, "AutoDrive:onEnterVehicle trailerCount %s", tostring(trailerCount))
    if trailerCount > 0 then
        -- AutoLoad
        local currentFillType = AutoDrive:getALCurrentFillType(trailers[1])
        if currentFillType ~= nil then
            self.ad.stateModule:setFillType(currentFillType)
        end
    end
    if g_currentMission.controlledVehicle ~= nil and g_currentMission.controlledVehicle.ad ~= nil and g_currentMission.controlledVehicle == self then
        AutoDrive.Hud.lastUIScale = 0
    end
end

function AutoDrive:onLeaveVehicle()
    if self.ad ~= nil and self.ad.stateModule ~= nil then
        self.ad.stateModule:disableCreationMode()
    end
end


function AutoDrive:onDelete()
    AutoDriveHud:deleteMapHotspot(self)
end

function AutoDrive:onDrawEditorMode()
    local isActive = self.ad.stateModule:isActive()
    local DrawingManager = ADDrawingManager

    local startNode = self.ad.frontNode
    if not AutoDrive.experimentalFeatures.redLinePosition then
        startNode = self.components[1].node
    end
    local x1, y1, z1 = getWorldTranslation(startNode)

    local dy = y1 + 3.5 - AutoDrive.getSetting("lineHeight")
    local maxDistance = AutoDrive.drawDistance
    local arrowPosition = DrawingManager.arrows.position.start

    local previewDirection =
                    not AutoDrive.leftLSHIFTmodifierKeyPressed
                    and AutoDrive.leftCTRLmodifierKeyPressed
                    and not AutoDrive.leftALTmodifierKeyPressed
                    and not AutoDrive.rightSHIFTmodifierKeyPressed

    local previewSubPrio =
                    AutoDrive.leftLSHIFTmodifierKeyPressed
                    and not AutoDrive.leftCTRLmodifierKeyPressed
                    and not AutoDrive.leftALTmodifierKeyPressed
                    and not AutoDrive.rightSHIFTmodifierKeyPressed


    --Draw close destinations
    for _, marker in pairs(ADGraphManager:getMapMarkers()) do
        local wp = ADGraphManager:getWayPointById(marker.id)
        if MathUtil.vector2Length(wp.x - x1, wp.z - z1) < maxDistance then
            Utils.renderTextAtWorldPosition(wp.x, wp.y + 4, wp.z, marker.name, getCorrectTextSize(0.013), 0)
            DrawingManager:addMarkerTask(wp.x, wp.y + 0.45, wp.z)
        end
    end

    if ADGraphManager:getWayPointById(1) ~= nil and not AutoDrive.isEditorShowEnabled() then
        --Draw line to selected neighbor point
        local neighbour = self.ad.stateModule:getSelectedNeighbourPoint()
        if neighbour ~= nil then
            DrawingManager:addLineTask(x1, dy, z1, neighbour.x, neighbour.y, neighbour.z, 1, 1, 0)
        end

        --Draw line to closest point
        local closest, _ = self:getClosestWayPoint(true)
        local wp = ADGraphManager:getWayPointById(closest)
        if wp ~= nil then
            DrawingManager:addLineTask(x1, dy, z1, wp.x, wp.y, wp.z, unpack(AutoDrive.currentColors.ad_color_closestLine))
            DrawingManager:addSmallSphereTask(x1, dy, z1, unpack(AutoDrive.currentColors.ad_color_closestLine))
        end
    end

    local outPointsSeen = {}
    for _, point in pairs(self:getWayPointsInRange(0, maxDistance)) do
        local x = point.x
        local y = point.y
        local z = point.z
        local isSubPrio = ADGraphManager:getIsPointSubPrio(point.id)

        if AutoDrive.isInExtendedEditorMode() then
            arrowPosition = DrawingManager.arrows.position.middle
            if AutoDrive.enableSphrere == true then
                if AutoDrive.mouseIsAtPos(point, 0.01) then
                    DrawingManager:addSphereTask(x, y, z, 3, unpack(AutoDrive.currentColors.ad_color_hoveredNode))
                else
                    if point.id == self.ad.selectedNodeId then
                        DrawingManager:addSphereTask(x, y, z, 3, unpack(AutoDrive.currentColors.ad_color_selectedNode))
                    else
                        if isSubPrio then
                            DrawingManager:addSphereTask(x, y, z, 3, unpack(AutoDrive.currentColors.ad_color_subPrioNode))
                        else
                            if point.colors ~= nil then
                                DrawingManager:addSphereTask(x, y, z, 3, unpack(point.colors))
                            else
                                DrawingManager:addSphereTask(x, y, z, 3, unpack(AutoDrive.currentColors.ad_color_default))
                            end
                        end
                    end
                end

                -- If the lines are drawn above the vehicle, we have to draw a line to the reference point on the ground and a second cube there for moving the node position
                if AutoDrive.getSettingState("lineHeight") > 1 then
                    local gy = y - AutoDrive.drawHeight - AutoDrive.getSetting("lineHeight")
                    DrawingManager:addLineTask(x, y, z, x, gy, z, unpack(AutoDrive.currentColors.ad_color_editorHeightLine))

                    if AutoDrive.mouseIsAtPos(point, 0.01) or AutoDrive.mouseIsAtPos({x = x, y = gy, z = z}, 0.01) then
                        DrawingManager:addSphereTask(x, gy, z, 3, unpack(AutoDrive.currentColors.ad_color_hoveredNode))
                    else
                        if point.id == self.ad.selectedNodeId then
                            DrawingManager:addSphereTask(x, gy, z, 3, unpack(AutoDrive.currentColors.ad_color_selectedNode))
                        else
                            if isSubPrio then
                                DrawingManager:addSphereTask(x, gy, z, 3, unpack(AutoDrive.currentColors.ad_color_subPrioNode))
                            else
                                DrawingManager:addSphereTask(x, gy, z, 3, unpack(AutoDrive.currentColors.ad_color_default))
                            end
                        end
                    end
                end

                -- draw previous and next points in different colors - note: sequence is important
                if point.out ~= nil and not isActive then
                    for _, neighbor in pairs(point.out) do
                        local nWp = ADGraphManager:getWayPointById(neighbor)
                        if nWp ~= nil then
                            if AutoDrive.mouseIsAtPos(nWp, 0.01) then
                                -- draw previous point in GOLDHOFER_PINK1
                                DrawingManager:addSphereTask(point.x, point.y, point.z, 3.4, unpack(AutoDrive.currentColors.ad_color_previousNode))
                            end
                            if AutoDrive.mouseIsAtPos(point, 0.01) then
                                -- draw next point
                                DrawingManager:addSphereTask(nWp.x, nWp.y, nWp.z, 3.2, unpack(AutoDrive.currentColors.ad_color_nextNode))
                            end
                        end
                    end
                end
            end
        end

-- draw connection lines
        if point.out ~= nil then

            for _, neighbor in pairs(point.out) do
                -- if a section is active, skip these connections, they are drawn below
                local skipSectionDraw = false
                if self.ad.sectionWayPoints ~= nil and #self.ad.sectionWayPoints > 2 then
                    if 
                        table.contains(self.ad.sectionWayPoints, point.id) 
                        and table.contains(self.ad.sectionWayPoints, neighbor) 
                        and (previewDirection or previewSubPrio) 
                        then
                        skipSectionDraw = true
                    end
                end
                
                table.insert(outPointsSeen, neighbor)
                local target = ADGraphManager:getWayPointById(neighbor)
                local targetIsSubPrio = ADGraphManager:getIsPointSubPrio(neighbor)
                if target ~= nil and not skipSectionDraw then
                    --check if outgoing connection is a dual way connection
                    local nWp = ADGraphManager:getWayPointById(neighbor)
                    if point.incoming == nil or table.contains(point.incoming, neighbor) then
                        --draw dual way line
                        if point.id > nWp.id then
                            if isSubPrio or targetIsSubPrio then
                                DrawingManager:addLineTask(x, y, z, nWp.x, nWp.y, nWp.z, unpack(AutoDrive.currentColors.ad_color_subPrioDualConnection))
                            else
                                DrawingManager:addLineTask(x, y, z, nWp.x, nWp.y, nWp.z, unpack(AutoDrive.currentColors.ad_color_dualConnection))
                            end
                        end
                    else
                        --draw line with direction markers (arrow)
                        if (nWp.incoming == nil or table.contains(nWp.incoming, point.id)) then
                            -- one way line
                            if isSubPrio or targetIsSubPrio then
                                DrawingManager:addLineTask(x, y, z, nWp.x, nWp.y, nWp.z, unpack(AutoDrive.currentColors.ad_color_subPrioSingleConnection))
                                DrawingManager:addArrowTask(x, y, z, nWp.x, nWp.y, nWp.z, arrowPosition, unpack(AutoDrive.currentColors.ad_color_subPrioSingleConnection))
                            else
                                DrawingManager:addLineTask(x, y, z, nWp.x, nWp.y, nWp.z, unpack(AutoDrive.currentColors.ad_color_singleConnection))
                                DrawingManager:addArrowTask(x, y, z, nWp.x, nWp.y, nWp.z, arrowPosition, unpack(AutoDrive.currentColors.ad_color_singleConnection))
                            end
                        else
                            -- reverse way line
                            DrawingManager:addLineTask(x, y, z, nWp.x, nWp.y, nWp.z, unpack(AutoDrive.currentColors.ad_color_reverseConnection))
                            DrawingManager:addArrowTask(x, y, z, nWp.x, nWp.y, nWp.z, arrowPosition, unpack(AutoDrive.currentColors.ad_color_reverseConnection))
                        end
                    end
                end
            end
        end

        --just a quick way to highlight single (forgotten) points with no connections
        if (#point.out == 0) and (#point.incoming == 0) and not table.contains(outPointsSeen, point.id) and point.colors == nil then
            y = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, 1, z) + 0.5
            DrawingManager:addCrossTask(x, y, z)
        end
    end

-- draw the section, with respect to preview types, active or next connections and SubPrio
    if (previewDirection or previewSubPrio) and self.ad.sectionWayPoints ~= nil and #self.ad.sectionWayPoints > 2 then
        local sectionPrio = ADGraphManager:getIsPointSubPrio(self.ad.sectionWayPoints[2])   -- 2nd WayPoint is the 1st in section and has the actual Prio
        local wayPointsDirection = ADGraphManager:getIsWayPointJunction(self.ad.sectionWayPoints[1], self.ad.sectionWayPoints[2])
        for i = 1, #self.ad.sectionWayPoints - 1 do
            local start = ADGraphManager:getWayPointById(self.ad.sectionWayPoints[i])
            local target = ADGraphManager:getWayPointById(self.ad.sectionWayPoints[i+1])

            if wayPointsDirection == 1 then
                if previewSubPrio then
                    if not sectionPrio then
                        DrawingManager:addLineTask(start.x, start.y, start.z, target.x, target.y, target.z, unpack(AutoDrive.currentColors.ad_color_subPrioSingleConnection))
                        DrawingManager:addArrowTask(start.x, start.y, start.z, target.x, target.y, target.z, arrowPosition, unpack(AutoDrive.currentColors.ad_color_subPrioSingleConnection))
                    else
                        DrawingManager:addLineTask(start.x, start.y, start.z, target.x, target.y, target.z, unpack(AutoDrive.currentColors.ad_color_singleConnection))
                        DrawingManager:addArrowTask(start.x, start.y, start.z, target.x, target.y, target.z, arrowPosition, unpack(AutoDrive.currentColors.ad_color_singleConnection))
                    end
                elseif previewDirection then
                    -- new direction backward
                    if not sectionPrio then
                        DrawingManager:addLineTask(target.x, target.y, target.z, start.x, start.y, start.z,  unpack(AutoDrive.currentColors.ad_color_singleConnection))       -- green
                        DrawingManager:addArrowTask(target.x, target.y, target.z, start.x, start.y, start.z, arrowPosition, unpack(AutoDrive.currentColors.ad_color_singleConnection))
                    else
                        DrawingManager:addLineTask(target.x, target.y, target.z, start.x, start.y, start.z,  unpack(AutoDrive.currentColors.ad_color_subPrioSingleConnection))    -- orange
                        DrawingManager:addArrowTask(target.x, target.y, target.z, start.x, start.y, start.z, arrowPosition, unpack(AutoDrive.currentColors.ad_color_subPrioSingleConnection))
                    end
                else
                end
            elseif wayPointsDirection == 2 then
                if previewSubPrio then
                    if not sectionPrio then
                        DrawingManager:addLineTask(target.x, target.y, target.z, start.x, start.y, start.z,  unpack(AutoDrive.currentColors.ad_color_subPrioSingleConnection))    -- orange
                        DrawingManager:addArrowTask(target.x, target.y, target.z, start.x, start.y, start.z, arrowPosition, unpack(AutoDrive.currentColors.ad_color_subPrioSingleConnection))
                    else
                        DrawingManager:addLineTask(target.x, target.y, target.z, start.x, start.y, start.z,  unpack(AutoDrive.currentColors.ad_color_singleConnection))       -- green
                        DrawingManager:addArrowTask(target.x, target.y, target.z, start.x, start.y, start.z, arrowPosition, unpack(AutoDrive.currentColors.ad_color_singleConnection))
                    end
                elseif previewDirection then
                    -- new direction dual
                    if not sectionPrio then
                        DrawingManager:addLineTask(start.x, start.y, start.z, target.x, target.y, target.z, unpack(AutoDrive.currentColors.ad_color_dualConnection))  -- blue
                    else
                        DrawingManager:addLineTask(start.x, start.y, start.z, target.x, target.y, target.z, unpack(AutoDrive.currentColors.ad_color_subPrioDualConnection))    -- dark orange
                    end
                else
                end
            elseif wayPointsDirection == 3 then
                if previewSubPrio then
                    if not sectionPrio then
                        DrawingManager:addLineTask(start.x, start.y, start.z, target.x, target.y, target.z, unpack(AutoDrive.currentColors.ad_color_subPrioDualConnection))    -- dark orange
                    else
                        DrawingManager:addLineTask(start.x, start.y, start.z, target.x, target.y, target.z, unpack(AutoDrive.currentColors.ad_color_dualConnection))    -- blue
                    end
                elseif previewDirection then
                    -- new direction forward
                    if not sectionPrio then
                        DrawingManager:addLineTask(start.x, start.y, start.z, target.x, target.y, target.z, unpack(AutoDrive.currentColors.ad_color_singleConnection))        -- green
                        DrawingManager:addArrowTask(start.x, start.y, start.z, target.x, target.y, target.z, arrowPosition, unpack(AutoDrive.currentColors.ad_color_singleConnection))
                    else
                        DrawingManager:addLineTask(start.x, start.y, start.z, target.x, target.y, target.z, unpack(AutoDrive.currentColors.ad_color_subPrioSingleConnection)) -- orange
                        DrawingManager:addArrowTask(start.x, start.y, start.z, target.x, target.y, target.z, arrowPosition, unpack(AutoDrive.currentColors.ad_color_subPrioSingleConnection))
                    end
                else
                end
            end
        end
    end
end

function AutoDrive:startAutoDrive()
    if self.isServer then
        if not self.ad.stateModule:isActive() then
            self.ad.stateModule:setActive(true)

            self.ad.isStoppingWithError = false
            self.ad.onRouteToPark = false


            
            if self.spec_aiVehicle ~= nil then
                if self.getAINeedsTrafficCollisionBox ~= nil then
                    if self:getAINeedsTrafficCollisionBox() then                    
                        if AIFieldWorker.TRAFFIC_COLLISION ~= nil and AIFieldWorker.TRAFFIC_COLLISION ~= 0 then
                            self.spec_aiVehicle.aiTrafficCollision = AIFieldWorker.TRAFFIC_COLLISION
                        end
                    end
                end
                if self.spec_aiVehicle.aiTrafficCollisionTranslation ~= nil then
                    self.spec_aiVehicle.aiTrafficCollisionTranslation[2] = -1000
                end
            end

            
            g_currentMission:farmStats(self:getOwnerFarmId()):updateStats("driversHired", 1)

            AutoDriveStartStopEvent:sendStartEvent(self)
        end
    else
        Logging.devError("AutoDrive:startAutoDrive() must be called only on the server.")
    end
end

function AutoDrive:stopAutoDrive()
    local x, y, z = getWorldTranslation(self.components[1].node)

    local point = nil
    local distanceToStart = 0
    if
        self.ad ~= nil and ADGraphManager.getWayPointById ~= nil and self.ad.stateModule ~= nil and self.ad.stateModule.getFirstMarker ~= nil and self.ad.stateModule:getFirstMarker() ~= nil and self.ad.stateModule:getFirstMarker() ~= 0 and
            self.ad.stateModule:getFirstMarker().id ~= nil
     then
        point = ADGraphManager:getWayPointById(self.ad.stateModule:getFirstMarker().id)
        if point ~= nil then
            distanceToStart = MathUtil.vector2Length(x - point.x, z - point.z)
        end
    end

    if self.isServer then
        ADScheduler:removePathfinderVehicle(self)

        if self.ad.stateModule:isActive() then
            g_currentMission:farmStats(self:getOwnerFarmId()):updateStats("driversHired", -1)
            self.ad.drivePathModule:reset()
            self.ad.specialDrivingModule:reset()
            self.ad.trailerModule:reset()

            for _, mode in pairs(self.ad.modes) do
                mode:reset()
            end

            if self.setBeaconLightsVisibility ~= nil and AutoDrive.getSetting("useBeaconLights", self) then
                self:setBeaconLightsVisibility(false)
            end
            if self.setTurnLightState ~= nil then
                self:setTurnLightState(Lights.TURNLIGHT_OFF)
            end

            local hasCallbacks = self.ad.callBackFunction ~= nil and self.ad.isStoppingWithError == false

            if hasCallbacks then
                --work with copys, so we can remove the callBackObjects before calling the function
                local callBackFunction = self.ad.callBackFunction
                local callBackObject = self.ad.callBackObject
                local callBackArg = self.ad.callBackArg
                if distanceToStart < 30 then -- pass control to external mod only when near to field point
                    if callBackObject ~= nil then
                        if callBackArg ~= nil then
                            AutoDrive.debugPrint(self, AutoDrive.DC_EXTERNALINTERFACEINFO, "AutoDrive:stopAutoDrive pass control to external mod callBackObject %s callBackArg %s", tostring(callBackObject), tostring(callBackArg))
                            self.ad.callBackFunction = nil
                            self.ad.callBackObject = nil
                            self.ad.callBackArg = nil
                            callBackFunction(callBackObject, callBackArg)
                        else
                            AutoDrive.debugPrint(self, AutoDrive.DC_EXTERNALINTERFACEINFO, "AutoDrive:stopAutoDrive pass control to external mod callBackObject %s", tostring(callBackObject))
                            self.ad.callBackFunction = nil
                            self.ad.callBackObject = nil
                            self.ad.callBackArg = nil
                            callBackFunction(callBackObject)
                        end
                    else
                        if callBackArg ~= nil then
                            AutoDrive.debugPrint(self, AutoDrive.DC_EXTERNALINTERFACEINFO, "AutoDrive:stopAutoDrive pass control to external mod callBackArg %s", tostring(callBackArg))
                            self.ad.callBackFunction = nil
                            self.ad.callBackObject = nil
                            self.ad.callBackArg = nil
                            callBackFunction(callBackArg)
                        else
                            AutoDrive.debugPrint(self, AutoDrive.DC_EXTERNALINTERFACEINFO, "AutoDrive:stopAutoDrive pass control to external mod, no callBackArg no callBackArg")
                            self.ad.callBackFunction = nil
                            self.ad.callBackObject = nil
                            self.ad.callBackArg = nil
                            callBackFunction()
                        end
                    end
                end
            else
                AutoDrive.driveInDirection(self, 16, 30, 0, 0.2, 20, false, self.ad.drivingForward, 0, 0, 0, 1)
                self:setCruiseControlState(Drivable.CRUISECONTROL_STATE_OFF)

                if not AutoDrive:getIsEntered(self) and not self.ad.isStoppingWithError then --self.ad.onRouteToPark and 
                    self.ad.onRouteToPark = false
                    if self.deactivateLights ~= nil then
                        self:deactivateLights()
                    end
                    if self.stopMotor ~= nil then
                        self:stopMotor()
                    end
                end

                if self.ad.sensors ~= nil then
                    for _, sensor in pairs(self.ad.sensors) do
                        sensor:setEnabled(false)
                    end
                end

                if self.spec_aiVehicle.aiTrafficCollisionTranslation ~= nil then
                    self.spec_aiVehicle.aiTrafficCollisionTranslation[2] = 0
                end
            end

            self.ad.stateModule:setActive(false)

            self.ad.taskModule:abortAllTasks()
            self.ad.taskModule:reset()

            local isStartingAIVE = (not self.ad.isStoppingWithError and self.ad.stateModule:getStartCP_AIVE() and not self.ad.stateModule:getUseCP_AIVE())
            local isPassingToCP = hasCallbacks or (not self.ad.isStoppingWithError and self.ad.stateModule:getStartCP_AIVE() and self.ad.stateModule:getUseCP_AIVE())
            AutoDriveStartStopEvent:sendStopEvent(self, isPassingToCP, isStartingAIVE)

            if not hasCallbacks and not self.ad.isStoppingWithError and distanceToStart < 30 then
                if self.ad.stateModule:getStartCP_AIVE() then
                    self.ad.stateModule:setStartCP_AIVE(false)
                    if g_courseplay ~= nil and self.ad.stateModule:getUseCP_AIVE() then
                        AutoDrive.debugPrint(self, AutoDrive.DC_EXTERNALINTERFACEINFO, "AutoDrive:stopAutoDrive pass control to CP with start")
                        AutoDrive:StartCP(self)
                    else
                        if self.acParameters ~= nil then
                            self.acParameters.enabled = true
                            AutoDrive.debugPrint(self, AutoDrive.DC_EXTERNALINTERFACEINFO, "AutoDrive:stopAutoDrive pass control to AIVE with startAIVehicle")
                            self:toggleAIVehicle()
                        end
                    end
                end
            end
            
            self.ad.trailerModule:handleTrailerReversing(false)
            if self.ad.isStoppingWithError == true then
                self.ad.onRouteToRefuel = false
                AutoDrive.debugPrint(self.vehicle, AutoDrive.DC_VEHICLEINFO, "AutoDrive:startAutoDrive self.ad.onRouteToRefuel %s", tostring(self.ad.onRouteToRefuel))
            end
        end
    else
        Logging.devError("AutoDrive:stopAutoDrive() must be called only on the server.")
    end
end

function AutoDrive:onStartAutoDrive()
    self.forceIsActive = true
    self.spec_motorized.stopMotorOnLeave = false
    self.spec_enterable.disableCharacterOnLeave = false
    self.spec_aiVehicle.isActive = true

    if self.spec_aiVehicle.currentHelper == nil then
        self.spec_aiVehicle.currentHelper = g_helperManager:getRandomHelper()

        if self.spec_aiVehicle.currentHelper == nil then
            g_currentMission.maxNumHirables = g_currentMission.maxNumHirables + 1;
            --g_helperManager:addHelper("AD_" .. math.AD_random(100, 1000), "dataS2/character/helper/helper02.xml")
            AutoDrive.AddHelper()
            self.spec_aiVehicle.currentHelper = g_helperManager:getRandomHelper()
        end

        if self.spec_aiVehicle.currentHelper ~= nil then
            g_helperManager:useHelper(self.spec_aiVehicle.currentHelper)
        end
        if self.setRandomVehicleCharacter ~= nil then
            self:setRandomVehicleCharacter()
            self.ad.vehicleCharacter = self.spec_enterable.vehicleCharacter
        end
        if self.spec_aiJobVehicle ~= nil then
            self.spec_aiJobVehicle.currentHelper = self.spec_aiVehicle.currentHelper
        end
        if self.spec_enterable.controllerFarmId ~= nil and self.spec_enterable.controllerFarmId ~= 0 then
            self.spec_aiVehicle.startedFarmId = self.spec_enterable.controllerFarmId
        else
            if g_currentMission ~= nil and g_currentMission.player ~= nil and g_currentMission.player.farmId ~= nil and g_currentMission.player.farmId ~= 0 then
                self.spec_aiVehicle.startedFarmId = g_currentMission.player.farmId
            elseif self.spec_aiVehicle.startedFarmId == nil or self.spec_aiVehicle.startedFarmId == 0 then
                if self.getOwnerFarmId ~= nil and self:getOwnerFarmId() ~= nil and self:getOwnerFarmId() ~= 0 then
                    self.spec_aiVehicle.startedFarmId = self:getOwnerFarmId()
                else
                    self.spec_aiVehicle.startedFarmId = 1
                end
            end
        end
    end

    if self.spec_motorized.motor ~= nil then
        self.spec_motorized.motor:setGearShiftMode(VehicleMotor.SHIFT_MODE_AUTOMATIC)
    end

    AutoDriveHud:createMapHotspot(self)

    if g_server ~= nil then
        if AutoDrive.getSetting("enableParkAtJobFinished", self) and ((self.ad.stateModule:getMode() == AutoDrive.MODE_PICKUPANDDELIVER) or (self.ad.stateModule:getMode() == AutoDrive.MODE_DELIVERTO)) then
            local actualParkDestination = self.ad.stateModule:getParkDestinationAtJobFinished()
            if actualParkDestination >= 1 then
            else
                AutoDriveMessageEvent.sendMessage(self, ADMessagesManager.messageTypes.ERROR, "$l10n_AD_parkVehicle_noPosSet;", 5000)
            end
        end
    end
end

function AutoDrive.AddHelper()
    local source = g_helperManager.indexToHelper[1]
    
    g_helperManager.numHelpers = g_helperManager.numHelpers + 1
    local helper = {}
    helper.name = source.name .. "_" .. math.random(100, 1000)
    helper.index = g_helperManager.numHelpers
    helper.title = helper.name
    helper.filename = source.filename

    g_helperManager.helpers[helper.name] = helper
    g_helperManager.nameToIndex[helper.name] = g_helperManager.numHelpers
    g_helperManager.indexToHelper[g_helperManager.numHelpers] = helper
    table.insert(g_helperManager.availableHelpers, helper)
end

function AutoDrive:onStopAutoDrive(hasCallbacks, isStartingAIVE)
    if not hasCallbacks then
        --if self.raiseAIEvent ~= nil and not isStartingAIVE then
            --self:raiseAIEvent("onAIFieldWorkerEnd", "onAIImplementEnd")
        --end

        self.spec_aiVehicle.isActive = false
        self.forceIsActive = false
        self.spec_motorized.stopMotorOnLeave = true
        self.spec_enterable.disableCharacterOnLeave = true
        if self.spec_aiVehicle.currentHelper ~= nil then
            g_helperManager:releaseHelper(self.spec_aiVehicle.currentHelper)
        end
        self.spec_aiVehicle.currentHelper = nil
        if self.spec_aiJobVehicle ~= nil then
            self.spec_aiJobVehicle.currentHelper = nil
        end

        if self.restoreVehicleCharacter ~= nil then
            self:restoreVehicleCharacter()
        end

        if self.spec_motorized.motor ~= nil then
            self.spec_motorized.motor:setGearShiftMode(self.spec_motorized.gearShiftMode)
        end
    end

    -- In case we get this event before the status has been updated with the readStream
    if self.ad.stateModule:isActive() then
        -- Set this to false without raising flags. The update should already be on the wire
        -- Otherwise this following requestActionEventUpdate will not allow user input since the AI is still active
        self.ad.stateModule.active = false
    end

    self:requestActionEventUpdate()

    AutoDriveHud:deleteMapHotspot(self)
end

function AutoDrive:updateWayPointsDistance()
    self.ad.distances.wayPoints = {}
    self.ad.distances.closest.wayPoint = nil
    self.ad.distances.closest.distance = math.huge
    self.ad.distances.closestNotReverse.wayPoint = nil
    self.ad.distances.closestNotReverse.distance = math.huge

    local x, _, z = getWorldTranslation(self.components[1].node)

    --We should see some perfomance increase by localizing the sqrt/pow functions right here
    local sqrt = math.sqrt
    local distanceFunc = function(a, b)
        return sqrt(a * a + b * b)
    end
    for _, wp in pairs(ADGraphManager:getWayPoints()) do
        local distance = distanceFunc(wp.x - x, wp.z - z)
        if distance < self.ad.distances.closest.distance then
            self.ad.distances.closest.distance = distance
            self.ad.distances.closest.wayPoint = wp
        end
        if distance <= AutoDrive.drawDistance then
            table.insert(self.ad.distances.wayPoints, {distance = distance, wayPoint = wp})
        end
        if distance < self.ad.distances.closestNotReverse.distance and (wp.incoming == nil or #wp.incoming > 0) then
            self.ad.distances.closestNotReverse.distance = distance
            self.ad.distances.closestNotReverse.wayPoint = wp
        end
    end
end

function AutoDrive:resetClosestWayPoint()
    self.ad.distances.closest.wayPoint = -1
end

function AutoDrive:resetWayPointsDistance()
    self.ad.distances.wayPoints = nil
end

function AutoDrive:getWayPointsDistance()
    return self.ad.distances.wayPoints
end

function AutoDrive:updateClosestWayPoint()
    if self.ad.distances.wayPoints == nil then
        self:updateWayPointsDistance()
    end
    self.ad.distances.closest.wayPoint = nil
    self.ad.distances.closest.distance = math.huge
    self.ad.distances.closestNotReverse.wayPoint = nil
    self.ad.distances.closestNotReverse.distance = math.huge

    if self.ad.distances.wayPoints == nil then
        -- something went wrong, so exit
        return
    end
    local x, _, z = getWorldTranslation(self.components[1].node)

    --We should see some perfomance increase by localizing the sqrt/pow functions right here
    local sqrt = math.sqrt
    local distanceFunc = function(a, b)
        return sqrt(a * a + b * b)
    end
    for _, elem in pairs(self.ad.distances.wayPoints) do
        local wp = elem.wayPoint
        local distance = distanceFunc(wp.x - x, wp.z - z)
        if distance < self.ad.distances.closest.distance then
            self.ad.distances.closest.distance = distance
            self.ad.distances.closest.wayPoint = wp
        end
        if distance < self.ad.distances.closestNotReverse.distance and (wp.incoming == nil or #wp.incoming > 0) then
            self.ad.distances.closestNotReverse.distance = distance
            self.ad.distances.closestNotReverse.wayPoint = wp
        end
    end
end

-- update distances only if not called in (frame) update functions
function AutoDrive:getClosestWayPoint(noUpdate)
    if noUpdate == nil or noUpdate == false then
        -- update on request function calls - force all update
        self:updateWayPointsDistance()
    end
    if self.ad.distances.closest.wayPoint == nil or noUpdate == true then
        -- get closest wayPoint in view distance -> perfomance improvement
        self:updateClosestWayPoint()
    end
    if self.ad.distances.closest.wayPoint ~= nil then
        return self.ad.distances.closest.wayPoint.id, self.ad.distances.closest.distance
    end
    return -1, math.huge
end

function AutoDrive:getClosestNotReversedWayPoint()
    if self.ad.distances.closestNotReverse.wayPoint == -1 then
        self:updateWayPointsDistance()
    end
    if self.ad.distances.closestNotReverse.wayPoint ~= nil then
        return self.ad.distances.closestNotReverse.wayPoint.id, self.ad.distances.closestNotReverse.distance
    end
    return -1, math.huge
end

function AutoDrive:getWayPointsInRange(minDistance, maxDistance)
    if self.ad.distances.wayPoints == nil then
        self:updateWayPointsDistance()
    end
    local inRange = {}
    for _, elem in pairs(self.ad.distances.wayPoints) do
        if elem.distance >= minDistance and elem.distance <= maxDistance and elem.wayPoint.id > 0 then
            table.insert(inRange, elem.wayPoint)
        end
    end
    return inRange
end

function AutoDrive:getWayPointIdsInRange(minDistance, maxDistance)
    if self.ad.distances.wayPoints == nil then
        self:updateWayPointsDistance()
    end
    local inRange = {}
    for _, elem in pairs(self.ad.distances.wayPoints) do
        if elem.distance >= minDistance and elem.distance <= maxDistance and elem.wayPoint.id > 0 then
            table.insert(inRange, elem.wayPoint.id)
        end
    end
    return inRange
end

function AutoDrive:toggleMouse()
    if g_inputBinding:getShowMouseCursor() then
        if self.spec_enterable ~= nil and self.spec_enterable.cameras ~= nil then
            for _, camera in pairs(self.spec_enterable.cameras) do
                camera.storedAllowTranslation = camera.allowTranslation
                --camera.storedIsRotatable = camera.isRotatable
                camera.allowTranslation = false
                camera.isRotatable = false
            end
        end
    else
        if self.spec_enterable ~= nil and self.spec_enterable.cameras ~= nil then
            for _, camera in pairs(self.spec_enterable.cameras) do
                if camera.storedAllowTranslation ~= nil then
                    camera.allowTranslation = camera.storedAllowTranslation
                else
                    camera.allowTranslation = true
                end
                if camera.storedIsRotatable ~= nil then
                    camera.isRotatable = camera.storedIsRotatable
                else
                    camera.isRotatable = true
                end
            end
        end
    end
    self.ad.lastMouseState = g_inputBinding:getShowMouseCursor()
end

function AutoDrive:leaveVehicle(superFunc)
    if self.ad ~= nil then
        if self.getIsEntered ~= nil and self:getIsEntered() then
            if g_inputBinding:getShowMouseCursor() then
                g_inputBinding:setShowMouseCursor(false)
            end
            AutoDrive.Hud:closeAllPullDownLists(self)
        end
    end
    superFunc(self)
end

function AutoDrive:updateAutoDriveLights()
    if self.ad ~= nil and self.ad.stateModule:isActive() then
        -- If AutoDrive is active, then we take care of lights our self
        local spec = self.spec_lights
        local dayMinutes = g_currentMission.environment.dayTime / (1000 * 60)
        local needLights = not g_currentMission.environment.isSunOn -- (dayMinutes > g_currentMission.environment.nightStartMinutes or dayMinutes < g_currentMission.environment.nightEndMinutes)
        if needLights then
            local x, y, z = getWorldTranslation(self.components[1].node)            
            if spec.aiLightsTypesMaskWork ~= nil and spec.lightsTypesMask ~= spec.aiLightsTypesMaskWork and AutoDrive.checkIsOnField(x, y, z) then
                self:setLightsTypesMask(spec.aiLightsTypesMaskWork)
                return
            end
            
            if spec.aiLightsTypesMask ~= nil and spec.lightsTypesMask ~= spec.aiLightsTypesMask and not AutoDrive.checkIsOnField(x, y, z) then
                self:setLightsTypesMask(spec.aiLightsTypesMask)
                return
            end

            if spec.lightsTypesMask ~= 1 and not AutoDrive.checkIsOnField(x, y, z) then
                self:setLightsTypesMask(1)
            end
        else
            if spec.lightsTypesMask ~= 0 then
                self:setLightsTypesMask(0)
            end
        end
    end
end

function AutoDrive:getCanMotorRun(superFunc)
    if self.ad ~= nil and self.ad.stateModule:isActive() and self.ad.specialDrivingModule:shouldStopMotor() then
        return false
    else
        return superFunc(self)
    end
end

function AutoDrive:getIsAIActive(superFunc)
    return superFunc(self) or self.ad.stateModule:isActive()
end

function AutoDrive:getIsVehicleControlledByPlayer(superFunc)
    return superFunc(self) and not self.ad.stateModule:isActive()
end

function AutoDrive:getActiveFarm(superFunc)
    if self.spec_aiVehicle ~= 0 and self.spec_aiVehicle.startedFarmId and self.ad.stateModule:isActive() then
        return self.spec_aiVehicle.startedFarmId
    else
        return superFunc(self)
    end
end