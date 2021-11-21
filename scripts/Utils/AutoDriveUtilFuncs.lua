-- positive X -> left
-- negative X -> right
function AutoDrive.createWayPointRelativeToVehicle(vehicle, offsetX, offsetZ)
    local wayPoint = {}
    wayPoint.x, wayPoint.y, wayPoint.z = localToWorld(vehicle.components[1].node, offsetX, 0, offsetZ)
    return wayPoint
end

function AutoDrive.createWayPointRelativeToNode(node, offsetX, offsetZ)
    local wayPoint = {}
    wayPoint.x, wayPoint.y, wayPoint.z = localToWorld(node, offsetX, 0, offsetZ)
    return wayPoint
end

function AutoDrive.isTrailerInCrop(vehicle, enlargeDetectionArea)
    local widthFactor = 1
    if enlargeDetectionArea then
        widthFactor = 1.5
    end

    local trailers, trailerCount = AutoDrive.getTrailersOf(vehicle)
    local trailer = trailers[trailerCount]
    local inCrop = false
    if trailer ~= nil then
        if trailer.ad == nil then
            trailer.ad = {}
        end
        ADSensor:handleSensors(trailer, 0)
        inCrop = trailer.ad.sensors.centerSensorFruit:pollInfo(true, widthFactor)
    end
    return inCrop
end

function AutoDrive.isVehicleOrTrailerInCrop(vehicle, enlargeDetectionArea)
    local widthFactor = 1
    if enlargeDetectionArea then
        widthFactor = 1.5
    end

    return AutoDrive.isTrailerInCrop(vehicle, enlargeDetectionArea) or vehicle.ad.sensors.centerSensorFruit:pollInfo(true, widthFactor)
end

function AutoDrive:checkIsConnected(toCheck, other)
    local isAttachedToMe = false
    if toCheck == nil or other == nil then
        return false
    end
    if toCheck.getAttachedImplements == nil then
        return false
    end

    for _, impl in pairs(toCheck:getAttachedImplements()) do
        if impl.object ~= nil then
            if impl.object == other then
                return true
            end

            if impl.object.getAttachedImplements ~= nil then
                isAttachedToMe = isAttachedToMe or AutoDrive:checkIsConnected(impl.object, other)
            end
        end
    end

    return isAttachedToMe
end

function AutoDrive.defineMinDistanceByVehicleType(vehicle)
    local min_distance = 1.8
    if
        vehicle.typeDesc == "combine" or vehicle.typeDesc == "harvester" or vehicle.typeName == "combineDrivable" or vehicle.typeName == "selfPropelledMower" or vehicle.typeName == "woodHarvester" or vehicle.typeName == "combineCutterFruitPreparer" or vehicle.typeName == "drivableMixerWagon" or
            vehicle.typeName == "cottonHarvester" or
            vehicle.typeName == "pdlc_claasPack.combineDrivableCrawlers"
     then
        min_distance = 6
    elseif vehicle.typeDesc == "telehandler" or vehicle.spec_crabSteering ~= nil then --If vehicle has 4 steering wheels like xerion or hardi self Propelled sprayer then also min_distance = 3;
        min_distance = 3
    elseif vehicle.typeDesc == "truck" then
        min_distance = 3
    end
    -- If vehicle is quadtrack then also min_distance = 6;
    if vehicle.spec_articulatedAxis ~= nil and vehicle.spec_articulatedAxis.rotSpeed ~= nil then
        min_distance = 6
    end
    return min_distance
end

function AutoDrive.getVehicleMaxSpeed(vehicle)
    -- 255 is the max value to prevent errors with MP sync
    if vehicle ~= nil and vehicle.spec_motorized ~= nil and vehicle.spec_motorized.motor ~= nil then
        local motor = vehicle.spec_motorized.motor
        return math.min(motor:getMaximumForwardSpeed() * 3.6, 255)
    end
    return 255
end

function AutoDrive.renameDriver(vehicle, name, sendEvent)
    if name:len() > 1 and vehicle ~= nil and vehicle.ad ~= nil then
        if sendEvent == nil or sendEvent == true then
            -- Propagating driver rename all over the network
            AutoDriveRenameDriverEvent.sendEvent(vehicle, name)
        else
            vehicle.ad.stateModule:setName(name)
        end
    end
end

-- return fillType to refuel or nil if no refuel required
--[[
ignoreFillLevel:
- only useful for diesel and electricCharge - def is included in most cases with diesel
- how to decide to pick diesel or def?
]]
function AutoDrive.getRequiredRefuel(vehicle, ignoreFillLevel)
    local spec = vehicle.spec_motorized
    local ret = 0

    if spec ~= nil and spec.consumersByFillTypeName ~= nil then
        if spec.consumersByFillTypeName.diesel ~= nil and spec.consumersByFillTypeName.diesel.fillUnitIndex ~= nil and (vehicle:getFillUnitFillLevelPercentage(spec.consumersByFillTypeName.diesel.fillUnitIndex) < AutoDrive.REFUEL_LEVEL or ignoreFillLevel) then
            ret = g_fillTypeManager:getFillTypeIndexByName('DIESEL')
        end
        if spec.consumersByFillTypeName.def ~= nil and spec.consumersByFillTypeName.def.fillUnitIndex ~= nil and (vehicle:getFillUnitFillLevelPercentage(spec.consumersByFillTypeName.def.fillUnitIndex) < AutoDrive.REFUEL_LEVEL) then
            ret = g_fillTypeManager:getFillTypeIndexByName('DEF')
        end
        if spec.consumersByFillTypeName.electricCharge ~= nil and spec.consumersByFillTypeName.electricCharge.fillUnitIndex ~= nil and (vehicle:getFillUnitFillLevelPercentage(spec.consumersByFillTypeName.electricCharge.fillUnitIndex) < AutoDrive.REFUEL_LEVEL or ignoreFillLevel) then
            ret = g_fillTypeManager:getFillTypeIndexByName('ELECTRICCHARGE')
        end
    end

    return ret
end

function AutoDrive.combineIsTurning(combine)
    local cpIsTurning = combine.cp ~= nil and (combine.cp.isTurning or (combine.cp.turnStage ~= nil and combine.cp.turnStage > 0))
    local cpIsTurningTwo = combine.cp ~= nil and combine.cp.driver and (combine.cp.driver.turnIsDriving or (combine.cp.driver.fieldworkState ~= nil and combine.cp.driver.fieldworkState == combine.cp.driver.states.TURNING))
    local aiIsTurning = (combine.getAIIsTurning ~= nil and combine:getAIIsTurning() == true)
    --local combineSteering = combine.rotatedTime ~= nil and (math.deg(combine.rotatedTime) > 30)
    local combineIsTurning = cpIsTurning or cpIsTurningTwo or aiIsTurning --or combineSteering

    --local b = AutoDrive.boolToString
    --print("cpIsTurning: " .. b(cpIsTurning) .. " cpIsTurningTwo: " .. b(cpIsTurningTwo) .. " aiIsTurning: " .. b(aiIsTurning) .. " combineIsTurning: " .. b(combineIsTurning) .. " driveForwardDone: " .. b(combine.ad.driveForwardTimer:done()))
    if not combineIsTurning then --(combine.ad.driveForwardTimer:done() and (not combine:getIsBufferCombine()))
        return false
    end
    if combine.ad.noMovementTimer.elapsedTime > 3000 then
        return false
    end
    return true
end

function AutoDrive.pointIsBetweenTwoPoints(x, z, startX, startZ, endX, endZ)
    local xInside = (startX >= x and endX <= x) or (startX <= x and endX >= x)
    local zInside = (startZ >= z and endZ <= z) or (startZ <= z and endZ >= z)
    return xInside and zInside
end

function AutoDrive.semanticVersionToValue(versionString)
    local codes = versionString:split(".")
    local value = 0
    if codes ~= nil then
        for i, code in ipairs(codes) do
            local subCodes = code:split("-")
            if subCodes ~= nil and subCodes[1] ~= nil then
                value = value * 10 + tonumber(subCodes[1])
                if subCodes[2] ~= nil then
                    value = value + (tonumber(subCodes[2]) / 1000)
                end
            end
        end
    end

    return value
end

function AutoDrive.mouseIsAtPos(position, radius)
    local x, y, _ = project(position.x, position.y + AutoDrive.drawHeight + AutoDrive.getSetting("lineHeight"), position.z)

    if g_lastMousePosX < (x + radius) and g_lastMousePosX > (x - radius) then
        if g_lastMousePosY < (y + radius) and g_lastMousePosY > (y - radius) then
            return true
        end
    end

    return false
end

function AutoDrive.isVehicleInBunkerSiloArea(vehicle)
    if not (vehicle.ad.stateModule:getCurrentMode():shouldUnloadAtTrigger() == true) then
        -- check only for bunker silo if should unload to improve performance
        return false
    end
    for _, trigger in pairs(ADTriggerManager.getUnloadTriggers()) do
        local x, y, z = getWorldTranslation(vehicle.components[1].node)
        local tx, _, tz = x, y, z + 1
        if trigger ~= nil and trigger.bunkerSiloArea ~= nil then
            local x1, z1 = trigger.bunkerSiloArea.sx, trigger.bunkerSiloArea.sz
            local x2, z2 = trigger.bunkerSiloArea.wx, trigger.bunkerSiloArea.wz
            local x3, z3 = trigger.bunkerSiloArea.hx, trigger.bunkerSiloArea.hz
            if MathUtil.hasRectangleLineIntersection2D(x1, z1, x2 - x1, z2 - z1, x3 - x1, z3 - z1, x, z, tx - x, tz - z) then
                return true
            end

            local trailers, trailerCount = AutoDrive.getTrailersOf(vehicle)
            if trailerCount > 0 then
                for _, trailer in pairs(trailers) do
                    if AutoDrive.isTrailerInBunkerSiloArea(trailer, trigger) then
                        return true
                    end
                end
            end
        end
    end

    return false
end

function AutoDrive.isEditorModeEnabled()
    return (AutoDrive.getSetting("EditorMode") == AutoDrive.EDITOR_ON) or (AutoDrive.getSetting("EditorMode") == AutoDrive.EDITOR_EXTENDED)
end

function AutoDrive.isEditorShowEnabled()
    return (AutoDrive.getSetting("EditorMode") == AutoDrive.EDITOR_SHOW)
end

function AutoDrive.isInExtendedEditorMode()
    return (AutoDrive.getSetting("EditorMode") == AutoDrive.EDITOR_EXTENDED)
end

function AutoDrive.getEditorMode()
    return (AutoDrive.getSetting("EditorMode"))
end

function AutoDrive.setEditorMode(editorMode)
    AutoDrive.setSettingState("EditorMode", editorMode)
end

function AutoDrive.cycleEditMode()
    local vehicle = g_currentMission.controlledVehicle
    if g_client ~= nil then

        if vehicle ~= nil and vehicle.ad ~= nil then
            vehicle.ad.selectedNodeId = nil
            vehicle.ad.nodeToMoveId = nil
            vehicle.ad.hoveredNodeId = nil
			vehicle.ad.newcreated = nil
            vehicle.ad.sectionWayPoints = {}
        end
        if (AutoDrive.getSetting("EditorMode") == AutoDrive.EDITOR_OFF) then
            AutoDrive.setEditorMode(AutoDrive.EDITOR_EXTENDED)
        else
            AutoDrive.setEditorMode(AutoDrive.EDITOR_OFF)
            if g_server ~= nil and g_client ~= nil and g_dedicatedServerInfo == nil then
                -- in SP always delete color selection wayPoints if there are any
                ADGraphManager:deleteColorSelectionWayPoints()
            end
            if vehicle ~= nil and vehicle.ad ~= nil and vehicle.ad.stateModule ~= nil then
                vehicle.ad.stateModule:disableCreationMode()
            end
        end
    end
end

function AutoDrive.cycleEditorShowMode()
    local vehicle = g_currentMission.controlledVehicle

    if (AutoDrive.getSetting("EditorMode") == AutoDrive.EDITOR_OFF) then
        AutoDrive.setEditorMode(AutoDrive.EDITOR_SHOW)
    else
        AutoDrive.setEditorMode(AutoDrive.EDITOR_OFF)
		if vehicle ~= nil and vehicle.ad ~= nil and vehicle.ad.stateModule ~= nil then
            vehicle.ad.stateModule:disableCreationMode()
        end
    end
end

function AutoDrive.getSelectedWorkTool(vehicle)
    local selectedWorkTool = nil

    if vehicle ~= nil and vehicle.getAttachedImplements and #vehicle:getAttachedImplements() > 0 then
        local allImp = {}
        -- Credits to Tardis from FS17
        local function addAllAttached(obj)
            for _, imp in pairs(obj:getAttachedImplements()) do
                addAllAttached(imp.object)
                table.insert(allImp, imp)
            end
        end

        addAllAttached(vehicle)

        if allImp ~= nil then
            for i = 1, #allImp do
                local imp = allImp[i]
                if imp ~= nil and imp.object ~= nil and imp.object:getIsSelected() then
                    selectedWorkTool = imp.object
                    break
                end
            end
        end
    end
    return selectedWorkTool
end

function AutoDrive.getVehicleLeadingEdge(vehicle)
    local leadingEdge = 0
    local implements = AutoDrive.getAllImplements(vehicle)
    if implements ~= nil then
        for i = 1, #implements do
            local implement = implements[i]
            if implement ~= nil and implement.object ~= nil then
                local implementX, implementY, implementZ = getWorldTranslation(implement.object.components[1].node)
                local _, _, diffZ = worldToLocal(vehicle.components[1].node, implementX, implementY, implementZ)
                if diffZ > 0 and implement.object.sizeLength ~= nil then                    
                    leadingEdge = math.max(leadingEdge, diffZ + (implement.object.sizeLength / 2) - (vehicle.sizeLength / 2))
                end
            end
        end
    end
    return leadingEdge
end

function AutoDrive.getAllImplements(vehicle)
    if vehicle ~= nil and vehicle.getAttachedImplements and #vehicle:getAttachedImplements() > 0 then
        local allImp = {}
        -- Credits to Tardis from FS17
        local function addAllAttached(obj)
            for _, imp in pairs(obj:getAttachedImplements()) do
                addAllAttached(imp.object)
                table.insert(allImp, imp)
            end
        end

        addAllAttached(vehicle)

        return allImp
    end
end

-- set or delete park destination for selected vehicle, tool from user input action, client mode!
function AutoDrive.setActualParkDestination(vehicle)
    local actualParkDestination = -1
    local selectedWorkTool = nil

    if vehicle ~= nil and vehicle.ad ~= nil and vehicle.ad.stateModule ~= nil and vehicle.ad.stateModule:getFirstMarker() ~= nil then
        local firstMarkerID = vehicle.ad.stateModule:getFirstMarkerId()
        if firstMarkerID > 0 then
            local mapMarker = ADGraphManager:getMapMarkerById(firstMarkerID)
            -- do not allow to set debug marker as park destination
            if mapMarker ~= nil and mapMarker.isADDebug ~= true then
                selectedWorkTool = AutoDrive.getSelectedWorkTool(vehicle)

                if selectedWorkTool == nil then
                    -- no attachment selected, so use the vehicle itself
                    selectedWorkTool = vehicle
                end

                if selectedWorkTool ~= nil then
                    if AutoDrive.isInExtendedEditorMode() and AutoDrive.leftCTRLmodifierKeyPressed and not AutoDrive.leftALTmodifierKeyPressed then
                        -- assign park destination
                        if vehicle.advd ~= nil then
                            vehicle.advd:setParkDestination(selectedWorkTool, firstMarkerID)
                        end

                        -- on client sendMessage is not allowed, so add the message to ADMessagesManager to show it
                        local messageText = "$l10n_AD_parkVehicle_selected; %s"
                        local messageArg = vehicle.ad.stateModule:getFirstMarker().name
                        -- localization
                        messageText = AutoDrive.localize(messageText)
                        -- formatting
                        messageText = string.format(messageText, messageArg)
                        ADMessagesManager:addMessage(ADMessagesManager.messageTypes.INFO, messageText, 5000)
                        
                    elseif AutoDrive.isInExtendedEditorMode() and not AutoDrive.leftCTRLmodifierKeyPressed and AutoDrive.leftALTmodifierKeyPressed then
                        -- delete park destination
                        if vehicle.advd ~= nil then
                            vehicle.advd:setParkDestination(selectedWorkTool, -1)
                        end

                        -- on client sendMessage is not allowed, so add the message to ADMessagesManager to show it
                        local messageText = "$l10n_AD_parkVehicle_deleted; %s"
                        local messageArg = vehicle.ad.stateModule:getFirstMarker().name
                        -- localization
                        messageText = AutoDrive.localize(messageText)
                        -- formatting
                        messageText = string.format(messageText, messageArg)
                        ADMessagesManager:addMessage(ADMessagesManager.messageTypes.INFO, messageText, 5000)
                    end
                end
            end
        end
    end
end

-- MP: Important! vehicle:getIsEntered() is not working as expected on server!
-- This is the alternative MP approach
function AutoDrive:getIsEntered(vehicle)
    local user = nil
    if g_dedicatedServerInfo ~= nil and vehicle ~= nil and g_currentMission.userManager ~= nil and g_currentMission.userManager.getUserByConnection ~= nil and vehicle.getOwner ~= nil then
        -- MP
        user = g_currentMission.userManager:getUserByConnection(vehicle:getOwner())
    else
        -- SP
        if vehicle ~= nil and vehicle.getIsEntered ~= nil then
            return vehicle:getIsEntered()
        end
    end
    return user ~= nil
end

function AutoDrive:getColorKeyNames()
    local colorKeyNames = {}
	for k, v in pairs(AutoDrive.colors) do
		local tagName = string.format("%s",k)
        table.insert(colorKeyNames, tagName)
    end
    return colorKeyNames
end

function AutoDrive:getColorAssignment(colorKey)
    if AutoDrive.currentColors[colorKey] ~= nil then
        local r = AutoDrive.currentColors[colorKey][1]
        local g = AutoDrive.currentColors[colorKey][2]
        local b = AutoDrive.currentColors[colorKey][3]
        local a = AutoDrive.currentColors[colorKey][4]
        return {r, g, b, a}
    else
        return {AutoDrive.currentColors.ad_color_default[1], AutoDrive.currentColors.ad_color_default[2], AutoDrive.currentColors.ad_color_default[3], AutoDrive.currentColors.ad_color_default[4]}
    end
end

function AutoDrive:setColorAssignment(colorKey, r, g, b, a)
    if AutoDrive.currentColors[colorKey] ~= nil then
        AutoDrive.currentColors[colorKey][1] = r
        AutoDrive.currentColors[colorKey][2] = g
        AutoDrive.currentColors[colorKey][3] = b
        if a ~= nil then
            AutoDrive.currentColors[colorKey][4] = a
        end
    end
end

function AutoDrive:resetColorAssignment(colorKey, all)
    if all ~= nil and all == true then
        AutoDrive.currentColors = {}
        for k, v in pairs(AutoDrive.colors) do
            AutoDrive.currentColors[k] = {}
            for i = 1, 4 do
                AutoDrive.currentColors[k][i] = AutoDrive.colors[k][i]
            end
        end
    elseif AutoDrive.currentColors[colorKey] ~= nil then
        for i = 1, 4 do
            AutoDrive.currentColors[colorKey][i] = AutoDrive.colors[colorKey][i]
        end
    end
end
