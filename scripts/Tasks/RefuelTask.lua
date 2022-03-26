RefuelTask = ADInheritsFrom(AbstractTask)

RefuelTask.STATE_PATHPLANNING = 1
RefuelTask.STATE_DRIVING = 2

function RefuelTask:new(vehicle, destinationID)
    local o = RefuelTask:create()
    o.vehicle = vehicle
    o.isRefueled = false
    o.destinationID = destinationID
    o.trailers = nil
    o.fillTypesCount = 1
    return o
end

function RefuelTask:setUp()
    AutoDrive.debugPrint(self.vehicle, AutoDrive.DC_VEHICLEINFO, "RefuelTask:setUp ")
    self.refuelTrigger = nil
    self.fillTypesCount = 1
    if ADGraphManager:getDistanceFromNetwork(self.vehicle) > 30 then
        self.state = RefuelTask.STATE_PATHPLANNING
        self.vehicle.ad.pathFinderModule:startPathPlanningToNetwork(self.destinationID)
    else
        self.state = RefuelTask.STATE_DRIVING
        self.vehicle.ad.drivePathModule:setPathTo(self.destinationID)
    end
    AutoDriveMessageEvent.sendNotification(self.vehicle, ADMessagesManager.messageTypes.WARN, "$l10n_AD_Driver_of; %s $l10n_AD_task_drive_to_refuel_point;", 5000, self.vehicle.ad.stateModule:getName())
    self.trailers, _ = AutoDrive.getAllUnits(self.vehicle)
    AutoDrive.setTrailerCoverOpen(self.vehicle, self.trailers, false)
end

function RefuelTask:update(dt)

    if self.refuelTrigger ~= nil and self.refuelTrigger.stoppedTimer ~= nil then
        -- update timer
        self.refuelTrigger.stoppedTimer:timer(not self.refuelTrigger.isLoading,300,dt)
    end

    self.isRefueled = self.fillTypesCount > table.count(AutoDrive.fuelFillTypes)

    if self.state == RefuelTask.STATE_PATHPLANNING then
        if self.vehicle.ad.pathFinderModule:hasFinished() then
            self.wayPoints = self.vehicle.ad.pathFinderModule:getPath()
            if self.wayPoints == nil or #self.wayPoints == 0 then
                Logging.error("[AutoDrive] Could not calculate path - shutting down")
                self.vehicle.ad.taskModule:abortAllTasks()
                self.vehicle:stopAutoDrive()
                AutoDriveMessageEvent.sendMessageOrNotification(self.vehicle, ADMessagesManager.messageTypes.ERROR, "$l10n_AD_Driver_of; %s $l10n_AD_cannot_find_path;", 5000, self.vehicle.ad.stateModule:getName())
            else
                self.vehicle.ad.drivePathModule:setWayPoints(self.wayPoints)
                --self.vehicle.ad.drivePathModule:appendPathTo(self.wayPoints[#self.wayPoints], self.destinationID)
                self.state = RefuelTask.STATE_DRIVING
            end
        else
            self.vehicle.ad.pathFinderModule:update(dt)
            self.vehicle.ad.specialDrivingModule:stopVehicle()
            self.vehicle.ad.specialDrivingModule:update(dt)
        end
    else
        if self.vehicle.ad.drivePathModule:isTargetReached() then
            self:finished()
        else
            if self.refuelTrigger == nil then
                self:isInRefuelRange()
            end
            if self.refuelTrigger ~= nil and not (self.refuelTrigger.isLoading or (self.refuelTrigger.stoppedTimer ~= nil and not self.refuelTrigger.stoppedTimer:done())) and not self.isRefueled then
                self:startRefueling()
            end
            if self.refuelTrigger ~= nil and (self.refuelTrigger.isLoading or (self.refuelTrigger.stoppedTimer ~= nil and not self.refuelTrigger.stoppedTimer:done())) then
                self.vehicle.ad.specialDrivingModule:stopVehicle()
                self.vehicle.ad.specialDrivingModule:update(dt)
            else
                self.vehicle.ad.drivePathModule:update(dt)
            end
        end
    end
end

function RefuelTask:abort()
end

function RefuelTask:finished()
    self.vehicle.ad.onRouteToRefuel = #AutoDrive.getRequiredRefuels(self.vehicle, true) > 0

    self.vehicle.ad.stateModule:setRefuelFillType(0)        -- before start the mode again, we need to clear the refuel type
    self.vehicle:stopAutoDrive()
    self.vehicle.ad.stateModule:getCurrentMode():start()
    self.vehicle.ad.taskModule:setCurrentTaskFinished(ADTaskModule.DONT_PROPAGATE)
end

function RefuelTask:isInRefuelRange()
    local x, _, z = getWorldTranslation(self.vehicle.components[1].node)
    local refuelX, refuelZ = ADGraphManager:getWayPointById(self.destinationID).x, ADGraphManager:getWayPointById(self.destinationID).z
    local distance = MathUtil.vector2Length(refuelX - x, refuelZ - z)       -- vehicle to destination

    if distance <= AutoDrive.MAX_REFUEL_TRIGGER_DISTANCE then
        if self.refuelTrigger == nil then
            self.refuelTrigger = ADTriggerManager.getClosestRefuelTrigger(self.vehicle, self.vehicle.ad.onRouteToRefuel)
        end
        if self.refuelTrigger ~= nil and not self.refuelTrigger.isLoading then
            for _, fillableObject in pairs(self.refuelTrigger.fillableObjects) do
                if fillableObject == self.vehicle or (fillableObject.object ~= nil and fillableObject.object == self.vehicle and fillableObject.fillUnitIndex == fillUnitIndex) then
                    AutoDrive.debugPrint(self.vehicle, AutoDrive.DC_VEHICLEINFO, "RefuelTask:isInRefuelRange return true")
                    return true
                end
            end
        end
    end
    return false
end

function RefuelTask:startRefueling()
    if self.refuelTrigger ~= nil and (not self.refuelTrigger.isLoading) then
        AutoDrive.debugPrint(self.vehicle, AutoDrive.DC_VEHICLEINFO, "RefuelTask:startRefueling Start refueling")

        local fillUnits = self.vehicle:getFillUnits()
        local fillTypeName = AutoDrive.fuelFillTypes[self.fillTypesCount]
        local fillTypeIndex =  g_fillTypeManager:getFillTypeIndexByName(fillTypeName)
        for i = 1, #fillUnits do
            if AutoDrive.fillTypesMatch(self.vehicle, self.refuelTrigger, self.vehicle, {fillTypeIndex}, i) then
                AutoDrive.debugPrint(self.vehicle, AutoDrive.DC_VEHICLEINFO, "RefuelTask:startRefueling fillTypesMatch -> fillTypeName %s", fillTypeName)

                self.refuelTrigger.autoStart = true
                self.refuelTrigger.selectedFillType = fillTypeIndex
                AutoDrive.debugPrint(self.vehicle, AutoDrive.DC_VEHICLEINFO, "RefuelTask:startRefueling Start onFillTypeSelection")
                self.refuelTrigger:onFillTypeSelection(fillTypeIndex)
                if self.refuelTrigger.isLoading then    
                    AutoDrive.debugPrint(self.vehicle, AutoDrive.DC_VEHICLEINFO, "RefuelTask:startRefueling isLoading")
                    self.refuelTrigger.selectedFillType = fillTypeIndex
                    self.refuelTrigger.autoStart = true
                    g_effectManager:setFillType(self.refuelTrigger.effects, self.refuelTrigger.selectedFillType)
                end
                if self.refuelTrigger.stoppedTimer == nil then
                    self.refuelTrigger.stoppedTimer = AutoDriveTON:new()
                end
                self.refuelTrigger.stoppedTimer:timer(false, 300)
                break
            end
        end
        self.fillTypesCount = self.fillTypesCount + 1
    end
end

function RefuelTask:getInfoText()
    if self.state == RefuelTask.STATE_PATHPLANNING then
        local actualState, maxStates = self.vehicle.ad.pathFinderModule:getCurrentState()
        return g_i18n:getText("AD_task_pathfinding") .. string.format(" %d / %d ", actualState, maxStates)
    else
        return g_i18n:getText("AD_task_drive_to_refuel_point")
    end
end

function RefuelTask:getI18nInfo()
    if self.state == RefuelTask.STATE_PATHPLANNING then
        local actualState, maxStates = self.vehicle.ad.pathFinderModule:getCurrentState()
        return "$l10n_AD_task_pathfinding;" .. string.format(" %d / %d ", actualState, maxStates)
    else
        return "$l10n_AD_task_drive_to_refuel_point;"
    end
end
