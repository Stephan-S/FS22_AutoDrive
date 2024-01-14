ADBunkerSiloManager = {}

ADBunkerSiloManager.UPDATE_TIME = 1000

function ADBunkerSiloManager:load()
    self.bunkerSilos = {}
    self.lastUpdateTime = 0
end

function ADBunkerSiloManager:update(dt)

    if g_time < self.lastUpdateTime + ADBunkerSiloManager.UPDATE_TIME then
        return
    end
    self.lastUpdateTime = g_time
    local bsmRange = AutoDrive.getSetting("BSMRange") or 0
    if bsmRange == 0 then
        return
    end
    local network = ADGraphManager:getWayPoints()

    self.bunkerSilos = {}
    for _, bunkerSilo in pairs(ADTriggerManager.getUnloadTriggers()) do
        if bunkerSilo and bunkerSilo.bunkerSiloArea then
            bunkerSilo.adVehicles = {}
            table.insert(self.bunkerSilos, bunkerSilo)
        end
    end

    for _, bunkerSilo in pairs(self.bunkerSilos) do
        local minDistance = math.huge
        for _, vehicle in pairs(g_currentMission.vehicles) do
            if vehicle and vehicle.ad and vehicle.ad.stateModule and vehicle.ad.stateModule:isActive() then
                local currentTask = vehicle.ad.taskModule:getActiveTask()
                local isUnloading = currentTask and currentTask.taskType and vehicle.ad.taskModule:getActiveTask().taskType == "UnloadAtDestinationTask"
                if isUnloading then
                    local destination = vehicle.ad.stateModule:getCurrentDestination()
                    if destination then
                        local wp = network[destination.id]
                        if wp then
                            local targetInBunker = MathUtil.isPointInParallelogram(wp.x, wp.z, bunkerSilo.bunkerSiloArea.sx, bunkerSilo.bunkerSiloArea.sz, 
                                bunkerSilo.bunkerSiloArea.dwx, bunkerSilo.bunkerSiloArea.dwz, bunkerSilo.bunkerSiloArea.dhx, bunkerSilo.bunkerSiloArea.dhz)
                            if targetInBunker then
                                table.insert(bunkerSilo.adVehicles, vehicle)
                                local vehicleX, _, vehicleZ = getWorldTranslation(vehicle.components[1].node)
                                local triggerX, _, triggerZ = ADTriggerManager.getTriggerPos(bunkerSilo)
                                if triggerX ~= nil then
                                    local distance = MathUtil.vector2Length(triggerX - vehicleX, triggerZ - vehicleZ)
                                    if minDistance > distance then
                                        minDistance = distance
                                        bunkerSilo.adClosestVehicle = vehicle
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    for _, bunkerSilo in pairs(self.bunkerSilos) do
        for _, vehicle in pairs(bunkerSilo.adVehicles) do
            local vehicleX, _, vehicleZ = getWorldTranslation(vehicle.components[1].node)
            local triggerX, _, triggerZ = ADTriggerManager.getTriggerPos(bunkerSilo)
            if triggerX ~= nil then
                local distance = MathUtil.vector2Length(triggerX - vehicleX, triggerZ - vehicleZ)
                if distance < bsmRange then
                    if bunkerSilo.adClosestVehicle == vehicle 
                        -- or bunkerSilo.adClosestVehicle == nil
                        or AutoDrive.isVehicleInBunkerSiloArea(vehicle) then
                        -- IMPORTANT: DO NOT SET setUnPaused to avoid crash with CP silo compacter !!!
                        -- vehicle.ad.drivePathModule:setUnPaused()
                    else
                        vehicle.ad.drivePathModule:setPaused()
                    end
                end
            end
        end
    end
end
