RepairTask = ADInheritsFrom(AbstractTask)

RepairTask.STATE_PATHPLANNING = 1
RepairTask.STATE_DRIVING = 2

function RepairTask:new(vehicle, destinationID)
    local o = RepairTask:create()
    o.vehicle = vehicle
    o.isRepaired = false
    o.destinationID = destinationID
    o.trailers = nil
    return o
end

function RepairTask:setUp()
    AutoDrive.debugPrint(self.vehicle, AutoDrive.DC_VEHICLEINFO, "RepairTask:setUp ")
    self.repairTrigger = nil
    if ADGraphManager:getDistanceFromNetwork(self.vehicle) > 30 then
        self.state = RepairTask.STATE_PATHPLANNING
        self.vehicle.ad.pathFinderModule:startPathPlanningToNetwork(self.destinationID)
    else
        self.state = RepairTask.STATE_DRIVING
        self.vehicle.ad.drivePathModule:setPathTo(self.destinationID)
    end
    AutoDriveMessageEvent.sendNotification(self.vehicle, ADMessagesManager.messageTypes.WARN, "$l10n_AD_Driver_of; %s $l10n_AD_task_drive_to_repair_point;", 5000, self.vehicle.ad.stateModule:getName())
    self.trailers, _ = AutoDrive.getAllUnits(self.vehicle)
    AutoDrive.setTrailerCoverOpen(self.vehicle, self.trailers, false)
end

function RepairTask:update(dt)
    if self.state == RepairTask.STATE_PATHPLANNING then
        if self.vehicle.ad.pathFinderModule:hasFinished() then
            self.wayPoints = self.vehicle.ad.pathFinderModule:getPath()
            if self.wayPoints == nil or #self.wayPoints == 0 then
                Logging.error("[AutoDrive] Could not calculate path - shutting down")
                self.vehicle.ad.taskModule:abortAllTasks()
                self.vehicle:stopAutoDrive()
                AutoDriveMessageEvent.sendMessageOrNotification(self.vehicle, ADMessagesManager.messageTypes.ERROR, "$l10n_AD_Driver_of; %s $l10n_AD_cannot_find_path;", 5000, self.vehicle.ad.stateModule:getName())
            else
                self.vehicle.ad.drivePathModule:setWayPoints(self.wayPoints)
                self.state = RepairTask.STATE_DRIVING
            end
        else
            self.vehicle.ad.pathFinderModule:update(dt)
            self.vehicle.ad.specialDrivingModule:stopVehicle()
            self.vehicle.ad.specialDrivingModule:update(dt)
        end
    else
        if self.vehicle.ad.drivePathModule:isTargetReached() then
            -- Do the actual repair here
            -- Todo, for all attached objects
            local event = WearableRepairEvent.new(self.vehicle, true)
            if g_server ~= nil then
                local implements = AutoDrive.getAllImplements(self.vehicle, true)
                for _, implement in pairs(implements) do
                    if implement ~= nil and implement.repairVehicle ~= nil then
                        implement:repairVehicle()
                        --g_server:broadcastEvent(self)
                        --g_messageCenter:publish(MessageType.VEHICLE_REPAIRED, self.vehicle, self.atSellingPoint)
                    end
                end
            end
            self:finished()
        else
            self.vehicle.ad.drivePathModule:update(dt)
        end
    end
end

function RepairTask:abort()
end

function RepairTask:finished()
    local callBackFunction = self.vehicle.ad.callBackFunction
    local callBackObject = self.vehicle.ad.callBackObject
    local callBackArg = self.vehicle.ad.callBackArg
    self.vehicle.ad.callBackFunction = nil
    self.vehicle.ad.callBackObject = nil
    self.vehicle.ad.callBackArg = nil

    self.vehicle:stopAutoDrive()
    self.vehicle.ad.stateModule:getCurrentMode():start()
    self.vehicle.ad.taskModule:setCurrentTaskFinished(ADTaskModule.DONT_PROPAGATE)
    
    self.vehicle.ad.callBackFunction = callBackFunction
    self.vehicle.ad.callBackObject = callBackObject
    self.vehicle.ad.callBackArg = callBackArg
end

function RepairTask:getInfoText()
    if self.state == RepairTask.STATE_PATHPLANNING then
        local actualState, maxStates = self.vehicle.ad.pathFinderModule:getCurrentState()
        return g_i18n:getText("AD_task_pathfinding") .. string.format(" %d / %d ", actualState, maxStates)
    else
        return g_i18n:getText("AD_task_drive_to_repair_point")
    end
end

function RepairTask:getI18nInfo()
    if self.state == RepairTask.STATE_PATHPLANNING then
        local actualState, maxStates = self.vehicle.ad.pathFinderModule:getCurrentState()
        return "$l10n_AD_task_pathfinding;" .. string.format(" %d / %d ", actualState, maxStates)
    else
        return "$l10n_AD_task_drive_to_repair_point;"
    end
end
