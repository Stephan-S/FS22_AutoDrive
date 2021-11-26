ADTriggerManager = {}

ADTriggerManager.tipTriggers = {}
ADTriggerManager.siloTriggers = {}

ADTriggerManager.searchedForTriggers = false

AutoDrive.MAX_REFUEL_TRIGGER_DISTANCE = 15
AutoDrive.REFUEL_LEVEL = 0.15

function ADTriggerManager.load()
end

function ADTriggerManager:update(dt)
end

function ADTriggerManager.checkForTriggerProximity(vehicle, distanceToTarget)
    local shouldLoad = vehicle.ad.stateModule:getCurrentMode():shouldLoadOnTrigger()
    local shouldUnload = vehicle.ad.stateModule:getCurrentMode():shouldUnloadAtTrigger()
    if (not shouldUnload) and (not shouldLoad) or distanceToTarget == nil then
        return false
    end

    local x, y, z = getWorldTranslation(vehicle.components[1].node)
    local allFillables, _ = AutoDrive.getTrailersOf(vehicle, false)

    local totalMass = vehicle:getTotalMass(false)
    local massFactor = math.max(1, math.min(3, (totalMass + 20) / 30))
    if vehicle.lastSpeedReal * 3600 < 15 then
        massFactor = 1
    end
    local speedFactor = math.max(0.5, math.min(4, (((vehicle.lastSpeedReal * 3600) + 10) / 20.0)))
    local distanceToSlowDownAt = 15 * speedFactor * massFactor

    if vehicle.ad.trailerModule:isActiveAtTrigger() then
        return true
    end

    if shouldLoad then
        for _, trigger in pairs(ADTriggerManager.siloTriggers) do
            local triggerX, _, triggerZ = ADTriggerManager.getTriggerPos(trigger)
            if triggerX ~= nil then
                local distance = MathUtil.vector2Length(triggerX - x, triggerZ - z)

                if distance < distanceToSlowDownAt and distanceToTarget < AutoDrive.getSetting("maxTriggerDistance") then
                    local hasRequiredFillType = false
                    local allowedFillTypes = {vehicle.ad.stateModule:getFillType()}
                    local fillTypeName = g_fillTypeManager:getFillTypeNameByIndex(vehicle.ad.stateModule:getFillType())

                    if fillTypeName == 'SEEDS' or fillTypeName == 'FERTILIZER' or fillTypeName == 'LIQUIDFERTILIZER' then
                        -- seeds, fertilizer, liquidfertilizer
                        allowedFillTypes = {}
                        table.insert(allowedFillTypes, g_fillTypeManager:getFillTypeIndexByName('SEEDS'))
                        table.insert(allowedFillTypes, g_fillTypeManager:getFillTypeIndexByName('FERTILIZER'))
                        table.insert(allowedFillTypes, g_fillTypeManager:getFillTypeIndexByName('LIQUIDFERTILIZER'))
                    end

                    for _, trailer in pairs(allFillables) do
                        hasRequiredFillType = hasRequiredFillType or AutoDrive.fillTypesMatch(vehicle, trigger, trailer, allowedFillTypes)
                    end

                    if hasRequiredFillType then
                        return true
                    end
                end
            end
        end
    end

    if shouldUnload then
        for _, trigger in pairs(ADTriggerManager.tipTriggers) do
            local triggerX, _, triggerZ = ADTriggerManager.getTriggerPos(trigger)
            if triggerX ~= nil then
                local distance = MathUtil.vector2Length(triggerX - x, triggerZ - z)
                if distance < distanceToSlowDownAt and (distanceToTarget < AutoDrive.getSetting("maxTriggerDistance") or (trigger.bunkerSiloArea ~= nil and distanceToTarget < 300)) then
                    return true
                end
            end
        end
    end

    return false
end

function ADTriggerManager.loadAllTriggers()
    ADTriggerManager.searchedForTriggers = true
    ADTriggerManager.tipTriggers = {}
    ADTriggerManager.siloTriggers = {}
    for _, ownedItem in pairs(g_currentMission.ownedItems) do
        if ownedItem.storeItem ~= nil then
            if ownedItem.storeItem.categoryName == "SILOS" then
                for _, item in pairs(ownedItem.items) do
                    if item.spec_bunkerSilo ~= nil then
                        if not table.contains(ADTriggerManager.tipTriggers, item.spec_bunkerSilo.bunkerSilo) then
                            table.insert(ADTriggerManager.tipTriggers, item.spec_bunkerSilo.bunkerSilo)
                        end
                    end

                    if item.loadingStation ~= nil then
                        for _, loadTrigger in pairs(item.loadingStation.loadTriggers) do
                            if not table.contains(ADTriggerManager.siloTriggers, loadTrigger) then
                                table.insert(ADTriggerManager.siloTriggers, loadTrigger)
                            end
                        end
                    end
                end
            end
        end
    end

    if g_currentMission.placeables ~= nil then
        for _, placeable in pairs(g_currentMission.placeables) do
            if placeable.sellingStation ~= nil then
                for _, unloadTrigger in pairs(placeable.sellingStation.unloadTriggers) do
                    if not table.contains(ADTriggerManager.tipTriggers, unloadTrigger) then
                        table.insert(ADTriggerManager.tipTriggers, unloadTrigger)
                    end
                end
            end

            if placeable.unloadingStation ~= nil then
                for _, unloadTrigger in pairs(placeable.unloadingStation.unloadTriggers) do
                    if not table.contains(ADTriggerManager.tipTriggers, unloadTrigger) then
                        table.insert(ADTriggerManager.tipTriggers, unloadTrigger)
                    end
                end
            end

            if placeable.modulesById ~= nil then
                for i = 1, #placeable.modulesById do
                    local myModule = placeable.modulesById[i]
                    if myModule.unloadPlace ~= nil then
                        if not table.contains(ADTriggerManager.tipTriggers, myModule.unloadPlace) then
                            table.insert(ADTriggerManager.tipTriggers, myModule.unloadPlace)
                        end
                    end

                    if myModule.feedingTrough ~= nil then
                        if not table.contains(ADTriggerManager.tipTriggers, myModule.feedingTrough) then
                            table.insert(ADTriggerManager.tipTriggers, myModule.feedingTrough)
                        end
                    end

                    if myModule.loadPlace ~= nil then
                        if not table.contains(ADTriggerManager.siloTriggers, myModule.loadPlace) then
                            table.insert(ADTriggerManager.siloTriggers, myModule.loadPlace)
                        end
                    end
                end
            end

            if placeable.buyingStation ~= nil then
                for _, loadTrigger in pairs(placeable.buyingStation.loadTriggers) do
                    if not table.contains(ADTriggerManager.siloTriggers, loadTrigger) then
                        table.insert(ADTriggerManager.siloTriggers, loadTrigger)
                    end
                end
            end

            if placeable.loadingStation ~= nil then
                for _, loadTrigger in pairs(placeable.loadingStation.loadTriggers) do
                    if not table.contains(ADTriggerManager.siloTriggers, loadTrigger) then
                        table.insert(ADTriggerManager.siloTriggers, loadTrigger)
                    end
                end
            end

            if placeable.bunkerSilos ~= nil then
                for _, bunker in pairs(placeable.bunkerSilos) do
                    if not table.contains(ADTriggerManager.tipTriggers, bunker) then
                        table.insert(ADTriggerManager.tipTriggers, bunker)
                    end
                end
            end
        end
    end

    if g_currentMission.nodeToObject ~= nil then
        for _, object in pairs(g_currentMission.nodeToObject) do
            if object.triggerNode ~= nil then
                if not table.contains(ADTriggerManager.siloTriggers, object) then
                    table.insert(ADTriggerManager.siloTriggers, object)
                end
            end

            if object.exactFillRootNode ~= nil then
                table.insert(ADTriggerManager.tipTriggers, object)
			end
        end
    end

    if g_currentMission.bunkerSilos ~= nil then
        for _, trigger in pairs(g_currentMission.bunkerSilos) do
            if trigger.bunkerSilo then
                if not table.contains(ADTriggerManager.tipTriggers, trigger) then
                    table.insert(ADTriggerManager.tipTriggers, trigger)
                end
            end
        end
    end
    
    for _, trigger in pairs(ADTriggerManager.siloTriggers) do
        if trigger.stoppedTimer == nil then
            trigger.stoppedTimer = AutoDriveTON:new()
        end
    end
end

function ADTriggerManager.getUnloadTriggers()
    if not ADTriggerManager.searchedForTriggers then
        ADTriggerManager.loadAllTriggers()
    end
    return ADTriggerManager.tipTriggers
end

function ADTriggerManager.getLoadTriggers()
    if not ADTriggerManager.searchedForTriggers then
        ADTriggerManager.loadAllTriggers()
    end
    return ADTriggerManager.siloTriggers
end

-- returns only suitable fuel triggers according to used fuel type
function ADTriggerManager.getRefuelTriggers(vehicle)
    local refuelTriggers = {}
    local fillType = vehicle.ad.stateModule:getRefuelFillType()

    if fillType > 0 then

        for _, trigger in pairs(ADTriggerManager.getLoadTriggers()) do
            --loadTriggers
            -- vanilla LoadingStation
            local fillLevels = {}
            if trigger.source ~= nil and trigger.source.getAllFillLevels ~= nil then
                fillLevels, _ = trigger.source:getAllFillLevels(vehicle:getOwnerFarmId())
            end
            -- GC trigger
            local gcFillLevels = {}
            if trigger.source ~= nil and trigger.source.getAllProvidedFillLevels ~= nil then
                gcFillLevels, _ = trigger.source:getAllProvidedFillLevels(vehicle:getOwnerFarmId(), trigger.managerId)
            end
            if table.getn(fillLevels) == 0 and table.getn(gcFillLevels) == 0 and trigger.source ~= nil and trigger.source.gcId ~= nil and trigger.source.fillLevels ~= nil then
                for index, fillLevel in pairs(trigger.source.fillLevels) do
                    if fillLevel ~= nil and fillLevel[1] ~= nil then
                        fillLevels[index] = fillLevel[1]
                    end
                end
            end
            local hasCapacity = (fillLevels[fillType] ~= nil and fillLevels[fillType] > 0) or (gcFillLevels[fillType] ~= nil and gcFillLevels[fillType] > 0)

            if hasCapacity then
                table.insert(refuelTriggers, trigger)
            end
        end
    end

    return refuelTriggers
end

function ADTriggerManager.getClosestRefuelTrigger(vehicle)
    local refuelTriggers = ADTriggerManager.getRefuelTriggers(vehicle)
    local x, _, z = getWorldTranslation(vehicle.components[1].node)

    local closestRefuelTrigger = nil
    local closestDistance = math.huge

    for _, refuelTrigger in pairs(refuelTriggers) do
        local triggerX, _, triggerZ = ADTriggerManager.getTriggerPos(refuelTrigger)
        local distance = MathUtil.vector2Length(triggerX - x, triggerZ - z)

        if distance < closestDistance then
            closestDistance = distance
            closestRefuelTrigger = refuelTrigger
        end
    end

    return closestRefuelTrigger
end

function ADTriggerManager.getRefuelDestinations(vehicle)
    local refuelDestinations = {}

    local refuelTriggers = ADTriggerManager.getRefuelTriggers(vehicle)

    for mapMarkerID, mapMarker in pairs(ADGraphManager:getMapMarkers()) do
        for _, refuelTrigger in pairs(refuelTriggers) do
            local triggerX, _, triggerZ = ADTriggerManager.getTriggerPos(refuelTrigger)
            local distance = MathUtil.vector2Length(triggerX - ADGraphManager:getWayPointById(mapMarker.id).x, triggerZ - ADGraphManager:getWayPointById(mapMarker.id).z)
            if distance < AutoDrive.MAX_REFUEL_TRIGGER_DISTANCE then
                table.insert(refuelDestinations, {mapMarkerID = mapMarkerID, refuelTrigger = refuelTrigger, distance = distance})
            end
        end
    end

    return refuelDestinations
end

function ADTriggerManager.getClosestRefuelDestination(vehicle)
    local refuelDestinations = ADTriggerManager.getRefuelDestinations(vehicle)

    local x, _, z = getWorldTranslation(vehicle.components[1].node)
    local closestRefuelDestination = nil
    local closestDistance = math.huge
    local closestRefuelTrigger = nil

    -- for _, refuelDestination in pairs(refuelDestinations) do
    for _, item in pairs(refuelDestinations) do
        local refuelX, refuelZ = ADGraphManager:getWayPointById(ADGraphManager:getMapMarkerById(item.mapMarkerID).id).x, ADGraphManager:getWayPointById(ADGraphManager:getMapMarkerById(item.mapMarkerID).id).z
        local distance = MathUtil.vector2Length(refuelX - x, refuelZ - z)       -- vehicle to destination
        if distance <= closestDistance then
            closestRefuelDestination = item.mapMarkerID
            closestRefuelTrigger = item.refuelTrigger
            closestDistance = distance
        end
    end
    if closestRefuelTrigger ~= nil then
        -- now find the closest mapMarker for the found refuel trigger
        local closestDistance2 = math.huge
        for _, item in pairs(refuelDestinations) do
            if item.refuelTrigger == closestRefuelTrigger and item.distance < closestDistance2 then
                closestRefuelTrigger = item.refuelTrigger
                closestDistance2 = item.distance
                closestRefuelDestination = item.mapMarkerID
            end
        end
    end

    return closestRefuelDestination
end

function ADTriggerManager.getTriggerPos(trigger)
    local x, y, z = 0, 0, 0
    if trigger.triggerNode ~= nil and g_currentMission.nodeToObject[trigger.triggerNode] ~= nil and entityExists(trigger.triggerNode) then 
        x, y, z = getWorldTranslation(trigger.triggerNode)
    end
    if trigger.exactFillRootNode ~= nil and g_currentMission.nodeToObject[trigger.exactFillRootNode] ~= nil and entityExists(trigger.exactFillRootNode) then
        x, y, z = getWorldTranslation(trigger.exactFillRootNode)
    end
    if trigger.interactionTriggerNode ~= nil and g_currentMission.nodeToObject[trigger.interactionTriggerNode] ~= nil and entityExists(trigger.interactionTriggerNode) then
        x, y, z = getWorldTranslation(trigger.interactionTriggerNode)
    end
    return x, y, z
end

function ADTriggerManager:loadTriggerLoad(superFunc, rootNode, xmlFile, xmlNode)
    local result = superFunc(self, rootNode, xmlFile, xmlNode)

    if result and ADTriggerManager ~= nil and ADTriggerManager.siloTriggers ~= nil then
        if not table.contains(ADTriggerManager.siloTriggers, self) then
            table.insert(ADTriggerManager.siloTriggers, self)
        end
    end

    return result
end

function ADTriggerManager:loadTriggerDelete(superFunc)
    if ADTriggerManager ~= nil and ADTriggerManager.siloTriggers ~= nil then
        table.removeValue(ADTriggerManager.siloTriggers, self)
    end
    superFunc(self)
end

function ADTriggerManager:onPlaceableBuy()
    ADTriggerManager.searchedForTriggers = false
end

function ADTriggerManager.triggerSupportsFillType(trigger, fillType)
    if fillType > 0 then
        if trigger ~= nil and trigger.getIsFillTypeSupported then
            return trigger:getIsFillTypeSupported(fillType)
        end
    end  
    return false  
end

function ADTriggerManager.getAllTriggersForFillType(fillType)
    local triggers = {}

    for _, trigger in pairs(ADTriggerManager.getUnloadTriggers()) do
        if ADTriggerManager.triggerSupportsFillType(trigger, fillType) then
            table.insert(triggers, trigger)
        end
    end

    return triggers
end
