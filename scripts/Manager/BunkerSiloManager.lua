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

    self.bunkerSilos = {}
    for _, bunkerSilo in pairs(ADTriggerManager.getUnloadTriggers()) do
        if bunkerSilo and bunkerSilo.bunkerSiloArea then
            bunkerSilo.adVehicles = {}
            table.insert(self.bunkerSilos, bunkerSilo)
        end
    end

    for _, bunkerSilo in pairs(self.bunkerSilos) do
        local minDistance = math.huge
        bunkerSilo.adClosestVehicle = nil
        for _, vehicle in pairs(g_currentMission.vehicles) do
            if vehicle and vehicle.ad and vehicle.ad.stateModule and vehicle.ad.stateModule:isActive() then
                if self:isDestinationInBunkerSilo(vehicle, bunkerSilo) then
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

    for _, bunkerSilo in pairs(self.bunkerSilos) do
        for _, vehicle in pairs(bunkerSilo.adVehicles) do
            local vehicleX, _, vehicleZ = getWorldTranslation(vehicle.components[1].node)
            local triggerX, _, triggerZ = ADTriggerManager.getTriggerPos(bunkerSilo)
            if triggerX ~= nil then
                local distance = MathUtil.vector2Length(triggerX - vehicleX, triggerZ - vehicleZ)
                if distance < bsmRange then
                    if AutoDrive.isVehicleInBunkerSiloArea(vehicle) or bunkerSilo.adClosestVehicle == vehicle then
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

function ADBunkerSiloManager:isDestinationInBunkerSilo(vehicle, bunkerSilo)
    local network = ADGraphManager:getWayPoints()
    local destination = nil
    local destinationInBunkerSilo = false
    if vehicle.ad.stateModule:getMode() == AutoDrive.MODE_PICKUPANDDELIVER or vehicle.ad.stateModule:getMode() == AutoDrive.MODE_UNLOAD then
        destination = vehicle.ad.stateModule:getSecondWayPoint()
    elseif vehicle.ad.stateModule:getMode() == AutoDrive.MODE_DELIVERTO then
        destination = vehicle.ad.stateModule:getFirstWayPoint()
    end
    if destination and destination > 0 then
        local wp = network[destination]
        if wp then
            destinationInBunkerSilo = MathUtil.isPointInParallelogram(wp.x, wp.z, bunkerSilo.bunkerSiloArea.sx, bunkerSilo.bunkerSiloArea.sz, 
                bunkerSilo.bunkerSiloArea.dwx, bunkerSilo.bunkerSiloArea.dwz, bunkerSilo.bunkerSiloArea.dhx, bunkerSilo.bunkerSiloArea.dhz)
        end
    end
    return destinationInBunkerSilo
end
