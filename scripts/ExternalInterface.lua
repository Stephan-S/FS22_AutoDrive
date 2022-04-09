AutoDrive.destinationListeners = {}

--startX, startZ: World location
--startYRot: rotation in rad
--destinationID: ID of marker to find path to
--options (optional): options.minDistance, options.maxDistance (default 1m, 20m) define boundaries between the first AutoDrive waypoint and the starting location.
function AutoDrive:GetPath(startX, startZ, startYRot, destinationID, options)
    AutoDrive.debugPrint(nil, AutoDrive.DC_EXTERNALINTERFACEINFO, "AutoDrive:GetPath(%s, %s, %s, %s, %s)", startX, startZ, startYRot, destinationID, options)
    if startX == nil or startZ == nil or startYRot == nil or destinationID == nil or ADGraphManager:getMapMarkerById(destinationID) == nil then
        return
    end
    startYRot = AutoDrive.normalizeAngleToPlusMinusPI(startYRot)
    local markerName = ADGraphManager:getMapMarkerById(destinationID).name
    local startPoint = {x = startX, z = startZ}
    local minDistance = 1
    local maxDistance = 20
    if options ~= nil and options.minDistance ~= nil then
        minDistance = options.minDistance
    end
    if options ~= nil and options.maxDistance ~= nil then
        maxDistance = options.maxDistance
    end
    local directionVec = {x = math.sin(startYRot), z = math.cos(startYRot)}
    local bestPoint = ADGraphManager:findMatchingWayPoint(startPoint, directionVec, ADGraphManager:getWayPointsInRange(startPoint, minDistance, maxDistance))

    if bestPoint == -1 then
        bestPoint = AutoDrive:GetClosestPointToLocation(startX, startZ, minDistance)
        if bestPoint == -1 then
            return
        end
    end

    return ADGraphManager:FastShortestPath(bestPoint, markerName, ADGraphManager:getMapMarkerById(destinationID).id)
end

function AutoDrive:GetPathVia(startX, startZ, startYRot, viaID, destinationID, options)
    AutoDrive.debugPrint(nil, AutoDrive.DC_EXTERNALINTERFACEINFO, "AutoDrive:GetPathVia(%s, %s, %s, %s, %s, %s)", startX, startZ, startYRot, viaID, destinationID, options)
    if startX == nil or startZ == nil or startYRot == nil or destinationID == nil or ADGraphManager:getMapMarkerById(destinationID) == nil or viaID == nil or ADGraphManager:getMapMarkerById(viaID) == nil then
        return
    end
    startYRot = AutoDrive.normalizeAngleToPlusMinusPI(startYRot)

    local markerName = ADGraphManager:getMapMarkerById(viaID).name
    local startPoint = {x = startX, z = startZ}
    local minDistance = 1
    local maxDistance = 20
    if options ~= nil and options.minDistance ~= nil then
        minDistance = options.minDistance
    end
    if options ~= nil and options.maxDistance ~= nil then
        maxDistance = options.maxDistance
    end
    local directionVec = {x = math.sin(startYRot), z = math.cos(startYRot)}
    local bestPoint = ADGraphManager:findMatchingWayPoint(startPoint, directionVec, ADGraphManager:getWayPointsInRange(startPoint, minDistance, maxDistance))

    if bestPoint == -1 then
        bestPoint = AutoDrive:GetClosestPointToLocation(startX, startZ, minDistance)
        if bestPoint == -1 then
            return
        end
    end

    local toViaID = ADGraphManager:FastShortestPath(bestPoint, markerName, ADGraphManager:getMapMarkerById(viaID).id)

    if toViaID == nil or #toViaID < 1 then
        return
    end

    local fromViaID = ADGraphManager:FastShortestPath(toViaID[#toViaID].id, ADGraphManager:getMapMarkerById(destinationID).name, ADGraphManager:getMapMarkerById(destinationID).id)

    for i, wayPoint in pairs(fromViaID) do
        if i > 1 then
            table.insert(toViaID, wayPoint)
        end
    end

    return toViaID
end

function AutoDrive:GetDriverName(vehicle)
    return vehicle.ad.stateModule:getName()
end

function AutoDrive:GetAvailableDestinations()
    AutoDrive.debugPrint(nil, AutoDrive.DC_EXTERNALINTERFACEINFO, "AutoDrive:GetAvailableDestinations()")
    local destinations = {}
    for markerID, marker in pairs(ADGraphManager:getMapMarkers()) do
        local point = ADGraphManager:getWayPointById(marker.id)
        if point ~= nil then
            destinations[markerID] = {name = marker.name, x = point.x, y = point.y, z = point.z, id = markerID}
        end
    end
    return destinations
end

function AutoDrive:GetClosestPointToLocation(x, z, minDistance)
    AutoDrive.debugPrint(nil, AutoDrive.DC_EXTERNALINTERFACEINFO, "AutoDrive:GetClosestPointToLocation(%s, %s, %s)", x, z, minDistance)
    local closest = -1
    if ADGraphManager:getWayPointsCount() < 1 then
        local distance = math.huge

        for i in pairs(ADGraphManager:getWayPoints()) do
            local dis = MathUtil.vector2Length(ADGraphManager:getWayPointById(i).x - x, ADGraphManager:getWayPointById(i).z - z)
            if dis < distance and dis >= minDistance then
                closest = i
                distance = dis
            end
        end
    end

    return closest
end

function AutoDrive:StartDriving(vehicle, destinationID, unloadDestinationID, callBackObject, callBackFunction, callBackArg)
    AutoDrive.debugPrint(vehicle, AutoDrive.DC_EXTERNALINTERFACEINFO, "AutoDrive:StartDriving(%s, %s, %s, %s, %s)", destinationID, unloadDestinationID, callBackObject, callBackFunction, callBackArg)
    if vehicle ~= nil and vehicle.ad ~= nil and not vehicle.ad.stateModule:isActive() then
        vehicle.ad.callBackObject = callBackObject
        vehicle.ad.callBackFunction = callBackFunction
        vehicle.ad.callBackArg = callBackArg

        if destinationID ~= nil and destinationID >= 0 and ADGraphManager:getMapMarkerById(destinationID) ~= nil 
            and unloadDestinationID ~= nil and unloadDestinationID >= 0 and ADGraphManager:getMapMarkerById(unloadDestinationID) ~= nil then
            vehicle.ad.stateModule:setFirstMarker(destinationID)
        end
        if unloadDestinationID ~= nil then
            if unloadDestinationID >= 0 and ADGraphManager:getMapMarkerById(unloadDestinationID) ~= nil then
                vehicle.ad.stateModule:setSecondMarker(unloadDestinationID)
                vehicle.ad.stateModule:getCurrentMode():start()
            elseif unloadDestinationID == -3 then --park
                local parkDestinationAtJobFinished = vehicle.ad.stateModule:getParkDestinationAtJobFinished()
                if parkDestinationAtJobFinished >= 1 then
                    local trailers, _ = AutoDrive.getAllUnits(vehicle)
                    local fillLevel, _, _ = AutoDrive.getAllFillLevels(trailers)
                    if vehicle.ad.stateModule:getMode() == AutoDrive.MODE_PICKUPANDDELIVER and fillLevel > 0 then
                        -- unload before going to park
                        AutoDrive.debugPrint(vehicle, AutoDrive.DC_EXTERNALINTERFACEINFO, "AutoDrive:StartDriving unload before going to park")
                        vehicle.ad.stateModule:setMode(AutoDrive.MODE_DELIVERTO)
                        vehicle.ad.stateModule:setFirstMarker(vehicle.ad.stateModule:getSecondMarkerId())
                    else
                        vehicle.ad.stateModule:setMode(AutoDrive.MODE_DRIVETO)
                        vehicle.ad.stateModule:setFirstMarker(parkDestinationAtJobFinished)
                        vehicle.ad.onRouteToPark = true
                    end
                    vehicle.ad.stateModule:getCurrentMode():start()
                else
                    AutoDriveMessageEvent.sendMessage(vehicle, ADMessagesManager.messageTypes.ERROR, "$l10n_AD_parkVehicle_noPosSet;", 5000)
                    -- stop vehicle movement
                    vehicle.ad.trailerModule:handleTrailerReversing(false)
                    AutoDrive.driveInDirection(vehicle, 16, 30, 0, 0.2, 20, false, false, 0, 0, 0, 1)
                    vehicle:setCruiseControlState(Drivable.CRUISECONTROL_STATE_OFF)
                    if vehicle.stopMotor ~= nil then
                        vehicle:stopMotor()
                    end
                end
            else --unloadDestinationID == -2 refuel
                -- vehicle.ad.stateModule:setMode(AutoDrive.MODE_DRIVETO) -- should fix #1477
                vehicle.ad.stateModule:getCurrentMode():start()
            end
        end
    end
end

function AutoDrive:StartDrivingWithPathFinder(vehicle, destinationID, unloadDestinationID, callBackObject, callBackFunction, callBackArg)
    AutoDrive.debugPrint(vehicle, AutoDrive.DC_EXTERNALINTERFACEINFO, "AutoDrive:StartDrivingWithPathFinder(%s, %s, %s, %s, %s)", destinationID, unloadDestinationID, callBackObject, callBackFunction, callBackArg)
    if vehicle ~= nil and vehicle.ad ~= nil and not vehicle.ad.stateModule:isActive() then
        if unloadDestinationID < -1 then
            if unloadDestinationID == -3 then --park
                AutoDrive:StartDriving(vehicle, destinationID, unloadDestinationID, callBackObject, callBackFunction, callBackArg)
            elseif unloadDestinationID == -2 then --refuel
                AutoDrive:StartDriving(vehicle, vehicle.ad.stateModule:getFirstMarkerId(), unloadDestinationID, callBackObject, callBackFunction, callBackArg)
            end
        else
            AutoDrive:StartDriving(vehicle, destinationID, unloadDestinationID, callBackObject, callBackFunction, callBackArg)
        end
    end
end

function AutoDrive:GetParkDestination(vehicle)
    AutoDrive.debugPrint(vehicle, AutoDrive.DC_EXTERNALINTERFACEINFO, "AutoDrive:GetParkDestination()")
    if vehicle ~= nil and vehicle.ad ~= nil and vehicle.ad.stateModule ~= nil then
        local parkDestinationAtJobFinished = vehicle.ad.stateModule:getParkDestinationAtJobFinished()
        if parkDestinationAtJobFinished >= 1 then
            return parkDestinationAtJobFinished
        end
    end
    return nil
end

function AutoDrive:registerDestinationListener(callBackObject, callBackFunction)
    AutoDrive.debugPrint(nil, AutoDrive.DC_EXTERNALINTERFACEINFO, "AutoDrive:registerDestinationListener(%s, %s)", callBackObject, callBackFunction)
    if AutoDrive.destinationListeners[callBackObject] == nil then
        AutoDrive.destinationListeners[callBackObject] = callBackFunction
    end
end

function AutoDrive:unRegisterDestinationListener(callBackObject)
    AutoDrive.debugPrint(nil, AutoDrive.DC_EXTERNALINTERFACEINFO, "AutoDrive:unRegisterDestinationListener(%s)", callBackObject)
    if AutoDrive.destinationListeners[callBackObject] ~= nil then
        AutoDrive.destinationListeners[callBackObject] = nil
    end
end

function AutoDrive:notifyDestinationListeners()
    AutoDrive.debugPrint(nil, AutoDrive.DC_EXTERNALINTERFACEINFO, "AutoDrive:notifyDestinationListeners()")
    for object, callBackFunction in pairs(AutoDrive.destinationListeners) do
        callBackFunction(object, true)
    end
    AutoDrive.triggerStaticOutput()
end

function AutoDrive:combineIsCallingDriver(combine)	--only for CoursePlay
	local openPipe,_ = ADHarvestManager.getOpenPipePercent(combine)
	return openPipe or ADHarvestManager.doesHarvesterNeedUnloading(combine, true)
end

function AutoDrive:getCombineOpenPipePercent(combine)	--for AIVE
	local _, pipePercent = ADHarvestManager.getOpenPipePercent(combine)
	return pipePercent
end

-- start CP using CP HUD settings. Allows CP to control job parameters.
function AutoDrive:StartCP(vehicle)
    local cpDelay = AutoDrive.getSetting("CPDelayWaitTime", vehicle) -- delay in seconds, set in vehicle settings.
    local cpDelayInc = 0.35 -- timer addition to make it work for seconds as cpDelay
    local isPassingToCP = (vehicle.ad.stateModule:getStartCP_AIVE() and vehicle.ad.stateModule:getUseCP_AIVE())
    local target = vehicle.ad.stateModule:getFirstMarker().name
    local mapMarker = ADGraphManager:getMapMarkerByWayPointId(vehicle.destinationID)

    if mapMarker ~= nil and mapMarker.name ~= nil then
        target = mapMarker.name
    end
    if vehicle == nil then
        return
    end
    if not isPassingToCP then
        if vehicle.cpDelayTimer ~= nil then
            vehicle.cpDelayTimer:timer(false)
        end
        if vehicle.ad.stateModule:isActive() then
            vehicle.ad.stateModule:setActive(false)
        end
        vehicle.cpDelayWait = false
        return
    end
    if vehicle.cpDelayTimer == nil then
        vehicle.cpDelayTimer = AutoDriveTON:new()
    end
    if vehicle.cpDelay ~= nil then
        cpDelay = vehicle.cpDelay
    else
        vehicle.cpDelay = cpDelay * 10
    end

    AutoDrive.debugPrint(vehicle, AutoDrive.DC_EXTERNALINTERFACEINFO, "AutoDrive:StartCP...")
    if AutoDrive.experimentalFeatures.DelayCoursePlay then
        -- TODO: Need to add HUD data showing delay and time left

        AutoDrive.debugPrint(vehicle, AutoDrive.DC_EXTERNALINTERFACEINFO, "AutoDrive:StartCP - Trying CP interface with delay")
        -- Added in delay timer to allow convoy to be set from start point to CP pickup point. AD will wait to hand over to CP.hasCpCourse
        if not vehicle.cpDelayTimer:done() then
            if not vehicle.ad.stateModule:isActive() then
                AutoDriveMessageEvent.sendNotification(vehicle, ADMessagesManager.messageTypes.INFO, "$l10n_AD_Driver_of; %s $l10n_AD_wait_CP; %s", 5000, vehicle.ad.stateModule:getName(), target)
                vehicle.ad.stateModule:setActive(true)
            end
            vehicle.cpDelayWait = true
            AutoDrive.debugPrint(vehicle, AutoDrive.DC_EXTERNALINTERFACEINFO, "AutoDrive:StartCP - Checking CP delay in progress")
            AutoDrive.debugPrint(vehicle, AutoDrive.DC_EXTERNALINTERFACEINFO, "AutoDrive:StartCP - Checking CP delay times "..vehicle.cpDelayTimer.elapsedTime.."/"..vehicle.cpDelay)
            vehicle.cpDelayTimer:timer(true, vehicle.cpDelay, cpDelayInc)
        else
            AutoDrive.debugPrint(vehicle, AutoDrive.DC_EXTERNALINTERFACEINFO, "AutoDrive:StartCP - Checking CP delay finished")
            vehicle.cpDelayTimer:timer(false)
            if vehicle.ad.stateModule:isActive() then
                vehicle.ad.stateModule:setActive(false)
            end
            vehicle.ad.stateModule:toggleStartCP_AIVE()
            vehicle.cpDelayWait = false
            AutoDriveMessageEvent.sendNotification(vehicle, ADMessagesManager.messageTypes.INFO, "$l10n_AD_Driver_of; %s $l10n_AD_start_CP; %s", 5000, vehicle.ad.stateModule:getName(), target)
            vehicle:cpStartStopDriver()
        end

    else
        AutoDrive.debugPrint(vehicle, AutoDrive.DC_EXTERNALINTERFACEINFO, "AutoDrive:StartCP - Trying CP interface without delay")
        if vehicle.ad.stateModule:isActive() then
            vehicle.ad.stateModule:setActive(false)
        end
        vehicle.ad.stateModule:toggleStartCP_AIVE()
        AutoDriveMessageEvent.sendNotification(vehicle, ADMessagesManager.messageTypes.INFO, "$l10n_AD_Driver_of; %s $l10n_AD_start_CP; %s", 5000, vehicle.ad.stateModule:getName(), target)
        vehicle:cpStartStopDriver()
    end
end

-- restart CP to continue
function AutoDrive:RestartCP(vehicle)
    if vehicle == nil then 
        return 
    end
    AutoDrive.debugPrint(vehicle, AutoDrive.DC_EXTERNALINTERFACEINFO, "AutoDrive:RestartCP...")
    if vehicle.startCpAtLastWp ~= nil then
        vehicle:startCpAtLastWp()
    elseif vehicle.startCpALastWp ~= nil then
        vehicle:startCpALastWp()
    else
        AutoDrive.debugPrint(vehicle, AutoDrive.DC_EXTERNALINTERFACEINFO, "AutoDrive:RestartCP - Not possible. CP interface not found")
    end
end

-- stop CP if it is active
function AutoDrive:StopCP(vehicle)
    if vehicle == nil then 
        return 
    end
    local vehicleToCheck = vehicle.getRootVehicle and vehicle:getRootVehicle()

    AutoDrive.debugPrint(vehicle, AutoDrive.DC_EXTERNALINTERFACEINFO, "AutoDrive:StopCP...")

    if vehicleToCheck ~= nil then
        if vehicleToCheck.cpStartStopDriver ~= nil then
            if vehicleToCheck:getIsCpActive() then
                AutoDrive.debugPrint(vehicleToCheck, AutoDrive.DC_EXTERNALINTERFACEINFO, "AutoDrive:StopCP - cpStartStopDriver")
                vehicleToCheck:cpStartStopDriver()
            end
            if vehicleToCheck.ad ~= nil and vehicleToCheck.ad.stateModule ~= nil and vehicleToCheck.ad.stateModule:getUseCP_AIVE() and  vehicleToCheck.ad.stateModule:getStartCP_AIVE() then
                -- CP button active
                -- deactivate CP button
                AutoDrive.debugPrint(vehicleToCheck, AutoDrive.DC_EXTERNALINTERFACEINFO, "AutoDrive:StopCP - deactivate CP button")
                vehicleToCheck.ad.stateModule:setStartCP_AIVE(false)
            end
            vehicleToCheck.ad.restartCP = false -- do not continue CP course
        else
            AutoDrive.debugPrint(vehicleToCheck, AutoDrive.DC_EXTERNALINTERFACEINFO, "AutoDrive:StopCP - Not possible. CP interface not found")
        end
    end
end

function AutoDrive:HoldDriving(vehicle)
    if vehicle ~= nil and vehicle.ad ~= nil and vehicle.ad.stateModule:isActive() then
        AutoDrive.debugPrint(vehicle, AutoDrive.DC_EXTERNALINTERFACEINFO, "AutoDrive:HoldDriving should set setPaused")
        vehicle.ad.drivePathModule:setPaused()
    end
end

function AutoDrive:logCPStatus(vehicle, functionName)
    if vehicle == nil then
        return false
    end
    if (g_updateLoopIndex % 60) == 0 then
        local vehicleToCheck = vehicle.getRootVehicle and vehicle:getRootVehicle()
        if vehicleToCheck then
            if vehicleToCheck.getIsCpActive then
                AutoDrive.debugPrint(vehicleToCheck, AutoDrive.DC_EXTERNALINTERFACEINFO, "%s getIsCpActive %s", functionName, tostring(vehicleToCheck:getIsCpActive()))
            end
            if vehicleToCheck.getIsCpHarvesterWaitingForUnload then
                AutoDrive.debugPrint(vehicleToCheck, AutoDrive.DC_EXTERNALINTERFACEINFO, "%s getIsCpHarvesterWaitingForUnload %s", functionName, tostring(vehicleToCheck:getIsCpHarvesterWaitingForUnload()))
            end
            if  vehicleToCheck.getIsCpHarvesterWaitingForUnloadInPocket then
                AutoDrive.debugPrint(vehicleToCheck, AutoDrive.DC_EXTERNALINTERFACEINFO, "%s getIsCpHarvesterWaitingForUnloadInPocket %s", functionName, tostring(vehicleToCheck:getIsCpHarvesterWaitingForUnloadInPocket()))
            end
            if vehicleToCheck.getIsCpHarvesterWaitingForUnloadAfterPulledBack then
                AutoDrive.debugPrint(vehicleToCheck, AutoDrive.DC_EXTERNALINTERFACEINFO, "%s getIsCpHarvesterWaitingForUnloadAfterPulledBack %s", functionName, tostring(vehicleToCheck:getIsCpHarvesterWaitingForUnloadAfterPulledBack()))
            end
            if  vehicleToCheck.getIsCpHarvesterManeuvering then
                AutoDrive.debugPrint(vehicleToCheck, AutoDrive.DC_EXTERNALINTERFACEINFO, "%s getIsCpHarvesterManeuvering %s", functionName, tostring(vehicleToCheck:getIsCpHarvesterManeuvering()))
            end
        end
    end
end

function AutoDrive:getIsCPActive(vehicle)
    if vehicle == nil then
        return false
    end
    local vehicleToCheck = vehicle.getRootVehicle and vehicle:getRootVehicle()

    -- AutoDrive:logCPStatus(vehicleToCheck, "holdCPCombine") -- enable only if required

    if vehicleToCheck and vehicleToCheck.getIsCpActive and vehicleToCheck:getIsCpActive() then
        return true
    else
        return false
    end

end

function AutoDrive:holdCPCombine(vehicle)
    if vehicle == nil then
        AutoDrive.debugPrint(vehicle, AutoDrive.DC_EXTERNALINTERFACEINFO, "AutoDrive:holdCPCombine start ERROR: vehicle == nil")
        return false
    end
    local vehicleToCheck = vehicle.getRootVehicle and vehicle:getRootVehicle()

    AutoDrive:logCPStatus(vehicleToCheck, "holdCPCombine")

    if vehicleToCheck and AutoDrive:getIsCPActive(vehicleToCheck) 
        and
        (
            (vehicleToCheck.holdCpHarvesterTemporarily)
        )
    then
        if (g_updateLoopIndex % 60) == 0 then
            AutoDrive.debugPrint(vehicleToCheck, AutoDrive.DC_EXTERNALINTERFACEINFO, "AutoDrive:holdCPCombine ")
        end
        vehicleToCheck:holdCpHarvesterTemporarily(200) -- hold 200 ms
    end
end

function AutoDrive:getIsCPCombineInPocket(vehicle)
    if vehicle == nil then
        AutoDrive.debugPrint(vehicle, AutoDrive.DC_EXTERNALINTERFACEINFO, "AutoDrive:getIsCPCombineInPocket start ERROR: vehicle == nil")
        return false
    end
    local vehicleToCheck = vehicle.getRootVehicle and vehicle:getRootVehicle()

    AutoDrive:logCPStatus(vehicleToCheck, "getIsCPCombineInPocket")

    if vehicleToCheck and AutoDrive:getIsCPActive(vehicleToCheck) 
        and
        (
            (vehicleToCheck.getIsCpHarvesterWaitingForUnloadInPocket and vehicleToCheck:getIsCpHarvesterWaitingForUnloadInPocket())
            or 
            (vehicleToCheck.getIsCpHarvesterWaitingForUnloadAfterPulledBack and vehicleToCheck:getIsCpHarvesterWaitingForUnloadAfterPulledBack())
        )
    then
        AutoDrive.debugPrint(vehicleToCheck, AutoDrive.DC_EXTERNALINTERFACEINFO, "AutoDrive:getIsCPCombineInPocket AutoDrive:getIsCPCombineInPocket return true")
        return true
    else
        return false
    end

end

function AutoDrive:getIsCPWaitingForUnload(vehicle)
    if vehicle == nil then
        AutoDrive.debugPrint(vehicle, AutoDrive.DC_EXTERNALINTERFACEINFO, "AutoDrive:getIsCPWaitingForUnload start ERROR: vehicle == nil")
        return false
    end

    local vehicleToCheck = vehicle.getRootVehicle and vehicle:getRootVehicle()

    AutoDrive:logCPStatus(vehicleToCheck, "getIsCPWaitingForUnload")

    if vehicleToCheck and AutoDrive:getIsCPActive(vehicleToCheck)
        and
        (
            (vehicleToCheck.getIsCpHarvesterWaitingForUnload and vehicleToCheck:getIsCpHarvesterWaitingForUnload())
        )
    then
        if (g_updateLoopIndex % 60) == 0 then
            AutoDrive.debugPrint(vehicleToCheck, AutoDrive.DC_EXTERNALINTERFACEINFO, "AutoDrive:getIsCPWaitingForUnload return true")
        end
        return true
    else
        return false
    end

end

function AutoDrive:getIsCPTurning(vehicle)
    if vehicle == nil then
        AutoDrive.debugPrint(vehicle, AutoDrive.DC_EXTERNALINTERFACEINFO, "AutoDrive:getIsCPTurning start ERROR: vehicle == nil")
        return false
    end
    local vehicleToCheck = vehicle.getRootVehicle and vehicle:getRootVehicle()

    AutoDrive:logCPStatus(vehicleToCheck, "getIsCPTurning")

    if vehicleToCheck and AutoDrive:getIsCPActive(vehicleToCheck) 
        and 
        (
            (vehicleToCheck.getIsCpHarvesterManeuvering and vehicleToCheck:getIsCpHarvesterManeuvering())
        )
    then
        if (g_updateLoopIndex % 60) == 0 then
            AutoDrive.debugPrint(vehicleToCheck, AutoDrive.DC_EXTERNALINTERFACEINFO, "AutoDrive:getIsCPTurning return true")
        end
        return true
    else
        return false
    end

end

-- Autoloader
--[[
APalletAutoLoader:
]]
function AutoDrive:hasAL(object)
    if object == nil then
        return false
    end
    return object.spec_aPalletAutoLoader ~= nil
end

--[[
    STOPPED = 1,
    RUNNING = 2
]]

function AutoDrive:setALOn(object)
    if object == nil then
        return false
    end
    local spec = object.spec_aPalletAutoLoader
    if spec and object.SetLoadingState then
        -- set loading state off
        AutoDrive.debugPrint(object, AutoDrive.DC_EXTERNALINTERFACEINFO, "AutoDrive:setALOn SetLoadingState 2")
        object:SetLoadingState(2)
    end
end

function AutoDrive:setALOff(object)
    if object == nil then
        return false
    end

    local spec = object.spec_aPalletAutoLoader
    if spec and object.SetLoadingState then
        -- set loading state off
        AutoDrive.debugPrint(object, AutoDrive.DC_EXTERNALINTERFACEINFO, "AutoDrive:setALOff SetLoadingState 1")
        object:SetLoadingState(1)
    end
end

function AutoDrive.activateALTrailers(vehicle, trailers)
    if vehicle == nil or trailers == nil then
        return false
    end
    AutoDrive.debugPrint(vehicle, AutoDrive.DC_EXTERNALINTERFACEINFO, "AutoDrive:activateALTrailers")
    if #trailers > 0 then
        for i=1, #trailers do
            AutoDrive:setALOn(trailers[i])
        end
    end
end

function AutoDrive.deactivateALTrailers(vehicle, trailers)
    if vehicle == nil or trailers == nil then
        return false
    end
    AutoDrive.debugPrint(vehicle, AutoDrive.DC_EXTERNALINTERFACEINFO, "AutoDrive:deactivateTrailerAL")
    if #trailers > 0 then
        for i=1, #trailers do
            AutoDrive:setALOff(trailers[i])
        end
    end
end

--[[
APalletAutoLoaderTipsides = {
    LEFT = 1,
    RIGHT = 2
    MIDDLE = 3

}
    values = {0, 1, 2, 3, 4},
    texts = {"gui_ad_AL_off", "gui_ad_AL_center", "gui_ad_AL_left", "gui_ad_AL_behind", "gui_ad_AL_right"},

]]
-- TODO: unload in rear
function AutoDrive:unloadAL(object)
    if object == nil or not AutoDrive:hasAL(object) then
        return false
    end
    AutoDrive.debugPrint(object, AutoDrive.DC_EXTERNALINTERFACEINFO, "AutoDrive:unloadAL start")
    local rootVehicle = object:getRootVehicle()
    local unloadPositions = {
        3,
        1,
        0,
        2
    }

    local unloadPositionSetting = AutoDrive.getSetting("ALUnload", rootVehicle)
    AutoDrive.debugPrint(object, AutoDrive.DC_EXTERNALINTERFACEINFO, "AutoDrive:unloadAL unloadPositionSetting %s", tostring(unloadPositionSetting))
    if unloadPositionSetting ~= nil and unloadPositionSetting > 0 then
        local unloadPosition = unloadPositions[unloadPositionSetting]
        AutoDrive.debugPrint(object, AutoDrive.DC_EXTERNALINTERFACEINFO, "AutoDrive:unloadAL unloadPosition %s", tostring(unloadPosition))
        if unloadPosition ~= nil then
            -- should unload
            AutoDrive.debugPrint(object, AutoDrive.DC_EXTERNALINTERFACEINFO, "AutoDrive:unloadAL should unload")
            if object.setAllTensionBeltsActive ~= nil then
                object:setAllTensionBeltsActive(false, false)
            end
            local spec = object.spec_aPalletAutoLoader
            if spec and object.SetTipside and object.unloadAll then
                AutoDrive.debugPrint(object, AutoDrive.DC_EXTERNALINTERFACEINFO, "AutoDrive:unloadAL SetTipside unloadPosition %s", tostring(unloadPosition))
                if unloadPosition > 0 then
                    object:SetTipside(unloadPosition)
                end
                -- set loading state off
                object:unloadAll()
            end
        end
    end
    AutoDrive.debugPrint(object, AutoDrive.DC_EXTERNALINTERFACEINFO, "AutoDrive:unloadAL end")
end

function AutoDrive:unloadALAll(vehicle) -- used by UnloadAtDestinationTask
    if vehicle == nil then
        return false
    end
    local trailers, trailerCount = AutoDrive.getAllUnits(vehicle)
    AutoDrive.debugPrint(vehicle, AutoDrive.DC_EXTERNALINTERFACEINFO, "AutoDrive:unloadALAll trailerCount %s", tostring(trailerCount))
    if trailerCount > 0 then
        for i=1, trailerCount do
            AutoDrive:unloadAL(trailers[i])
        end
    end
end

function AutoDrive:getALObjectFillLevels(object) -- used by getIsFillUnitEmpty, getIsFillUnitFull, getObjectFillLevels, getAllFillLevels
    if object == nil then
        Logging.error("[AD] AutoDrive.getALObjectFillLevels object == nil")
        return 0, 0, false, 0
    end
    local rootVehicle = object:getRootVehicle()
    if rootVehicle == nil then
        Logging.error("[AD] AutoDrive.getALObjectFillLevels rootVehicle == nil")
        return 0, 0, false, 0
    end
    AutoDrive.debugPrint(object, AutoDrive.DC_EXTERNALINTERFACEINFO, "AutoDrive:getALObjectFillLevels object.spec_aPalletAutoLoader %s ", tostring(object.spec_aPalletAutoLoader))
    local fillCapacity = 0
    local fillLevel = 0
    local fillFreeCapacity = 0
    local spec = object.spec_aPalletAutoLoader
    if spec and object.getFillUnitCapacity and object.getFillUnitFillLevel and object.getFillUnitFreeCapacity then
        fillCapacity = object:getFillUnitCapacity()
        fillLevel = object:getFillUnitFillLevel()
        fillFreeCapacity = object:getFillUnitFreeCapacity()
        AutoDrive.debugPrint(object, AutoDrive.DC_EXTERNALINTERFACEINFO, "AutoDrive:getALObjectFillLevels fillCapacity %s fillLevel %s fillFreeCapacity %s", tostring(fillCapacity), tostring(fillLevel), tostring(fillFreeCapacity))
    end
    local filledToUnload = AutoDrive.isUnloadFillLevelReached(rootVehicle, fillFreeCapacity, fillCapacity)
    return fillLevel, fillCapacity, filledToUnload, fillFreeCapacity
end

function AutoDrive:getALFillTypes(object) -- used by PullDownList, getSupportedFillTypesOfAllUnitsAlphabetically
    if object == nil then
        return {}
    end
    local fillTypes = {}

    local spec = object.spec_aPalletAutoLoader
    if spec and object.GetAutoloadTypes then
        local autoLoadTypes = object:GetAutoloadTypes()
        if autoLoadTypes and table.count(autoLoadTypes) > 0 then
            for i = 1, table.count(autoLoadTypes) do
                if autoLoadTypes[i].nameTranslated then
                    table.insert(fillTypes, autoLoadTypes[i].nameTranslated)
                end
            end
        end
    end
    AutoDrive.debugPrint(vehicle, AutoDrive.DC_EXTERNALINTERFACEINFO, "AutoDrive:getALFillTypes #fillTypes %s", tostring(#fillTypes))
    return fillTypes
end

function AutoDrive:getALCurrentFillType(object) -- used by onEnterVehicle, onPostAttachImplement
    if object == nil then
        return nil
    end

    local spec = object.spec_aPalletAutoLoader
    if spec and spec.currentautoLoadTypeIndex then
        return spec.currentautoLoadTypeIndex
    end
    return nil
end

function AutoDrive:setALFillType(vehicle, fillType) -- used by PullDownList
    if vehicle == nil or fillType == nil then
        return false
    end
    AutoDrive.debugPrint(vehicle, AutoDrive.DC_EXTERNALINTERFACEINFO, "AutoDrive:setALFillType")
    local trailers, trailerCount = AutoDrive.getAllUnits(vehicle)
    if trailerCount > 0 then
        for i=1, trailerCount do
            local object = trailers[i]
            local spec = object.spec_aPalletAutoLoader
            if spec and object.SetLoadingState and object.SetAutoloadType then
                AutoDrive.debugPrint(vehicle, AutoDrive.DC_EXTERNALINTERFACEINFO, "AutoDrive:setALFillType fillType %s", tostring(fillType))
                -- set loading state off
                object:SetLoadingState(1)
                object:SetAutoloadType(fillType)
            end
        end
    end
end

