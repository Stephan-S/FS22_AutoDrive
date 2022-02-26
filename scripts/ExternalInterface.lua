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
                    local fillLevel, _, _ = AutoDrive.getAllNonFuelFillLevels(trailers)
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

-- start CP at first wayPoint
function AutoDrive:StartCP(vehicle)
    if vehicle == nil then 
        return 
    end
    AutoDrive.debugPrint(vehicle, AutoDrive.DC_EXTERNALINTERFACEINFO, "AutoDrive:StartCP...")
    -- if vehicle.startCpAtFirstWp ~= nil then
        -- vehicle:startCpAtFirstWp()
    if vehicle.startCpAtLastWp ~= nil then
        vehicle:startCpAtLastWp()
    elseif vehicle.startCpALastWp ~= nil then
        vehicle:startCpALastWp()
    else
        AutoDrive.debugPrint(vehicle, AutoDrive.DC_EXTERNALINTERFACEINFO, "AutoDrive:StartCP - Not possible. CP interface not found")
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
easyAutoLoader:
- old, i.e. embedded in mod, has easyAutoLoaderActionEvents
- new, standalone FS19_EasyAutoLoad has the variables in spec_easyAutoLoader, but functions direct in vehicle type
]]
function AutoDrive:hasAL(object)
    if object == nil then
        return false
    end
    -- AutoDrive.debugMsg(object, "AutoDrive:hasAL object.easyAutoLoaderActionEvents %s object.spec_easyAutoLoader %s", tostring(object.easyAutoLoaderActionEvents), tostring(object.easyAutoLoaderActionEvents))
    return object.easyAutoLoaderActionEvents ~= nil or (object.spec_easyAutoLoader ~= nil and object.spec_easyAutoLoader.workMode ~= nil )
end

function AutoDrive:getALWorkMode(object)
    if object == nil or not AutoDrive:hasAL(object) then
        return nil
    end
    AutoDrive.debugPrint(object, AutoDrive.DC_EXTERNALINTERFACEINFO, "AutoDrive:getALWorkMode")
    if object.easyAutoLoaderActionEvents ~= nil then
        return object.workMode
    elseif object.spec_easyAutoLoader ~= nil and object.spec_easyAutoLoader.workMode ~= nil then
        return object.spec_easyAutoLoader.workMode
    end
    return nil
end

function AutoDrive:setALOn(object)
    if object == nil or not AutoDrive:hasAL(object) then
        return false
    end
    AutoDrive.debugPrint(object, AutoDrive.DC_EXTERNALINTERFACEINFO, "AutoDrive:setALOn")
    local workMode = AutoDrive:getALWorkMode(object)
    -- AutoDrive.debugMsg(object, "AutoDrive:setALOn object.workMode %s", tostring(object.workMode))
    if workMode == false then
        -- AutoDrive.debugMsg(object, "AutoDrive:setALOn setWorkMode")
        object:setWorkMode()
    end
    -- AutoDrive.debugMsg(object, "AutoDrive:setALOn object.workMode %s", tostring(object.workMode))
end

function AutoDrive:setALOff(object)
    if object == nil or not AutoDrive:hasAL(object) then
        return false
    end
    AutoDrive.debugPrint(object, AutoDrive.DC_EXTERNALINTERFACEINFO, "AutoDrive:setALOff")
    local workMode = AutoDrive:getALWorkMode(object)
    -- AutoDrive.debugMsg(object, "AutoDrive:setALOff object.workMode %s", tostring(object.workMode))
    if workMode == true then
        -- AutoDrive.debugMsg(object, "AutoDrive:setALOff setWorkMode")
        object:setWorkMode()
    end
    -- AutoDrive.debugMsg(object, "AutoDrive:setALOff object.workMode %s", tostring(object.workMode))
end

function AutoDrive.activateALTrailers(vehicle, trailers)
    if vehicle == nil or trailers == nil then
        return false
    end
    AutoDrive.debugPrint(object, AutoDrive.DC_EXTERNALINTERFACEINFO, "AutoDrive:activateALTrailers")
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
    AutoDrive.debugPrint(object, AutoDrive.DC_EXTERNALINTERFACEINFO, "AutoDrive:deactivateTrailerAL")
    if #trailers > 0 then
        for i=1, #trailers do
            AutoDrive:setALOff(trailers[i])
        end
    end
end

--[[
    values = {0, 1, 2, 3, 4},
    texts = {"gui_ad_AL_off", "gui_ad_AL_center", "gui_ad_AL_left", "gui_ad_AL_behind", "gui_ad_AL_right"},

]]
function AutoDrive:unloadAL(object)
    if object == nil or not AutoDrive:hasAL(object) then
        return false
    end
    AutoDrive.debugPrint(object, AutoDrive.DC_EXTERNALINTERFACEINFO, "AutoDrive:unloadAL")
    local rootVehicle = object:getRootVehicle()
    local unloadPosition = AutoDrive.getSetting("ALUnload", rootVehicle)
    if unloadPosition ~= nil and unloadPosition > 0 then
        AutoDrive.debugPrint(object, AutoDrive.DC_EXTERNALINTERFACEINFO, "AutoDrive:unloadAL should unload")
        -- should unload
        AutoDrive:setALOff(object)
        if unloadPosition > 1 then
            for i=1, unloadPosition-1 do
                object:changeMarkerPosition()
            end
        end
        object:setUnload()
    end
end

function AutoDrive:unloadALAll(vehicle)
    if vehicle == nil then
        return false
    end
    AutoDrive.debugPrint(vehicle, AutoDrive.DC_EXTERNALINTERFACEINFO, "AutoDrive:unloadALAll")
    local trailers, trailerCount = AutoDrive.getAllUnits(vehicle)
    -- AutoDrive.debugMsg(object, "AutoDrive:unloadALAll trailerCount %s", tostring(trailerCount))
    if trailerCount > 0 then
        for i=1, trailerCount do
            AutoDrive:unloadAL(trailers[i])
        end
    end
end

function AutoDrive:getALOverallFillLevelPercentage(vehicle, trailers)
    if vehicle == nil or trailers == nil then
        return 0
    end
    local percentage = 0
    local percentages = 0
    if #trailers > 0 then
        for i=1, #trailers do
            local object = trailers[i]
            if object.easyAutoLoaderActionEvents ~= nil then
                percentages = percentages + (object.currentNumObjects / object.autoLoadObjects[object.state].maxNumObjects)
            elseif object.spec_easyAutoLoader ~= nil and object.spec_easyAutoLoader.workMode ~= nil then
                percentages = percentages + (object.spec_easyAutoLoader.currentNumObjects / object.spec_easyAutoLoader.autoLoadObjects[object.spec_easyAutoLoader.state].maxNumObjects)
            end
        end
        percentage = percentages / #trailers
    end
    AutoDrive.debugPrint(vehicle, AutoDrive.DC_EXTERNALINTERFACEINFO, "AutoDrive:getALOverallFillLevelPercentage percentage %s", tostring(percentage))
    return percentage
end

function AutoDrive:getALFillLevelPercentage(object)
    if object == nil then
        return 0
    end
    local currentNumObjects = 0
    local maxNumObjects = 1
    if object.easyAutoLoaderActionEvents ~= nil then
        currentNumObjects = object.currentNumObjects
        maxNumObjects = object.autoLoadObjects[object.state].maxNumObjects
    elseif object.spec_easyAutoLoader ~= nil and object.spec_easyAutoLoader.workMode ~= nil then
        currentNumObjects = object.spec_easyAutoLoader.currentNumObjects
        maxNumObjects = object.spec_easyAutoLoader.autoLoadObjects[object.spec_easyAutoLoader.state].maxNumObjects
    end
    if maxNumObjects == 0 then
        maxNumObjects = 1
    end
    AutoDrive.debugPrint(object, AutoDrive.DC_EXTERNALINTERFACEINFO, "AutoDrive:getALFillLevelPercentage currentNumObjects %s maxNumObjects %s", tostring(currentNumObjects), tostring(maxNumObjects))
    return (currentNumObjects / maxNumObjects)
end

function AutoDrive:getALFillLevelAndCapacityOfAllUnits(object)
    if object == nil then
        return 0,0
    end
    local fillLevel = 0
    local leftCapacity = 0

    if object.easyAutoLoaderActionEvents ~= nil then
        fillLevel = object.currentNumObjects
        leftCapacity = object.autoLoadObjects[object.state].maxNumObjects - fillLevel
    elseif object.spec_easyAutoLoader ~= nil and object.spec_easyAutoLoader.workMode ~= nil then
        fillLevel = object.spec_easyAutoLoader.currentNumObjects
        leftCapacity = object.spec_easyAutoLoader.autoLoadObjects[object.spec_easyAutoLoader.state].maxNumObjects - fillLevel
    end
    AutoDrive.debugPrint(object, AutoDrive.DC_EXTERNALINTERFACEINFO, "AutoDrive:getALFillLevelAndCapacityOfAllUnits fillLevel %s leftCapacity %s", tostring(fillLevel), tostring(leftCapacity))
    return fillLevel, leftCapacity
end

function AutoDrive:getALFillTypes(object)
    if object == nil then
        return {}
    end
    local fillTypes = {}
    if object.easyAutoLoaderActionEvents ~= nil then
    	for i = 1, #object.autoLoadObjects do
            table.insert(fillTypes, object.autoLoadObjects[i].nameL)
        end
    elseif object.spec_easyAutoLoader ~= nil and object.spec_easyAutoLoader.workMode ~= nil then
    	for i = 1, #object.spec_easyAutoLoader.autoLoadObjects do
            table.insert(fillTypes, object.spec_easyAutoLoader.autoLoadObjects[i].nameL)
        end
    end
    return fillTypes
end

function AutoDrive:getALCurrentFillType(object)
    if object == nil then
        return nil
    end
    if object.easyAutoLoaderActionEvents ~= nil then
        return object.state
    elseif object.spec_easyAutoLoader ~= nil and object.spec_easyAutoLoader.workMode ~= nil then
        return object.spec_easyAutoLoader.state
    end
    return nil
end

function AutoDrive:setALFillType(vehicle, fillType)
    if vehicle == nil or fillType == nil then
        return false
    end
    AutoDrive.debugPrint(vehicle, AutoDrive.DC_EXTERNALINTERFACEINFO, "AutoDrive:setALFillType")
    local trailers, trailerCount = AutoDrive.getAllUnits(vehicle)
    if trailerCount > 0 then
        for i=1, trailerCount do
            local object = trailers[i]
            local currentWorkMode = AutoDrive:getALWorkMode(object)
            if currentWorkMode == true then
                -- if enabled disable to change fillType
                -- AutoDrive.debugMsg(object, "AutoDrive:setALOn setWorkMode")
                object:setWorkMode()
            end

            if object.easyAutoLoaderActionEvents ~= nil then
                object:doStateChange(3, false, fillType, 0, object.palletIcon, object.squareBaleIcon, object.roundBaleIcon, false)
            elseif object.spec_easyAutoLoader ~= nil and object.spec_easyAutoLoader.workMode ~= nil then
                object:doStateChange(3, false, fillType, 0, object.spec_easyAutoLoader.palletIcon, object.spec_easyAutoLoader.squareBaleIcon, object.spec_easyAutoLoader.roundBaleIcon, false)
            end

            if currentWorkMode == true then
                -- now enable again
                -- AutoDrive.debugMsg(object, "AutoDrive:setALOn setWorkMode")
                object:setWorkMode()
            end

        end
    end
end

