function AutoDrive.getIsFilled(vehicle, trailer, fillUnitIndex)
    local vehicleFull = false
    local trailerFull = false
    local fillUnitFull = false

    if vehicle ~= nil then
        local allFillables, _ = AutoDrive.getTrailersOf(vehicle, false)
        local fillLevel, leftCapacity = AutoDrive.getFillLevelAndCapacityOfAll(allFillables)
        local maxCapacity = fillLevel + leftCapacity
        vehicleFull = (leftCapacity <= (maxCapacity * (1 - AutoDrive.getSetting("unloadFillLevel", vehicle) + 0.001)))
    end

    if trailer ~= nil then
        local trailerFillLevel, trailerLeftCapacity = AutoDrive.getFilteredFillLevelAndCapacityOfAllUnits(trailer)
        local maxCapacity = trailerFillLevel + trailerLeftCapacity
        trailerFull = (trailerLeftCapacity <= (maxCapacity * (1 - AutoDrive.getSetting("unloadFillLevel", vehicle) + 0.001)))
    end

    if fillUnitIndex ~= nil then
        if trailer ~= nil and AutoDrive:hasAL(trailer) then
            -- AutoLoad
            fillUnitFull = AutoDrive:getALFillLevelPercentage(trailer) >= AutoDrive.getSetting("unloadFillLevel", vehicle) * 0.999
        else
            fillUnitFull = trailer:getFillUnitFillLevelPercentage(fillUnitIndex) >= AutoDrive.getSetting("unloadFillLevel", vehicle) * 0.999
        end
    end

    return vehicleFull, trailerFull, fillUnitFull
end

function AutoDrive.getIsEmpty(vehicle, trailer, fillUnitIndex)
    local vehicleEmpty = false
    local trailerEmpty = false
    local fillUnitEmpty = false

    if vehicle ~= nil then
        local allFillables, _ = AutoDrive.getTrailersOf(vehicle, false)
        local fillLevel, _ = AutoDrive.getFillLevelAndCapacityOfAll(allFillables)
        --local maxCapacity = fillLevel + leftCapacity
        vehicleEmpty = fillLevel <= 0.001
    end

    if trailer ~= nil then
        local trailerFillLevel, _ = AutoDrive.getFilteredFillLevelAndCapacityOfAllUnits(trailer)
        --local maxCapacity = trailerFillLevel + trailerLeftCapacity
        trailerEmpty = trailerFillLevel <= 0.001
    end

    if fillUnitIndex ~= nil then
        if trailer ~= nil and AutoDrive:hasAL(trailer) then
            -- AutoLoad
            fillUnitEmpty = AutoDrive:getALFillLevelPercentage(trailer) <= 0.001
        else
            fillUnitEmpty = trailer:getFillUnitFillLevelPercentage(fillUnitIndex) <= 0.001
        end
    end

    return vehicleEmpty, trailerEmpty, fillUnitEmpty
end

function AutoDrive.fillTypesMatch(vehicle, fillTrigger, workTool, allowedFillTypes, fillTypeIndex)
    if fillTrigger ~= nil then
        local typesMatch = false
        local selectedFillType = vehicle.ad.stateModule:getFillType() or FillType.UNKNOWN
        local fillUnits = workTool:getFillUnits()

        local fillTypesToCheck = {}
        if allowedFillTypes ~= nil then
            fillTypesToCheck = allowedFillTypes
        else
            if vehicle.ad.stateModule:getFillType() == nil then
                table.insert(fillTypesToCheck, FillType.UNKNOWN)
            else
                table.insert(fillTypesToCheck, vehicle.ad.stateModule:getFillType())
            end
        end

        -- go through the single fillUnits and check:
        -- does the trigger support the tools filltype ?
        -- does the trigger support the single fillUnits filltype ?
        -- does the trigger and the fillUnit match the selectedFilltype or do they ignore it ?
        for i = 1, #fillUnits do
            if fillTypeIndex == nil or i == fillTypeIndex then
                local selectedFillTypeIsNotInMyFillUnit = true
                local matchInThisUnit = false
                for index, _ in pairs(workTool:getFillUnitSupportedFillTypes(i)) do
                    --loadTriggers
                    -- standard silo
                    if fillTrigger.source ~= nil and fillTrigger.source.providedFillTypes ~= nil and fillTrigger.source.providedFillTypes[index] then
                        typesMatch = true
                        matchInThisUnit = true
                    end
                    if fillTrigger.source ~= nil and fillTrigger.source.gcId ~= nil and fillTrigger.source.fillLevels ~= nil and fillTrigger.source.fillLevels[index] then
                        typesMatch = true
                        matchInThisUnit = true
                    end
                    
                    --fillTriggers
                    if fillTrigger.source ~= nil and fillTrigger.source.productLines ~= nil then --is gc trigger
                        for _, subSource in pairs(fillTrigger.source.providedFillTypes) do
                            --if type(subSource) == "table" then
                                if subSource[index] ~= nil then
                                    typesMatch = true
                                    matchInThisUnit = true
                                end
                            --end
                        end
                    end

                    if fillTrigger.sourceObject ~= nil then
                        local fillTypes = fillTrigger.sourceObject:getFillUnitSupportedFillTypes(1)
                        if fillTypes[index] then
                            typesMatch = true
                            matchInThisUnit = true
                        end
                    end

                    for _, allowedFillType in pairs(fillTypesToCheck) do
                        if index == allowedFillType and allowedFillType ~= FillType.UNKNOWN then
                            selectedFillTypeIsNotInMyFillUnit = false
                        end
                    end
                end
                if matchInThisUnit and selectedFillTypeIsNotInMyFillUnit then
                    return false
                end
            end
        end

        if typesMatch then
            for _, allowedFillType in pairs(fillTypesToCheck) do
                if allowedFillType == FillType.UNKNOWN then
                    return true
                end
            end

            local isFillType = false
            for _, allowedFillType in pairs(fillTypesToCheck) do
                if fillTrigger.source then
                    if fillTrigger.source.productLines ~= nil then --is gc trigger
                        return true
                    else
                        if (fillTrigger.source.providedFillTypes ~= nil and fillTrigger.source.providedFillTypes[allowedFillType]) or 
                            (fillTrigger.source.fillLevels ~= nil and fillTrigger.source.fillLevels[allowedFillType]) then
                            return true
                        end
                    end
                elseif fillTrigger.sourceObject ~= nil then
                    local fillType = fillTrigger.sourceObject:getFillUnitFillType(1)
                    isFillType = (fillType == selectedFillType)
                end
            end
            return isFillType
        end
    end
    return false
end

function AutoDrive.getTrailersOf(vehicle, onlyDischargeable)
    AutoDrive.tempTrailers = {}
    AutoDrive.tempTrailerCount = 0

    if (vehicle.spec_dischargeable ~= nil or not (onlyDischargeable == true)) and vehicle.getFillUnits ~= nil then
        local vehicleFillLevel, vehicleLeftCapacity = AutoDrive.getFilteredFillLevelAndCapacityOfAllUnits(vehicle, nil)
        --g_logManager:devInfo("VehicleFillLevel: " .. vehicleFillLevel .. " vehicleLeftCapacity: " .. vehicleLeftCapacity);
        if not (vehicleFillLevel == 0 and vehicleLeftCapacity == 0) then
            AutoDrive.tempTrailerCount = AutoDrive.tempTrailerCount + 1
            AutoDrive.tempTrailers[AutoDrive.tempTrailerCount] = vehicle
        end
    end
    --g_logManager:devInfo("AutoDrive.tempTrailerCount after vehicle: "  .. AutoDrive.tempTrailerCount);

    if vehicle.getAttachedImplements ~= nil then
        for _, implement in pairs(vehicle:getAttachedImplements()) do
            AutoDrive.getTrailersOfImplement(implement.object, onlyDischargeable)
        end
    end

    return AutoDrive.tempTrailers, AutoDrive.tempTrailerCount
end

function AutoDrive.getTrailersOfImplement(attachedImplement, onlyDischargeable)
    if (((attachedImplement.typeDesc == g_i18n:getText("typeDesc_tipper") or attachedImplement.spec_dischargeable ~= nil) or not (onlyDischargeable == true)) and attachedImplement.getFillUnits ~= nil) or AutoDrive:hasAL(attachedImplement) then
        if not (attachedImplement.vehicleType.specializationsByName["leveler"] ~= nil or attachedImplement.typeDesc == g_i18n:getText("typeDesc_frontloaderTool") or attachedImplement.typeDesc == g_i18n:getText("typeDesc_wheelLoaderTool")) then --avoid trying to fill shovels and levellers atached
            local trailer = attachedImplement
            AutoDrive.tempTrailerCount = AutoDrive.tempTrailerCount + 1
            AutoDrive.tempTrailers[AutoDrive.tempTrailerCount] = trailer
        end
    end
    if attachedImplement.getAttachedImplements ~= nil then
        for _, implement in pairs(attachedImplement:getAttachedImplements()) do
            AutoDrive.getTrailersOfImplement(implement.object)
        end
    end

    return
end

function AutoDrive.getBackImplementsOf(vehicle, onlyDischargeable)
    AutoDrive.tempBackImplements = {}
    AutoDrive.tempBackImplementsCount = 0

    if vehicle.getAttachedImplements ~= nil then
        for _, implement in pairs(vehicle:getAttachedImplements()) do
            if implement ~= nil and implement.object ~= nil and implement.object ~= vehicle then
                local implementX, implementY, implementZ = getWorldTranslation(implement.object.components[1].node)
                local _, _, diffZ = worldToLocal(vehicle.components[1].node, implementX, implementY, implementZ)
                if diffZ < 0 then
                    AutoDrive.tempBackImplementsCount = AutoDrive.tempBackImplementsCount + 1
                    AutoDrive.tempBackImplements[AutoDrive.tempBackImplementsCount] = implement.object
                end
            end
        end
    end

    return AutoDrive.tempBackImplements, AutoDrive.tempBackImplementsCount
end

function AutoDrive.getDistanceToTargetPosition(vehicle)
    -- returns the distance to load destination depending on mode
    if vehicle.ad.stateModule:getFirstMarker() == nil then
        return math.huge
    end
    local x, _, z = getWorldTranslation(vehicle.components[1].node)
    local destination = ADGraphManager:getWayPointById(vehicle.ad.stateModule:getFirstMarker().id)

    if vehicle.ad.stateModule:getMode() == AutoDrive.MODE_LOAD then
        -- in pickup mode return distance to second destination
        if vehicle.ad.stateModule:getSecondMarker() == nil then
            return math.huge
        end
        destination = ADGraphManager:getWayPointById(vehicle.ad.stateModule:getSecondMarker().id)
    end
    if destination == nil then
        return math.huge
    end
    return MathUtil.vector2Length(x - destination.x, z - destination.z)
end

function AutoDrive.getDistanceToUnloadPosition(vehicle)
    -- returns the distance to unload destination depending on mode
    local x, _, z = getWorldTranslation(vehicle.components[1].node)
    local destination = nil
    if vehicle.ad.stateModule:getMode() == AutoDrive.MODE_DELIVERTO then
        -- in deliver mode only 1st target in HUD is taken
        if vehicle.ad.stateModule:getFirstMarker() == nil then
            return math.huge
        end
        destination = ADGraphManager:getWayPointById(vehicle.ad.stateModule:getFirstMarker().id)
    elseif vehicle.ad.stateModule:getMode() == AutoDrive.MODE_LOAD then
        -- in pickup mode no unload in this mode, so return huge distance
        return math.huge
    else
        if vehicle.ad.stateModule:getSecondMarker() == nil then
            return math.huge
        end
        destination = ADGraphManager:getWayPointById(vehicle.ad.stateModule:getSecondMarker().id)
    end
    if destination == nil then
        return math.huge
    end
    return MathUtil.vector2Length(x - destination.x, z - destination.z)
end

function AutoDrive.getFillLevelAndCapacityOfAll(trailers)
    local leftCapacity = 0
    local fillLevel = 0
    local hasAL = false

    if trailers ~= nil then
        for _, trailer in pairs(trailers) do
            hasAL = hasAL or AutoDrive:hasAL(trailer)
        end
        if hasAL then
            -- AutoLoad
            for _, trailer in pairs(trailers) do
                local trailerFillLevel, trailerLeftCapacity = AutoDrive:getALFillLevelAndCapacityOfAllUnits(trailer)
                fillLevel = fillLevel + trailerFillLevel
                leftCapacity = leftCapacity + trailerLeftCapacity
            end
        else
            for _, trailer in pairs(trailers) do
                local trailerFillLevel, trailerLeftCapacity = AutoDrive.getFilteredFillLevelAndCapacityOfAllUnits(trailer)
                fillLevel = fillLevel + trailerFillLevel
                leftCapacity = leftCapacity + trailerLeftCapacity
            end
        end
    end

    return fillLevel, leftCapacity
end

function AutoDrive.getFillLevelAndCapacityOf(trailer)
    local leftCapacity = 0
    local fillLevel = 0


    if trailer ~= nil then
        if AutoDrive:hasAL(trailer) then
            -- AutoLoad
            fillLevel, leftCapacity = AutoDrive:getALFillLevelAndCapacityOfAllUnits(trailer)
        else
            for fillUnitIndex, _ in pairs(trailer:getFillUnits()) do

                local trailerFillLevel, trailerLeftCapacity = AutoDrive.getFilteredFillLevelAndCapacityOfOneUnit(trailer, fillUnitIndex)
                fillLevel = fillLevel + trailerFillLevel
                leftCapacity = leftCapacity + trailerLeftCapacity
            end
        end
    end

    return fillLevel, leftCapacity
end

function AutoDrive.getFilteredFillLevelAndCapacityOfAllUnits(object)
    local leftCapacity = 0
    local fillLevel = 0
    if AutoDrive:hasAL(object) then
        -- AutoLoad
        fillLevel, leftCapacity = AutoDrive:getALFillLevelAndCapacityOfAllUnits(object)
    elseif object.getFillUnits ~= nil then
        for fillUnitIndex, _ in pairs(object:getFillUnits()) do
            --print("object fillUnit " .. fillUnitIndex ..  " has :");
            local unitFillLevel, unitLeftCapacity = AutoDrive.getFilteredFillLevelAndCapacityOfOneUnit(object, fillUnitIndex)
            --print("   fillLevel: " .. unitFillLevel ..  " leftCapacity: " .. unitLeftCapacity);
            fillLevel = fillLevel + unitFillLevel
            leftCapacity = leftCapacity + unitLeftCapacity
        end
    end
    --print("Total fillLevel: " .. fillLevel ..  " leftCapacity: " .. leftCapacity);
    return fillLevel, leftCapacity
end

function AutoDrive.getFilteredFillLevelAndCapacityOfOneUnit(object, fillUnitIndex)
    local fillTypeIsProhibited = false
    local isSelectedFillType = false
    local hasOnlyDieselForFuel = AutoDrive.checkForDieselTankOnlyFuel(object)
    for fillType, _ in pairs(object:getFillUnitSupportedFillTypes(fillUnitIndex)) do
        local fillTypeName = g_fillTypeManager:getFillTypeNameByIndex(fillType)
        if (fillTypeName == 'UNKNOWN' or fillTypeName == 'ELECTRICCHARGE' or fillTypeName == 'AIR' or fillTypeName == 'DEF' or fillTypeName == 'DIESEL') then --1:UNKNOWN 34:AIR 33:AdBlue 32:Diesel
            if object.isEntered ~= nil or hasOnlyDieselForFuel then
                fillTypeIsProhibited = true
            end
        end
    end


    if object:getFillUnitCapacity(fillUnitIndex) > 300 and (not fillTypeIsProhibited) then
        return object:getFillUnitFillLevel(fillUnitIndex), object:getFillUnitFreeCapacity(fillUnitIndex)
    end
    return 0, 0
end

function AutoDrive.checkForDieselTankOnlyFuel(object)
    if object.getFillUnits == nil then
        return true
    end
    local dieselFuelUnitCount = 0
    local adBlueUnitCount = 0
    local otherFillUnitsCapacity = 0
    local dieselFillUnitCapacity = 0
    local numberOfFillUnits = 0
    for fillUnitIndex, _ in pairs(object:getFillUnits()) do
        numberOfFillUnits = numberOfFillUnits + 1
        local dieselFillUnit = false
        for fillType, _ in pairs(object:getFillUnitSupportedFillTypes(fillUnitIndex)) do
            local fillTypeName = g_fillTypeManager:getFillTypeNameByIndex(fillType)
            if fillTypeName == 'DEF' then
                adBlueUnitCount = adBlueUnitCount + 1
            end
            if fillTypeName == 'DIESEL' then
                dieselFuelUnitCount = dieselFuelUnitCount + 1
                dieselFillUnit = true
            end
        end
        if dieselFillUnit then
            dieselFillUnitCapacity = dieselFillUnitCapacity + object:getFillUnitCapacity(fillUnitIndex)
        else
            otherFillUnitsCapacity = otherFillUnitsCapacity + object:getFillUnitCapacity(fillUnitIndex)
        end
    end

    return ((dieselFuelUnitCount == adBlueUnitCount) or (dieselFillUnitCapacity < otherFillUnitsCapacity)) and numberOfFillUnits > 1
end

function AutoDrive.setTrailerCoverOpen(vehicle, trailers, open)
    if trailers == nil then
        return
    end
    if (AutoDrive.getSetting("autoTrailerCover", vehicle) ~= true) then
        return
    end

    for _, trailer in pairs(trailers) do
        local targetState = 0
        if open then
            targetState = 1
        end
        if trailer.spec_cover ~= nil and trailer.spec_cover.state ~= nil then
            if trailer.spec_cover.covers ~= nil then
                targetState = targetState * #trailer.spec_cover.covers
            end
            if trailer.spec_cover.state ~= targetState and trailer:getIsNextCoverStateAllowed(targetState) then
                trailer:setCoverState(targetState, false)
            end
        end
    end
end

function AutoDrive.setAugerPipeOpen(trailers, open)
    if trailers == nil then
        return
    end

    local targetState = 1
    if open then
        targetState = 2
    end
    for _, trailer in pairs(trailers) do
        if trailer.spec_pipe ~= nil and trailer.spec_pipe.currentState ~= nil and trailer.getIsPipeStateChangeAllowed ~= nil then
            if trailer.spec_pipe.currentState ~= targetState and trailer:getIsPipeStateChangeAllowed(targetState) then
                trailer:setPipeState(targetState, false)
            end
        end
    end
end

function AutoDrive.findAndSetBestTipPoint(vehicle, trailer)
    local dischargeCondition = true
    if trailer.getCanDischargeToObject ~= nil and trailer.getCurrentDischargeNode ~= nil then
        dischargeCondition = (not trailer:getCanDischargeToObject(trailer:getCurrentDischargeNode()))
    end
    if (AutoDrive.getSetting("autoTipSide", vehicle) == true) and dischargeCondition and (not vehicle.ad.isLoading) and (not vehicle.ad.isUnloading) and trailer.getCurrentDischargeNode ~= nil and trailer:getCurrentDischargeNode() ~= nil then
        local spec = trailer.spec_trailer
        if spec == nil then
            return
        end
        local currentDischargeNodeIndex = trailer:getCurrentDischargeNode().index
        for i = 1, spec.tipSideCount, 1 do
            local tipSide = spec.tipSides[i]
            trailer:setCurrentDischargeNodeIndex(tipSide.dischargeNodeIndex)
            trailer:updateRaycast(trailer:getCurrentDischargeNode())
            if trailer:getCanDischargeToObject(trailer:getCurrentDischargeNode()) then
                if trailer:getCanTogglePreferdTipSide() then
                    trailer:setPreferedTipSide(i)
                    trailer:updateRaycast(trailer:getCurrentDischargeNode())
                    AutoDrive.debugPrint(vehicle, AutoDrive.DC_VEHICLEINFO, "Changed tip side to %s", i)
                    return
                end
            end
        end
        trailer:setCurrentDischargeNodeIndex(currentDischargeNodeIndex)
    end
end

function AutoDrive.isTrailerInBunkerSiloArea(trailer, trigger)
    if trailer.getCurrentDischargeNode ~= nil then
        local dischargeNode = trailer:getCurrentDischargeNode()
        if dischargeNode ~= nil then
            local x, y, z = getWorldTranslation(dischargeNode.node)
            local tx, _, tz = x, y, z + 1
            if trigger ~= nil and trigger.bunkerSiloArea ~= nil then
                local x1, z1 = trigger.bunkerSiloArea.sx, trigger.bunkerSiloArea.sz
                local x2, z2 = trigger.bunkerSiloArea.wx, trigger.bunkerSiloArea.wz
                local x3, z3 = trigger.bunkerSiloArea.hx, trigger.bunkerSiloArea.hz
                return MathUtil.hasRectangleLineIntersection2D(x1, z1, x2 - x1, z2 - z1, x3 - x1, z3 - z1, x, z, tx - x, tz - z)
            end
        end
    end
    return false
end

function AutoDrive.getTriggerAndTrailerPairs(vehicle, dt)
    AutoDrive.debugPrint(vehicle, AutoDrive.DC_TRAILERINFO, "AutoDrive.getTriggerAndTrailerPairs start...")
    local trailerTriggerPairs = {}
    local trailers, _ = AutoDrive.getTrailersOf(vehicle, false)

    for _, trailer in pairs(trailers) do
        local trailerX, _, trailerZ = getWorldTranslation(trailer.components[1].node)

        for _, trigger in pairs(ADTriggerManager:getLoadTriggers()) do
            local triggerX, _, triggerZ = ADTriggerManager.getTriggerPos(trigger)
            if triggerX ~= nil then
                local distance = MathUtil.vector2Length(triggerX - trailerX, triggerZ - trailerZ)
                if distance <= AutoDrive.getSetting("maxTriggerDistance") then
                    AutoDrive.debugPrint(vehicle, AutoDrive.DC_TRAILERINFO, "AutoDrive.getTriggerAndTrailerPairs distance %s", tostring(distance))
                    vehicle.ad.debugTrigger = trigger
                    local allowedFillTypes = {vehicle.ad.stateModule:getFillType()}

                    -- seeds, fertilizer, liquidfertilizer should always be loaded if in trigger available
                    local fillUnits = trailer:getFillUnits()
                    if #fillUnits > 1 then
                        local fillTypeName = g_fillTypeManager:getFillTypeNameByIndex(vehicle.ad.stateModule:getFillType())
                        AutoDrive.debugPrint(vehicle, AutoDrive.DC_TRAILERINFO, "AutoDrive.getTriggerAndTrailerPairs #fillUnits > 1 fillTypeName %s", tostring(fillTypeName))
                        if fillTypeName == 'SEEDS' or fillTypeName == 'FERTILIZER' or fillTypeName == 'LIQUIDFERTILIZER' then
                            -- seeds, fertilizer, liquidfertilizer
                            allowedFillTypes = {}
                            table.insert(allowedFillTypes, g_fillTypeManager:getFillTypeIndexByName('SEEDS'))
                            table.insert(allowedFillTypes, g_fillTypeManager:getFillTypeIndexByName('FERTILIZER'))
                            table.insert(allowedFillTypes, g_fillTypeManager:getFillTypeIndexByName('LIQUIDFERTILIZER'))
                        end
                    end

                    local fillLevels = {}
                    if trigger.source ~= nil and trigger.source.getAllFillLevels ~= nil then
                        fillLevels, _ = trigger.source:getAllFillLevels(vehicle:getOwnerFarmId())
                        AutoDrive.debugPrint(vehicle, AutoDrive.DC_TRAILERINFO, "AutoDrive.getTriggerAndTrailerPairs fillLevels %s", tostring(fillLevels))
                    end
                    local gcFillLevels = {}
                    if trigger.source ~= nil and trigger.source.getAllProvidedFillLevels ~= nil then
                        gcFillLevels, _ = trigger.source:getAllProvidedFillLevels(vehicle:getOwnerFarmId(), trigger.managerId)
                        AutoDrive.debugPrint(vehicle, AutoDrive.DC_TRAILERINFO, "AutoDrive.getTriggerAndTrailerPairs gcFillLevels %s", tostring(gcFillLevels))
                    end
                    if table.getn(fillLevels) == 0 and table.getn(gcFillLevels) == 0 and trigger.source ~= nil and trigger.source.gcId ~= nil and trigger.source.fillLevels ~= nil then
                        --g_logManager:devInfo("Adding gm fill levels now")
                        for index, fillLevel in pairs(trigger.source.fillLevels) do
                            if fillLevel ~= nil and fillLevel[1] ~= nil then
                                --g_logManager:devInfo("Adding gm fill levels now - adding " .. index .. " with value: " .. fillLevel[1])
                                AutoDrive.debugPrint(vehicle, AutoDrive.DC_TRAILERINFO, "AutoDrive.getTriggerAndTrailerPairs Adding gm fill levels now - adding fillLevel[1] %s", tostring(fillLevel[1]))
                                fillLevels[index] = fillLevel[1]
                            end
                        end
                    end
                    local hasRequiredFillType = false
                    for i = 1, #fillUnits do
                        local hasFill = trigger.hasInfiniteCapacity 
                        local isFillAllowed = false
                        hasRequiredFillType = AutoDrive.fillTypesMatch(vehicle, trigger, trailer, allowedFillTypes, i)
                        local isNotFilled = trailer:getFillUnitFillLevelPercentage(i) <= AutoDrive.getSetting("unloadFillLevel", vehicle) * 0.999
                        AutoDrive.debugPrint(vehicle, AutoDrive.DC_TRAILERINFO, "AutoDrive.getTriggerAndTrailerPairs hasRequiredFillType %s isNotFilled %s", tostring(hasRequiredFillType), tostring(isNotFilled))

                        for _, allowedFillType in pairs(allowedFillTypes) do
                            if trailer:getFillUnitSupportsFillType(i, allowedFillType) then
                                isFillAllowed = isFillAllowed or (fillLevels[allowedFillType] ~= nil) or (gcFillLevels[allowedFillType] ~= nil)
                                hasFill = hasFill or (fillLevels[allowedFillType] ~= nil and fillLevels[allowedFillType] > 0) or (gcFillLevels[allowedFillType] ~= nil and gcFillLevels[allowedFillType] > 0)
                            end
                        end
                        AutoDrive.debugPrint(vehicle, AutoDrive.DC_TRAILERINFO, "AutoDrive.getTriggerAndTrailerPairs isFillAllowed %s hasFill %s", tostring(isFillAllowed), tostring(hasFill))

                        local trailerIsInRange = AutoDrive.trailerIsInTriggerList(trailer, trigger, i)
                        if trailer.inRangeTimers == nil then
                            trailer.inRangeTimers = {}
                        end
                        if trailer.inRangeTimers[i] == nil then
                            trailer.inRangeTimers[i] = {}
                        end
                        if trailer.inRangeTimers[i][trigger] == nil then
                            trailer.inRangeTimers[i][trigger] = AutoDriveTON:new()
                        end
                        AutoDrive.debugPrint(vehicle, AutoDrive.DC_TRAILERINFO, "AutoDrive.getTriggerAndTrailerPairs trailerIsInRange %s", tostring(trailerIsInRange))

                        local timerDone = trailer.inRangeTimers[i][trigger]:timer(trailerIsInRange, 200, dt) -- vehicle.ad.stateModule:getFieldSpeedLimit()*100

                        if timerDone and hasRequiredFillType and isNotFilled and isFillAllowed then
                            AutoDrive.debugPrint(vehicle, AutoDrive.DC_TRAILERINFO, "AutoDrive.getTriggerAndTrailerPairs timerDone %s", tostring(timerDone))
                            local pair = {trailer = trailer, trigger = trigger, fillUnitIndex = i, hasFill = hasFill}
                            table.insert(trailerTriggerPairs, pair)
                        end
                    end
                end
            end
        end
    end

    AutoDrive.debugPrint(vehicle, AutoDrive.DC_TRAILERINFO, "AutoDrive.getTriggerAndTrailerPairs end #trailerTriggerPairs %s", tostring(#trailerTriggerPairs))
    return trailerTriggerPairs
end

function AutoDrive.trailerIsInTriggerList(trailer, trigger, fillUnitIndex)
    --[[
    if trigger ~= nil and trigger.fillableObjects ~= nil then
        for _, fillableObject in pairs(trigger.fillableObjects) do
            if fillableObject == trailer or (fillableObject.object ~= nil and fillableObject.object == trailer and fillableObject.fillUnitIndex == fillUnitIndex) then
                return true
            end
        end
    end
    --]]
    local activatable = true
    if trigger.getIsActivatable ~= nil then
        activatable = trigger:getIsActivatable(trailer)
    end

    if trigger ~= nil and trigger.validFillableObject ~= nil and trigger.validFillableFillUnitIndex ~= nil and activatable then
        --print("Activateable: " .. AutoDrive.boolToString(activatable) .. " isLoading: " .. AutoDrive.boolToString(trigger.isLoading))
        if activatable and trigger.validFillableObject == trailer and trigger.validFillableFillUnitIndex == fillUnitIndex then
            --print("Is trailer and correctFillUnitIndex: " .. fillUnitIndex)
            return true
        end
    end

    return false
end

function AutoDrive.getTractorTrainLength(vehicle, includeTractor, onlyFirstTrailer)
    local totalLength = 0
    if includeTractor then
        totalLength = totalLength + vehicle.sizeLength
    end

    local trailers, _ = AutoDrive.getTrailersOf(vehicle, false)

    for _, trailer in ipairs(trailers) do
        totalLength = totalLength + trailer.sizeLength
        if onlyFirstTrailer then
            break
        end
    end
    return totalLength
end

function AutoDrive.checkForContinueOnEmptyLoadTrigger(vehicle)
    return AutoDrive.getSetting("continueOnEmptySilo") or ((AutoDrive.getSetting("rotateTargets", vehicle) == AutoDrive.RT_ONLYPICKUP or AutoDrive.getSetting("rotateTargets", vehicle) == AutoDrive.RT_PICKUPANDDELIVER) and AutoDrive.getSetting("useFolders"))
end

function AutoDrive.getWaterTrailerInWater(vehicle, trailers)
    if trailers ~= nil then
        for _, trailer in pairs(trailers) do
            local spec = trailer.spec_waterTrailer
            if spec ~= nil and spec.waterFillNode ~= nil and g_currentMission.waterY ~= nil then
                local _,y,_ = getWorldTranslation(spec.waterFillNode)
                local isNearWater = (y <= g_currentMission.waterY + 0.2)
                local fillUnits = trailer:getFillUnits()
                for i = 1, #fillUnits do
                    local isNotFilled = trailer:getFillUnitFillLevelPercentage(i) <= AutoDrive.getSetting("unloadFillLevel", vehicle) * 0.999
                    local allowedFillType = vehicle.ad.stateModule:getFillType() == FillType.WATER
                    if isNearWater and isNotFilled and allowedFillType then
                        return trailer
                    end
                end
            end
        end
    end
    return nil
end

function AutoDrive.startFillTrigger(trailers)
    local ret = nil
    if trailers == nil then
        return ret
    end
    for _, trailer in pairs(trailers) do
        local spec = trailer.spec_fillUnit
        if spec ~= nil and spec.fillTrigger ~= nil and spec.fillTrigger.triggers ~= nil and #spec.fillTrigger.triggers >0 then
            if not spec.fillTrigger.isFilling then
                AutoDrive.debugPrint(vehicle, AutoDrive.DC_TRAILERINFO, "AutoDrive.startFillTrigger currentTrigger %s #triggers %s", tostring(spec.fillTrigger.currentTrigger), tostring(#spec.fillTrigger.triggers))
                spec:setFillUnitIsFilling(true)
            end
            if spec.fillTrigger.isFilling ~= nil and spec.fillTrigger.currentTrigger ~= nil then
                return spec.fillTrigger
            end
        end
    end
    return ret
end

function AutoDrive.isInRangeToLoadUnloadTarget(vehicle)
    if vehicle == nil or vehicle.ad == nil or vehicle.ad.stateModule == nil or vehicle.ad.drivePathModule == nil then
        return false
    end
    local ret = false
    ret =
            (
                ((vehicle.ad.stateModule:getCurrentMode():shouldLoadOnTrigger() == true) and AutoDrive.getDistanceToTargetPosition(vehicle) <= AutoDrive.getSetting("maxTriggerDistance"))
                or
                ((vehicle.ad.stateModule:getCurrentMode():shouldUnloadAtTrigger() == true) and AutoDrive.getDistanceToUnloadPosition(vehicle) <= AutoDrive.getSetting("maxTriggerDistance"))
            )
    return ret
end
