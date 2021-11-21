RefuelTask = ADInheritsFrom(AbstractTask)

RefuelTask.STATE_PATHPLANNING = 1
RefuelTask.STATE_DRIVING = 2

function RefuelTask:new(vehicle, destinationID)
    local o = RefuelTask:create()
    o.vehicle = vehicle
    o.hasRefueled = false
    o.isRefueled = false
    o.destinationID = destinationID
    o.trailers = nil
    return o
end

function RefuelTask:setUp()
    self.refuelTrigger = nil
    if ADGraphManager:getDistanceFromNetwork(self.vehicle) > 30 then
        self.state = RefuelTask.STATE_PATHPLANNING
        self.vehicle.ad.pathFinderModule:startPathPlanningToNetwork(self.destinationID)
    else
        self.state = RefuelTask.STATE_DRIVING
        self.vehicle.ad.drivePathModule:setPathTo(self.destinationID)
    end
    AutoDriveMessageEvent.sendNotification(self.vehicle, ADMessagesManager.messageTypes.WARN, "$l10n_AD_Driver_of; %s $l10n_AD_task_drive_to_refuel_point;", 5000, self.vehicle.ad.stateModule:getName())
    self.trailers, _ = AutoDrive.getTrailersOf(self.vehicle, false)
    AutoDrive.setTrailerCoverOpen(self.vehicle, self.trailers, false)
end

function RefuelTask:update(dt)
    local spec = self.vehicle.spec_motorized

    if self.vehicle.ad.stateModule:getRefuelFillType() > 0 then
        local fillUnitIndex = self.vehicle.spec_motorized:getConsumerFillUnitIndex(self.vehicle.ad.stateModule:getRefuelFillType())
        if fillUnitIndex ~= nil then
            self.isRefueled = self.vehicle:getFillUnitFillLevelPercentage(fillUnitIndex) >= 0.99
        end
    end

    if self.state == RefuelTask.STATE_PATHPLANNING then
        if self.vehicle.ad.pathFinderModule:hasFinished() then
            self.wayPoints = self.vehicle.ad.pathFinderModule:getPath()
            if self.wayPoints == nil or #self.wayPoints == 0 then
                g_logManager:error("[AutoDrive] Could not calculate path - shutting down")
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
            if self:isInRefuelRange() and not self.hasRefueled then
                self:startRefueling()
            end
            if self.hasRefueled and not self.isRefueled then
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
    local callBackFunction = self.vehicle.ad.callBackFunction
    local callBackObject = self.vehicle.ad.callBackObject
    local callBackArg = self.vehicle.ad.callBackArg
    self.vehicle.ad.callBackFunction = nil
    self.vehicle.ad.callBackObject = nil
    self.vehicle.ad.callBackArg = nil

    self.vehicle.ad.stateModule:setRefuelFillType(0)        -- before start the mode again, we need to clear the refuel type
    self.vehicle:stopAutoDrive()
    self.vehicle.ad.stateModule:getCurrentMode():start()
    self.vehicle.ad.taskModule:setCurrentTaskFinished(ADTaskModule.DONT_PROPAGATE)
    
    self.vehicle.ad.callBackFunction = callBackFunction
    self.vehicle.ad.callBackObject = callBackObject
    self.vehicle.ad.callBackArg = callBackArg
end

function RefuelTask:isInRefuelRange()
    local x, _, z = getWorldTranslation(self.vehicle.components[1].node)
    local refuelX, refuelZ = ADGraphManager:getWayPointById(self.destinationID).x, ADGraphManager:getWayPointById(self.destinationID).z
    local distance = MathUtil.vector2Length(refuelX - x, refuelZ - z)       -- vehicle to destination

    if self.vehicle.ad.stateModule:getRefuelFillType() > 0 then
        local fillUnitIndex = self.vehicle.spec_motorized:getConsumerFillUnitIndex(self.vehicle.ad.stateModule:getRefuelFillType())

        if fillUnitIndex ~= nil then
            if distance <= AutoDrive.MAX_REFUEL_TRIGGER_DISTANCE then
                self.refuelTrigger = ADTriggerManager.getClosestRefuelTrigger(self.vehicle)
                if self.refuelTrigger ~= nil and not self.refuelTrigger.isLoading then
                    for _, fillableObject in pairs(self.refuelTrigger.fillableObjects) do
                        if fillableObject == self.vehicle or (fillableObject.object ~= nil and fillableObject.object == self.vehicle and fillableObject.fillUnitIndex == fillUnitIndex) then
                            return true
                        end
                    end
                end
            end
        end
    end
    return false
end

function RefuelTask:startRefueling()
    if self.refuelTrigger ~= nil and (not self.refuelTrigger.isLoading) and (not self.isRefueled) then
        AutoDrive.debugPrint(self.vehicle, AutoDrive.DC_VEHICLEINFO, "Start refueling")

        local fillType = self.vehicle.ad.stateModule:getRefuelFillType()
        AutoDrive.debugPrint(self.vehicle, AutoDrive.DC_VEHICLEINFO, "Start refueling fillType %s", tostring(fillType))
        if fillType > 0 then
            self.refuelTrigger.autoStart = true
            self.refuelTrigger.selectedFillType = fillType
            AutoDrive.debugPrint(self.vehicle, AutoDrive.DC_VEHICLEINFO, "Start onFillTypeSelection")
            self.refuelTrigger:onFillTypeSelection(fillType)
            self.refuelTrigger.selectedFillType = fillType
            self.hasRefueled = true
            g_effectManager:setFillType(self.refuelTrigger.effects, self.refuelTrigger.selectedFillType)
        end
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
