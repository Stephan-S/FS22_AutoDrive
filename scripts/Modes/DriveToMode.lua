DriveToMode = ADInheritsFrom(AbstractMode)

function DriveToMode:new(vehicle)
    local o = DriveToMode:create()
    o.vehicle = vehicle
    DriveToMode.reset(o)
    return o
end

function DriveToMode:reset()
    self.driveToDestinationTask = nil
    self.destinationID = nil
    self.vehicle.ad.trailerModule:reset()
end

function DriveToMode:start()
    if not self.vehicle.ad.stateModule:isActive() then
        self.vehicle:startAutoDrive()
    end

    if self.vehicle.ad.stateModule:getFirstMarker() == nil then
        return
    end

    self:reset()
    self.destinationID = self.vehicle.ad.stateModule:getFirstMarker().id

    if self.vehicle.ad.onRouteToRefuel then
        local refuelDestinationMarkerID = ADTriggerManager.getClosestRefuelDestination(self.vehicle)
        if refuelDestinationMarkerID ~= nil then
            self.driveToDestinationTask = RefuelTask:new(self.vehicle, ADGraphManager:getMapMarkerById(refuelDestinationMarkerID).id)
        else
            self.vehicle.ad.isStoppingWithError = true
            self.vehicle:stopAutoDrive()
            local refuelFillTypeTitle = g_fillTypeManager:getFillTypeByIndex(self.vehicle.ad.stateModule:getRefuelFillType()).title
            AutoDriveMessageEvent.sendMessageOrNotification(self.vehicle, ADMessagesManager.messageTypes.ERROR, "$l10n_AD_Driver_of; %s $l10n_AD_No_Refuel_Station; %s", 5000, self.vehicle.ad.stateModule:getName(), refuelFillTypeTitle)
        end
        self.vehicle.ad.onRouteToRefuel = false
    else
        self.driveToDestinationTask = DriveToDestinationTask:new(self.vehicle, self.destinationID)
    end
    self.vehicle.ad.taskModule:addTask(self.driveToDestinationTask)
end

function DriveToMode:monitorTasks(dt)
end

function DriveToMode:handleFinishedTask()
    if self.driveToDestinationTask ~= nil then
        self.driveToDestinationTask = nil
        self.vehicle.ad.taskModule:addTask(StopAndDisableADTask:new(self.vehicle))
    else
        local target = self.vehicle.ad.stateModule:getFirstMarker().name
        for _, mapMarker in pairs(ADGraphManager:getMapMarkers()) do
            if self.destinationID == mapMarker.id then
                target = mapMarker.name
                break
            end
        end
        if self.vehicle.ad.isStoppingWithError == false then
            AutoDriveMessageEvent.sendNotification(self.vehicle, ADMessagesManager.messageTypes.INFO, "$l10n_AD_Driver_of; %s $l10n_AD_has_reached; %s", 5000, self.vehicle.ad.stateModule:getName(), target)
        end
    end
end

function DriveToMode:stop()
end
